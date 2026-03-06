/*******************************************************************************
 * SPARK — Smart Ping-pong Automated Referee Kit
 * Shared Inter-Node Protocol  (v1.0)
 *
 * This header is included by ALL three ESP32 nodes.
 * PlatformIO build flag:  -I../../shared
 ******************************************************************************/
#pragma once
#include <stdint.h>

/* ========================  NODE IDENTIFIERS  ============================== */
#define NODE_MASTER     0
#define NODE_ALPHA      1          // S3-Alpha  (Acoustic + Side-A)
#define NODE_BETA       2          // S3-Beta   (Side-B + Net)

/* ========================  WIFI (Master STA only)  ======================= */
#define SPARK_SSID           "SPARK_Table"
#define SPARK_PASS           "sparkping2026"

/* ========================  HARDWIRED UART BUS  ============================ */
/*
 * All three nodes are connected via dedicated UART links over CAT5E cable.
 * ESP-NOW has been removed for commercial-grade reliability.
 *
 * Topology:   S3-Alpha ──Serial──> Master <──Serial── S3-Beta
 *
 *   Master WROOM:
 *     Serial1 (UART1)  RX=16  TX=17   ↔  S3 Alpha
 *     Serial2 (UART2)  RX=25  TX=26   ↔  S3 Beta
 *
 *   S3 Alpha:
 *     Serial1 (UART1)  RX=18  TX=17   ↔  Master
 *
 *   S3 Beta:
 *     Serial1 (UART1)  RX=18  TX=17   ↔  Master
 *
 * ──────────────────────────────────────────────────────────────
 *   CAT5E WIRING  (≤ 3 m, alongside 15 A LED power rail)
 * ──────────────────────────────────────────────────────────────
 *   Signal integrity requires each data line to share a twisted
 *   pair with GND.  Use the following mapping:
 *
 *     Pair 1 (Orange):  Solid  = TX   |  Striped = GND
 *     Pair 2 (Green):   Solid  = RX   |  Striped = GND
 *     Pair 3 (Blue):    Solid  = +5 V |  Striped = GND   (optional power)
 *     Pair 4 (Brown):   Solid  = SPARE|  Striped = GND
 *
 *   CRITICAL: Run GND on *every* striped wire of the used pairs.
 *   The differential twist rejection of CAT5E mitigates EMI from
 *   the adjacent WS2812B 5 V / 15 A power rail.
 * ──────────────────────────────────────────────────────────────
 */

#define UART_BAUD_RATE       921600     // High-speed UART over CAT5E

// Master WROOM pin assignments
#define MASTER_UART1_RX      16         // → S3 Alpha TX
#define MASTER_UART1_TX      17         // → S3 Alpha RX
#define MASTER_UART2_RX      25         // → S3 Beta  TX
#define MASTER_UART2_TX      26         // → S3 Beta  RX

// S3 Alpha pin assignments
#define ALPHA_UART1_RX       18         // → Master TX (UART1)
#define ALPHA_UART1_TX       17         // → Master RX (UART1)

// S3 Beta pin assignments
#define BETA_UART1_RX        18         // → Master TX (UART2)
#define BETA_UART1_TX        17         // → Master RX (UART2)

// Non-blocking serial read buffer size
#define UART_RX_BUF_SIZE     512

// Framing: each binary packet is preceded by a 2-byte sync word
// and followed by a 1-byte CRC-8 for integrity over the wire.
#define UART_SYNC_BYTE_0     0xA5
#define UART_SYNC_BYTE_1     0x5A

/* ========================  TABLE GEOMETRY (mm) ============================ */
#define TABLE_LENGTH_MM     2740.0f
#define TABLE_WIDTH_MM      1525.0f
#define TABLE_HALF_MM       (TABLE_LENGTH_MM / 2.0f)   // net x-position
#define NET_HEIGHT_MM       152.5f
#define TABLE_HEIGHT_MM     760.0f

/* Mic mounting positions (mm) — origin at Side-A-left corner, z = 0 at surface
 *    M0 ──────────────────── M1
 *    │        Side A         │
 *    │..........NET..........│
 *    │        Side B         │
 *    M3 ──────────────────── M2                                             */
static const float MIC_POS[4][3] = {
    {           0.0f,            0.0f, 0.0f},   // M0
    {TABLE_LENGTH_MM,            0.0f, 0.0f},   // M1
    {TABLE_LENGTH_MM, TABLE_WIDTH_MM,  0.0f},   // M2
    {           0.0f, TABLE_WIDTH_MM,  0.0f},   // M3
};

/* ========================  PACKET TYPES  ================================== */
enum PacketType : uint8_t {
    PKT_PIEZO_EVENT     = 0x01,
    PKT_TDOA_RESULT     = 0x02,
    PKT_NET_EVENT       = 0x03,
    PKT_CALIBRATION     = 0x10,
    PKT_GAME_CMD        = 0x20,
    PKT_GAME_STATE      = 0x21,
    PKT_HEARTBEAT       = 0xFE,
};

/* ========================  ZONE / SIDE  =================================== */
enum SensorZone : uint8_t {
    ZONE_SIDE_A  = 0,
    ZONE_SIDE_B  = 1,
    ZONE_NET     = 2,
    ZONE_PADDLE  = 3,          // TDOA-detected paddle strike
};

/* ========================  WIRE STRUCTS (packed) ========================== */
#pragma pack(push, 1)

struct PiezoEventPacket {
    PacketType  type;            // PKT_PIEZO_EVENT
    uint8_t     nodeId;          // NODE_ALPHA | NODE_BETA
    uint8_t     sensorId;        // 0-3 table corners, 4-5 net
    SensorZone  zone;
    int64_t     timestamp_us;    // esp_timer_get_time()
    uint16_t    intensity;       // 0 for digital-only triggers
};

struct TDOAResultPacket {
    PacketType  type;            // PKT_TDOA_RESULT
    uint8_t     nodeId;          // NODE_ALPHA
    float       x;               // mm
    float       y;               // mm
    float       z;               // mm  (height above surface)
    float       confidence;      // 0.0 – 1.0
    int64_t     timestamp_us;
};

struct NetEventPacket {
    PacketType  type;            // PKT_NET_EVENT
    uint8_t     sensorId;        // 0 or 1
    int64_t     timestamp_us;
};

struct CalibrationPacket {
    PacketType  type;            // PKT_CALIBRATION
    float       speedOfSound;    // m/s
    float       temperature;     // °C
    float       humidity;        // %RH
    float       pressure;        // hPa
};

struct GameCommandPacket {
    PacketType  type;            // PKT_GAME_CMD
    uint8_t     command;         // 0 RESET · 1 START · 2 PAUSE
    uint8_t     server;          // 0=A  1=B  (for START)
};

struct GameStatePacket {
    PacketType  type;            // PKT_GAME_STATE
    uint8_t     scoreA;
    uint8_t     scoreB;
    uint8_t     server;          // 0=A  1=B
    uint8_t     gameState;       // GameState enum
};

struct HeartbeatPacket {
    PacketType  type;            // PKT_HEARTBEAT
    uint8_t     nodeId;
    uint32_t    uptimeMs;
    uint8_t     status;          // 0 OK · 1 WARN · 2 ERR
};

#pragma pack(pop)

/* ========================  GAME-STATE ENUM  =============================== */
enum GameState : uint8_t {
    GS_IDLE          = 0,
    GS_WAIT_SERVE    = 1,
    GS_SERVE_HIT     = 2,       // Paddle hit detected
    GS_SERVE_BOUNCED = 3,       // Bounced on server's side
    GS_RALLY         = 4,
    GS_LET           = 5,
    GS_POINT         = 6,
    GS_GAME_OVER     = 7,
    GS_DEUCE         = 8,
};

/* ========================  LED ANIMATION MODES  =========================== */
enum LEDMode : uint8_t {
    LED_OFF          = 0,
    LED_IDLE         = 1,
    LED_SERVE_PULSE  = 2,       // Blue pulse
    LED_POINT_GREEN  = 3,       // Green flash
    LED_FAULT_RED    = 4,       // Red flash
    LED_LET_YELLOW   = 5,       // Yellow wave
    LED_SCORE        = 6,
    LED_GAME_OVER    = 7,
};

/* ========================  AUDIO CLIP PATHS  ============================== */
#define WAV_POINT_A        "/audio/point_red.wav"
#define WAV_POINT_B        "/audio/point_blue.wav"
#define WAV_LET            "/audio/let.wav"
#define WAV_FAULT          "/audio/fault.wav"
#define WAV_GAME_OVER      "/audio/game_over.wav"
#define WAV_CHANGE_SERVER  "/audio/change_server.wav"
#define WAV_DEUCE          "/audio/deuce.wav"
#define WAV_MATCH_POINT    "/audio/match_point.wav"
#define WAV_GAME_START     "/audio/game_start.wav"

/* ========================  TIMING CONSTANTS  ============================== */
#define SERVE_TIMEOUT_US          2000000LL    // 2 s
#define RALLY_BOUNCE_TIMEOUT_US    800000LL    // 800 ms
#define DEBOUNCE_US                  5000LL    // 5 ms
#define TDOA_CAPTURE_DELAY_US       15000LL    // 15 ms
#define CALIBRATION_INTERVAL_MS     60000UL    // 60 s

/* ========================  I2S / DSP CONSTANTS  =========================== */
#define I2S_SAMPLE_RATE             44100
#define I2S_BITS                    32
#define TDOA_WINDOW_SAMPLES         1024       // ~23 ms @ 44.1 kHz
#define TDOA_MAX_DELAY_SAMPLES      450        // ≈ 10 ms  (table diag)
#define RING_BUFFER_SAMPLES         8192       // ~186 ms circular buffer / mic
#define ACOUSTIC_THRESHOLD          800000     // Raw I2S amplitude for paddle-hit detect

/* ========================  UTILITY INLINE  ================================ */
static inline float calcSpeedOfSound(float tempC, float humidityPct) {
    // Cramer (1993): v ≈ 331.3 + 0.606·T + 0.0124·H
    return 331.3f + 0.606f * tempC + 0.0124f * humidityPct;
}

/* ========================  UART FRAMING HELPERS  ========================== */
/*
 * Wire format:  [0xA5] [0x5A] [len_lo] [len_hi] [payload ...] [crc8]
 *   len = payload byte count (excludes sync, len, and crc)
 *   crc8 = CRC-8/MAXIM over the payload bytes only
 */

static inline uint8_t crc8(const uint8_t* data, size_t len) {
    uint8_t crc = 0x00;
    for (size_t i = 0; i < len; ++i) {
        crc ^= data[i];
        for (int b = 0; b < 8; ++b)
            crc = (crc & 0x80) ? ((crc << 1) ^ 0x31) : (crc << 1);
    }
    return crc;
}

/// Send a packed struct over a HardwareSerial port with sync + CRC framing.
static inline void uartSendPacket(HardwareSerial& port,
                                  const void* payload, uint16_t len)
{
    const uint8_t sync[2] = {UART_SYNC_BYTE_0, UART_SYNC_BYTE_1};
    const uint8_t lenBytes[2] = {(uint8_t)(len & 0xFF), (uint8_t)(len >> 8)};
    uint8_t chk = crc8((const uint8_t*)payload, len);

    port.write(sync, 2);
    port.write(lenBytes, 2);
    port.write((const uint8_t*)payload, len);
    port.write(chk);
}

/// Non-blocking UART receive state machine.
/// Call repeatedly from loop(); returns true when a complete, CRC-valid
/// packet has been assembled in `outBuf` (length written to *outLen).
struct UartRxState {
    enum Phase : uint8_t { WAIT_SYNC0, WAIT_SYNC1, WAIT_LEN0, WAIT_LEN1,
                           PAYLOAD, WAIT_CRC };
    Phase    phase    = WAIT_SYNC0;
    uint8_t  buf[256];
    uint16_t expected = 0;
    uint16_t pos      = 0;
};

static inline bool uartPollPacket(HardwareSerial& port, UartRxState& st,
                                  uint8_t* outBuf, uint16_t* outLen)
{
    while (port.available()) {
        uint8_t c = port.read();
        switch (st.phase) {
        case UartRxState::WAIT_SYNC0:
            if (c == UART_SYNC_BYTE_0) st.phase = UartRxState::WAIT_SYNC1;
            break;
        case UartRxState::WAIT_SYNC1:
            st.phase = (c == UART_SYNC_BYTE_1)
                       ? UartRxState::WAIT_LEN0 : UartRxState::WAIT_SYNC0;
            break;
        case UartRxState::WAIT_LEN0:
            st.expected = c;
            st.phase = UartRxState::WAIT_LEN1;
            break;
        case UartRxState::WAIT_LEN1:
            st.expected |= ((uint16_t)c << 8);
            if (st.expected == 0 || st.expected > sizeof(st.buf)) {
                st.phase = UartRxState::WAIT_SYNC0;   // bad length
            } else {
                st.pos = 0;
                st.phase = UartRxState::PAYLOAD;
            }
            break;
        case UartRxState::PAYLOAD:
            st.buf[st.pos++] = c;
            if (st.pos >= st.expected) st.phase = UartRxState::WAIT_CRC;
            break;
        case UartRxState::WAIT_CRC: {
            uint8_t calc = crc8(st.buf, st.expected);
            st.phase = UartRxState::WAIT_SYNC0;
            if (c == calc) {
                memcpy(outBuf, st.buf, st.expected);
                *outLen = st.expected;
                return true;
            }
            // CRC mismatch — drop frame
            break;
        }
        }
    }
    return false;
}
