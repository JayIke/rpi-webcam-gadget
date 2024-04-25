from gpiozero import Button, LED
from time import sleep
import subprocess
import os
import signal
import psutil

# sudo apt install python3-psutil

# Name of processes to kill later
UVCPROC = "uvc-gadget"
OTHERPROC = "cam2.py"

button1 = Button(6)  # GPIO.BOARD pin 31
led1 = LED(5)        # GPIO.BOARD pin 29

# Function to handle USB camera via subprocess
def USBcamera():
    # run the configFS script including line --> uvc-gadget -c 0 uvc.0
    subprocess.run(["/bin/bash", "/home/jordin/.original.sh"])
    
def Ninacamera():
    # Run nina's code
    subprocess.run(["~/cam2.py"])

# Pass the proc you're trying to kill
def SearchAndDestroy(CURRENT):
    for proc in psutil.process_iter():
    #check whether the process name matches
        if proc.name() == CURRENT:
            proc.kill()


def handle_button1():
    led1.toggle()
    if led1.is_lit:
        print("LED ON")
        USBcamera()  # Assuming you want to run this when the LED turns on
    else:
        print("LED OFF")

button1.when_pressed = handle_button1

# This loop keeps the script running to manage the callbacks
while True:
    sleep(1)
