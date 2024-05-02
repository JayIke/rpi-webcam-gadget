import io
import logging
import socketserver
from http import server
from threading import Condition
import cv2
import numpy as np
from picamera2 import Picamera2, Preview, MappedArray
from picamera2.encoders import MJPEGEncoder
from picamera2.outputs import FileOutput
import time

'''
File: blurred_stream.py
Description: Post-processed (blurred) MJPEG Streaming Server 
'''
# Globals: face_detector, last_detection_time, detection_interval, last_faces

# Load the opencv face detector
face_detector = cv2.CascadeClassifier("/usr/share/opencv4/haarcascades/haarcascade_frontalface_default.xml")

last_detection_time = 0
detection_interval = 0.8  # Run face detection every 800 ms
last_faces = []  # Store the last detected faces

# Web page to display the video stream
PAGE = """\
<html>
<head>
<title>PiCamera2 MJPEG Streaming Demo</title>
</head>
<body>
<h1>PiCamera2 MJPEG Streaming Demo</h1>
<img src="stream.mjpg" width="640" height="480" />
</body>
</html>
"""

class StreamingOutput(io.BufferedIOBase):
    def __init__(self):
        self.frame = None
        self.condition = Condition()

    def write(self, buf):
        with self.condition:
            self.frame = buf
            self.condition.notify_all()

class StreamingHandler(server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(301)
            self.send_header('Location', '/index.html')
            self.end_headers()
        elif self.path == '/index.html':
            content = PAGE.encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'text/html')
            self.send_header('Content-Length', len(content))
            self.end_headers()
            self.wfile.write(content)
        elif self.path == '/stream.mjpg':
            self.send_response(200)
            self.send_header('Content-Type', 'multipart/x-mixed-replace; boundary=FRAME')
            self.end_headers()
            try:
                while True:
                    with output.condition:
                        output.condition.wait()
                        frame = output.frame
                        self.wfile.write(b'--FRAME\r\n')
                        self.send_header('Content-Type', 'image/jpeg')
                        self.send_header('Content-Length', len(frame))
                        self.end_headers()
                        self.wfile.write(frame)
                        self.wfile.write(b'\r\n')
            except Exception as e:
                logging.warning('Removed streaming client %s: %s', self.client_address, str(e))
        else:
            self.send_error(404)
            self.end_headers()

class StreamingServer(socketserver.ThreadingMixIn, server.HTTPServer):
    allow_reuse_address = True
    daemon_threads = True

def draw_faces(request):
    global last_detection_time, last_faces
    current_time = time.time()
    with MappedArray(request, "main") as m:
        if current_time - last_detection_time > detection_interval:
            last_detection_time = current_time
            grey = cv2.cvtColor(m.array, cv2.COLOR_BGR2GRAY)
            last_faces = face_detector.detectMultiScale(grey, scaleFactor=1.1, minNeighbors=5, minSize=(60, 60))
        
        
        # Create a mask with the same dimensions as the frame, initialize to black
        mask = np.zeros_like(m.array, dtype=np.uint8)

        # For each detected face, fill the corresponding area in the mask with white
        for (x, y, w, h) in last_faces:
            cv2.rectangle(mask, (x, y), (x + w, y + h), (255, 255, 255, 0), thickness=cv2.FILLED)

        # Create a blurred version of the original frame
        blurred_frame = cv2.blur(m.array, (21, 21), 0)

        # Combine the blurred frame and the original frame using the mask
        # Only the areas with white in the mask will keep the original pixels
        final_frame = np.where(mask == np.array([255, 255, 255, 0]), m.array, blurred_frame)

        # Replace the array's contents with the final frame
        m.array[:] = final_frame

picam2 = Picamera2()
config = picam2.create_preview_configuration(main={"size": (640, 480)})
picam2.configure(config)
picam2.post_callback = draw_faces
output = StreamingOutput()

picam2.start_recording(MJPEGEncoder(), FileOutput(output))

try:
    address = ('', 8000)
    server = StreamingServer(address, StreamingHandler)
    server.serve_forever()
finally:
    picam2.stop_recording()
