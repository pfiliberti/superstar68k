# superstar68k
Circa 1984 I designed a 68000 based computer with graphics and sound
to be utilized as an arcade type gaming board. The board utilized an
Hitach HM63484 GPU as a graphics processor and an SAA1099 for sounds.

It Also had a secondary 8051 compatible CPU made by Dallas Semiconductor
the DS-5000 that had built in memory backup and other features. This
was used as an I/O and game controller and exchanged information with
the 68000 processor which mainly worked the graphics and animation
functions. It could communicate serially with a computer/terminal 
serial port or it could also do rs-485 multidrop so it could be
connected to multiple betting stations etc..

It has a ROM debuger and Tiny Basic which was modified to support the
GPU internal draw commands. We used this a lot to experiment and to
exercise the hardware.
# SUPERSTAR COMPUTER SPECIFICATIONS
1. CRT Display            : 640 Dots X 200 Rasters X 256 Color per dot (Pixel)
2. Dot Clock              : 14.318 MHZ
3. 2Clk                   : 7.159 MHZ
4. ACRTC Type             : 8 MHZ
5. Shift Quantity         : 8 Pixels Per Memory Access
6. Access Mode            : Interleaved access mode
7. Graphic bit mode       : 8 Bits Per Pixel
8. Address Increment mode : +4
9. Graphics Memory Type : HD50464 or Equiv. 64K x 4 bits 120ns QTY=16
10. Total Graphics Memory : 512K (One Screen = 128,000 bytes)
11. Main Microprocessor : 68000-8 Cpu
12. Program ROM Size : 256K WORDS (512K Bytes)
13. Program RAM Size : 8K Words (16K RAM)

### 68000 Memory Map
1. 00000- 7FFFF   256K WORDS OF ROM
2. 80000- 83FFF   8K WORDS OF RAM
3. AX000- AX002   63484 VIDEO IC #1 PORTS
4. AX400- AX7FF   VIDEO DAC #1 RAM LOCATIONS
---
Posting to Github so others may see the design and possible work on a new board with a few less features not needed for the arcade market but to possibly build a small retro computer with cool graphics and sound for educational purposes.



