#!/bin/bash
##########################
# webcam-gadget.sh
# functions: uvc and uac2
##########################

# Referencing: https://developer.ridgerun.com/wiki/index.php/How_to_use_the_UVC_gadget_driver_in_Linux#Configuring_UVC_function
# Official kernel docs: https://www.kernel.org/doc/html/v5.5/usb/gadget-testing.html#uac2-function

# This loads the module responsible for allowing USB Gadgets to be
# configured through configfs, without which we can't connect to the
# UVC gadget kernel driver

######################
# Directories
######################
UDC=`ls /sys/class/udc`
#UDC_ROLE=/sys/devices/platform/soc/78d9000.usb/ci_hdrc.0/role
CONFIGFS="/sys/kernel/config"
GADGET="$CONFIGFS/usb_gadget"

#######################
# Basic Strings
#######################
VID="0x0525"
PID="0xa4a2"		# 0x0104 multi-function / 0x0101 for audio gadget / 0xa4a2 uvc-webcam?
SERIAL="0123456789"
MANUF=$(hostname)
PRODUCT="RTT Gadget"
BCD_DEVICE=0x0100	# 0x0100 v.1.0.0
BCD_USB=0x0200		# USB2.0
BDEVCLASS=0x10h		# 0x10h (Base Device Class) USB Audio/Video Base Class
BDEVSUB=0x01h		# 0x01h AVControl Interface
VIDSUB=0x02h		# Video Streaming Interface
AUDIOSUB=0x03h		# Audio Streaming Interface
##############################################
# Load modules
# libcomposite: allows us to define our device
# i2s-driver: initialize audio capture card
##############################################
echo "Loading composite module"
modprobe libcomposite
echo "Loading i2s audio capture card"
modprobe i2s-driver

cd $CONFIGFS
# Create the gadget
mkdir -p $GADGET/g1			# UDC, bDeviceClass, bDeviceSubclass, bMaxPacketSize0, bcdDevice, bcdDevice,
					# bcdUSB, configs, functions, idProduct, idVendor, os_desc, strings
# Set vendor and product ID
cd $GADGET/g1
echo $VID > idVendor
echo $PID > idProduct
echo $BCD_DEVICE > bcdDevice
echo $BCD_USB > bcdUSB

# Create english string
mkdir -p strings/0x409			# manufacturer, product, serialnumber

# Add manufacturer, serial number, and product information
echo $SERIAL > strings/0x409/serialnumber
echo $MANUF > strings/0x409/manufacturer
echo $PRODUCT > strings/0x409/product


#########################################
# Define audio (UAC2) function/attributes
#########################################
AUDIO_CHANNEL_MASK_CAPTURE=3		# 1=Left 2=Right 3=Stereo 0=disables the device
AUDIO_CHANNEL_MASK_PLAYBACK=3
AUDIO_SAMPLE_RATES_CAPTURE=48000
AUDIO_SAMPLE_RATES_PLAYBACK=48000
AUDIO_SAMPLE_SIZE_CAPTURE=4		# 1 for S8LE / 2 for S16LE / 3 for S24LE / 4 for S32LE
AUDIO_SAMPLE_SIZE_PLAYBACK=4


# Later on, this function is used to tell the usb video subsystem that we want
# to support a particular format, framesize and frameintervals
create_frame() {
	# Example usage:
	# create_frame <function name> <width> <height> <format> <name> <intervals>

	FUNCTION=$1
	WIDTH=$2
	HEIGHT=$3
	FORMAT=$4
	NAME=$5

	wdir=functions/$FUNCTION/streaming/$FORMAT/$NAME/${HEIGHT}p

	mkdir -p $wdir
	echo $WIDTH > $wdir/wWidth
	echo $HEIGHT > $wdir/wHeight
	echo $(( $WIDTH * $HEIGHT * 2 )) > $wdir/dwMaxVideoFrameBufferSize
	cat <<EOF > $wdir/dwFrameInterval
$6
EOF
}

# This function sets up the UVC gadget function in configfs and binds us
# to the UVC gadget driver.
create_uvc() {
	CONFIG=$1
	FUNCTION=$2

	echo "	Creating UVC gadget functionality : $FUNCTION"
	mkdir functions/$FUNCTION

	create_frame $FUNCTION 640 480 uncompressed u "333333
416667
500000
666666
1000000
1333333
2000000
"
	create_frame $FUNCTION 1280 720 uncompressed u "1000000
1333333
2000000
"
	create_frame $FUNCTION 1920 1080 uncompressed u "2000000
"
	create_frame $FUNCTION 640 480 mjpeg m "333333
416667
500000
666666
1000000
1333333
2000000
"
	create_frame $FUNCTION 1280 720 mjpeg m "333333
416667
500000
666666
1000000
1333333
2000000
"
	create_frame $FUNCTION 1920 1080 mjpeg m "333333
416667
500000
666666
1000000
1333333
2000000
"

	mkdir functions/$FUNCTION/streaming/header/h
	cd functions/$FUNCTION/streaming/header/h
	ln -s ../../uncompressed/u
	ln -s ../../mjpeg/m
	cd ../../class/fs
	ln -s ../../header/h
	cd ../../class/hs
	ln -s ../../header/h
	cd ../../class/ss
	ln -s ../../header/h
	cd ../../../control
	mkdir header/h
	ln -s header/h class/fs
	ln -s header/h class/ss
	cd ../../../

	# This configures the USB endpoint to allow 3x 1024 byte packets per
	# microframe, which gives us the maximum speed for USB 2.0. Other
	# valid values are 1024 and 2048, but these will result in a lower
	# supportable framerate.
	echo 1024 > functions/$FUNCTION/streaming_maxpacket

	ln -s functions/$FUNCTION configs/c.1
}

# Create configuration
echo "Creating config: c.1"
mkdir configs/c.1			# MaxPower, bmAttributes, strings

# Create english string for configuration
echo "Setting English strings"
mkdir -p configs/c.1/strings/0x409
CON_STR="UVC_UAC"
echo $CON_STR > configs/c.1/strings/0x409/configuration

# Create UVC functions --> UVC for video USB video class
echo "Creating UVC functions..."
VIDEO="uvc.usb0"
create_uvc configs/c.1 $VIDEO

echo "uvc.usb0 functions OK"

cd $GADGET/g1

# Create UAC1 functions --> UAC1 for (USB audio class 1) may need to use UAC2 instead
echo "Creating UAC2 functions..."
AUDIO="uac2.usb0"
mkdir functions/$AUDIO			# c_chmask, c_srate, c_ssize, p_chmask, p_srate, p_ssize, req_number
echo "uac2.usb0 functions OK"

echo $AUDIO_CHANNEL_MASK_CAPTURE > functions/uac2.usb0/c_chmask
echo $AUDIO_SAMPLE_RATES_CAPTURE > functions/uac2.usb0/c_srate
echo $AUDIO_SAMPLE_SIZE_CAPTURE > functions/uac2.usb0/c_ssize
echo $AUDIO_CHANNEL_MASK_PLAYBACK > functions/uac2.usb0/p_chmask
echo $AUDIO_SAMPLE_RATES_PLAYBACK > functions/uac2.usb0/p_srate
echo $AUDIO_SAMPLE_SIZE_PLAYBACK > functions/uac2.usb0/p_ssize

# Assigning configuration to functions
echo "Linking c.1 to audio function uac2.usb0..."
ln -s functions/$AUDIO configs/c.1/

echo "Binding USB Device Controller..."
echo $UDC > UDC
echo "Bounded to udc : $UDC"

#uvc-gadget -c 0 uvc.usb0

# Add resolutions
#mkdir -p functions/$FUNCTION/streaming/uncompressed/u/360p

# ls functions/uvc.0/streaming/
# class  color_matching  header  mjpeg  uncompressed

# ls functions/uvc.0/streaming/uncompressed/u/
# 360p  bAspectRatioX  bAspectRatioY  bBitsPerPixel  bDefaultFrameIndex  bmInterfaceFlags  bmaControls  guidForma

#ls functions/uvc.0/streaming/uncompressed/u/360p/
# bmCapabilities dwDefaultFrameInterval	dwFrameInterval  dwMaxBitRate  dwMaxVideoFrameBufferS
