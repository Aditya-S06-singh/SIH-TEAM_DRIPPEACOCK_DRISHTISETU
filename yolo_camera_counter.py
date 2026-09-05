import cv2
import numpy as np
from ultralytics import YOLO
import cvzone
import time
import csv
import os
import urllib.request
import json
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler
from datetime import datetime

CSV_FILE = "people_count.csv"

# Global streaming state for Live Inspection Portal
latest_annotated_jpeg = None
frame_lock = threading.Lock()

class AnnotatedStreamHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        global latest_annotated_jpeg
        if self.path == '/stream':
            self.send_response(200)
            self.send_header('Content-Type', 'multipart/x-mixed-replace; boundary=boundary')
            self.send_header('Cache-Control', 'no-cache, private')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()

            while True:
                try:
                    with frame_lock:
                        frame_bytes = latest_annotated_jpeg
                    if frame_bytes is not None:
                        header = f"--boundary\r\nContent-Type: image/jpeg\r\nContent-Length: {len(frame_bytes)}\r\n\r\n".encode('utf-8')
                        self.wfile.write(header)
                        self.wfile.write(frame_bytes)
                        self.wfile.write(b"\r\n")
                    time.sleep(0.04)
                except Exception:
                    break
        elif self.path == '/snapshot':
            with frame_lock:
                frame_bytes = latest_annotated_jpeg
            if frame_bytes is not None:
                self.send_response(200)
                self.send_header('Content-Type', 'image/jpeg')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(frame_bytes)
            else:
                self.send_response(503)
                self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass  # Suppress HTTP access logging

def run_annotated_stream_server(port=8089):
    try:
        server = HTTPServer(('0.0.0.0', port), AnnotatedStreamHandler)
        print(f"[YOLO Stream Server] Serving annotated live feed on http://0.0.0.0:{port}/stream")
        server.serve_forever()
    except Exception as e:
        print(f"[YOLO Stream Server] Error starting on port {port}: {e}")

# Start stream server in daemon thread
stream_thread = threading.Thread(target=run_annotated_stream_server, daemon=True)
stream_thread.start()

if not os.path.exists(CSV_FILE):
    with open(CSV_FILE, mode='w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(["Timestamp", "People_Count"])

def log_count_to_csv(people_count):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(CSV_FILE, mode='a', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow([timestamp, people_count])
    print(f"[{timestamp}] Saved to CSV -> People Count: {people_count}")

# Appwrite Cloud Config for Live Sync to DrishtiSetu Dashboard
APPWRITE_ENDPOINT = "https://sgp.cloud.appwrite.io/v1"
PROJECT_ID = "6a9a6256001c52e05bcc"
DATABASE_ID = "drishtisetu_db"
COLLECTION_ID = "zones"
DOCUMENT_ID = "6a9bd5200029250fea89"

last_appwrite_sync = 0
gate_expected_count = 23  # Synced gate turnstile baseline

def sync_to_appwrite(headcount):
    global last_appwrite_sync
    curr = time.time()
    # Sync every 2 seconds
    if curr - last_appwrite_sync < 2.0:
        return
    last_appwrite_sync = curr

    discrepancy = gate_expected_count - headcount
    severity = "critical" if discrepancy > 5 else ("warning" if discrepancy > 0 else "normal")

    url = f"{APPWRITE_ENDPOINT}/databases/{DATABASE_ID}/collections/{COLLECTION_ID}/documents/{DOCUMENT_ID}"
    data = json.dumps({
        "data": {
            "detectedCount": headcount,
            "expectedCount": gate_expected_count,
            "discrepancy": discrepancy,
            "severity": severity,
            "isCameraOnline": True,
            "lastAuditTimestamp": datetime.now().isoformat()
        }
    }).encode("utf-8")

    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "X-Appwrite-Project": PROJECT_ID,
            "Content-Type": "application/json"
        },
        method="PATCH"
    )
    try:
        with urllib.request.urlopen(req, timeout=1.5) as response:
            pass
    except Exception:
        pass

def RGB(event, x, y, flags, param):
    if event == cv2.EVENT_MOUSEMOVE:
        point = [x, y]
        # print(point)

cv2.namedWindow('DrishtiSetu YOLO11n Camera Feed')
cv2.setMouseCallback('DrishtiSetu YOLO11n Camera Feed', RGB)

# Using yolo11n for fast inference
print("Loading YOLO11n model...")
model = YOLO("yolo11n.pt")
names = model.names

import sys

# Support wireless phone camera stream URL via command-line argument or environment variable:
# e.g.: python yolo_camera_counter.py http://192.168.43.1:8088/stream
source = "0"
if len(sys.argv) > 1 and sys.argv[1].strip():
    source = sys.argv[1].strip()
elif os.environ.get("PHONE_STREAM_URL"):
    source = os.environ.get("PHONE_STREAM_URL").strip()

if source.isdigit():
    source = int(source)
    print(f"Connecting to local Camera Source ({source})...")
    cap = cv2.VideoCapture(source, cv2.CAP_DSHOW)
    if not cap.isOpened():
        cap = cv2.VideoCapture(source)
else:
    print(f"Connecting to Wireless Phone Camera: {source} ...")
    cap = cv2.VideoCapture(source)

if not cap.isOpened():
    print(f"Could not connect to {source}. Falling back to default webcam (0)...")
    cap = cv2.VideoCapture(0)

SAVE_INTERVAL = 600
last_save_time = time.time()

# FPS and performance settings
SKIP_FRAMES = 2       # Run YOLO every 3rd frame (massive FPS boost)
frame_idx = 0
prev_time = time.time()
fps = 0
cached_boxes = []     # Store detections between skipped frames
people_count = 0

is_http_source = str(source).startswith("http")
snapshot_url = str(source).replace("/stream", "/snapshot") if is_http_source else None

print("Camera feed active. Press 'q' in the camera window to exit.")

while True:
    frame = None
    if is_http_source:
        try:
            req = urllib.request.Request(snapshot_url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=1.0) as resp:
                img_array = np.asarray(bytearray(resp.read()), dtype=np.uint8)
                frame = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
        except Exception:
            pass

    if frame is None and cap is not None:
        ret, frame = cap.read()

    if frame is None:
        time.sleep(0.05)
        continue

    frame_idx += 1

    # Resize input frame to standard (1020, 600)
    frame = cv2.resize(frame, (1020, 600))

    # Track only persons (COCO class 0)
    results = model.track(frame, persist=True, classes=[0], verbose=False)

    # Check if there are tracked boxes
    if results[0].boxes is not None and results[0].boxes.id is not None:
        boxes = results[0].boxes.xyxy.int().cpu().tolist()
        track_ids = results[0].boxes.id.int().cpu().tolist()
        people_count = len(boxes)

        for box, track_id in zip(boxes, track_ids):
            x1, y1, x2, y2 = box
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 0, 255), 2)
            cvzone.putTextRect(frame, f'ID: {track_id}', (x1, max(30, y1)), 1, 1)
    else:
        people_count = 0

    sync_to_appwrite(people_count)

    # Calculate actual display FPS
    curr_time = time.time()
    fps = int(1.0 / max(0.001, (curr_time - prev_time)))
    prev_time = curr_time

    # Periodic 10-minute CSV logging
    elapsed = curr_time - last_save_time
    time_left = max(0, int(SAVE_INTERVAL - elapsed))
    if elapsed >= SAVE_INTERVAL:
        log_count_to_csv(people_count)
        last_save_time = curr_time

    # Display HUD
    cvzone.putTextRect(frame, f'PEOPLE COUNT: {people_count}', (20, 40), scale=1.3, thickness=2, colorR=(0, 180, 0))
    cvzone.putTextRect(frame, f'FPS: {fps}', (20, 80), scale=1.0, thickness=1, colorR=(0, 100, 255))
    cvzone.putTextRect(frame, f'Next Save: {time_left // 60}m {time_left % 60}s', (20, 115), scale=0.8, thickness=1, colorR=(60, 60, 60))

    # Encode annotated frame with boxes & HUD for the Live Inspection Portal
    ret_enc, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
    if ret_enc:
        with frame_lock:
            latest_annotated_jpeg = buffer.tobytes()

    cv2.imshow("DrishtiSetu YOLO11n Camera Feed", frame)

    if cv2.waitKey(1) & 0xFF == ord("q"):
        break

cap.release()
cv2.destroyAllWindows()
