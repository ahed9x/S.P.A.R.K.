/*******************************************************************************
 * SPARK — S3 Beta  (Side-B Corner Piezos + Net Sensors)   v2.0  UART
 *
 * Hardware
 *   • ESP32-S3  (16 MB Flash, 8 MB PSRAM)
 *   • 4× 35 mm Piezos via LM393 / SW420  (Side-B corners, digital interrupt)
 *   • 2× 35 mm Piezos via LM393 / SW420  (Net, digital interrupt)
 *
 * Role
 *   1.  Record microsecond-accurate timestamps on every piezo interrupt.
 *   2.  Immediately forward PiezoEventPacket / NetEventPacket to the Master
 *       over a hardwired UART link (Serial1).
 *   3.  Send heartbeats every 5 s.
 *
 * Wiring  (CAT5E, ≤ 3 m)
 *   ─────────────────────────────────────────────────────────
 *   This node connects to the Master WROOM via Serial1.
 *     Serial1  TX = GPIO 17   →  Master UART2 RX (GPIO 25)
 *     Serial1  RX = GPIO 18   ←  Master UART2 TX (GPIO 26)
 *
 *   CAT5E pin-out (alongside 15 A LED power rail):
 *     Orange pair:  Solid = TX,  Striped = GND
 *     Green  pair:  Solid = RX,  Striped = GND
 *   ─────────────────────────────────────────────────────────
 ******************************************************************************/

#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/queue.h>
#include "spark_protocol.h"

/* ===========================================================================
 *                          PIN DEFINITIONS
 * =========================================================================*/

// Side-B corner piezos  (active-LOW from LM393)
#define PIEZO_B0   4
#define PIEZO_B1   5
#define PIEZO_B2   6
#define PIEZO_B3   7

// Net piezos
#define PIEZO_N0   15
#define PIEZO_N1   16

// Table of all 6 sensors  { pin, sensorId, zone }
struct SensorDef {
    uint8_t    pin;
    uint8_t    id;
    SensorZone zone;
};

static const SensorDef SENSORS[] = {
    {PIEZO_B0, 0, ZONE_SIDE_B},
    {PIEZO_B1, 1, ZONE_SIDE_B},
    {PIEZO_B2, 2, ZONE_SIDE_B},
    {PIEZO_B3, 3, ZONE_SIDE_B},
    {PIEZO_N0, 4, ZONE_NET},
    {PIEZO_N1, 5, ZONE_NET},
};
#define NUM_SENSORS  6

#define STATUS_LED   48

/* ===========================================================================
 *                          GLOBALS
 * =========================================================================*/

// Per-sensor debounce timestamps
static volatile int64_t gLastFire[NUM_SENSORS] = {};

// Generic event (union-size matches both packet types; we tag with zone)
struct SensorEvent {
    uint8_t    sensorId;
    SensorZone zone;
    int64_t    timestamp_us;
};

static QueueHandle_t qEvents  = nullptr;
static TaskHandle_t  hSendTask = nullptr;

// UART RX state (for future commands from Master)
static UartRxState   gUartRx;

/* ===========================================================================
 *                    INTERRUPT  SERVICE  ROUTINES
 * =========================================================================*/

static void IRAM_ATTR sensorISR(void* arg) {
    int64_t now = esp_timer_get_time();
    uint8_t idx = (uint8_t)(uintptr_t)arg;

    if (now - gLastFire[idx] < DEBOUNCE_US) return;
    gLastFire[idx] = now;

    SensorEvent evt;
    evt.sensorId     = SENSORS[idx].id;
    evt.zone         = SENSORS[idx].zone;
    evt.timestamp_us = now;

    BaseType_t woken = pdFALSE;
    xQueueSendFromISR(qEvents, &evt, &woken);
    portYIELD_FROM_ISR(woken);
}

/* ===========================================================================
 *              SEND  TASK  (dequeues events → UART to Master)
 * =========================================================================*/

static void sendTask(void*) {
    SensorEvent evt;
    for (;;) {
        if (xQueueReceive(qEvents, &evt, portMAX_DELAY) != pdTRUE) continue;

        if (evt.zone == ZONE_NET) {
            // Net event
            NetEventPacket pkt = {};
            pkt.type         = PKT_NET_EVENT;
            pkt.sensorId     = evt.sensorId;
            pkt.timestamp_us = evt.timestamp_us;
            uartSendPacket(Serial1, &pkt, sizeof(pkt));
            Serial.printf("[NET]  sensor %u  t=%lld\n",
                          evt.sensorId, evt.timestamp_us);
        } else {
            // Side-B bounce
            PiezoEventPacket pkt = {};
            pkt.type         = PKT_PIEZO_EVENT;
            pkt.nodeId       = NODE_BETA;
            pkt.sensorId     = evt.sensorId;
            pkt.zone         = ZONE_SIDE_B;
            pkt.timestamp_us = evt.timestamp_us;
            pkt.intensity    = 0;
            uartSendPacket(Serial1, &pkt, sizeof(pkt));
            Serial.printf("[PIZ]  B%u  t=%lld\n",
                          evt.sensorId, evt.timestamp_us);
        }
    }
}

/* ===========================================================================
 *                           SETUP
 * =========================================================================*/

void setup() {
    Serial.begin(115200);
    Serial.println("\n=== SPARK  S3-Beta  v2.0  (UART) ===");

    pinMode(STATUS_LED, OUTPUT);
    digitalWrite(STATUS_LED, LOW);

    // ---- UART to Master ----
    // CAT5E wiring:  Orange pair = TX+GND, Green pair = RX+GND
    Serial1.begin(UART_BAUD_RATE, SERIAL_8N1, BETA_UART1_RX, BETA_UART1_TX);
    Serial.printf("[UART] Serial1 @ %d baud  (RX=%d TX=%d)\n",
                  UART_BAUD_RATE, BETA_UART1_RX, BETA_UART1_TX);

    // ---- Event queue + send task ----
    qEvents = xQueueCreate(32, sizeof(SensorEvent));
    xTaskCreatePinnedToCore(sendTask, "send", 4096, nullptr, 4, &hSendTask, 1);

    // ---- Arm all 6 piezo interrupts ----
    for (int i = 0; i < NUM_SENSORS; ++i) {
        pinMode(SENSORS[i].pin, INPUT_PULLUP);
        attachInterruptArg(digitalPinToInterrupt(SENSORS[i].pin),
                           sensorISR, (void*)(uintptr_t)i, FALLING);
    }
    Serial.println("[IRQ]  6x sensor interrupts armed (4 Side-B + 2 Net)");

    digitalWrite(STATUS_LED, HIGH);
    Serial.println(">>> S3-Beta READY <<<\n");
}

/* ===========================================================================
 *                           LOOP  (heartbeat + UART poll)
 * =========================================================================*/

static uint32_t lastHB = 0;

void loop() {
    uint32_t now = millis();

    // ---- Poll UART for incoming packets from Master (future: commands) ----
    uint8_t  rxBuf[256];
    uint16_t rxLen = 0;
    while (uartPollPacket(Serial1, gUartRx, rxBuf, &rxLen)) {
        if (rxLen >= 1) {
            PacketType t = (PacketType)rxBuf[0];
            if (t == PKT_GAME_CMD) {
                Serial.println("[CMD] received game command from Master");
            }
        }
    }

    // ---- Heartbeat every 5 s ----
    if (now - lastHB >= 5000) {
        lastHB = now;
        HeartbeatPacket hb = {};
        hb.type     = PKT_HEARTBEAT;
        hb.nodeId   = NODE_BETA;
        hb.uptimeMs = now;
        hb.status   = 0;
        uartSendPacket(Serial1, &hb, sizeof(hb));

        Serial.printf("[HB] up %lu s\n", now / 1000);
    }

    vTaskDelay(pdMS_TO_TICKS(1));      // yield, non-blocking
}
