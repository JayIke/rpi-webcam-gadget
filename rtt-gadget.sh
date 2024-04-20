#!/bin/bash

######################################################################
# Author: Jordin Eicher
# File: ~/.rtt-gadget.sh
# Description: Configure as UVC device with audio subclass (UAC2)
#              using the IAD class (Interface Association Descriptor)
######################################################################

######################################################################
# 1) Define directory paths for ConfigFS
######################################################################



CONFIGFS="/sys/kernel/config"       # base
GADGET="$CONFIGFS/usb_gadget"       # gadget

UDC=`ls /sys/class/udc`             # 3f980000.usb (ep0 - control reqs)

######################################################################
# 2) Define strings/descriptors 
######################################################################

# Strings
VENDOR_ID="0x0525"                     # idProduct = RTT
PRODUCT_ID="0xa4a2"                 # idProduct = 0x0728 / 0x0104 multi-function / 0xa4a2 try 
SERIAL="31942399"                   # serial
MANUF="Runtime Terror"              # id
PRODUCT="RTT Webcam"                # idProduct = RTT Webcam

# Device Descriptor
BLENGTH=0x12
BCD_USB=0x0200		                # USB2.0
BCD_DEVICE=0x0100	                # v.1.0.0

## Assign specific values to class, sub, and prototype to enable IAD mode: 
BDEVCLASS=0xEF                      ## Miscellaneous (Composite)
BDEVSUBCLASS=0x02                   ## Multiple interfaces or CDC
BDEVPROTOCOL=0x01                   ## 0x01 = (Interface Association Descriptor - IAD)

BMAXPACKETSIZE=0x40                 # bMaxPacketSize0 = 0x40 (64)
BDESCTYPE=0x01                      # 0x01 = (DEVICE descriptor)
NUMCONF=0x01                        # using only 1 config

IPRODUCT=0x02                       # 2 products vid/audio
IMANUF=0x01                         # RTT

# Configuration Descriptor
CONF_BLENGTH=0x09                  
CONF_DESCTYPE=0x02                  # 0x02 = (CONFIGURATION descriptor)
CONF_VAL=0x01                       # uvc/uac under same config
I_CONF=0x01                         # 0x01 = specifying USB device > USB 1.1
CONF_ATTRIB=0x80                    # 0x81 = self-powered, 0x80 = not self-powered
CONF_NUM_INTERFACES=0x04            # 2 interfaces each for vid/audio
CONF_MAXPOWER=0x19                  # 0xFA = 250 = 2.50W = 500mA / 0x19 = 50mA

# Interface Assoication Descriptor (IAD)
IAD_BLENGTH=0x08
IAD_DESC_TYPE=0x0B                   # 0x0A = USB comm. device, 0x0B = wireless comm. dev class
IAD_FIRST_INT=0x00
IAD_INT_COUNT=0x02                   # num of interfaces in interface collection
IAD_FUNCT_CLASS=0x0E                 # video: bFunctionClass --match-- bInterfaceClass
IAD_FUNCT_SUBCLASS=0x03              # 2 + 1 ? audio: bFunctionClass --match-- bInterfaceClass

BFUNCTCLASS=0x0E                     # Video
BFUNCTSUBCLASS=0x03                  # idk
BFUNCTPROTOCOL=0x00                  #
IFUNCT=0x04                          # 

# Video Control Interface Descriptor
VC_BLENGTH=0x09                         
VC_DESCTYPE=0x04
VC_INT_NUM=0x00
VC_ALT_SET=0x00
VC_NUM_EP=0x01
VC_INT_CLASS=0x0E                      # Video class
VC_INT_SUBCLASS=0x01                   # Audio class
VC_INT_PROTOCOL=0x00         
VC_INT=0x05

# Video Control Endpoint Descriptor
VEP_BLENGTH=0x07
#TBC

# Audio
AUDIO_CHANNEL_MASK_CAPTURE=0		# 1=Left 2=Right 3=Stereo 0=disables the device
AUDIO_CHANNEL_MASK_PLAYBACK=3
AUDIO_SAMPLE_RATES_CAPTURE=48000
AUDIO_SAMPLE_RATES_PLAYBACK=48000
AUDIO_SAMPLE_SIZE_CAPTURE=4		# 1 for S8LE / 2 for S16LE / 3 for S24LE / 4 for S32LE
AUDIO_SAMPLE_SIZE_PLAYBACK=4

###################################################################### 
# Functions - class descriptors
######################################################################
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
	echo "333333" > $wdir/dwDefaultFrameInterval

	# has to be writable for future changes, hence the format
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
	mkdir -p functions/$FUNCTION
	# Interface association descriptor
	#mkdir functions/$FUNCTION/interface.0
	#mkdir functions/$FUNCTION/interface.1


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
	create_frame $FUNCTION 1920 1080 uncompressed u "2000000"
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
	#ln -s header/h class/hs
	#ln -s header/h class/ss
	cd ../../../

	# This configures the USB endpoint to allow 3x 1024 byte packets per
	# microframe, which gives us the maximum speed for USB 2.0. Other
	# valid values are 1024 and 2048, but these will result in a lower
	# supportable framerate.
	echo 2048 > functions/$FUNCTION/streaming_maxpacket
	#echo 2048 > functions/$FUNCTION/streaming_maxpacket
	#echo 1024 > functions/$FUNCTION/streaming_maxpacket
	ln -s functions/$FUNCTION configs/c.1
}

delete_uvc() {
	# Example usage:
	#	delete_uvc <target config> <function name>
	#	delete_uvc config/c.1 uvc.0
	CONFIG=$1
	FUNCTION=$2
	SUB="UAC2"
	echo "	Deleting UVC gadget functionality : $FUNCTION"
	rm $CONFIG/$FUNCTION
	#rm $CONFIG/$SUB

	rm functions/$FUNCTION/control/class/*/h
	rm functions/$FUNCTION/streaming/class/*/h
	rm functions/$FUNCTION/streaming/header/h/u
	rmdir functions/$FUNCTION/streaming/uncompressed/u/*/
	rmdir functions/$FUNCTION/streaming/uncompressed/u
	rm -rf functions/$FUNCTION/streaming/mjpeg/m/*/
	rm -rf functions/$FUNCTION/streaming/mjpeg/m
	rmdir functions/$FUNCTION/streaming/header/h
	rmdir functions/$FUNCTION/control/header/h
	rmdir functions/$FUNCTION

	#rm -rf functions/$SUB
}


######################################################################
# The Juice
######################################################################
#echo "Loading composite module"
#modprobe libcomposite
modprobe i2s-driver

cd $CONFIGFS
mkdir -p $GADGET/g1
cd $GADGET/g1

mkdir -p strings/0x409
echo $SERIAL > strings/0x409/serialnumber
echo $MANUF > strings/0x409/manufacturer
echo $PRODUCT > strings/0x409/product


# Device Descriptor Class directory
echo $VENDOR_ID > idVendor
echo $PRODUCT_ID > idProduct
echo $BCD_DEVICE > bcdDevice
echo $BCD_USB > bcdUSB
echo $BDESCTYPE > bDescriptorType
echo $BDEVCLASS > bDeviceClass
echo $BDEVSUBCLASS > bDeviceSubclass
echo $BMAXPACKETSIZE > bMaxPacketSize0
echo $BDEVPROTOCOL > bDeviceProtocol
echo $IMANUF > iManufacturer
echo $IPRODUCT > iProduct
echo $SERIAL > iSerialNumber
echo $NUMCONF > bNumConfigurations
echo $BLENGTH > bLength



# ... jump to functions for symbolic-linking and file writes
echo "Creating config: c.1"
mkdir -p configs/c.1			# MaxPower, bmAttributes, strings
# Create english string for configuration
echo "Setting English strings"
mkdir -p configs/c.1/strings/0x409

echo "Creating UVC functions..."
VIDEO="uvc.0"
create_uvc configs/c.1 $VIDEO
echo "uvc.0 functions OK"
cd $GADGET/g1
# Create UAC1 functions --> UAC1 for (USB audio class 1) may need to use UAC2 instead
#echo "Creating UAC2 functions..."
#AUDIO="uac2.0"
mkdir -p functions/$AUDIO			# c_chmask, c_srate, c_ssize, p_chmask, p_srate, p_ssize, req_number
echo "uac2. functions OK"
echo $AUDIO_CHANNEL_MASK_CAPTURE > functions/uac2.0/c_chmask
echo $AUDIO_SAMPLE_RATES_CAPTURE > functions/uac2.0/c_srate
echo $AUDIO_SAMPLE_SIZE_CAPTURE > functions/uac2.0/c_ssize
echo $AUDIO_CHANNEL_MASK_PLAYBACK > functions/uac2.0/p_chmask
echo $AUDIO_SAMPLE_RATES_PLAYBACK > functions/uac2.0/p_srate
echo $AUDIO_SAMPLE_SIZE_PLAYBACK > functions/uac2.0/p_ssize
# Assigning configuration to functions
echo "Linking c.1 to audio function uac2.0..."
ln -s functions/$AUDIO configs/c.1
echo "Binding USB Device Controller..."
echo $UDC > UDC
echo "Bounded to udc : $UDC"