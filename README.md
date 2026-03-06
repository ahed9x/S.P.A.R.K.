# ⚡ SPARK — Smart Ping-Pong Automated Referee Kit

> A 14-sensor, triple-ESP32 distributed system that referees table-tennis matches in real time using acoustic TDOA positioning, piezo vibration sensing, and an ESP-NOW microsecond-latency mesh.

---

## Architecture

```
┌───────────────────┐   ESP-NOW   ┌───────────────────┐
│   S3 Alpha        │◄───────────►│   Master WROOM    │
│  (Acoustic Brain  │             │  (Game Engine)     │
│   + Side-A Piezos)│             │  BME680 · Fan     │
│  4× INMP441 Mics  │             │  MAX98357A + SD   │
│  4× LM393 Piezos  │             │  300× WS2812B     │
└───────────────────┘             │  WiFi AP + WebUI  │
                                  └────────▲──────────┘
┌───────────────────┐   ESP-NOW            │
│   S3 Beta         │◄────────────────────►│
│  (Side-B + Net)   │
│  4× LM393 Piezos  │
│  2× LM393 Net     │
└───────────────────┘
```

## Quick Start

### 1. Get MAC Addresses

Flash each board with a tiny sketch:
```cpp
#include <WiFi.h>
void setup() {
    Serial.begin(115200);
    delay(1000);
    Serial.println(WiFi.macAddress());
}
void loop() {}
```

Write down all three addresses and update them in **`shared/spark_protocol.h`**:
```cpp
static const uint8_t MASTER_MAC[]   = { ... };
static const uint8_t S3_ALPHA_MAC[] = { ... };
static const uint8_t S3_BETA_MAC[]  = { ... };
```

### 2. Build & Flash (PlatformIO)

```bash
# S3 Alpha
cd s3_alpha
pio run --target upload

# S3 Beta
cd ../s3_beta
pio run --target upload

# Master WROOM  (firmware + filesystem)
cd ../master_wroom
pio run --target uploadfs   # uploads data/index.html to LittleFS
pio run --target upload     # uploads firmware
```

### 3. Connect to Dashboard

1. Connect your phone/laptop to WiFi **`SPARK_Table`** (password: `sparkping2026`).
2. Open **`http://192.168.4.1`** in a browser.
3. Press **New Game** — you're live!

---

## Directory Layout

```
SPARK/
├── shared/
│   └── spark_protocol.h        ← Shared structs, enums, constants
├── s3_alpha/
│   ├── platformio.ini
│   └── src/main.cpp            ← I2S DMA + TDOA + Side-A piezos
├── s3_beta/
│   ├── platformio.ini
│   └── src/main.cpp            ← 6× piezo ISR (Side-B + Net)
├── master_wroom/
│   ├── platformio.ini
│   ├── src/main.cpp            ← Game engine + peripherals + web server
│   └── data/
│       └── index.html          ← Dashboard SPA (WebSocket)
└── README.md
```

---

## Hardware Wiring Reference

### S3 Alpha (ESP32-S3)

| Function         | GPIO |
|:-----------------|:----:|
| I2S0 SCK         | 5    |
| I2S0 WS          | 6    |
| I2S0 SD (data)   | 7    |
| I2S1 SCK         | 15   |
| I2S1 WS          | 16   |
| I2S1 SD (data)   | 17   |
| Piezo A0 (LM393) | 35   |
| Piezo A1          | 36   |
| Piezo A2          | 37   |
| Piezo A3          | 38   |

> **INMP441 stereo wiring:** Two mics share one I2S bus. Mic L/R pin → GND = Left channel, L/R pin → VDD = Right channel.

### S3 Beta (ESP32-S3)

| Function              | GPIO |
|:----------------------|:----:|
| Piezo B0 (Side-B)     | 4    |
| Piezo B1              | 5    |
| Piezo B2              | 6    |
| Piezo B3              | 7    |
| Piezo N0 (Net)        | 15   |
| Piezo N1 (Net)        | 16   |

### Master WROOM (ESP32)

| Function          | GPIO |
|:------------------|:----:|
| BME680 SDA        | 21   |
| BME680 SCL        | 22   |
| Fan PWM (MOSFET)  | 25   |
| MAX98357A BCLK    | 26   |
| MAX98357A LRCLK   | 27   |
| MAX98357A DIN     | 14   |
| SD Card MOSI      | 23   |
| SD Card MISO      | 19   |
| SD Card SCK       | 18   |
| SD Card CS        | 5    |
| WS2812B Data      | 13   |

---

## Physics & Math

### Speed of Sound (Cramer 1993)

$$v \approx 331.3 + 0.606 \cdot T + 0.0124 \cdot H$$

where $T$ is temperature in °C and $H$ is relative humidity in %.
Recalculated every 60 s from BME680 and broadcast to S3 Alpha.

### TDOA Multilateration

Four microphones at the table corners provide 3 independent time-difference-of-arrival measurements (relative to Mic 0). The system linearises the hyperbolic range-difference equations into a 3×3 matrix solved via Cramer's rule:

$$\mathbf{A}\begin{bmatrix}x\\y\\r_0\end{bmatrix}=\mathbf{b}$$

Sub-sample accuracy is achieved through **parabolic interpolation** around the cross-correlation peak.

### Fan PWM Curve

| Temperature | PWM Duty | Note               |
|:-----------:|:--------:|:-------------------|
| < 35 °C     | 0 %      | Silent             |
| 38 – 45 °C  | 30 %     | 25 kHz (inaudible) |
| > 45 °C     | 100 %    | Full speed         |

---

## SD Card Audio Files

Place `.wav` files in an `audio/` folder on a FAT32 micro SD card:

```
/audio/
  ├── point_red.wav
  ├── point_blue.wav
  ├── let.wav
  ├── fault.wav
  ├── game_over.wav
  ├── change_server.wav
  ├── deuce.wav
  ├── match_point.wav
  └── game_start.wav
```

Recommended format: **16-bit PCM, mono, 16 kHz** (or 22.05 kHz).

---

## Game Rules Implemented

| Rule                      | Detection Method                           |
|:--------------------------|:-------------------------------------------|
| Valid serve               | TDOA → Piezo (server side) → Piezo (receiver side) |
| Let                       | Net piezo fires between serve bounces      |
| Point – in                | Valid bounce within table coordinates       |
| Point – out               | Timeout after paddle hit (no piezo fires)  |
| Service rotation          | Every 2 points; every 1 point at deuce     |
| Win condition             | First to 11, win by 2                      |

---

## License

MIT — Build cool things. 🏓
