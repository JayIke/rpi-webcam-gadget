# Overview
Senior Design - RPI as an embedded AI plug-and-play USB2.0 webcam, 
Materials:
1. Raspberry Pi Zero 2W (32-Bit Bullseye LITE)
2. Camera - RPI Camera Module V.3
3. Stereo Microphone - SPH0645 (Qty. 2)
4. Cables - Micro-USB Power and Micro-USB 2.0 Data

## Video Processing and Software Stack
The Big Picture:
The `Libcamera` software stack is primarily responsible for enabling access to camera data. It bypasses the GPU of which users do not have access to and provides the API interface for applications. Our AI functions are built on top of this framework. The computer vision library, `opencv`, will be responsible for autonomously manipulating the live video stream. Autonomous behavior is defined by the combination of logic, prebuilt ML models, and event loops. However, `opencv` (for some reason) relies on `pycamera2` to grab frames. `v4l2` (Linux video/camera kernel interface) is the low-level interface between user-space and the kernel. The goal is to define a camera system comprised of the following software grouped by function:
1) Computer vision and processing --> `opencv` and `picamera2` will work together to acquire and manipulate frames.
  To do: Direct output to an images/slideshow directory, buffer, or other output type accessible by uvc-gadget program.
2) Host-side Control and GPIO signaling - Build on top of working `ConfigFS` framework in the `processing` or `extension unit (xu)` directory to query and respond to IOCTL requests and GPIO signals. For example, toggle blur effect or camera stream on and off. File descriptors in this directory rely on the uvc-chain configuration (source/output ids). May need to tear down or build up  after disable or enable signal is received - in runtime.
   To do: Check compatibility with `v4l2` api
3) USB output and Pipeline config: `uvc-gadget` utilizes various libraries, but a logical start would be to discern the difference in choosing the current default, `Libcamera` as a video source, and `v4l2` directory pointers. `Libcamera` is certainly a valid video source and `v4l2` details our main video stream as a sub-device which is a layer below media device.
   To do: Understand the interaction between `uvc-gadget` and `v4l2` - `libcamera` would be worth a second look.

Video=Pictures:
Video is produced by transmitting individual frames at a certain frequency (i.e., 30 fps). So a set of pictures being displayed sequentially and at a rate that makes it appear seamless, we call a video. Resolution is the pixel density i think and a pixel contains a color value corresponding to the selected color group (i.e., RGB, BGR, Grayscale, HSV, etc). Data acquired from the camera module is stored in frame buffers which are responsible for temporarily storing data while its being moved. Once data has traveled safely to its destination, we need to destroy it so the memory it occupied is now free - literally using either a `release()` or `destroy()` function call.

## V4L2 Devices
I'm just assuming this to be a compatibility layer between higher level libcamera API and lower level uvc-driver implementations. It's clear V4L2 video devices get created as a result of both camera detection (libcamera media controller) and ConfigFS function to UDC binding (`rpi-webcam-gadget.sh` creates `/dev/video2`).

Probably important:

[V4L2 Events](https://www.kernel.org/doc/html/v4.9/media/kapi/v4l2-event.html)

[V4l2 IOCTL OPS](https://www.kernel.org/doc/html/v4.9/media/kapi/v4l2-videobuf.html#ioctl-operations)

### 3 buffer types
1) For scatter/gather DMA ops: Buffers which are scattered in both the physical and (kernel) virtual address spaces. (Almost) all user-space buffers are like this, but it makes great sense to allocate kernel-space buffers this way as well when it is possible. Unfortunately, it is not always possible; working with this kind of buffer normally requires hardware which can do scatter/gather DMA operations.
3) Allocated with `vmalloc()`: Buffers which are physically scattered, but which are virtually contiguous; buffers allocated with vmalloc(), in other words. These buffers are just as hard to use for DMA operations, but they can be useful in situations where DMA is not available but virtually-contiguous buffers are convenient.
4) Buffers which are physically contiguous. Allocation of this kind of buffer can be unreliable on fragmented systems, but simpler DMA controllers cannot deal with anything else.

I think we use (2), at least in uvc-gadget driver.

## Control Scheme
Eventually we want to start/stop/toggle between stream delivery methods effectively and without locking up memory or controls. The first step is to install buttons to gpio and listen using the pigpiozero lib (.py) to trigger basic terminal commands. The next step will be to pass/emit events to the correct places - if it's not too involved. We may have to just pass hard start and kill cmds to terminal to emulate (fake) some sophisticated level of control.

## Top-Level Diagram
More like a block diagram
```mermaid
sequenceDiagram
box Blue Hardware (Peripherals)
participant Devices
end
box Purple Raspberry Pi Zero 2W (Controller)
participant Device Drivers
participant Gadget Drivers
participant USB Device Controller (UDC)
end
box Windows/Mac PC
participant USB Host (PC)
end
Devices->Device Drivers: RPI Camera v3 
Devices->Device Drivers: I2S Mic (Stereo)
Device Drivers-->Gadget Drivers: Video
Device Drivers-->Gadget Drivers: Audio
Gadget Drivers-->USB Device Controller (UDC): Video/Audio Pipeline
Note over Device Drivers,USB Device Controller (UDC): Config FS - uvc and uac1 functions 
USB Device Controller (UDC)->USB Host (PC): Webcam Stream
```

## ConfigFS Framework (See Docs)
- Purpose: Create gadget device, define attributes, and bind to a UDC driver. 

UVC Gadget ConfigFS Initialization:

![image](https://github.com/JayIke/rpi-webcam-gadget/assets/69820301/09f0fe65-3cae-4013-956a-f4d2eb6aac23)

### UVC Gadget
Overview from (https://docs.kernel.org/usb/gadget_uvc.html)

>*The UVC Gadget driver is a driver for hardware on the device side of a USB connection. It is intended to run on a Linux system that has USB device-side hardware such as boards with an OTG port.*
>
>*On the device system, once the driver is bound it appears as a V4L2 device with the output capability.*
> 
>*On the host side (once connected via USB cable), a device running the UVC Gadget driver and controlled by an appropriate userspace program should appear as a UVC specification compliant camera, and function appropriately with any program designed to handle them.*
>
>*The userspace program running on the device system can queue image buffers from a variety of sources to be transmitted via the USB connection. Typically this would mean forwarding the buffers from a camera sensor peripheral, but the source of the buffer is entirely dependent on the userspace companion program.*

# AI Stuff

Check your OS version (32 or 64 bit): 

```getconf LONG_BIT ```

***Opencv (Open Source Computer Vision Library):***

Description: Library of programming functions for real time computer vision operations - how we manipulate the video stream.

***Opencv Install for Python:*** [opencv install on rpi - Sam Westby Tech](https://www.youtube.com/watch?v=QzVYnG-WaM4)

# Audio Setup
This is the hardware driver for the microphone. UAC functions are defined in upon configFS initialization and of which the output of the capture card should be defaulted to. Throughput has been verified using `alsaloop` - configured with the hardware capture card as the capture device and UAC2 card as playback at 48000 (upmix to 96000?).

  To do: Integrate into pipeline using the built in libav codec - look to see syncing options available within the libcamera or v4l2 api and implement the function in uvc-gadget or other application.

## Audio Hardware

- Gadget Controller - Raspberry Pi Zero 2 W
- Microphones - ADAFRUIT SPH0645 (Stereo Configuration)

Source/reference: 
[Microphone Installation/Tutorial](https://learn.adafruit.com/adafruit-i2s-mems-microphone-breakout/raspberry-pi-wiring-test)

  LEFT MIC
  - 3.3V  Connector Pin 1
  - GND   GND
  - LRCL  Connector Pin 35 GPIO 19
  - DOUT  Connector Pin 38 GPIO 20
  - BCLK  Connector Pin 12 GPIO 18
  - SEL   Connector Pin GND

  RIGHT MIC
  - 3.3V  Connector Pin 1
  - GND   GND
  - LRCL  Connector Pin 35 GPIO 19
  - DOUT  Connector Pin 38 GPIO 20
  - BCLK  Connector Pin 12 GPIO 18
  - SEL   Connector Pin 3.3V
 
## Audio Software

Stereo Configuration works using Paul's driver.

Modified the dma_engine request to bcm2710 - not sure if this was necessary.

[Paul Creaser's i2s mic driver](https://github.com/PaulCreaser/rpi-i2s-audio)

```bash
# Working in mono config:
sudo nano /boot/config.txt # uncomment dtparam=i2s=on (i enabled the i2c_arm and spi params as well)
git clone https://github.com/PaulCreaser/rpi-i2s-audio
cd rpi-i2s-audio/


sudo nano my_loader.c
# Change dma_engine=bcm2708-dmaengine to dma_engine=bcm2710-dmaengine (Pi-zero Z2W)

# install latest kernel headers if necessary
sudo apt-get install raspberrypi-kernel-headers

# build my_loader module
make -C /lib/modules/$(uname -r)/build M=$(pwd) modules
sudo insmod my_loader.ko

# Check if capture card is available
arecord -l && arecord -L

# Try recording - volume will be low but vumeter should react (2% by default for me)
arecord -D plughw:1 -c 2 -r 48000 -f S32_LE -V stereo -v -t wav test.wav

# may need to reboot and insmod again
# i believe this would call my_loader on boot:
echo "my_loader" | sudo tee -a /etc/modules
```

![image](https://github.com/JayIke/rpi-webcam-gadget/assets/69820301/4ce2cc78-517c-4827-904a-ae4a77075d87)

### Combine/sync to Video
Maybe the way
[rpicam-apps libav tutorial](https://github.com/raspberrypi/documentation/blob/develop/documentation/asciidoc/computers/camera/rpicam_apps_libav.adoc)

# Resources

GPIO Zero for hardware buttons

[GPIO Zero - Controlling GPIO using Python](https://gpiozero.readthedocs.io/en/latest/recipes.html)

[Pi-Zero 2W AI Benchmarks](https://qengineering.eu/install-64-os-on-raspberry-pi-zero-2.html)

[ffmpeg adding audio to video](https://json2video.com/how-to/ffmpeg-course/ffmpeg-add-audio-to-video.html)

[Image Signal Processor - ISP Overview](https://www.utmel.com/blog/categories/integrated%20circuit/what-is-isp-image-signal-processor)

## v4l2 
V4L2 Video/Media node descriptions
![image](https://github.com/JayIke/rpi-webcam-gadget/assets/69820301/6425d938-8c80-4f28-bade-58a7b78f6aa2)

### Archive Graveyard
Archives, honorable mentions, failed attempts - this is where I am hording currently unused or out of scope references/tutorials I stumbled upon.

### Software Dependency archive
Putting old software install and build instructions here so as to not be confused with current build.

### Installation History (not current - reflashed w/ fresh Bullseye image)
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

### Custom libcamera build (old - reflashed)
[libcamera/rpicam build tutorial](https://www.raspberrypi.com/documentation/computers/camera_software.html#building-libcamera-and-rpicam-apps)
```bash
# If not already cloned:
git clone https://git.libcamera.org/libcamera/libcamera.git
cd libcamera
meson setup build --buildtype=release -Dpipelines=rpi/vc4,rpi/pisp -Dipas=rpi/vc4,rpi/pisp -Dv4l2=true -Dgstreamer=enabled -Dtest=false -Dlc-compliance=disabled -Dcam=disabled -Dqcam=disabled -Ddocumentation=disabled -Dpycamera=enabled
```
![image=](https://github.com/JayIke/rpi-webcam-gadget/assets/69820301/b1378ccc-cc5f-4543-8d9f-a0a411360ea3)

### Custom rpicam build (old - reflashed)
[libcamera/rpicam build tutorial](https://www.raspberrypi.com/documentation/computers/camera_software.html#building-libcamera-and-rpicam-apps)
```bash
# Make sure build tools are installed
sudo apt install -y meson ninja-build
# If not already cloned
git clone https://github.com/raspberrypi/rpicam-apps.git
cd rpicam-apps
meson setup build -Denable_libav=true -Denable_drm=true -Denable_egl=false Denable_qt=false -Denable_opencv=true -Denable_tflite=false
meson compile -j1 -C build
sudo meson install -C build
```
![image](https://github.com/JayIke/rpi-webcam-gadget/assets/69820301/d58ee568-9849-4d96-89cb-db1fbe7f25d8)

## Resource Archive

No longer referencing these:
[Gstreamer Bullseye Setup (ignore - for pi4](https://qengineering.eu/install-gstreamer-1.18-on-raspberry-pi-4.html)
[Build Stuff (ignore)](https://bootlin.com/blog/enabling-new-hardware-on-raspberry-pi-with-device-tree-overlays/#:~:text=The%20Raspberry%20Pi%20kernel%20tree%20contains%20a%20number,stored%20in.dts%20file%20gets%20compiled%20into%20a.dtbo%20files.)

Host Side USB

  - [IRQ - interrupt requests](https://www.techtarget.com/whatis/definition/IRQ-interrupt-request)

Client/Device Side USB

 - [ConfigFS Gadget](https://irq5.io/2016/12/22/raspberry-pi-zero-as-multiple-usb-gadgets/)
 - [Linux Kernel Building](https://www.raspberrypi.com/documentation/computers/linux_kernel.html#building-the-kernel)
 - [Linux-Header Install](https://www.raspberrypi.com/documentation/computers/linux_kernel.html#kernel-headers)
 - [Multi-gadget ConfigFS Example](https://gist.github.com/geekman/5bdb5abdc9ec6ac91d5646de0c0c60c4)
   `"On a mac, use ecm, rather than rndis."`
 - [ConfigFS Attribute Definitions](https://docs.kernel.org/usb/gadget_configfs.html)
  
Alternate Cam

Arducam Camera Module 3 (Third Party)
- Model - UC-A74 Rev. B
- SKU   - B0311
- Specs - 110deg, wide-angle, auto focus
- [Vendor Site](https://docs.arducam.com/Raspberry-Pi-Camera/Native-camera/12MP-IMX708/)

(OLD) TO DO:
- Use ConfigFS framework to reconfigure our current pipeline from the tutorial [the plug-and-play tutorial gives a solid stream but we need to reconfigure](https://gitlab.freedesktop.org/camera/uvc-gadget/)
- Important: [Camera Tuning Guide](https://datasheets.raspberrypi.com/camera/raspberry-pi-camera-guide.pdf?_gl=1*ahfnux*_ga*Nzc4ODQ2NDAwLjE3MDk5NTExMTU.*_ga_22FD70LWDS*MTcxMDg4MzY0Ny40Ny4xLjE3MTA4ODU5MDMuMC4wLjA.)
- [Video] Figure out which node will take care of post-processing (add features)
-   do we have enough memory allocated?
  
- [Audio] Avoid any processing --> sink straight to usb endpoint
-   Include audio function in uvc-gadget app



