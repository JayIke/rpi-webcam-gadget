#!/usr/bin/python3

import socket
import time

from picamera2 import Picamera2
from picamera2.encoders import H264Encoder
from picamera2.outputs import FileOutput, FfmpegOutput



picam2 = Picamera2()
video_config = picam2.create_video_configuration({"size": (1280, 720)})
picam2.configure(video_config)
encoder = H264Encoder(1000000)
#output = FfmpegOutput("-f mpegts udp://192.168.0.185:10001")

with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
    sock.connect(('0.0.0.0', 8000))
    stream = sock.makefile("wb")
    picam2.start_recording(encoder, FileOutput(stream))
    time.sleep(20)
    picam2.stop_recording()
