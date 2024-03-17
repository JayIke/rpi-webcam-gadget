# Overview

camera with a voice and brain

# Hardware Setup
- Gadget Controller - Raspberry Pi Zero 2 W
- Camera - RPi camera module v.2 (for now)
- Microphones - ADAFRUIT SPH0645 (Stereo Configuration)

  LEFT MIC
  - 3.3V Connector Pin 1
  - GND   Connector Pin 39
  - LRCL  Connector Pin 35 GPIO 19
  - DOUT  Connector Pin 37 GPIO 20
  - BCLK  Connector Pin 12 GPIO 18
  - SEL   Connector Pin 3.3V

  RIGHT MIC
  - 3.3V Connector Pin 1
  - GND   Connector Pin 5?
  - LRCL  Connector Pin 35 GPIO 19
  - DOUT  Connector Pin 37 GPIO 20
  - BCLK  Connector Pin 12 GPIO 18
  - SEL   Connector Pin GND
 
# Software

Testing Paul's rpi-i2s-audio device tree overlay on (Debian12/Bookworm OS-lite - 6.6.21) 03/17/24

## rpi-i2s-mic.dts

This is the overlay for a MEMs microphone, specifically the SPH0645 I2C MIC.

# Configuration and Test Procedures

## Clone and Compile 
### Clone repo without history
``` bash
cd ~
git clone --depth=1 https://github.com/JayIke/rpi-i2s-audio.git
```
### Compile device tree into device tree blob overlay
``` bash
git clone --depth=1 https://github.com/JayIke/rpi-i2s-audio.git
dtc  -I dts -O dtb -o rpi-i2s-mic.dtbo  rpi-i2s-mic.dts 
sudo cp rpi-i2s-mic.dtbo /boot/firmware/overlays/.
# just to be safe:
sudo cp rpi-i2s-mic.dtbo /boot/overlays/.
```
### Enable overlay in config.txt
``` bash
echo "dtoverlay=rpi-i2s-mic" | sudo tee -a /boot/firmware/config.txt
sudo reboot
```
# Install Hardware and Test
### Check if sound card is available in alsa
``` bash
arecord -l && arecord -L
```
### Try recording a file and saving it as .wav
``` bash
arecord -D mic -c 2 -r 48000 -f S32_LE -V stereo -v -t wav test.wav
```


## i2s_audio_read_test.py

Simple demo application for recording audio from I2S mems mic

# Warning

After looking at the raw data via python using the sounddevice module, it seems there is a dc offset in the output data. Subtracting the mean or high pass filtering can be used to remove this offset. During playback you will hear a pop or click when audio playback starts or finishes.
