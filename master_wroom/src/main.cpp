/*******************************************************************************
 * SPARK — Master WROOM  v3.0  (Hardwired UART + WebSocket API)
 *
 * Hardware
 *   • ESP32-WROOM-32  (4 MB Flash)
 *   • BME680           (I2C  SDA 21 / SCL 22)
 *   • 5 V PWM Fan      (GPIO 4 via N-MOSFET)
 *   • MAX98357A I2S Amp (BCLK 27 / LRCLK 12 / DIN 14)  +  3 W Speaker
 *   • MicroSD Card      (SPI  MOSI 23 / MISO 19 / SCK 18 / CS 5)
 *   • WS2812B strip     (300 LEDs, GPIO 13, 3.3→5 V level-shifted)
 *
 * v3.0 Changes  (from v2.0)
 *   • Removed ESP-NOW entirely.  Inter-node comms now use hardwired UART
 *     over CAT5E Ethernet cable for commercial-grade reliability.
 *   • Serial1 (RX 16 / TX 17)  ↔  S3 Alpha
 *   • Serial2 (RX 25 / TX 26)  ↔  S3 Beta
 *   • Fan PWM moved from GPIO 25 → GPIO 4  (25 is now UART2 RX)
 *   • I2S BCLK moved from GPIO 26 → GPIO 27, LRCLK from 27 → 12
 *     (26 is now UART2 TX)
 *   • WiFi runs as pure STA for LAN access (no AP needed for ESP-NOW).
 *
 * Wiring  (CAT5E, ≤ 3 m, alongside 15 A LED power rail)
 *   ─────────────────────────────────────────────────────────
 *   Cable A  (Master ↔ S3 Alpha):
 *     Orange pair:  Solid = Master TX (17) → Alpha RX (18),  Striped = GND
 *     Green  pair:  Solid = Alpha  TX (17) → Master RX (16), Striped = GND
 *
 *   Cable B  (Master ↔ S3 Beta):
 *     Orange pair:  Solid = Master TX (26) → Beta RX (18),   Striped = GND
 *     Green  pair:  Solid = Beta   TX (17) → Master RX (25), Striped = GND
 *
 *   CRITICAL: pair each data line with GND on the striped wire.
 *   ─────────────────────────────────────────────────────────
 ******************************************************************************/

#include <Arduino.h>
#include <WiFi.h>
#include <driver/i2s.h>
#include <SPI.h>
#include <SD.h>
#include <Wire.h>
#include <Adafruit_BME680.h>
#include <FastLED.h>
#include <WebSocketsServer.h>
#include <ArduinoJson.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/queue.h>
#include "spark_protocol.h"

/* ===========================================================================
 *                       NETWORK CONFIGURATION
 * =========================================================================*/

// Local WiFi router credentials — change to match your network
#define WIFI_SSID     "YOUR_WIFI_SSID"
#define WIFI_PASS     "YOUR_WIFI_PASSWORD"
#define WS_PORT       81

/* ===========================================================================
 *                          PIN DEFINITIONS
 *
 *  GPIO 16 = UART1 RX (Alpha)    GPIO 17 = UART1 TX (Alpha)
 *  GPIO 25 = UART2 RX (Beta)     GPIO 26 = UART2 TX (Beta)
 *  ↑ These 4 pins are now reserved for inter-node UART.
 * =========================================================================*/

#define BME_SDA     21
#define BME_SCL     22

#define FAN_PIN     4           // moved from 25 (now UART2 RX)
#define FAN_CH      0
#define FAN_FREQ    25000
#define FAN_RES     8

#define I2S_BCLK    27          // moved from 26 (now UART2 TX)
#define I2S_LRCLK   12          // moved from 27 (taken by BCLK)
#define I2S_DIN     14

#define SD_MOSI     23
#define SD_MISO     19
#define SD_SCK      18
#define SD_CS       5

#define LED_PIN     13
#define NUM_LEDS    300
#define LED_BRIGHT  178

#define LED_A_START   0
#define LED_A_END   124
#define LED_NET_START 125
#define LED_NET_END   174
#define LED_B_START   175
#define LED_B_END     299

/* ===========================================================================
 *                          GLOBALS
 * =========================================================================*/

static Adafruit_BME680    bme;
static CRGB               leds[NUM_LEDS];
static WebSocketsServer   wsServer(WS_PORT);

// ---- UART receive state machines ----
static UartRxState        gRxAlpha;       // Serial1 — S3 Alpha
static UartRxState        gRxBeta;        // Serial2 — S3 Beta

// ---- Environment ----
static float    gTemp           = 25.0f;
static float    gHumidity       = 50.0f;
static float    gPressure       = 1013.25f;
static float    gSpeedOfSound   = 343.0f;
static uint8_t  gFanPWM         = 0;

// ---- Game state ----
static uint8_t   gScoreA        = 0;
static uint8_t   gScoreB        = 0;
static uint8_t   gServer        = 0;
static uint8_t   gFirstServer   = 0;
static GameState gState         = GS_IDLE;
static int64_t   gStateTime     = 0;
static bool      gNetTouched    = false;
static uint8_t   gExpectedBounce = 0;
static uint16_t  gRallyCount    = 0;

// ---- LED animation ----
static LEDMode   gLedMode       = LED_IDLE;
static uint32_t  gLedStart      = 0;

// ---- Audio queue ----
static QueueHandle_t qAudio     = nullptr;

// ---- Hit ring buffer ----
#define MAX_HITS 200
struct HitRecord { float x; float y; float velocity; uint8_t zone; };
static HitRecord gHits[MAX_HITS];
static int       gHitCount = 0;
static int       gHitIdx   = 0;

// ---- Calibration state ----
static bool    gCalibrationMode = false;
static uint8_t gCalibStep       = 0;

/* ===========================================================================
 *                  FORWARD DECLARATIONS
 * =========================================================================*/
static void processEvent(const uint8_t* data, int len);
static void awardPoint(uint8_t toSide);
static void updateServerRotation();
static void enterState(GameState ns);
static void updateLEDs();
static void wsBroadcast(const char* json);
static void wsPushState();
static void wsPushHit(float x, float y, float velocity, const char* evt);
static void wsPushPiezo(uint8_t nodeId, uint8_t sensorId, SensorZone zone);
static void wsPushCalibration();
static void wsPushEvent(const char* event, const char* detail);
static void playSound(const char* path);

/* ===========================================================================
 *                  BME680  +  SPEED OF SOUND  +  FAN PWM
 * =========================================================================*/

static void updateEnvironment() {
    if (!bme.performReading()) return;
    gTemp         = bme.temperature;
    gHumidity     = bme.humidity;
    gPressure     = bme.pressure / 100.0f;
    gSpeedOfSound = calcSpeedOfSound(gTemp, gHumidity);

    if      (gTemp < 35.0f)  gFanPWM = 0;
    else if (gTemp < 38.0f)  gFanPWM = 0;
    else if (gTemp < 45.0f)  gFanPWM = 77;      // 30 %
    else                     gFanPWM = 255;      // 100 %
    ledcWrite(FAN_CH, gFanPWM);
}

/// Send calibration packet to S3 Alpha so it updates its speed-of-sound.
static void broadcastCalibration() {
    CalibrationPacket cal = {};
    cal.type         = PKT_CALIBRATION;
    cal.speedOfSound = gSpeedOfSound;
    cal.temperature  = gTemp;
    cal.humidity     = gHumidity;
    cal.pressure     = gPressure;
    // Send over UART to Alpha
    uartSendPacket(Serial1, &cal, sizeof(cal));
    Serial.printf("[CAL] v=%.2f  T=%.1f  H=%.1f  P=%.1f\n",
                  gSpeedOfSound, gTemp, gHumidity, gPressure);
}

/* ===========================================================================
 *                   GAME  STATE  MACHINE
 * =========================================================================*/

static void enterState(GameState ns) {
    gState     = ns;
    gStateTime = esp_timer_get_time();
    if (ns == GS_RALLY) gRallyCount = 0;
    wsPushState();
}

static void processEvent(const uint8_t* data, int len) {
    PacketType t = (PacketType)data[0];

    /* ---- TDOA result (paddle hit) ---- */
    if (t == PKT_TDOA_RESULT && len >= (int)sizeof(TDOAResultPacket)) {
        const TDOAResultPacket* p = (const TDOAResultPacket*)data;

        static int64_t lastHitTime = 0;
        float velocity = 0;
        if (lastHitTime > 0) {
            float dt = (float)(p->timestamp_us - lastHitTime) / 1e6f;
            if (dt > 0.01f && dt < 2.0f)
                velocity = TABLE_LENGTH_MM / 1000.0f / dt;
        }
        lastHitTime = p->timestamp_us;

        gHits[gHitIdx] = {p->x, p->y, velocity, ZONE_PADDLE};
        gHitIdx = (gHitIdx + 1) % MAX_HITS;
        if (gHitCount < MAX_HITS) gHitCount++;

        wsPushHit(p->x, p->y, velocity, "paddle");

        if (gCalibrationMode) {
            char buf[128];
            snprintf(buf, sizeof(buf),
                "{\"type\":\"calibTap\",\"step\":%u,\"x\":%.1f,\"y\":%.1f}",
                gCalibStep, p->x, p->y);
            wsBroadcast(buf);
            return;
        }

        if (gState == GS_WAIT_SERVE) enterState(GS_SERVE_HIT);
        return;
    }

    /* ---- Net event ---- */
    if (t == PKT_NET_EVENT && len >= (int)sizeof(NetEventPacket)) {
        if (gState == GS_SERVE_BOUNCED || gState == GS_SERVE_HIT)
            gNetTouched = true;
        wsPushHit(TABLE_HALF_MM, TABLE_WIDTH_MM / 2.0f, 0, "net");
        wsPushEvent("net", "Net touched");
        return;
    }

    /* ---- Piezo event (table bounce) ---- */
    if (t == PKT_PIEZO_EVENT && len >= (int)sizeof(PiezoEventPacket)) {
        const PiezoEventPacket* p = (const PiezoEventPacket*)data;
        SensorZone zone = p->zone;

        wsPushPiezo(p->nodeId, p->sensorId, zone);

        switch (gState) {
        case GS_SERVE_HIT: {
            uint8_t serverSide = (gServer == 0) ? ZONE_SIDE_A : ZONE_SIDE_B;
            if (zone == serverSide) {
                enterState(GS_SERVE_BOUNCED);
                wsPushEvent("serve_bounce", "Serve bounced on server side");
            }
            break;
        }
        case GS_SERVE_BOUNCED: {
            uint8_t recvSide = (gServer == 0) ? ZONE_SIDE_B : ZONE_SIDE_A;
            if (zone == recvSide) {
                if (gNetTouched) {
                    enterState(GS_LET);
                    gLedMode = LED_LET_YELLOW; gLedStart = millis();
                    playSound(WAV_LET);
                    wsPushEvent("let", "LET — replay serve");
                } else {
                    gExpectedBounce = (gServer == 0) ? ZONE_SIDE_A : ZONE_SIDE_B;
                    enterState(GS_RALLY);
                    gLedMode = LED_SERVE_PULSE; gLedStart = millis();
                    wsPushEvent("rally", "Rally begins");
                }
                gNetTouched = false;
            }
            break;
        }
        case GS_RALLY: {
            gRallyCount++;
            if (zone == gExpectedBounce) {
                gExpectedBounce = (gExpectedBounce == ZONE_SIDE_A)
                                  ? ZONE_SIDE_B : ZONE_SIDE_A;
                gStateTime = esp_timer_get_time();
            } else {
                uint8_t winner = (zone == ZONE_SIDE_A) ? 1 : 0;
                awardPoint(winner);
            }
            break;
        }
        default: break;
        }
        return;
    }

    /* ---- Heartbeat ---- */
    if (t == PKT_HEARTBEAT) {
        const HeartbeatPacket* hb = (const HeartbeatPacket*)data;
        char buf[96];
        snprintf(buf, sizeof(buf),
            "{\"type\":\"heartbeat\",\"node\":%u,\"uptime\":%u,\"status\":%u}",
            hb->nodeId, hb->uptimeMs, hb->status);
        wsBroadcast(buf);
    }
}

static void checkTimeouts() {
    int64_t now   = esp_timer_get_time();
    int64_t delta = now - gStateTime;

    switch (gState) {
    case GS_SERVE_HIT:
        if (delta > SERVE_TIMEOUT_US) {
            awardPoint(1 - gServer);
            wsPushEvent("fault", "Serve timeout — fault");
        }
        break;
    case GS_SERVE_BOUNCED:
        if (delta > SERVE_TIMEOUT_US) {
            awardPoint(1 - gServer);
            wsPushEvent("fault", "Serve not returned");
        }
        break;
    case GS_RALLY:
        if (delta > RALLY_BOUNCE_TIMEOUT_US) {
            uint8_t winner = (gExpectedBounce == ZONE_SIDE_A) ? 0 : 1;
            awardPoint(winner);
            wsPushEvent("out", "Ball out — rally timeout");
        }
        break;
    case GS_LET:
        if (delta > 2000000) {
            enterState(GS_WAIT_SERVE);
            gLedMode = LED_SCORE; gLedStart = millis();
        }
        break;
    case GS_POINT:
        if (delta > 2000000) {
            enterState(GS_WAIT_SERVE);
            gLedMode = LED_SCORE; gLedStart = millis();
        }
        break;
    default: break;
    }
}

/* ===========================================================================
 *                    SCORING  &  SERVICE  ROTATION
 * =========================================================================*/

static void awardPoint(uint8_t toSide) {
    if (toSide == 0) {
        gScoreA++;
        gLedMode = LED_POINT_GREEN; gLedStart = millis();
        playSound(WAV_POINT_A);
        wsPushEvent("point", "Point Player A");
    } else {
        gScoreB++;
        gLedMode = LED_POINT_GREEN; gLedStart = millis();
        playSound(WAV_POINT_B);
        wsPushEvent("point", "Point Player B");
    }

    uint8_t prev = gServer;
    updateServerRotation();
    if (gServer != prev) {
        playSound(WAV_CHANGE_SERVER);
        wsPushEvent("serve_change", gServer == 0 ? "Service → A" : "Service → B");
    }

    if (gScoreA >= 10 && gScoreB >= 10 && gScoreA == gScoreB)
        playSound(WAV_DEUCE);
    if ((gScoreA == 10 && gScoreB < 10) || (gScoreB == 10 && gScoreA < 10))
        playSound(WAV_MATCH_POINT);

    bool over = false;
    if (gScoreA >= 11 && gScoreA - gScoreB >= 2) over = true;
    if (gScoreB >= 11 && gScoreB - gScoreA >= 2) over = true;

    if (over) {
        enterState(GS_GAME_OVER);
        gLedMode = LED_GAME_OVER; gLedStart = millis();
        playSound(WAV_GAME_OVER);
        char buf[160];
        snprintf(buf, sizeof(buf),
            "{\"type\":\"gameOver\",\"winner\":%u,\"scoreA\":%u,\"scoreB\":%u,\"rally\":%u}",
            toSide, gScoreA, gScoreB, gRallyCount);
        wsBroadcast(buf);
    } else {
        enterState(GS_POINT);
    }
    wsPushState();
}

static void updateServerRotation() {
    int total = gScoreA + gScoreB;
    bool deuce = (gScoreA >= 10 && gScoreB >= 10);
    int turns = deuce ? (10 + total - 20) : (total / 2);
    gServer = (turns % 2 == 0) ? gFirstServer : (1 - gFirstServer);
}

/* ===========================================================================
 *                  LED  STRIP  (same animations as v1)
 * =========================================================================*/

static void showScore() {
    int ledsPerPt = 11;
    int litA = min((int)gScoreA * ledsPerPt, 125);
    for (int i = LED_A_START; i <= LED_A_END; ++i)
        leds[i] = (i < LED_A_START + litA) ? CRGB(0xFF, 0x20, 0x20) : CRGB::Black;
    int litB = min((int)gScoreB * ledsPerPt, 125);
    for (int i = LED_B_END; i >= LED_B_START; --i)
        leds[i] = ((LED_B_END - i) < litB) ? CRGB(0x20, 0x60, 0xFF) : CRGB::Black;
    for (int i = LED_NET_START; i <= LED_NET_END; ++i)
        leds[i] = CRGB(30, 30, 30);
}

static void updateLEDs() {
    uint32_t now = millis();
    uint32_t elapsed = now - gLedStart;

    switch (gLedMode) {
    case LED_OFF:
        fill_solid(leds, NUM_LEDS, CRGB::Black); break;
    case LED_IDLE: {
        uint8_t b = beatsin8(15, 20, 80);
        fill_solid(leds, NUM_LEDS, CRGB::Black);
        for (int i = LED_NET_START; i <= LED_NET_END; ++i) leds[i] = CRGB(0,0,b);
        break;
    }
    case LED_SERVE_PULSE: {
        showScore();
        uint8_t b = beatsin8(40, 60, 200);
        for (int i = LED_NET_START; i <= LED_NET_END; ++i) leds[i] = CRGB(0,0,b);
        if (elapsed > 1000) { gLedMode = LED_SCORE; gLedStart = now; }
        break;
    }
    case LED_POINT_GREEN: {
        if (elapsed < 500) {
            uint8_t g = (elapsed / 50 % 2 == 0) ? 255 : 0;
            fill_solid(leds, NUM_LEDS, CRGB(0,g,0));
        } else { showScore(); gLedMode = LED_SCORE; gLedStart = now; }
        break;
    }
    case LED_FAULT_RED: {
        if (elapsed < 600) {
            uint8_t r = (elapsed / 60 % 2 == 0) ? 255 : 0;
            fill_solid(leds, NUM_LEDS, CRGB(r,0,0));
        } else { showScore(); gLedMode = LED_SCORE; gLedStart = now; }
        break;
    }
    case LED_LET_YELLOW: {
        if (elapsed < 1500) {
            for (int i = 0; i < NUM_LEDS; ++i) {
                uint8_t wave = sin8((uint8_t)(i * 3 + elapsed / 4));
                leds[i] = CRGB(wave, wave/2, 0);
            }
        } else { showScore(); gLedMode = LED_SCORE; gLedStart = now; }
        break;
    }
    case LED_SCORE:
        showScore(); break;
    case LED_GAME_OVER: {
        for (int i = 0; i < NUM_LEDS; ++i)
            leds[i] = CHSV((uint8_t)(i*2 + elapsed/10), 255, 180);
        break;
    }
    default: break;
    }
    FastLED.show();
}

/* ===========================================================================
 *                  AUDIO  (WAV → I2S, unchanged)
 * =========================================================================*/

struct WavHeader {
    char riff[4]; uint32_t fileSize; char wave[4]; char fmt[4];
    uint32_t fmtSize; uint16_t audioFormat; uint16_t numChannels;
    uint32_t sampleRate; uint32_t byteRate; uint16_t blockAlign;
    uint16_t bitsPerSample; char data[4]; uint32_t dataSize;
};

static void audioTask(void*) {
    char path[64];
    uint8_t buf[512];
    for (;;) {
        if (xQueueReceive(qAudio, path, portMAX_DELAY) != pdTRUE) continue;
        File f = SD.open(path, FILE_READ);
        if (!f) { Serial.printf("[AUD] open FAIL %s\n", path); continue; }

        WavHeader hdr;
        if (f.read((uint8_t*)&hdr, sizeof(hdr)) != sizeof(hdr)) { f.close(); continue; }

        if (memcmp(hdr.data, "data", 4) != 0) {
            f.seek(12);
            while (f.available()) {
                char tag[4]; uint32_t sz;
                f.read((uint8_t*)tag, 4);
                f.read((uint8_t*)&sz, 4);
                if (memcmp(tag, "data", 4) == 0) { hdr.dataSize = sz; break; }
                f.seek(f.position() + sz);
            }
        }

        i2s_set_sample_rates(I2S_NUM_0, hdr.sampleRate);
        uint32_t remaining = hdr.dataSize;
        while (remaining > 0 && f.available()) {
            size_t toRead = min((size_t)remaining, sizeof(buf));
            size_t got = f.read(buf, toRead);
            if (got == 0) break;
            size_t written;
            i2s_write(I2S_NUM_0, buf, got, &written, portMAX_DELAY);
            remaining -= got;
        }
        i2s_zero_dma_buffer(I2S_NUM_0);
        f.close();
    }
}

static void playSound(const char* path) {
    xQueueSend(qAudio, path, 0);
}

/* ===========================================================================
 *          WEBSOCKET  SERVER  (port 81, with ping/pong heartbeat)
 * =========================================================================*/

static void handleWSCommand(uint8_t clientNum, const char* payload) {
    StaticJsonDocument<512> doc;
    DeserializationError err = deserializeJson(doc, payload);
    if (err) { Serial.printf("[WS] JSON err: %s\n", err.c_str()); return; }

    const char* cmd = doc["cmd"] | "";

    /* ---- Game control ---- */
    if (strcmp(cmd, "start") == 0) {
        gScoreA = gScoreB = 0;
        gRallyCount = 0;
        gFirstServer = doc["firstServer"] | 0;
        gServer = gFirstServer;
        enterState(GS_WAIT_SERVE);
        gLedMode = LED_SCORE; gLedStart = millis();
        playSound(WAV_GAME_START);
        wsPushState();
        wsPushEvent("game", "Game started");
    }
    else if (strcmp(cmd, "reset") == 0) {
        gScoreA = gScoreB = 0;
        gRallyCount = 0;
        gServer = 0;
        enterState(GS_IDLE);
        gLedMode = LED_IDLE; gLedStart = millis();
        gHitCount = gHitIdx = 0;
        wsPushState();
        wsPushEvent("game", "Game reset");
    }
    /* ---- LED mode ---- */
    else if (strcmp(cmd, "led") == 0) {
        const char* mode = doc["mode"] | "score";
        if      (strcmp(mode, "off") == 0)     gLedMode = LED_OFF;
        else if (strcmp(mode, "idle") == 0)    gLedMode = LED_IDLE;
        else if (strcmp(mode, "score") == 0)   gLedMode = LED_SCORE;
        else if (strcmp(mode, "victory") == 0) gLedMode = LED_GAME_OVER;
        gLedStart = millis();
    }
    /* ---- Custom LED colour ---- */
    else if (strcmp(cmd, "ledColor") == 0) {
        uint8_t r = doc["r"] | 0;
        uint8_t g = doc["g"] | 0;
        uint8_t b = doc["b"] | 0;
        fill_solid(leds, NUM_LEDS, CRGB(r, g, b));
        FastLED.show();
        gLedMode = LED_OFF;
    }
    /* ---- Play sound ---- */
    else if (strcmp(cmd, "playSound") == 0) {
        const char* file = doc["file"] | "";
        if (strlen(file) > 0) playSound(file);
    }
    /* ---- Calibration ---- */
    else if (strcmp(cmd, "calibStart") == 0) {
        gCalibrationMode = true;
        gCalibStep = 0;
        wsPushCalibration();
        wsPushEvent("calib", "Calibration mode entered");
    }
    else if (strcmp(cmd, "calibNext") == 0) {
        gCalibStep++;
        if (gCalibStep > 3) {
            gCalibrationMode = false;
            gCalibStep = 0;
            wsPushEvent("calib", "Calibration complete");
        }
    }
    else if (strcmp(cmd, "calibStop") == 0) {
        gCalibrationMode = false;
        gCalibStep = 0;
    }
    /* ---- One-shot env request ---- */
    else if (strcmp(cmd, "getEnv") == 0) {
        wsPushCalibration();
    }
    /* ---- Hit history dump ---- */
    else if (strcmp(cmd, "getHits") == 0) {
        DynamicJsonDocument arr(4096);
        JsonArray a = arr.to<JsonArray>();
        for (int i = 0; i < gHitCount; ++i) {
            int idx = (gHitIdx - gHitCount + i + MAX_HITS) % MAX_HITS;
            JsonObject h = a.createNestedObject();
            h["x"] = gHits[idx].x;
            h["y"] = gHits[idx].y;
            h["v"] = gHits[idx].velocity;
        }
        char buf[4096];
        serializeJson(arr, buf, sizeof(buf));
        char out[4200];
        snprintf(out, sizeof(out), "{\"type\":\"hitHistory\",\"hits\":%s}", buf);
        wsServer.sendTXT(clientNum, out);
    }
}

static void onWSEvent(uint8_t clientNum, WStype_t type,
                      uint8_t* payload, size_t length)
{
    switch (type) {
    case WStype_CONNECTED: {
        IPAddress ip = wsServer.remoteIP(clientNum);
        Serial.printf("[WS] #%u connected from %s\n", clientNum, ip.toString().c_str());
        wsPushState();
        wsPushCalibration();
        break;
    }
    case WStype_DISCONNECTED:
        Serial.printf("[WS] #%u disconnected\n", clientNum);
        break;
    case WStype_TEXT:
        handleWSCommand(clientNum, (const char*)payload);
        break;
    case WStype_PONG:
        break;
    default: break;
    }
}

/* ---- Broadcast helpers ---- */
static void wsBroadcast(const char* json) {
    wsServer.broadcastTXT(json);
}

static void wsPushState() {
    char buf[320];
    snprintf(buf, sizeof(buf),
        "{\"type\":\"state\",\"scoreA\":%u,\"scoreB\":%u,\"server\":%u,"
        "\"gameState\":%u,\"rally\":%u}",
        gScoreA, gScoreB, gServer, (uint8_t)gState, gRallyCount);
    wsBroadcast(buf);
}

static void wsPushHit(float x, float y, float velocity, const char* evt) {
    char buf[160];
    snprintf(buf, sizeof(buf),
        "{\"type\":\"hit\",\"x\":%.1f,\"y\":%.1f,\"velocity\":%.1f,\"event\":\"%s\"}",
        x, y, velocity, evt);
    wsBroadcast(buf);
}

static void wsPushPiezo(uint8_t nodeId, uint8_t sensorId, SensorZone zone) {
    char buf[96];
    snprintf(buf, sizeof(buf),
        "{\"type\":\"piezo\",\"node\":%u,\"sensor\":%u,\"zone\":%u}",
        nodeId, sensorId, (uint8_t)zone);
    wsBroadcast(buf);
}

static void wsPushCalibration() {
    char buf[256];
    snprintf(buf, sizeof(buf),
        "{\"type\":\"env\",\"temp\":%.2f,\"humidity\":%.1f,\"pressure\":%.1f,"
        "\"speedOfSound\":%.2f,\"fanPWM\":%u,\"calibMode\":%s,\"calibStep\":%u}",
        gTemp, gHumidity, gPressure, gSpeedOfSound, gFanPWM,
        gCalibrationMode ? "true" : "false", gCalibStep);
    wsBroadcast(buf);
}

static void wsPushEvent(const char* event, const char* detail) {
    char buf[192];
    snprintf(buf, sizeof(buf),
        "{\"type\":\"event\",\"event\":\"%s\",\"detail\":\"%s\",\"ts\":%lu}",
        event, detail, millis());
    wsBroadcast(buf);
}

/* ===========================================================================
 *                       I2S  OUTPUT  (speaker)
 * =========================================================================*/

static void initI2SOutput() {
    i2s_config_t cfg = {};
    cfg.mode                 = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_TX);
    cfg.sample_rate          = 16000;
    cfg.bits_per_sample      = I2S_BITS_PER_SAMPLE_16BIT;
    cfg.channel_format       = I2S_CHANNEL_FMT_ONLY_LEFT;
    cfg.communication_format = I2S_COMM_FORMAT_STAND_I2S;
    cfg.intr_alloc_flags     = ESP_INTR_FLAG_LEVEL1;
    cfg.dma_buf_count        = 8;
    cfg.dma_buf_len          = 128;
    cfg.use_apll             = false;
    cfg.tx_desc_auto_clear   = true;
    i2s_driver_install(I2S_NUM_0, &cfg, 0, nullptr);

    i2s_pin_config_t pins = {};
    pins.bck_io_num   = I2S_BCLK;
    pins.ws_io_num    = I2S_LRCLK;
    pins.data_out_num = I2S_DIN;
    pins.data_in_num  = I2S_PIN_NO_CHANGE;
    i2s_set_pin(I2S_NUM_0, &pins);
}

/* ===========================================================================
 *                             SETUP
 * =========================================================================*/

void setup() {
    Serial.begin(115200);
    delay(500);
    Serial.println("\n=== SPARK  Master WROOM  v3.0  (UART + WebSocket API) ===");

    // ---- UART1 → S3 Alpha ----
    Serial1.begin(UART_BAUD_RATE, SERIAL_8N1, MASTER_UART1_RX, MASTER_UART1_TX);
    Serial.printf("[UART1] Alpha link @ %d baud  (RX=%d TX=%d)\n",
                  UART_BAUD_RATE, MASTER_UART1_RX, MASTER_UART1_TX);

    // ---- UART2 → S3 Beta ----
    Serial2.begin(UART_BAUD_RATE, SERIAL_8N1, MASTER_UART2_RX, MASTER_UART2_TX);
    Serial.printf("[UART2] Beta  link @ %d baud  (RX=%d TX=%d)\n",
                  UART_BAUD_RATE, MASTER_UART2_RX, MASTER_UART2_TX);

    // ---- I2C + BME680 ----
    Wire.begin(BME_SDA, BME_SCL);
    if (!bme.begin()) {
        Serial.println("[BME] init FAIL — check wiring");
    } else {
        bme.setTemperatureOversampling(BME680_OS_8X);
        bme.setHumidityOversampling(BME680_OS_2X);
        bme.setPressureOversampling(BME680_OS_4X);
        bme.setIIRFilterSize(BME680_FILTER_SIZE_3);
        Serial.println("[BME] ok");
    }

    // ---- Fan PWM ----
    ledcSetup(FAN_CH, FAN_FREQ, FAN_RES);
    ledcAttachPin(FAN_PIN, FAN_CH);
    ledcWrite(FAN_CH, 0);
    Serial.println("[FAN] PWM 25 kHz ready on GPIO 4");

    // ---- SD card ----
    SPI.begin(SD_SCK, SD_MISO, SD_MOSI, SD_CS);
    if (!SD.begin(SD_CS))
        Serial.println("[SD] mount FAIL");
    else
        Serial.printf("[SD] %llu MB\n", SD.cardSize() / (1024*1024));

    // ---- I2S speaker ----
    initI2SOutput();
    Serial.println("[I2S] speaker output ready (BCLK=27 LRCLK=12 DIN=14)");

    // ---- LED strip ----
    FastLED.addLeds<WS2812B, LED_PIN, GRB>(leds, NUM_LEDS);
    FastLED.setBrightness(LED_BRIGHT);
    fill_solid(leds, NUM_LEDS, CRGB::Black);
    FastLED.show();
    Serial.println("[LED] 300x WS2812B @ 70%%");

    // ---- WiFi: STA only (no AP needed — ESP-NOW removed) ----
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASS);
    Serial.print("[WiFi] connecting");
    int tries = 0;
    while (WiFi.status() != WL_CONNECTED && tries < 40) {
        delay(500); Serial.print("."); tries++;
    }
    if (WiFi.status() == WL_CONNECTED)
        Serial.printf("\n[WiFi] STA IP: %s\n", WiFi.localIP().toString().c_str());
    else
        Serial.println("\n[WiFi] STA FAIL — no WS clients can connect");

    // ---- Queues ----
    qAudio = xQueueCreate(8, 64);

    // ---- Audio task (Core 0) ----
    xTaskCreatePinnedToCore(audioTask, "audio", 8192, nullptr, 2, nullptr, 0);

    // ---- WebSocket server on port 81 ----
    wsServer.begin();
    wsServer.onEvent(onWSEvent);
    wsServer.enableHeartbeat(15000, 3000, 2);
    Serial.printf("[WS] server on :%d  (ping/pong enabled)\n", WS_PORT);

    // Initial readings
    updateEnvironment();
    broadcastCalibration();

    gLedMode = LED_IDLE; gLedStart = millis();
    Serial.println(">>> Master v3.0 READY <<<\n");
}

/* ===========================================================================
 *                             LOOP
 * =========================================================================*/

static uint32_t lastEnv     = 0;
static uint32_t lastCal     = 0;
static uint32_t lastLED     = 0;
static uint32_t lastWSPush  = 0;

void loop() {
    uint32_t now = millis();

    // ---- WebSocket tick ----
    wsServer.loop();

    // ---- Poll UART1 (S3 Alpha) for incoming packets ----
    {
        uint8_t  buf[256];
        uint16_t len = 0;
        while (uartPollPacket(Serial1, gRxAlpha, buf, &len))
            processEvent(buf, len);
    }

    // ---- Poll UART2 (S3 Beta) for incoming packets ----
    {
        uint8_t  buf[256];
        uint16_t len = 0;
        while (uartPollPacket(Serial2, gRxBeta, buf, &len))
            processEvent(buf, len);
    }

    // ---- Timeout checks ----
    checkTimeouts();

    // ---- Environment every 2 s ----
    if (now - lastEnv >= 2000) {
        lastEnv = now;
        updateEnvironment();
    }

    // ---- Calibration broadcast to Alpha every 60 s ----
    if (now - lastCal >= CALIBRATION_INTERVAL_MS) {
        lastCal = now;
        broadcastCalibration();
    }

    // ---- LED update every 20 ms (50 fps) ----
    if (now - lastLED >= 20) {
        lastLED = now;
        updateLEDs();
    }

    // ---- Periodic WS push every 1 s ----
    if (now - lastWSPush >= 1000) {
        lastWSPush = now;
        wsPushState();
        wsPushCalibration();
    }

    vTaskDelay(1);
}
