---
title: "S.P.A.R.K."
author: "ahed9x"
description: "ping pong no camera refree"
created_at: "2026-01-07"
---
# Collected the BOM

i collected everything i will need for this one and understood all the concepts for it to work, it is medium in difficulty but highly rewarding and better than using a camera

1x WS2812 Addressable RGB LED Strip (5m) — 750.00 EGP
1x Power Supply 12V 30A — 625.00 EGP
1x Power Supply 5V 20A — 395.00 EGP
2x Power Cable 6-16A (1.5m) — 50.00 EGP
2x AC Power Plug 250V Male — 34.00 EGP
1x Speaker 4 Ohm 3W (55mm) — 20.00 EGP
1x MAX98357A I2S Amplifier Module — 120.00 EGP
15x UTP CAT6 Ethernet Cable (Meters) — 120.00 EGP
2x Red & Black Audio Cable (Meters) — 12.00 EGP
2x Blue & Transparent Audio Cable (Meters) — 26.00 EGP
5x LED Strips Connecting Cable (Meters) — 67.50 EGP
1x ESP32-S3-N16R8 Development Board — 550.00 EGP
10x Piezo Buzzer Element (35mm) — 350.00 EGP
2x INMP441 MEMS Microphone — 560.00 EGP (Assuming 280 EGP each)
1x Neon Flexible LED Strip Roll 50M (Yellow) — 1,600.00 EGP
SHIPPING: 135egp
Total: 5,414.50 EGP

<img width="1268" height="898" alt="image" src="https://github.com/user-attachments/assets/ca8c10fe-b68e-47a8-aa1b-91f10c7d49c0" />

<img width="1267" height="906" alt="image" src="https://github.com/user-attachments/assets/34621755-9652-42aa-b3de-f0f8530a9212" />

<img width="375" height="143" alt="image" src="https://github.com/user-attachments/assets/d741683c-4cda-49df-acbd-bfb290f57232" />

<img width="1275" height="197" alt="image" src="https://github.com/user-attachments/assets/56187043-faa6-422f-9d9f-09f3142b097c" />



**Total time spent: 2.5 hours**

# Creating the sketch

SCHNew-Project2026-01-07

SchematicNew-Project2026-01-07
i created everything i am nearly ready to start building in real life after i finish the basic code


[Schematic_New-Project_2026-01-07.pdf](https://github.com/user-attachments/files/28225953/Schematic_New-Project_2026-01-07.pdf)



<img width="1169" height="827" alt="image" src="https://github.com/user-attachments/assets/815550c6-a040-4ece-beaa-67002bae0bf7" />

[Schematic_New-Project_2026-01-07](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6NzYxNTcsInB1ciI6ImJsb2JfaWQifX0=--2059aeb7d20e58d1e6439206101da1397c563e8a/Schematic_New-Project_2026-01-07.pdf)

**Total time spent: 3.5 hours**

# Firmware

using GitHub Copilot and gemini i created the first script that is ready for deployment along with the flutter app in seconds and these will maybe see some modifications when creating. also I removed 1 esp and 2 mics from the project because they are unnecessary.

<img width="1919" height="1079" alt="image" src="https://github.com/user-attachments/assets/6c917522-86a3-4528-9dbf-b276a0aacec7" />


**Total time spent: 0.2 hours**

# Rethinking the design

I heavily researched and will shift to a completely new plan:
first we will use 3 esps 1 for 4 mics and 4 piezos, and another for 6 piezos with a master one for the game logic, sd, speaker, and lights. Further, we added an SD card and a temperature, humidity, and pressure sensor all in one.
also i figuered out 50m of LEDs is an overkill, and I shall not ask for that here.

<img width="644" height="890" alt="image" src="https://github.com/user-attachments/assets/f5a081f8-d062-430b-a633-7c1ccb02e2d3" />

<img width="649" height="793" alt="image" src="https://github.com/user-attachments/assets/475fd9cf-63ff-40f7-bd0c-a5b4ca09adc6" />

<img width="1044" height="678" alt="image" src="https://github.com/user-attachments/assets/02c86cbd-4eb8-4033-aa07-9ad0f99712c6" />

**Total time spent: 7.0 hours**

# Designing ESP Case

In Fusion 360, I designed a case with a mini fan for the ESP, but for the lowest noise, the fans will work only if heat is detected, but still, the design might need more tweaking.

<img width="1519" height="889" alt="image" src="https://github.com/user-attachments/assets/1570199f-140d-40d9-9981-bc07872b1047" />
<img width="1519" height="843" alt="image" src="https://github.com/user-attachments/assets/9892eb7b-c73c-4092-81e2-0f98671edb0a" />
<img width="1519" height="889" alt="image" src="https://github.com/user-attachments/assets/f429380a-5f6f-40a5-84e1-0fcfc444610d" />
<img width="1522" height="893" alt="image" src="https://github.com/user-attachments/assets/a7164d5d-9df9-4f2b-84ea-d90d3d17751e" />


**Total time spent: 2.0 hours**

# Finished the new code

i created the initial code but it still also needs high refinement when all equipment is equipped to make it perfect through dedication and tuning.
<img width="1252" height="698" alt="image" src="https://github.com/user-attachments/assets/2aad1dbc-b326-49ea-8400-a6765a39dec9" />

<img width="1919" height="1022" alt="image" src="https://github.com/user-attachments/assets/00ebc7cf-d72e-4869-8f9a-2c209e390c9b" />


...

**Total time spent: 1.0 hour**

# Creating the github repo

I uploaded everything to the github and repo is fully ready, and I even created the BOM csv with links and prices, and use highly detailed makeing the project nearly complete

<img width="1919" height="814" alt="image" src="https://github.com/user-attachments/assets/7acf267a-c0cf-496a-9dbf-9d2efce7c4bb" />
<img width="1167" height="803" alt="image" src="https://github.com/user-attachments/assets/4d7fe816-c77d-46b0-9f26-81952132d4cf" />



**Total time spent: 1.0 hour**

# Wiring and final details


<img width="678" height="416" alt="image" src="https://github.com/user-attachments/assets/d0ad1a7d-5fd6-43a6-b101-2e2a72cf1753" />


The new total project cost is 8720egp or 175 usd, including shipping

Master Brain (ESP32 WROOM 32)
BME680: SDA -> 21 | SCL -> 22
SD Card: MOSI -> 23 | MISO -> 19 | SCK -> 18 | CS -> 5
MAX98357A (Amp): BCLK -> 26 | LRC -> 25 | DIN -> 27
UART 1 (From Alpha): RX -> 32 | TX -> 33
UART 2 (From Beta): RX -> 16 | TX -> 17
LED Data: 13 (Goes to Level Shifter LV1)
Fan PWM: 14 (Goes to MOSFET Gate)
S3 Alpha (ESP32-S3-1N16R8)
Front Mics (1 & 2): SCK -> 4 | WS -> 5 | SD -> 6
Back Mics (3 & 4): SCK -> 7 | WS -> 8 | SD -> 9
Side A Piezos (LM393 D0): 10, 11, 12, 13
Calibration Buzzer Bypass: 14 (Direct to Piezo 1 positive)
UART (To Master): TX -> 17 | RX -> 18
S3 Beta (ESP32-S3-1N16R8)
Side B Piezos (LM393 D0): 4, 5, 6, 7
Net Piezos (LM393 D0): 8, 9
UART (To Master): TX -> 17 | RX -> 18
Logic Level Shifter (For WS2812B LEDs)
LV -> ESP32 3.3V
LV1 -> Master Pin 13
LV GND -> ESP32 GND
HV -> 15A PSU 5V
HV1 -> LED Strip Data IN
HV GND -> 15A PSU GND
MOSFET (For 5V 60mm Fan)
Gate (SIG) -> Master Pin 14
Drain -> Fan Black Wire (-)
Source -> 15A PSU GND & ESP32 GND
Fan Red Wire (+) -> 15A PSU 5V
Power & CAT5E Rules
ALL components (ESP32s, modules, shifter, MOSFET, LED strip) MUST share the 15A PSU Ground (-).
CAT5E UART pairs: Orange = TX + GND. Green = RX + GND.

**Total time spent: 1.0 hour**

# Designing all Cad Parts Needed

I designed almost all cad parts needed to hold the electronics. Other electronics will be directly screwed or taped to the table and all cad mdels will be on github soon:
!!UPDATE i uploaded them on github [https://github.com/ahed9x/S.P.A.R.K./tree/main/cad](https://github.com/ahed9x/S.P.A.R.K./tree/main/cad)

<img width="489" height="401" alt="image (5)" src="https://github.com/user-attachments/assets/f310c29b-4d8c-4878-a4b3-2b3db8daf084" />
<img width="569" height="469" alt="image (6)" src="https://github.com/user-attachments/assets/d0c34816-cb35-4c0c-8025-8ae84fc97244" />
<img width="775" height="703" alt="image (7)" src="https://github.com/user-attachments/assets/b7a10b85-192f-44d8-b10d-6e866e3f1272" />
<img width="1041" height="613" alt="image" src="https://github.com/user-attachments/assets/8d906432-5a4b-4101-aae7-1c9533202b04" />


**Total time spent: 2.0 hours**

# Explaining SPARK

So briefly, in this project, I aim to make use of the time of arrival of the sound emitted by the ping pong ball to calculate where it hit on the table/ paddle in the air and thus creating a auto ping pong refree gamifying the process through LEDs, speakers, and the app.
core features:
1- on table ball hit mapping (x,y coordinates where the ball hits table)
2- in air paddle hit ball mapping (x,y,z coordinates where player hit ball)
3- ball net hit detection (detects when the ball hits the net)
4- interactive live addressable RGB LED strip (everything changes according to ball hits and points)
5- Gamified process through app and sound controls
6- Auto full refree combining all data to be the refree calculating points, penalties, and serves

<img width="1282" height="717" alt="Untitled-2026-03-07-0833" src="https://github.com/user-attachments/assets/d2cac3a9-b04b-4d05-b81f-3d0874467d90" />


**Total time spent: 1.0 hour**

# Creating new wiring schematic

I finally created the wiring schematic for the whole project. It was a pretty devastating process!

SchematicNew-Projecterewrewrwer2026-03-12 (1)
SchematicNew-Projecterewrewrwer2026-03-12 (1)
SCHNew-Projecterewrewrwer2026-03-12 (1)

<img width="2000" height="1416" alt="Schematic_New-Projecterewrewrwer_2026-03-12 (1)" src="https://github.com/user-attachments/assets/5fbbe91f-782d-4465-a225-d17da93601f2" />
[Schematic_New-Projecterewrewrwer_2026-03-12 (1).pdf](https://github.com/user-attachments/files/28225490/Schematic_New-Projecterewrewrwer_2026-03-12.1.pdf)

<img width="2000" height="1416" alt="Schematic_New-Projecterewrewrwer_2026-03-12 (1)" src="https://github.com/user-attachments/assets/93467e92-3fbf-480d-89c4-79d21026b6f9" />




**Total time spent: 3.0 hours**

# Finished the full CAD assembly

I finished the final full CAD assembly and noted that we can't poke holes and screws through the ping pong table, so everything will be glued/taped, or the table will be ruined.

<img width="1517" height="718" alt="image (1)" src="https://github.com/user-attachments/assets/c4ae6057-1ea1-4dd7-94d6-f7f0e4f33d15" />
<img width="1919" height="1024" alt="image (2)" src="https://github.com/user-attachments/assets/219bbfd1-774d-4021-9be7-62cfae1d022e" />
<img width="1919" height="1030" alt="image (4)" src="https://github.com/user-attachments/assets/af176bb5-7298-4539-bda1-0d2870ed8dee" />
<img width="1919" height="1032" alt="image (3)" src="https://github.com/user-attachments/assets/915213c1-d3eb-4ac6-bced-cd6b793d6b7e" />



**Total time spent: 1.0 hour**

# Github

I uploaded everything on github:
Code: [https://github.com/ahed9x/S.P.A.R.K](https://github.com/ahed9x/S.P.A.R.K).
BOM: [https://github.com/ahed9x/S.P.A.R.K./blob/main/BOM.csv](https://github.com/ahed9x/S.P.A.R.K./blob/main/BOM.csv)
the 3d design files: [https://github.com/ahed9x/S.P.A.R.K./tree/main/cad](https://github.com/ahed9x/S.P.A.R.K./tree/main/cad)
amp holder- [https://github.com/ahed9x/S.P.A.R.K./blob/main/cad/amp%20holder.step](https://github.com/ahed9x/S.P.A.R.K./blob/main/cad/amp%20holder.step)
mic holder- [https://github.com/ahed9x/S.P.A.R.K./blob/main/cad/mic%20holder.step]()
esp holder- [http://github.com/ahed9x/S.P.A.R.K./blob/main/cad/esp%2032%20s3%20case.step]()
sensor holder- [https://github.com/ahed9x/S.P.A.R.K./blob/main/cad/sensor%20holder.step]()
ASSEMBLY - [https://github.com/ahed9x/S.P.A.R.K./blob/main/cad/Full%20Assembly.zip]() [https://github.com/ahed9x/S.P.A.R.K./blob/main/cad/Full%20Assembly.f3z]()

<img width="1919" height="901" alt="image" src="https://github.com/user-attachments/assets/df4b7dc5-84f3-4c2f-8ca3-74ea7426d71b" />



**Total time spent: 0.1 hours**

# Summary

- I won't buy the acoustic because it feels very irrelevant and just to make it clear, even though the problem can be solved via code, it will add latency, which can differ in a sport like ping pong. 
- Second, the latest uploaded architecture with 3 esps will be used to ensure accuracy and speed.
- the total final cost will be around 3152 egp or 61 usd at this time may 25 of 2026 which may fluctuate +-20usd
<img width="689" height="370" alt="image" src="https://github.com/user-attachments/assets/e498c9b0-fe17-4630-af87-0fc79f731812" />

  



**Total time spent: 0.1 hours**

