---
title: "S.P.A.R.K."
author: "ahed9x"
description: "ping pong no camera refree"
created_at: "2026-01-07"
---

# ⚡ S.P.A.R.K.

> an acoustic ping pong referee. 15 sensors, 3 esp32s, zero cameras.

## why i built this
last summer i wasted weeks trying to train a computer vision model to track a ping pong ball. the frame rates were terrible, the processing lagged, and it basically sucked. then one day i was sitting by the table waiting for my turn, closed my eyes, and realized i could track the score and whose turn it was just by listening to the bounces. 

it clicked that acoustic time-of-flight on edge microcontrollers would be way faster for catching a 100km/h ball without needing a crazy gpu. so i scrapped the camera and built this instead.

## what it actually is
SPARK is a fully automated table-tennis referee. it uses 4 i2s microphones on the corners of the table to listen for the ball, and calculates the exact x/y coordinate of the hit using time-difference-of-arrival (TDOA) math. i also glued 10 lm393 piezo sensors under the table and net to catch instant physical vibrations. 

everything gets processed by a master esp32 that runs the game logic, drives a 5m led scoreboard, and yells the score out through a speaker.

<img width="1282" height="717" alt="Untitled-2026-03-07-0833" src="https://github.com/user-attachments/assets/d2cac3a9-b04b-4d05-b81f-3d0874467d90" />

## the architecture (why 3 chips?)
at first i tried to run this on one or two chips, but the interrupts kept crashing. ping pong is way too fast. if the esp is busy updating the led strip, it misses the sound of the bounce. 

the biggest hurdle was clock sync. all 4 microphones MUST share the exact same internal hardware clock. if i split them across different chips, the microsecond time-of-flight math drifts and the coordinates get completely ruined. 

so i split the load:
* **s3 alpha (left side):** handles all 4 mics (to keep the clock perfectly synced) + the left side piezos.
* **s3 beta (right side):** handles the right side piezos + the net piezos.
* **master wroom:** runs the actual game logic, the bme680, audio amp, and led scoreboard.

alpha and beta just act as raw sensor nodes and fire data back to the master over hardwired UART.

## the math & physics
**speed of sound drift:** the speed of sound literally changes depending on how hot the room is. if i don't account for this, the math drifts. i threw a bme680 sensor on the master board to constantly read the room temp in celsius and update the velocity variable in real time.

**tdoa (time difference of arrival):** 4 mics give us 3 independent arrival time differences. instead of running crazy non-linear solvers that would lag the esp, the system linearizes the equations into a 3x3 matrix and solves it instantly using cramer's rule. 

**analog vs digital piezos:** initially i tried reading the piezos via analog pins. terrible idea. the esp wasted too many cycles polling the voltage. i switched to lm393 modules so the hardware handles the threshold tuning. when a ball hits, it fires a digital HIGH, triggering a zero-latency hardware interrupt.

## the wiring nightmare
no custom pcb yet, it's all point-to-point. 

running raw uart and i2s data wires across a 2.7 meter table turns them into giant antennas that pick up massive emi static from the 15A power supply. it was a devastating process figuring out why the signals were garbage. i ended up using cat5e ethernet cables for the long data runs—twisting the rx/tx lines with ground wires inside the cat5e physically shields the signals.

<img width="2000" height="1416" alt="Schematic_New-Projecterewrewrwer_2026-03-12 (1)" src="https://github.com/user-attachments/assets/5fbbe91f-782d-4465-a225-d17da93601f2" />
[Schematic_New-Projecterewrewrwer_2026-03-12 (1).pdf](https://github.com/user-attachments/files/28225490/Schematic_New-Projecterewrewrwer_2026-03-12.1.pdf)

## 3d printed parts & acoustic shadows
i couldn't drill holes in the table (obviously), so everything mounts with vhb tape. 

i also originally wanted to mount the mics deep underneath the table to protect them, but realized the thick wooden edge creates an "acoustic shadow" that bends and delays the sound wave. that delay completely destroys the millimeter accuracy. i had to design custom fusion 360 brackets that extend out and keep the mic entry hole perfectly flush with the table surface.

![full assembly](https://github.com/user-attachments/assets/11f8baba-dc9f-4f11-876d-fe365effce73)
![ESP Case](https://github.com/user-attachments/assets/ff99ffbb-f727-4f0a-9f1a-e87f7ed1b32d)
![Mic Holder](https://github.com/user-attachments/assets/1c2541c9-c1d7-45f2-b686-679fba55c55a)

## the build / bom
the whole thing costs around 6492 EGP (like 125 USD). 

<img width="1268" height="898" alt="image" src="https://github.com/user-attachments/assets/ca8c10fe-b68e-47a8-aa1b-91f10c7d49c0" />
<img width="1267" height="906" alt="image" src="https://github.com/user-attachments/assets/34621755-9652-42aa-b3de-f0f8530a9212" />

* 2x ESP32-S3-N16R8
* 1x ESP32 WROOM
* 4x INMP441 MEMS Mics
* 10x LM393 Piezo Modules
* 1x BME680 Sensor
* 1x MAX98357A I2S Amp + 3W Speaker
* 5m WS2812B LEDs + 15A PSU
* lots of CAT5E cable

all cad files are in the `/cad` folder on this repo. 

<img width="1517" height="718" alt="image (1)" src="https://github.com/user-attachments/assets/c4ae6057-1ea1-4dd7-94d6-f7f0e4f33d15" />
<img width="1919" height="1024" alt="image (2)" src="https://github.com/user-attachments/assets/219bbfd1-774d-4021-9be7-62cfae1d022e" />

## quick start
1. flash all 3 esps using platformio.
2. grab the mac addresses of the alpha and beta chips and drop them into `shared/spark_protocol.h` on the master.
3. put your game audio `.wav` files (16-bit pcm, mono) onto a fat32 micro sd card and pop it into the master module.
4. connect to the `SPARK_Table` wifi network, hit `192.168.4.1`, and hit new game.
