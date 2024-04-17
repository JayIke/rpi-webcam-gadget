import RPi.GPIO as GPIO
import subprocess
from time import sleep
#from picamera import PiCamera

#camera = PiCamera()

# Use Broadcom SOC channel numbering for the pins
GPIO.setmode(GPIO.BOARD)

# Pin numbers
button_pin1 = 7
led_pin1 = 13

button_pin2 = 15
led_pin2 = 16

button_pin3 = 31
led_pin3 = 29

# Set up the button and LED pins
GPIO.setup(button_pin1, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.setup(led_pin1, GPIO.OUT)

GPIO.setup(button_pin2, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.setup(led_pin2, GPIO.OUT)

GPIO.setup(button_pin3, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.setup(led_pin3, GPIO.OUT)

def USBcamera():
	subprocess.run(["/bin/bash", ".rpi-uvc-gadget.sh"])

def libcam():
	subprocess.run(['libcamera-hello'])

# Keeps track of button state
button_state = False

while(1):
	if GPIO.input(button_pin1)==0:  # Button is pressed)
		if button_state == False:
			print("LED ON")
			GPIO.output(led_pin1, True)
			button_state = True
			USBcamera()
		#	camera.start_preview()
		#	sleep(10)
		#	camera.stop_preview()
		#	camera.close()
		else:
			print("LED OFF")
			GPIO.output(led_pin1, False)
			button_state = False
		sleep(.5)
	if GPIO.input(button_pin2)==0:  # Button is pressed)
                if button_state == False:
                        print("LED ON")
                        GPIO.output(led_pin2, True)
                        button_state = True
                        libcam()
                else:
                        print("LED OFF")
                        GPIO.output(led_pin2, False)
                        button_state = False
                sleep(.5)
	if GPIO.input(button_pin3)==0:  # Button is pressed)
                if button_state == False:
                        print("LED ON")
                        GPIO.output(led_pin3, True)
                        button_state = True
                else:
                        print("LED OFF")
                        GPIO.output(led_pin3, False)
                        button_state = False
                sleep(.5)
GPIO.cleanup()
