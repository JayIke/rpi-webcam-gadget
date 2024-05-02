import io
import logging
import socketserver
from http import server
from threading import Condition
import cv2
from picamera2 import Picamera2, Preview, MappedArray
from picamera2.encoders import MJPEGEncoder
from picamera2.outputs import FileOutput

# Load the face detector
face_detector = cv2.CascadeClassifier("/usr/share/opencv4/haarcascades/haarcascade_frontalface_default.xml")
req_count = 0
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
                        #self.send_header('Content-Type', 'image/png')
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
    with MappedArray(request, "main") as m:
        # Downscale the image for faster detection
        scale_factor = 0.5
        small_frame = cv2.resize(m.array, (0, 0), fx=scale_factor, fy=scale_factor)
        grey = cv2.cvtColor(small_frame, cv2.COLOR_BGR2GRAY)
        faces = face_detector.detectMultiScale(grey, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30))

        # Scale back up face locations before drawing them
        for (x, y, w, h) in faces:
            x, y, w, h = [int(v / scale_factor) for v in (x, y, w, h)]
            cv2.rectangle(m.array, (x, y), (x + w, y + h), (0, 255, 0), 2)

picam2 = Picamera2()
config = picam2.create_preview_configuration(main={"size": (640, 480)})
#config = picam2.create_preview_configuration(main={"size": (640, 480)},lores={"size": (320, 240), "format": "YUV420"})
picam2.configure(config)

picam2.post_callback = draw_faces
output = StreamingOutput()
#encoder = H264Encoder()
encoder = MJPEGEncoder(quality=30)
picam2.start_recording(encoder, FileOutput(output))

try:
    address = ('', 8000)
    server = StreamingServer(address, StreamingHandler)
    server.serve_forever()
finally:
    picam2.stop_recording()
