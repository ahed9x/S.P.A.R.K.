---

## title: "S.P.A.R.K."
author: "ahed9x"
description: "ping pong no camera refree"
created_at: "2026-01-07"

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

![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6ODc0MDksInB1ciI6ImJsb2JfaWQifX0=--64668ec0402cd21d008ce8f7e16fd75a30775ffa/image.png)
![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6ODc0MDIsInB1ciI6ImJsb2JfaWQifX0=--236ce4d11ebcd0138cd0cf7919944b2c20ad4e4c/image.png)![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6ODc0MDMsInB1ciI6ImJsb2JfaWQifX0=--e00141300b506f0d974a7b47ab1caac9782b6757/image.png)![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6ODc0MDQsInB1ciI6ImJsb2JfaWQifX0=--6a81a576d852e4a70f2642cf1358f6e95eac48eb/image.png)

**Total time spent: 2.5 hours**

# Creating the sketch

SCHNew-Project2026-01-07

SchematicNew-Project2026-01-07
i created everything i am nearly ready to start building in real life after i finish the basic code


[SCH_New-Project_2026-01-07](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6NzYxNTUsInB1ciI6ImJsb2JfaWQifX0=--1bcde22c5a20d487cc9692bd3d6b37c379a83c24/SCH_New-Project_2026-01-07.json)

![Schematic_New-Project_2026-01-07 (1)](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6NzYxNTYsInB1ciI6ImJsb2JfaWQifX0=--36eb3ab9fe79d368cf96e59386c256e9c0150f98/Schematic_New-Project_2026-01-07%20(1).png)

[Schematic_New-Project_2026-01-07](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6NzYxNTcsInB1ciI6ImJsb2JfaWQifX0=--2059aeb7d20e58d1e6439206101da1397c563e8a/Schematic_New-Project_2026-01-07.pdf)

**Total time spent: 3.5 hours**

# Firmware

using GitHub Copilot and gemini i created the first script that is ready for deployment along with the flutter app in seconds and these will maybe see some modifications when creating. also I removed 1 esp and 2 mics from the project because they are unnecessary.

![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6NzYxNjUsInB1ciI6ImJsb2JfaWQifX0=--d84409dfc48f1ab76c68ac47f976b6fec4fab45d/image.png)

**Total time spent: 0.2 hours**

# Rethinking the design

I heavily researched and will shift to a completely new plan:
first we will use 3 esps 1 for 4 mics and 4 piezos, and another for 6 piezos with a master one for the game logic, sd, speaker, and lights. Further, we added an SD card and a temperature, humidity, and pressure sensor all in one.
also i figuered out 50m of LEDs is an overkill, and I shall not ask for that here.

![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE2MTc5LCJwdXIiOiJibG9iX2lkIn19--038a268dab7fc12b10218f51f50634d7fb497a1a/image.png)

![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE2MTgwLCJwdXIiOiJibG9iX2lkIn19--cefa2e5dab426c2a10dee6152ef23cbd0462ca12/image.png)

![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE2MTgxLCJwdXIiOiJibG9iX2lkIn19--0518eea393ea9751ab8d809d02e4b2f58b2cd304/image.png)

**Total time spent: 7.0 hours**

# Designing ESP Case

In Fusion 360, I designed a case with a mini fan for the ESP, but for the lowest noise, the fans will work only if heat is detected, but still, the design might need more tweaking.

![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE2MTkzLCJwdXIiOiJibG9iX2lkIn19--9f8396f9be878ea9f397b4026afe46115b88aeb4/image.png)
![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE2MTk0LCJwdXIiOiJibG9iX2lkIn19--f78b9f482a4229d3ac23af8b52eca4645adcdc87/image.png)
![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE2MTk1LCJwdXIiOiJibG9iX2lkIn19--b800f2c10eafa62003efc606320546e277d199af/image.png)
![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE2MTk2LCJwdXIiOiJibG9iX2lkIn19--68b3736ef9fc50139c6f20c4d1509ea88b540f98/image.png)


**Total time spent: 2.0 hours**

# Finished the new code

i created the initial code but it still also needs high refinement when all equipment is equipped to make it perfect through dedication and tuning.

...

**Total time spent: 1.0 hour**

# Creating the github repo

I uploaded everything to the github and repo is fully ready, and I even created the BOM csv with links and prices, and use highly detailed making the project nearly complete

![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE2MjI4LCJwdXIiOiJibG9iX2lkIn19--47d4237978bc2229a0a2ec7b68315de71bc323ac/image.png)
![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE2MjI5LCJwdXIiOiJibG9iX2lkIn19--68e9e50c2689e9a371c7189affb9483029932c62/image.png)...

**Total time spent: 1.0 hour**

# Wiring and final details

After more research, I figured I need acoustic foam panels due to the room my ping pong table is in, as it has over echo, but i wont add those to the BOM because they are according to the room. I need around 200 panels, but they are mega expensive, so I will buy with around 2000 egp 72 panels, and I already own 24.

![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE2NDA4LCJwdXIiOiJibG9iX2lkIn19--a485db878a54e13badfc269651d57bc7d5534e7b/image.png)

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

![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE3MDE4LCJwdXIiOiJibG9iX2lkIn19--f31504556454e2892462e9210659b0343546cbbd/image.png)
![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE3MDE5LCJwdXIiOiJibG9iX2lkIn19--e3df4613af123387fe74a462c149e47e461746bc/image.png)![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE3MDIwLCJwdXIiOiJibG9iX2lkIn19--b7b90f9268836b7480858e90961a72d4f5573c5f/image.png)
![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE3MDIxLCJwdXIiOiJibG9iX2lkIn19--167d946d7a392bb0e701099e4096c87e69f8ad0b/image.png)

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

![Untitled-2026-03-07-0833](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE3MDQ1LCJwdXIiOiJibG9iX2lkIn19--9c8ea94dbc07a7231d3996427b1e3f2aad2c601f/Untitled-2026-03-07-0833.png)

**Total time spent: 1.0 hour**

# Creating new wiring schematic

I finally created the wiring schematic for the whole project. It was a pretty devastating process!

SchematicNew-Projecterewrewrwer2026-03-12 (1)
SchematicNew-Projecterewrewrwer2026-03-12 (1)
SCHNew-Projecterewrewrwer2026-03-12 (1)

![Schematic_New-Projecterewrewrwer_2026-03-12 (1)](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE5ODQ2LCJwdXIiOiJibG9iX2lkIn19--2f9d6ac885642415e403b52113aeb9034f7772f8/Schematic_New-Projecterewrewrwer_2026-03-12%20(1).png)

[Schematic_New-Projecterewrewrwer_2026-03-12 (1)](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE5ODQ3LCJwdXIiOiJibG9iX2lkIn19--1f37be31bc8fd04163ed71fed220f4af3f8625dd/Schematic_New-Projecterewrewrwer_2026-03-12%20(1).pdf)

[Schematic_New-Projecterewrewrwer_2026-03-12 (1)](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE5ODQ4LCJwdXIiOiJibG9iX2lkIn19--c872787a43fa714e4c539762dd768bc1d6fb2384/Schematic_New-Projecterewrewrwer_2026-03-12%20(1).svg)

[SCH_New-Projecterewrewrwer_2026-03-12 (1)](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE5ODQ5LCJwdXIiOiJibG9iX2lkIn19--1c38005ab2678881f3550a9525bf119aeaeedc5a/SCH_New-Projecterewrewrwer_2026-03-12%20(1).json)


**Total time spent: 3.0 hours**

# Finished the full CAD assembly

I finished the final full CAD assembly and noted that we can't poke holes and screws through the ping pong table, so everything will be glued/taped, or the table will be ruined.

![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE5ODYyLCJwdXIiOiJibG9iX2lkIn19--39beca4bd95157ab7a466512b3ce8f59d96a183d/image.png)
![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE5ODYzLCJwdXIiOiJibG9iX2lkIn19--61c4c4d90726cc5316300615d30a735791776f76/image.png)
![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE5ODY0LCJwdXIiOiJibG9iX2lkIn19--abea87dd6a44a95c11d0b8c1ce5e16118bd0f880/image.png)
![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE5ODY1LCJwdXIiOiJibG9iX2lkIn19--2ac13a4c6e529e6b948280e4ff1b40a8d1d10e06/image.png)


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

my sanity check: [https://hackclub.slack.com/archives/C083S537USC/p1773320504364319]()

![image](/user-attachments/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTE5ODc1LCJwdXIiOiJibG9iX2lkIn19--bfdba552dc4444d0fdce5369ea5815b533e46770/image.png)


**Total time spent: 0.1 hours**
