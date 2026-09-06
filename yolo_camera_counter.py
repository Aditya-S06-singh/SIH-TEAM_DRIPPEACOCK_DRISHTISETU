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
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
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
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(b"No frame yet")
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass  # Suppress HTTP access logging

def run_annotated_stream_server(port=8089):
    try:
        server = ThreadingHTTPServer(('0.0.0.0', port), AnnotatedStreamHandler)
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

# Using yolo11n for fast inference
print("Loading YOLO11n model...")
model = YOLO("yolo11n.pt")
names = model.names

import sys

# Support wireless phone camera stream URL via command-line argument or environment variable:
source = "http://127.0.0.1:8088/snapshot"
if len(sys.argv) > 1 and sys.argv[1].strip():
    raw_arg = sys.argv[1].strip()
    source = raw_arg.replace('/stream', '/snapshot') if raw_arg.startswith('http') else raw_arg

SAVE_INTERVAL = 600
last_save_time = time.time()
frame_idx = 0
prev_time = time.time()
fps = 0
people_count = 0

print(f"[YOLO Engine Active] Fetching frames directly from: {source}")

cap = None
if source.isdigit():
    cap = cv2.VideoCapture(int(source))
elif not source.startswith('http'):
    cap = cv2.VideoCapture(source)

while True:
    frame = None
    if cap is not None:
        ret, frame = cap.read()
    else:
        try:
            req = urllib.request.Request(source, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=1.5) as resp:
                raw_data = resp.read()
                if raw_data:
                    img_array = np.asarray(bytearray(raw_data), dtype=np.uint8)
                    frame = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
        except Exception:
            pass

    if frame is None:
        time.sleep(0.15)
        continue

    frame_idx += 1

    # Resize input frame to standard (1020, 600)
    frame = cv2.resize(frame, (1020, 600))

    # Accurate & resilient Person Detection (COCO class 0)
    people_count = 0
    try:
        results = model.predict(frame, classes=[0], verbose=False, conf=0.35)
        if results and len(results) > 0 and results[0].boxes is not None and len(results[0].boxes) > 0:
            boxes = results[0].boxes.xyxy.int().cpu().tolist()
            confs = results[0].boxes.conf.cpu().tolist() if results[0].boxes.conf is not None else [0.0]*len(boxes)
            people_count = len(boxes)

            for idx, (box, conf) in enumerate(zip(boxes, confs), 1):
                x1, y1, x2, y2 = box
                cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 210, 255), 2)
                cvzone.putTextRect(frame, f'Person #{idx} ({int(conf*100)}%)', (x1, max(30, y1)), scale=0.9, thickness=1, colorR=(20, 20, 20))
    except Exception as e:
        print(f'[YOLO Error] {e}')

    sync_to_appwrite(people_count)

    # Calculate actual display FPS
    curr_time = time.time()
    fps = int(1.0 / max(0.001, (curr_time - prev_time)))
    prev_time = curr_time

    if frame_idx % 15 == 0:
        print(f"[YOLO Live] Headcount: {people_count} | FPS: {fps} | Synced to Appwrite & Stream :8089")

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

    time.sleep(0.03)
