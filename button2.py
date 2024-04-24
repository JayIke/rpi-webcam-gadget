from gpiozero import Button, LED
from time import sleep
import subprocess
from picamera2 import Picamera2

# Set up the button and LED pins using gpiozero
button1 = Button(4)   # GPIO.BOARD pin 7
led1 = LED(27)        # GPIO.BOARD pin 13

button2 = Button(22)  # GPIO.BOARD pin 15
led2 = LED(23)        # GPIO.BOARD pin 16

button3 = Button(6)  # GPIO.BOARD pin 31
led3 = LED(5)        # GPIO.BOARD pin 29

# Function to handle USB camera via subprocess
def USBcamera():
    subprocess.run(["/bin/bash", "/home/addieschroeder/.rpi-uvc-gadget.sh"])

# Function to handle camera using libcamera
def libcam():
    subprocess.run(['libcamera-hello'])

# Initialize Picamera2
camera = Picamera2()

def handle_button1():
    led1.toggle()
    if led1.is_lit:
        print("LED ON")
        USBcamera()  # Assuming you want to run this when the LED turns on
    else:
        print("LED OFF")

def handle_button2():
    led2.toggle()
    if led2.is_lit:
        print("LED ON")
        libcam()  # Assuming you want to run this when the LED turns on
    else:
        print("LED OFF")

def handle_button3():
    led3.toggle()
    if led3.is_lit:
        print("LED ON")
        # Add any specific operations when button 3 is pressed and LED is on
    else:
        print("LED OFF")

button1.when_pressed = handle_button1
button2.when_pressed = handle_button2
button3.when_pressed = handle_button3

# This loop keeps the script running to manage the callbacks
while True:
    sleep(1)
