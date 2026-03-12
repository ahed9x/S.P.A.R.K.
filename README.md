# ⚡ SPARK — Smart Ping-Pong Automated Referee Kit

> A 15-sensor, triple-ESP32 distributed system that referees table-tennis matches in real time using acoustic TDOA positioning, piezo vibration sensing, and a CAT5 UART hardwired mesh with a temp/pressure/humidity sensor for real-time speed-of-sound calibration.

---

## 💡 Why I Made This

Since last summer, I tried to build a ping-pong referee using cameras — I downloaded a large dataset and trained an AI model for weeks, only to fail miserably. Months later, while waiting for my turn to play, I closed my eyes and realized I could accurately tell the score and whose turn it was just by listening. At that moment I remembered I wanted to build an acoustic camera for a school science fair, and it clicked — why not build an acoustic ping-pong referee instead?

---

## What is SPARK?

SPARK is an automatic table-tennis referee that uses no cameras. It uses 4 MEMS microphones at the table corners to calculate exactly where the ball lands using acoustic time-difference-of-arrival (TDOA) math, 10 piezo vibration sensors to detect ball bounces and net hits, and a full game engine running on an ESP32 that tracks score, serves, lets, and faults — all announced through a speaker and visualized on a 300-LED RGB strip.

**Core features:**
- On-table ball hit mapping (x, y coordinates)
- In-air paddle hit mapping (x, y, z coordinates)
- Net hit detection
- Interactive RGB LED scoreboard
- Gamified experience through app and sound
- Full automatic referee: points, penalties, serves

---

## Architecture

```
┌───────────────────┐  CAT5 UART  ┌───────────────────┐
│   S3 Alpha        │◄───────────►│   Master WROOM    │
│  (Acoustic Brain  │             │  (Game Engine)    │
│   + Side-A Piezos)│             │  BME680 · Fan     │
│  4× INMP441 Mics  │             │  MAX98357A + SD   │
│  4× LM393 Piezos  │             │  300× WS2812B     │
└───────────────────┘             │  WiFi AP + WebUI  │
                                  └────────▲──────────┘
┌───────────────────┐  CAT5 UART           │
│   S3 Beta         │◄────────────────────►│
│  (Side-B + Net)   │
│  4× LM393 Piezos  │
│  2× LM393 Net     │
└───────────────────┘
```

---

## 3D Model

> ⚠️ Full assembly screenshot coming soon — individual part models below.

All CAD source files (.step + .f3d) are in the [`/cad`](./cad) folder.

![ESP Case](https://github.com/user-attachments/assets/ff99ffbb-f727-4f0a-9f1a-e87f7ed1b32d)
![Mic Holder](https://github.com/user-attachments/assets/1c2541c9-c1d7-45f2-b686-679fba55c55a)
![Sensor Holder](https://github.com/user-attachments/assets/d8f4ef49-822e-4cbb-b0ba-2555748f1e1a)

---

## Wiring and Schematics

No PCB — all wiring is done directly between components using CAT5E twisted pairs for UART and stranded wire for power rails.

![Wiring Overview](https://github.com/user-attachments/assets/37bf6b0a-5312-48a7-8d36-304e87b52de0)

<img width="3310" height="2344" alt="Schematic" src="https://github.com/user-attachments/assets/047c5144-e459-4e27-bc46-d66bba45dfce" />

[📄 Download Schematic PDF](https://github.com/user-attachments/files/25934993/Schematic_New-Projecterewrewrwer_2026-03-12.1.pdf)

---

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

# Master WROOM (firmware + filesystem)
cd ../master_wroom
pio run --target uploadfs   # uploads data/index.html to LittleFS
pio run --target upload     # uploads firmware
```

### 3. Connect to Dashboard

1. Connect your phone/laptop to WiFi **`SPARK_Table`** (password: `sparkping2026`)
2. Open **`http://192.168.4.1`** in a browser
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
├── cad/                        ← All .step and .f3d CAD files
├── BOM.csv
└── README.md
```

---

## Hardware Wiring Reference

### S3 Alpha (ESP32-S3)

| Function | GPIO |
|:---------|:----:|
| I2S0 SCK | 5 |
| I2S0 WS | 6 |
| I2S0 SD (data) | 7 |
| I2S1 SCK | 15 |
| I2S1 WS | 16 |
| I2S1 SD (data) | 17 |
| Piezo A0 (LM393) | 35 |
| Piezo A1 | 36 |
| Piezo A2 | 37 |
| Piezo A3 | 38 |

> **INMP441 stereo wiring:** Two mics share one I2S bus. Mic L/R pin → GND = Left channel, L/R pin → VDD = Right channel.

### S3 Beta (ESP32-S3)

| Function | GPIO |
|:---------|:----:|
| Piezo B0 (Side-B) | 4 |
| Piezo B1 | 5 |
| Piezo B2 | 6 |
| Piezo B3 | 7 |
| Piezo N0 (Net) | 15 |
| Piezo N1 (Net) | 16 |

### Master WROOM (ESP32)

| Function | GPIO |
|:---------|:----:|
| BME680 SDA | 21 |
| BME680 SCL | 22 |
| Fan PWM (MOSFET) | 25 |
| MAX98357A BCLK | 26 |
| MAX98357A LRCLK | 27 |
| MAX98357A DIN | 14 |
| SD Card MOSI | 23 |
| SD Card MISO | 19 |
| SD Card SCK | 18 |
| SD Card CS | 5 |
| WS2812B Data | 13 |

---

## Physics & Math

### Speed of Sound (Cramer 1993)

$$v \approx 331.3 + 0.606 \cdot T + 0.0124 \cdot H$$

where $T$ is temperature in °C and $H$ is relative humidity in %.  
Recalculated every 60s from BME680 and used for TDOA calculations.

### TDOA Multilateration

Four microphones at the table corners provide 3 independent time-difference-of-arrival measurements (relative to Mic 0). The system linearises the hyperbolic range-difference equations into a 3×3 matrix solved via Cramer's rule:

$$\mathbf{A}\begin{bmatrix}x\\y\\r_0\end{bmatrix}=\mathbf{b}$$

Sub-sample accuracy is achieved through **parabolic interpolation** around the cross-correlation peak.

### Fan PWM Curve

| Temperature | PWM Duty | Note |
|:-----------:|:--------:|:-----|
| < 35 °C | 0 % | Silent |
| 38 – 45 °C | 30 % | 25 kHz (inaudible) |
| > 45 °C | 100 % | Full speed |

---

## Game Rules Implemented

| Rule | Detection Method |
|:-----|:----------------|
| Valid serve | TDOA → Piezo (server side) → Piezo (receiver side) |
| Let | Net piezo fires between serve bounces |
| Point – in | Valid bounce within table coordinates |
| Point – out | Timeout after paddle hit (no piezo fires) |
| Service rotation | Every 2 points; every 1 point at deuce |
| Win condition | First to 11, win by 2 |

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

## Bill of Materials

| Category | Qty | Item | Purpose | Price (EGP) | Link |
|----------|-----|------|---------|-------------|------|
| MCU & Logic | 2 | ESP32-S3-1N16R8 | S3 Alpha & Beta (Audio Buffering & Interrupts) | 900 | [Buy](https://store.fut-electronics.com/collections/all/products/esp32-s3-devkitc-1-copy?variant=43309674496109) |
| MCU & Logic | 1 | ESP32-S3 DevKitC-1 | Master WROOM (Game Engine & API Server) | 380 | [Buy](https://store.fut-electronics.com/collections/all/products/esp32-s3-devkitc-1?variant=42265460179053) |
| MCU & Logic | 1 | 4CH I2C Logic Level Converter | 3.3V to 5V shifter for LED strip data line | 45 | [Buy](https://store.fut-electronics.com/collections/all/products/logic-level-converter-1?variant=40470370025581) |
| MCU & Logic | 1 | Micro SD Card Module (5V) | Reads audio files and local player JSON data | 60 | [Buy](https://www.ram-e-shop.com/ar/shop/kit-sd-card-module-micro-sd-card-module-for-arduino-or-mcu-7056) |
| MCU & Logic | 1 | Micro SD Card 32GB HC10 | High-speed storage for web assets and audio | 375 | [Buy](https://www.ram-e-shop.com/ar/shop/micro-sd-32gb-micro-sd-card-32gb-hc10-krt-dhkr-mymwry-micro-sd-s-32-jyjbyt-6298) |
| Sensors & Audio | 4 | INMP441 MEMS Microphone I2S | Corner acoustic TDOA mapping | 1120 | [Buy](https://store.fut-electronics.com/collections/all/products/inmp441-mems-microphone-i2s?variant=43298631417965) |
| Sensors & Audio | 10 | Piezo Sensor Element 35mm | Vibration sensing and acoustic ping emission | 350 | [Buy](https://store.fut-electronics.com/collections/all/products/piezo-sensor-element-35mm?variant=40109101547629) |
| Sensors & Audio | 10 | Vibration Switch Module SW1801P | LM393 digital hardware interrupts | 250 | [Buy](https://makerselectronics.com/product/vibration-switch-module-sw1801p/) |
| Sensors & Audio | 1 | BME680 Environmental Sensor | Speed of sound calculation & thermal monitoring | 490 | [Buy](https://store.fut-electronics.com/collections/all/products/bme680-environmental-sensor-pressure-temperature-humidity-voc-gas?variant=30239052955757) |
| Sensors & Audio | 1 | MAX98357A I2S Amplifier | Drive the 3W speaker safely from ESP32 | 120 | [Buy](https://makerselectronics.com/product/max98357a-i2s-amplifier-module/) |
| Sensors & Audio | 1 | YD66-2 Speaker 8Ω 3W | Game announcer and UI sound effects | 24 | [Buy](https://makerselectronics.com/product/yd66-2-speaker-8%cf%89-3w-66mmx21mm/) |
| Power & Wiring | 1 | Power Supply 5V 15A | Main power for LEDs and system | 325 | [Buy](https://makerselectronics.com/product/power-supply-5v-15a/) |
| Power & Wiring | 1 | AC-04 Power Socket 3 Pin Male | Professional mains connection for Control Box | 9 | [Buy](https://makerselectronics.com/product/socket-3-pin-male-connector-10a-250v/) |
| Power & Wiring | 1 | AC Power Cord Cable 1.75m | Plugs Control Box into the wall | 45 | [Buy](https://www.ram-e-shop.com/ar/shop/power-cable-comp-ac-power-cord-cable-1-75m-kbl-bwr-kbl-kmbywtr-twl-1-75-mtr-5621) |
| Power & Wiring | 1 | WS2812 RGB LED Strip 60LED/m 5m | Visual scoreboard and game state feedback | 750 | [Buy](https://makerselectronics.com/product/ws2812-addressable-rgb-waterproof-le/) |
| Power & Wiring | 20 | UTP CAT5E Ethernet Cable (m) | Twisted pairs for UART & sensor data | 100 | [Buy](https://makerselectronics.com/product/utp-cat5e-tia-eia-ethernet-cable/) |
| Power & Wiring | 5 | Stranded Wire 1.5mm Red (m) | Main positive power rail under the table | 75 | [Buy](https://makerselectronics.com/product/stranded-wire-1-5mm%c2%b2-1meter/?attribute_color=Red) |
| Power & Wiring | 5 | Stranded Wire 1.5mm Black (m) | Main ground power rail under the table | 75 | [Buy](https://makerselectronics.com/product/stranded-wire-1-5mm%c2%b2-1meter/?attribute_color=Black) |
| Power & Wiring | 5 | Audio Speaker Cable 2x2mm (m) | Power injection to prevent LED voltage drop | 65 | [Buy](https://makerselectronics.com/product/audio-speaker-cable-2x2mm/) |
| Cooling & Safety | 8 | Aluminum Heatsink 9x9x12mm | Thermal dissipation for S3 chips | 200 | [Buy](https://www.ram-e-shop.com/ar/shop/hs1-aluminum-heatsink-hs-1-size-9x9x12-mm-mbrd-hrry-hyt-synk-lwmnywm-5979) |
| Cooling & Safety | 1 | MX-6 ARCTIC Thermal Paste 2g | High-performance heat transfer | 225 | [Buy](https://makerselectronics.com/product/mx-6-arctic-grey-high-copy-thermal-paste-2g/) |
| Cooling & Safety | 1 | Super Glue 3.2g | Permanent heatsink anchoring | 26 | [Buy](https://www.ram-e-shop.com/ar/shop/glue-3gm-super-glue-3-2g-lsq-swbr-jlw-lsrwkh-3-2-jm-6930) |
| Cooling & Safety | 3 | 5V DC 3010 Fan 30x30x10mm | Active emergency airflow for Control Box | 300 | [Buy](https://www.amazon.eg/-/en/Cooling-Fan-Brushless-3010-30x30x10mm/dp/B07DLLX6Y2) |
| Cooling & Safety | 3 | IRF520 MOSFET / TIP120 | PWM fan control from ESP32 | 60 | [Buy](https://makerselectronics.com/product/irf520-n-channel-power-mosfet-to-220/) |
| Components | 10 | Carbon Resistor 1MΩ 0.25W | Bleed resistors for 35mm piezos | 10 | [Buy](https://makerselectronics.com/product/carbon-resistor-1m%cf%89-0-25w-through-hol/) |
| Components | 10 | Zener Diode 5.1V 0.5W | Overvoltage spike protection for ESP32 inputs | 23 | [Buy](https://makerselectronics.com/product/zener-diode-5-1v-0-5w/) |

**Total: ~5,427 EGP**

---

## License

MIT — Build cool things. 🏓

