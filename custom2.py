import io
import logging
import socketserver
from http import server
from threading import Condition
import cv2
from picamera2 import Picamera2, Preview, MappedArray
from picamera2.encoders import MJPEGEncoder
from picamera2.outputs import FileOutput
import time

## custom2.py --> process lowres stream then draw to main

# Load the face detector
face_detector = cv2.CascadeClassifier("/usr/share/opencv4/haarcascades/haarcascade_frontalface_default.xml")

last_detection_time = 0
detection_interval = 1.0  # Time interval in seconds
last_faces = []

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
    with MappedArray(request, "lores") as lores_map, MappedArray(request, "main") as main_map:
        if current_time - last_detection_time > detection_interval:
            last_detection_time = current_time
            y_plane = lores_map.array[:, :, 0]  # YUV's Y plane for grey scale image
            last_faces = face_detector.detectMultiScale(y_plane, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30))

        scale_x = main_map.array.shape[1] / lores_map.array.shape[1]
        scale_y = main_map.array.shape[0] / lores_map.array.shape[0]

        for (x, y, w, h) in last_faces:
            x_main, y_main, w_main, h_main = int(x * scale_x), int(y * scale_y), int(w * scale_x), int(h * scale_y)
            cv2.rectangle(main_map.array, (x_main, y_main), (x_main + w_main, y_main + h_main), (0, 255, 0), 2)

picam2 = Picamera2()
config = picam2.create_video_configuration(
    main={"size": (640, 480), "format": "RGB888"},
    lores={"size": (320, 240), "format": "YUV420"}
)
#config = picam2.create_preview_configuration(main={"size": (640, 480)})
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
