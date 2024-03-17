# Overview

## Top-level View
```
|] (Peripheral/Gadget(s) Device) Pi Zero 2W + Camera + I2S Mic 
|
|] via USB 2.0 standard -- see Docs
|
|] (Host) Mac/Windows
```
## TO DO:
- Use ConfigFS framework to reconfigure our current pipeline from the tutorial ([the plug-and-play tutorial gives a solid stream but we need to reconfigure](https://gitlab.freedesktop.org/camera/uvc-gadget/))
- 
- [Video] Figure out which node will take care of post-processing (add features)
-   do we have enough memory allocation?
- [Audio] Avoid any processing --> sink straight to usb endpoint
-   do i have to wait for video?

## ConfigFS Framework (See Docs)
- Purpose: Create gadget device, define attributes, and bind to a UDC driver. This is done by symbolic linking?
```bash
ln -s <src_dir> <target_dir>
```
- ConfigFS instantiates Kernel objects provided by SysFS (SysFS just responds to uevents? i think?)

### Structure:
TOP: Upper Layers (network, fs, block I/O)
MID: Gadget Drivers (use gadget API, functions, end points (EPx)
LOW: Peripheral Drivers (HW, mic, camera)

# Helpful Commands
```bash
v4l2-ctl --all        # shows all recognized devices in pipeline
systemctl list-sockets # see services
systemctl --user status <service> # checks if named service is active or inactive, we might use these
systemd # Starts and monitors system and user services!!!
lsusb -v # shows usb hub info (how we identify with host)
lsmod # shows all active modules and dependencies
pstree # i believe this shows the systemd pipeline?
dmesg # boot messages, useful if something didn't come up as expected
```

## In Progress
1) overlay=dwc2 in config.txt 
2) modprobe libcomposite
3) set up USB gadgets via ConfigFS (place in /usr/bin/myusbgadget)

```bash
#!/bin/bash -e
 
modprobe libcomposite
 
cd /sys/kernel/config/usb_gadget/
mkdir g && cd g
 
echo 0x1d6b > idVendor  # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice # v1.0.0
echo 0x0200 > bcdUSB    # USB 2.0
 
mkdir -p strings/0x409
echo "deadbeef00115599" > strings/0x409/serialnumber
echo "irq5 labs"        > strings/0x409/manufacturer
echo "Pi Zero Gadget"   > strings/0x409/product
 
mkdir -p functions/acm.usb0    # serial
mkdir -p functions/rndis.usb0  # network
 
mkdir -p configs/c.1
echo 250 > configs/c.1/MaxPower
ln -s functions/rndis.usb0 configs/c.1/
ln -s functions/acm.usb0   configs/c.1/
 
udevadm settle -t 5 || :
ls /sys/class/udc/ > UDC
```
3) write the systemd service and use ```bash systemctl enable myusbgadget```
4) 
```bash
# /usr/lib/systemd/system/myusbgadget.service
 
[Unit]
Description=My USB gadget
After=systemd-modules-load.service
 
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/myusbgadget
 
[Install]
WantedBy=sysinit.target
```

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
