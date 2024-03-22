# Resources

## Pipeline related debugging commands 

```bash (download)
# ~/.bash_aliases
#
# Enable a bash alias file:
# 1) place this file in ~/.bash_aliases
# 2) cd ~
# 3) source ~/.bashrc
#
# Example: device-map
# Outputs: prints paths, id nodes, and links of sound v4l and video devices (pipeline related)
#
# RPI Z2W AI Webcam Project
# AI, Video and Audio

# Show camera devices v4l recognizes
alias show-video='v4l2-ctl --list-devices'

# Show audio capture and playback soundcards
alias show-audio='arecord -l && aplay -l'

# Start audio capture 2-channel,48kHz sample rate, signed 32-bit little endian format, save to wave
alias capture-audio='arecord -D plughw:0,0 -c 2 -r 48000 -f s32_le -t wav cap_audio.wav'

# show system devices
alias show-units='systemctl list-units'

# search for relevant modules
alias show-modules='lsmod | grep -iE "snd|g_|usb|uvc|vid|audio|sound|i2s|gadget|camera|lib"'

# show size and classifcation of files in directory - column
alias lt='ls --human-readable --size -1 -S --classify'

# shows device path, link, id node, and
alias device-map='ls -R -L -i -c /dev/snd/ /dev/v4l/ /dev/bus /dev/video*'
```

[Pi-Zero 2W AI Benchmarks](https://qengineering.eu/install-64-os-on-raspberry-pi-zero-2.html)

[Build Stuf (ignore)](https://bootlin.com/blog/enabling-new-hardware-on-raspberry-pi-with-device-tree-overlays/#:~:text=The%20Raspberry%20Pi%20kernel%20tree%20contains%20a%20number,stored%20in.dts%20file%20gets%20compiled%20into%20a.dtbo%20files.)

[Gstreamer Bullseye Setup](https://qengineering.eu/install-gstreamer-1.18-on-raspberry-pi-4.html)
## Software Dependencies
```bash
# Currently using -> 6.1.21-v7+ #1642 SMP Mon Apr  3 17:20:52 BST 2023 armv7l GNU/Linux

# libcamera / rpicam
sudo apt install -y libcamera-dev libjpeg-dev libtiff5-dev libpng-dev
sudo apt install libavcodec-dev libavdevice-dev libavformat-dev libswresample-dev
sudo apt install -y git

# libcamera
sudo apt install -y libboost-dev
sudo apt install -y libgnutls28-dev openssl libtiff5-dev pybind11-dev
# sudo apt install -y qtbase5-dev libqt5core5a libqt5gui5 libqt5widgets5 we don't need preview window
sudo apt install -y meson cmake
sudo apt install -y python3-yaml python3-ply
sudo apt install -y libglib2.0-dev libgstreamer-plugins-base1.0-dev

# build libcamera
git clone https://git.libcamera.org/libcamera/libcamera.git
cd libcamera
meson setup build --buildtype=release -Dpipelines=rpi/vc4,rpi/pisp -Dipas=rpi/vc4,rpi/pisp -Dv4l2=true -Dgstreamer=enabled -Dtest=false -Dlc-compliance=disabled -Dcam=disabled -Dqcam=disabled -Ddocumentation=disabled -Dpycamera=enabled
ninja -j 1 -C build # remove the -j 1 flag if it doesnt work
sudo ninja -j 1 -C build install # remove - j 1 flag if it doesnt work

# codeblocks
sudo apt install codeblocks

# open-cv
sudo apt install libopencv-dev
sudo apt install python3-opencv

#  v4l2-utils 
sudo apt install v4l2loopback-dkms v4l2loopback-utils ffmpeg

# Gstreamer for pipeline
sudo apt install python3-pip python3-yaml libyaml-dev python3-ply python3-jinja2
sudo apt install libx264-dev libjpeg-dev libgstreamer1.0-dev \
     libgstreamer-plugins-base1.0-dev \
     libgstreamer-plugins-bad1.0-dev \
     gstreamer1.0-plugins-ugly \
     gstreamer1.0-tools \
     gstreamer1.0-gl \
     gstreamer1.0-gtk3

# Ignore this, reference only
# git clone https://git.libcamera.org/libcamera/libcamera.git
# cd libcamera
# meson setup build
# ninja -C build install

# [Camera Tuning Guide](https://datasheets.raspberrypi.com/camera/raspberry-pi-camera-guide.pdf?_gl=1*ahfnux*_ga*Nzc4ODQ2NDAwLjE3MDk5NTExMTU.*_ga_22FD70LWDS*MTcxMDg4MzY0Ny40Ny4xLjE3MTA4ODU5MDMuMC4wLjA.)
```

## Current libcamera build
```bash
# If not already cloned:
git clone https://git.libcamera.org/libcamera/libcamera.git
cd libcamera
meson setup build --buildtype=release -Dpipelines=rpi/vc4,rpi/pisp -Dipas=rpi/vc4,rpi/pisp -Dv4l2=true -Dgstreamer=enabled -Dtest=false -Dlc-compliance=disabled -Dcam=disabled -Dqcam=disabled -Ddocumentation=disabled -Dpycamera=enabled
```
![image](https://github.com/JayIke/rpi-webcam-gadget/assets/69820301/b1378ccc-cc5f-4543-8d9f-a0a411360ea3)
## Connection Scheme
```
|] (Peripheral/Gadget(s) Device) Pi Zero 2W + Camera + I2S Mic 
|
|] via USB 2.0 standard -- see Docs
|
|] (Host) Mac/Windows
```

## TO DO:
- Use ConfigFS framework to reconfigure our current pipeline from the tutorial [the plug-and-play tutorial gives a solid stream but we need to reconfigure](https://gitlab.freedesktop.org/camera/uvc-gadget/)
- Important: [Camera Tuning Guide](https://datasheets.raspberrypi.com/camera/raspberry-pi-camera-guide.pdf?_gl=1*ahfnux*_ga*Nzc4ODQ2NDAwLjE3MDk5NTExMTU.*_ga_22FD70LWDS*MTcxMDg4MzY0Ny40Ny4xLjE3MTA4ODU5MDMuMC4wLjA.)
- [Video] Figure out which node will take care of post-processing (add features)
-   do we have enough memory allocated?
  
- [Audio] Avoid any processing --> sink straight to usb endpoint
-   do i have to wait for video?
-   using libav codec at the libav processing stage to combine PCM/wav audio low-res video
-   send combined audio/video output to h.264 encoder then send
-   ffffffffffffffffffffffffffffffffffffff

## ConfigFS Framework (See Docs)
- Purpose: Create gadget device, define attributes, and bind to a UDC driver. This is done by symbolic linking?


``` bash
CONFIGFS="/sys/kernel/config"
GADGET="$CONFIGFS/usb_gadget"
VID="0x1d6b" # 0x1d6b (Linux Foundation)
PID="0x0104" # idProduct = Multifunction Composite Gadget
SERIAL="0123456789"
MANUF=$(hostname)
PRODUCT="Terror Cam"
BOARD=$(strings /proc/device-tree/model)
UDC=`ls /sys/class/udc` # will identify the 'first' UDC
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

3/20/24

install `pipenv` to allow multiple environments and force dependencies to a single python version
: [pipenv install tutorial](https://devcamp.com/trails/development-environments/campsites/python-development-environment/guides/how-to-install-work-pipenv-linux)

Follow this: [User Guide - pip](https://pip.pypa.io/en/stable/user_guide/#user-installs_)
```bash
sudo apt install python3-pip
cd /path/to/project

python3 -m venv ./
./bin/activate

# break it and never update ever
pip3 install --break-system-packages pipenv
pip

# might have to do this:
export PYTHONUSERBASE=/myappenv
python3 -m pip install --user pipenv
```

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
 
# Audio Software
![image](https://github.com/JayIke/rpi-webcam-gadget/assets/69820301/4ce2cc78-517c-4827-904a-ae4a77075d87)


Testing Paul's rpi-i2s-audio device tree overlay on (Debian12/Bookworm OS-lite - 6.6.21) 03/17/24

rpi-i2s-mic.dts -> This is the overlay for a MEMs microphone, specifically the SPH0645 I2C MIC.

## Configuration and Test Procedures
 
### Clone repo without history
``` bash
cd ~
git clone --depth=1 https://github.com/JayIke/rpi-i2s-audio.git
```
### Compile device tree into device tree blob overlay
``` bash
git clone --depth=1 https://github.com/JayIke/rpi-i2s-audio.git # this is forked from Paul's repo
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
### Combine/sync to Video
[rpicam-apps libav tutorial](https://github.com/raspberrypi/documentation/blob/develop/documentation/asciidoc/computers/camera/rpicam_apps_libav.adoc)

## i2s_audio_read_test.py

Simple demo application for recording audio from I2S mems mic

# Warning

After looking at the raw data via python using the sounddevice module, it seems there is a dc offset in the output data. Subtracting the mean or high pass filtering can be used to remove this offset. During playback you will hear a pop or click when audio playback starts or finishes.
