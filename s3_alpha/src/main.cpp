/*******************************************************************************
 * SPARK — S3 Alpha  (Acoustic Brain + Side-A Piezos)    v2.0  UART
 *
 * Hardware
 *   • ESP32-S3  (16 MB Flash, 8 MB PSRAM)
 *   • 4× INMP441 I2S MEMS microphones  (corners of the table)
 *   • 4× 35 mm Piezos via LM393 / SW420  (Side-A corners, digital interrupt)
 *
 * Role
 *   1.  Continuously DMA-buffer stereo I2S audio from 2 buses (4 mics).
 *   2.  On a piezo interrupt OR acoustic impulse → run TDOA across 4 mic
 *       streams → multilaterate the (x, y) coordinate.
 *   3.  Forward PiezoEventPacket + TDOAResultPacket to Master via UART.
 *   4.  Accept CalibrationPacket from the Master over the same UART link.
 *
 * Wiring  (CAT5E, ≤ 3 m)
 *   ─────────────────────────────────────────────────────────
 *   This node connects to the Master WROOM via Serial1.
 *     Serial1  TX = GPIO 17   →  Master UART1 RX (GPIO 16)
 *     Serial1  RX = GPIO 18   ←  Master UART1 TX (GPIO 17)
 *
 *   CAT5E pin-out (alongside 15 A LED power rail):
 *     Orange pair:  Solid = TX,  Striped = GND
 *     Green  pair:  Solid = RX,  Striped = GND
 *   ─────────────────────────────────────────────────────────
 ******************************************************************************/

#include <Arduino.h>
#include <driver/i2s.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/queue.h>
#include <math.h>
#include "spark_protocol.h"

/* ===========================================================================
 *                          PIN DEFINITIONS
 * =========================================================================*/

// I2S Bus 0  — Mic 0 (L/R → GND = Left)  +  Mic 1 (L/R → VDD = Right)
#define I2S0_SCK    5
#define I2S0_WS     6
#define I2S0_SD     7

// I2S Bus 1  — Mic 2 (Left)  +  Mic 3 (Right)
#define I2S1_SCK    15
#define I2S1_WS     16
#define I2S1_SD     4       // moved from 17 (UART TX) to 4

// Side-A piezo digital inputs  (active-LOW from LM393)
#define PIEZO_A0    35
#define PIEZO_A1    36
#define PIEZO_A2    37
#define PIEZO_A3    38

static const uint8_t piezoPins[] = {PIEZO_A0, PIEZO_A1, PIEZO_A2, PIEZO_A3};
#define NUM_PIEZOS  4

#define STATUS_LED  48

/* ===========================================================================
 *                          GLOBALS
 * =========================================================================*/

// Speed of sound (updated by Master calibration packets over UART)
static volatile float gSpeedOfSound = 343.0f;

// --- Piezo ISR state ---
static volatile int64_t  gPiezoTime       = 0;
static volatile uint8_t  gPiezoId         = 0xFF;
static volatile bool     gPiezoFired      = false;
static volatile int64_t  gLastPiezoTime   = 0;

// --- Acoustic (paddle-hit) trigger state ---
static volatile bool     gAcousticFired   = false;
static volatile int64_t  gAcousticTime    = 0;
static volatile int64_t  gLastAcousticTime = 0;

// --- Ring buffers (PSRAM) for 4 microphones ---
static int32_t*         gMicBuf[4]  = {nullptr};
static volatile uint32_t gMicWr[4]  = {0, 0, 0, 0};

// --- FreeRTOS handles ---
static TaskHandle_t      hTDOA       = nullptr;
static TaskHandle_t      hI2S0       = nullptr;
static TaskHandle_t      hI2S1       = nullptr;
static TaskHandle_t      hPiezoSend  = nullptr;
static QueueHandle_t     qPiezoEvt   = nullptr;     // PiezoEventPacket queue

// --- UART RX state (for incoming CalibrationPackets from Master) ---
static UartRxState       gUartRx;

/* ===========================================================================
 *                     PIEZO  INTERRUPT  SERVICE  ROUTINES
 * =========================================================================*/

static void IRAM_ATTR piezoISR(void* arg) {
    int64_t now = esp_timer_get_time();
    if (now - gLastPiezoTime < DEBOUNCE_US) return;
    gLastPiezoTime = now;

    uint8_t id = (uint8_t)(uintptr_t)arg;
    gPiezoTime  = now;
    gPiezoId    = id;
    gPiezoFired = true;

    // Queue a packet for fast forwarding to Master
    PiezoEventPacket pkt;
    pkt.type         = PKT_PIEZO_EVENT;
    pkt.nodeId       = NODE_ALPHA;
    pkt.sensorId     = id;
    pkt.zone         = ZONE_SIDE_A;
    pkt.timestamp_us = now;
    pkt.intensity    = 0;
    BaseType_t woken = pdFALSE;
    xQueueSendFromISR(qPiezoEvt, &pkt, &woken);

    // Also wake the TDOA task
    if (hTDOA) vTaskNotifyGiveFromISR(hTDOA, &woken);
    portYIELD_FROM_ISR(woken);
}

/* ===========================================================================
 *                     I2S  CONFIGURATION
 * =========================================================================*/

static void initI2SBus(i2s_port_t port, int sck, int ws, int sd) {
    i2s_config_t cfg = {};
    cfg.mode                 = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_RX);
    cfg.sample_rate          = I2S_SAMPLE_RATE;
    cfg.bits_per_sample      = I2S_BITS_PER_SAMPLE_32BIT;
    cfg.channel_format       = I2S_CHANNEL_FMT_RIGHT_LEFT;
    cfg.communication_format = I2S_COMM_FORMAT_STAND_I2S;
    cfg.intr_alloc_flags     = ESP_INTR_FLAG_LEVEL1;
    cfg.dma_buf_count        = 8;
    cfg.dma_buf_len          = 256;
    cfg.use_apll             = true;
    cfg.tx_desc_auto_clear   = false;
    cfg.fixed_mclk           = 0;
    i2s_driver_install(port, &cfg, 0, nullptr);

    i2s_pin_config_t pins = {};
    pins.bck_io_num   = sck;
    pins.ws_io_num    = ws;
    pins.data_out_num = I2S_PIN_NO_CHANGE;
    pins.data_in_num  = sd;
    i2s_set_pin(port, &pins);
}

/* ===========================================================================
 *              I2S  DMA  READ  TASKS  (pinned to Core 0)
 *  Each task reads stereo frames and de-interleaves into per-mic ring buffers.
 * =========================================================================*/

static void i2sReadTask0(void*) {
    int32_t dma[512];            // 256 stereo frames
    size_t  br;
    for (;;) {
        i2s_read(I2S_NUM_0, dma, sizeof(dma), &br, portMAX_DELAY);
        int frames = br / (2 * sizeof(int32_t));
        for (int i = 0; i < frames; ++i) {
            int32_t L = dma[i * 2];
            int32_t R = dma[i * 2 + 1];
            uint32_t idx0 = gMicWr[0] % RING_BUFFER_SAMPLES;
            uint32_t idx1 = gMicWr[1] % RING_BUFFER_SAMPLES;
            gMicBuf[0][idx0] = L;   gMicWr[0]++;
            gMicBuf[1][idx1] = R;   gMicWr[1]++;

            // --- acoustic paddle-hit detector (on Mic 0) ---
            int64_t now = esp_timer_get_time();
            if (abs(L) > ACOUSTIC_THRESHOLD &&
                (now - gLastPiezoTime > 50000) &&
                (now - gLastAcousticTime > 100000)) {
                gAcousticFired = true;
                gAcousticTime  = now;
                gLastAcousticTime = now;
                if (hTDOA) {
                    BaseType_t w = pdFALSE;
                    vTaskNotifyGiveFromISR(hTDOA, &w);
                }
            }
        }
    }
}

static void i2sReadTask1(void*) {
    int32_t dma[512];
    size_t  br;
    for (;;) {
        i2s_read(I2S_NUM_1, dma, sizeof(dma), &br, portMAX_DELAY);
        int frames = br / (2 * sizeof(int32_t));
        for (int i = 0; i < frames; ++i) {
            uint32_t idx2 = gMicWr[2] % RING_BUFFER_SAMPLES;
            uint32_t idx3 = gMicWr[3] % RING_BUFFER_SAMPLES;
            gMicBuf[2][idx2] = dma[i * 2];     gMicWr[2]++;
            gMicBuf[3][idx3] = dma[i * 2 + 1]; gMicWr[3]++;
        }
    }
}

/* ===========================================================================
 *                 CROSS-CORRELATION  (integer, O(N·maxLag))
 * =========================================================================*/

static int crossCorrelate(const int32_t* a, const int32_t* b,
                          int N, int maxLag, float* peakVal)
{
    int   bestLag  = 0;
    float bestCorr = -1e30f;
    for (int lag = -maxLag; lag <= maxLag; ++lag) {
        float corr  = 0;
        int   count = 0;
        for (int n = 0; n < N; ++n) {
            int m = n + lag;
            if (m >= 0 && m < N) {
                corr += (float)a[n] * (float)b[m];
                ++count;
            }
        }
        if (count) corr /= count;
        if (corr > bestCorr) { bestCorr = corr; bestLag = lag; }
    }
    *peakVal = bestCorr;
    return bestLag;
}

/* Sub-sample parabolic interpolation around the peak */
static float refineLag(const int32_t* a, const int32_t* b,
                       int N, int coarseLag)
{
    auto cc = [&](int lag) -> float {
        float s = 0; int c = 0;
        for (int n = 0; n < N; ++n) {
            int m = n + lag;
            if (m >= 0 && m < N) { s += (float)a[n] * (float)b[m]; ++c; }
        }
        return c ? s / c : 0;
    };
    float ym1 = cc(coarseLag - 1);
    float y0  = cc(coarseLag);
    float yp1 = cc(coarseLag + 1);
    float denom = ym1 - 2.0f * y0 + yp1;
    if (fabsf(denom) < 1e-10f) return (float)coarseLag;
    return (float)coarseLag + 0.5f * (ym1 - yp1) / denom;
}

/* ===========================================================================
 *          TDOA  MULTILATERATION  (2-D + r0 → 3×3 linear solve)
 *
 *  Mic 0 is the reference.  Three hyperbolic range-difference equations
 *  are linearised into A·[x  y  r0]ᵀ = b and solved via Cramer's rule.
 * =========================================================================*/

static bool solveTDOA2D(const float delays[3], float speed,
                        float* outX, float* outY, float* outConf)
{
    float d[3];
    for (int i = 0; i < 3; ++i) d[i] = speed * delays[i];

    float mx[4], my[4], K[4];
    for (int i = 0; i < 4; ++i) {
        mx[i] = MIC_POS[i][0];
        my[i] = MIC_POS[i][1];
        K[i]  = mx[i] * mx[i] + my[i] * my[i];
    }

    float A[3][3], b[3];
    for (int i = 0; i < 3; ++i) {
        int j = i + 1;
        A[i][0] = -2.0f * (mx[j] - mx[0]);
        A[i][1] = -2.0f * (my[j] - my[0]);
        A[i][2] = -2.0f * d[i];
        b[i]    = d[i] * d[i] - K[j] + K[0];
    }

    float det = A[0][0] * (A[1][1] * A[2][2] - A[1][2] * A[2][1])
              - A[0][1] * (A[1][0] * A[2][2] - A[1][2] * A[2][0])
              + A[0][2] * (A[1][0] * A[2][1] - A[1][1] * A[2][0]);
    if (fabsf(det) < 1e-6f) { *outConf = 0; return false; }
    float inv = 1.0f / det;

    float x = (b[0]    * (A[1][1]*A[2][2] - A[1][2]*A[2][1])
             - A[0][1] * (b[1]   *A[2][2] - A[1][2]*b[2])
             + A[0][2] * (b[1]   *A[2][1] - A[1][1]*b[2])) * inv;

    float y = (A[0][0] * (b[1]   *A[2][2] - A[1][2]*b[2])
             - b[0]    * (A[1][0]*A[2][2] - A[1][2]*A[2][0])
             + A[0][2] * (A[1][0]*b[2]    - b[1]   *A[2][0])) * inv;

    float r0 = (A[0][0] * (A[1][1]*b[2]    - b[1]*A[2][1])
              - A[0][1] * (A[1][0]*b[2]    - b[1]*A[2][0])
              + b[0]    * (A[1][0]*A[2][1] - A[1][1]*A[2][0])) * inv;

    float conf = 1.0f;
    if (r0 < 0)                              conf *= 0.3f;
    if (x < -200 || x > TABLE_LENGTH_MM+200) conf *= 0.3f;
    if (y < -200 || y > TABLE_WIDTH_MM +200) conf *= 0.3f;

    *outX    = x;
    *outY    = y;
    *outConf = conf;
    return true;
}

/* ===========================================================================
 *                      TDOA  FreeRTOS  TASK  (Core 1)
 * =========================================================================*/

static void tdoaTask(void*) {
    int32_t* win[4];
    for (int i = 0; i < 4; ++i)
        win[i] = (int32_t*)ps_malloc(TDOA_WINDOW_SAMPLES * sizeof(int32_t));

    for (;;) {
        ulTaskNotifyTake(pdTRUE, portMAX_DELAY);

        bool wasPiezo    = gPiezoFired;
        bool wasAcoustic = gAcousticFired;
        int64_t trigTime = wasPiezo ? gPiezoTime : gAcousticTime;
        gPiezoFired    = false;
        gAcousticFired = false;
        if (!wasPiezo && !wasAcoustic) continue;

        vTaskDelay(pdMS_TO_TICKS(16));

        for (int m = 0; m < 4; ++m) {
            uint32_t end   = gMicWr[m];
            uint32_t start = end - TDOA_WINDOW_SAMPLES;
            for (int s = 0; s < TDOA_WINDOW_SAMPLES; ++s)
                win[m][s] = gMicBuf[m][(start + s) % RING_BUFFER_SAMPLES];
        }

        float delays[3];
        for (int i = 0; i < 3; ++i) {
            float pk;
            int coarse = crossCorrelate(win[0], win[i + 1],
                                        TDOA_WINDOW_SAMPLES,
                                        TDOA_MAX_DELAY_SAMPLES, &pk);
            float refined = refineLag(win[0], win[i + 1],
                                      TDOA_WINDOW_SAMPLES, coarse);
            delays[i] = refined / (float)I2S_SAMPLE_RATE;
        }

        float x, y, conf;
        if (solveTDOA2D(delays, gSpeedOfSound, &x, &y, &conf)) {
            TDOAResultPacket pkt = {};
            pkt.type         = PKT_TDOA_RESULT;
            pkt.nodeId       = NODE_ALPHA;
            pkt.x            = x;
            pkt.y            = y;
            pkt.z            = 0;
            pkt.confidence   = conf;
            pkt.timestamp_us = trigTime;
            // Send to Master over UART
            uartSendPacket(Serial1, &pkt, sizeof(pkt));
        }
    }
}

/* ===========================================================================
 *          PIEZO  SEND  TASK  (forwards queued events to Master via UART)
 * =========================================================================*/

static void piezoSendTask(void*) {
    PiezoEventPacket pkt;
    for (;;) {
        if (xQueueReceive(qPiezoEvt, &pkt, portMAX_DELAY) == pdTRUE) {
            uartSendPacket(Serial1, &pkt, sizeof(pkt));
        }
    }
}

/* ===========================================================================
 *                           SETUP
 * =========================================================================*/

void setup() {
    Serial.begin(115200);
    Serial.println("\n=== SPARK  S3-Alpha  v2.0  (UART) ===");

    pinMode(STATUS_LED, OUTPUT);
    digitalWrite(STATUS_LED, LOW);

    // ---- Allocate PSRAM ring buffers ----
    for (int i = 0; i < 4; ++i) {
        gMicBuf[i] = (int32_t*)ps_calloc(RING_BUFFER_SAMPLES, sizeof(int32_t));
        if (!gMicBuf[i]) {
            Serial.printf("PSRAM alloc FAIL mic %d\n", i);
            while (1) delay(1000);
        }
    }
    Serial.println("[MEM]  ring buffers OK  (PSRAM)");

    // ---- UART to Master  ----
    // CAT5E wiring:  Orange pair = TX+GND, Green pair = RX+GND
    Serial1.begin(UART_BAUD_RATE, SERIAL_8N1, ALPHA_UART1_RX, ALPHA_UART1_TX);
    Serial.printf("[UART] Serial1 @ %d baud  (RX=%d TX=%d)\n",
                  UART_BAUD_RATE, ALPHA_UART1_RX, ALPHA_UART1_TX);

    // ---- I2S buses ----
    initI2SBus(I2S_NUM_0, I2S0_SCK, I2S0_WS, I2S0_SD);
    initI2SBus(I2S_NUM_1, I2S1_SCK, I2S1_WS, I2S1_SD);
    Serial.println("[I2S]  buses 0 & 1 running @ 44.1 kHz");

    // ---- Piezo interrupts ----
    qPiezoEvt = xQueueCreate(16, sizeof(PiezoEventPacket));
    for (int i = 0; i < NUM_PIEZOS; ++i) {
        pinMode(piezoPins[i], INPUT_PULLUP);
        attachInterruptArg(digitalPinToInterrupt(piezoPins[i]),
                           piezoISR, (void*)(uintptr_t)i, FALLING);
    }
    Serial.println("[IRQ]  4x piezo interrupts armed");

    // ---- FreeRTOS tasks ----
    xTaskCreatePinnedToCore(i2sReadTask0, "i2s0", 4096, nullptr, 5, &hI2S0, 0);
    xTaskCreatePinnedToCore(i2sReadTask1, "i2s1", 4096, nullptr, 5, &hI2S1, 0);
    xTaskCreatePinnedToCore(tdoaTask,     "tdoa", 8192, nullptr, 3, &hTDOA, 1);
    xTaskCreatePinnedToCore(piezoSendTask,"pzTx", 4096, nullptr, 4, &hPiezoSend, 1);
    Serial.println("[RTOS] all tasks launched");

    digitalWrite(STATUS_LED, HIGH);
    Serial.println(">>> S3-Alpha READY <<<\n");
}

/* ===========================================================================
 *                           LOOP
 * =========================================================================*/

static uint32_t lastHB = 0;

void loop() {
    uint32_t now = millis();

    // ---- Poll UART for incoming packets from Master (calibration) ----
    uint8_t  rxBuf[256];
    uint16_t rxLen = 0;
    while (uartPollPacket(Serial1, gUartRx, rxBuf, &rxLen)) {
        if (rxLen >= 1) {
            PacketType t = (PacketType)rxBuf[0];
            if (t == PKT_CALIBRATION && rxLen >= (int)sizeof(CalibrationPacket)) {
                const CalibrationPacket* cal = (const CalibrationPacket*)rxBuf;
                gSpeedOfSound = cal->speedOfSound;
                Serial.printf("[CAL] v=%.2f m/s  T=%.1f°C  H=%.1f%%\n",
                              cal->speedOfSound, cal->temperature, cal->humidity);
            }
        }
    }

    // ---- Heartbeat every 5 s ----
    if (now - lastHB >= 5000) {
        lastHB = now;
        HeartbeatPacket hb = {};
        hb.type     = PKT_HEARTBEAT;
        hb.nodeId   = NODE_ALPHA;
        hb.uptimeMs = now;
        hb.status   = 0;
        uartSendPacket(Serial1, &hb, sizeof(hb));

        Serial.printf("[HB] up %lu s  v=%.1f m/s  wrIdx=%u\n",
                      now / 1000, gSpeedOfSound, gMicWr[0]);
    }

    vTaskDelay(pdMS_TO_TICKS(1));      // yield, non-blocking
}
