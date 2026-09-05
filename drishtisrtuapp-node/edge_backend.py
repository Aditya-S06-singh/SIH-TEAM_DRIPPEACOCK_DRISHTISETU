"""
DrishtiSetu Edge Node AI Vision Engine
Runs continuous YOLO11n on live camera feed (webcam / external USB camera / IP camera).
Includes built-in HTTP server on port 8088 serving:
  - /stream   : Live MJPEG video stream with YOLO bounding boxes and telemetry HUD
  - /snapshot : Latest JPEG frame
  - /health   : JSON telemetry status
Syncs crowd detection to Appwrite Cloud in real time so the DrishtiSetu Sentinel Dashboard updates instantly.
"""

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

# Appwrite Cloud Config
APPWRITE_ENDPOINT = "https://sgp.cloud.appwrite.io/v1"
PROJECT_ID = "6a9a6256001c52e05bcc"
DATABASE_ID = "drishtisetu_db"
COLLECTION_ID = "zones"
DOCUMENT_ID = "6a9bd5200029250fea89"

CSV_FILE = "people_count.csv"
if not os.path.exists(CSV_FILE):
    with open(CSV_FILE, mode='w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(["Timestamp", "People_Count"])

# Global shared state
current_jpeg_frame = None
frame_lock = threading.Lock()
gate_expected_count = 23
detected_headcount = 0
last_appwrite_sync = 0
last_save_time = time.time()
SAVE_INTERVAL = 600

def log_count_to_csv(people_count):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(CSV_FILE, mode='a', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow([timestamp, people_count])
    print(f"[{timestamp}] Saved to CSV -> People Count: {people_count}")

def sync_to_appwrite(headcount):
    global last_appwrite_sync
    curr = time.time()
    if curr - last_appwrite_sync < 1.5:
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

class StreamServerHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        global current_jpeg_frame, gate_expected_count, detected_headcount
        if self.path == '/stream':
            self.send_response(200)
            self.send_header('Content-Type', 'multipart/x-mixed-replace; boundary=boundary')
            self.send_header('Cache-Control', 'no-cache, private')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()

            while True:
                try:
                    with frame_lock:
                        frame = current_jpeg_frame
                    if frame is not None:
                        header = f"--boundary\r\nContent-Type: image/jpeg\r\nContent-Length: {len(frame)}\r\n\r\n".encode('utf-8')
                        self.wfile.write(header)
                        self.wfile.write(frame)
                        self.wfile.write(b"\r\n")
                    time.sleep(0.05)
                except Exception:
                    break
        elif self.path == '/snapshot':
            with frame_lock:
                frame = current_jpeg_frame
            if frame is not None:
                self.send_response(200)
                self.send_header('Content-Type', 'image/jpeg')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(frame)
            else:
                self.send_response(503)
                self.end_headers()
        elif self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            data = json.dumps({
                "status": "online",
                "gate_count": gate_expected_count,
                "detected_headcount": detected_headcount,
                "deficit": gate_expected_count - detected_headcount,
                "anomaly": (gate_expected_count - detected_headcount) > 5
            }).encode('utf-8')
            self.wfile.write(data)
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass  # Suppress excessive HTTP log output

def run_http_server():
    server = HTTPServer(('0.0.0.0', 8088), StreamServerHandler)
    print("[Stream Server] Streaming on http://0.0.0.0:8088/stream")
    server.serve_forever()

def sync_camera_offline_to_appwrite():
    url = f"{APPWRITE_ENDPOINT}/databases/{DATABASE_ID}/collections/{COLLECTION_ID}/documents/{DOCUMENT_ID}"
    data = json.dumps({
        "data": {
            "detectedCount": 0,
            "expectedCount": gate_expected_count,
            "discrepancy": gate_expected_count,
            "severity": "critical",
            "isCameraOnline": False,
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
        with urllib.request.urlopen(req, timeout=2.0) as response:
            print("[Appwrite] Camera failure anomaly logged to Appwrite: isCameraOnline=False, severity=critical")
    except Exception as e:
        print(f"[Appwrite] Sync error: {e}")

def camera_yolo_loop():
    global current_jpeg_frame, detected_headcount, last_save_time
    print("[YOLO Worker] Loading YOLO11n model...")
    model = YOLO("yolo11n.pt")
    names = model.names

    # ONLY check phone camera streams (laptop webcam completely disabled as requested)
    phone_urls = [
        "http://127.0.0.1:8089/stream",
        "http://192.168.1.2:8088/stream",
        "http://192.168.1.2:8080/video"
    ]

    cap = None
    active_source = None
    for src in phone_urls:
        print(f"[YOLO Worker] Probing Phone Camera at {src} ...")
        test_cap = cv2.VideoCapture(src)
        if test_cap.isOpened():
            ret, test_frame = test_cap.read()
            if ret and test_frame is not None:
                cap = test_cap
                active_source = src
                print(f"[YOLO Worker] Successfully linked to Phone Camera: {src}")
                break
            else:
                test_cap.release()
        else:
            test_cap.release()

    if cap is None:
        print("\n=======================================================")
        print("  [ALERT] CAMERA NOT WORKING / DISCONNECTED")
        print("  Laptop webcam is disabled. Phone camera not detected.")
        print("  Logging critical anomaly: CAMERA_OFFLINE")
        print("=======================================================\n")
        sync_camera_offline_to_appwrite()

        # Render 'CAMERA NOT WORKING' placeholder frame for the stream
        placeholder = np.zeros((540, 960, 3), dtype=np.uint8)
        cv2.putText(placeholder, "CAMERA NOT WORKING", (180, 240), cv2.FONT_HERSHEY_SIMPLEX, 1.6, (0, 0, 255), 3)
        cv2.putText(placeholder, "Feed Offline / Signal Lost - Anomaly Logged", (200, 300), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (200, 200, 200), 2)
        ret_enc, buffer = cv2.imencode('.jpg', placeholder, [cv2.IMWRITE_JPEG_QUALITY, 80])
        if ret_enc:
            with frame_lock:
                current_jpeg_frame = buffer.tobytes()

        # Retry loop checking for phone reconnection while keeping anomaly state synced
        while True:
            for src in phone_urls:
                test_cap = cv2.VideoCapture(src)
                if test_cap.isOpened():
                    ret, test_frame = test_cap.read()
                    if ret and test_frame is not None:
                        cap = test_cap
                        active_source = src
                        print(f"[YOLO Worker] Phone Camera reconnected: {src}")
                        break
                    test_cap.release()
            if cap is not None:
                break
            sync_camera_offline_to_appwrite()
            time.sleep(3.0)

    SKIP_FRAMES = 2
    frame_idx = 0
    cached_boxes = []
    prev_time = time.time()

    print(f"[YOLO Worker] Phone Camera active ({active_source}). Live counting started...")

    while True:
        ret, frame = cap.read()
        if not ret:
            time.sleep(0.1)
            continue

        frame_idx += 1
        frame = cv2.resize(frame, (960, 540))

        if frame_idx % (SKIP_FRAMES + 1) == 0:
            results = model(frame, imgsz=640, conf=0.25, classes=[0], verbose=False)
            cached_boxes = []
            if results[0].boxes is not None and len(results[0].boxes) > 0:
                boxes = results[0].boxes.xyxy.int().cpu().tolist()
                class_ids = results[0].boxes.cls.int().cpu().tolist()
                confs = results[0].boxes.conf.cpu().tolist()

                for box, cls_id, conf in zip(boxes, class_ids, confs):
                    cached_boxes.append((box, cls_id, conf))

            detected_headcount = len(cached_boxes)
            sync_to_appwrite(detected_headcount)

        for box, cls_id, conf in cached_boxes:
            x1, y1, x2, y2 = box
            cls_name = names[cls_id]
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
            cvzone.putTextRect(
                frame,
                f'{cls_name} {int(conf * 100)}%',
                (x1, max(20, y1 - 5)),
                scale=0.6,
                thickness=1,
                colorR=(0, 200, 0)
            )

        curr_time = time.time()
        fps = int(1.0 / max(0.001, (curr_time - prev_time)))
        prev_time = curr_time

        if curr_time - last_save_time >= SAVE_INTERVAL:
            log_count_to_csv(detected_headcount)
            last_save_time = curr_time

        deficit = gate_expected_count - detected_headcount
        status_color = (0, 0, 255) if deficit > 5 else (0, 180, 0)

        cvzone.putTextRect(frame, f'HEADCOUNT: {detected_headcount}', (20, 40), scale=1.3, thickness=2, colorR=(0, 180, 0))
        cvzone.putTextRect(frame, f'GATE: {gate_expected_count} | DEFICIT: {deficit}', (20, 85), scale=1.0, thickness=2, colorR=status_color)
        cvzone.putTextRect(frame, f'FPS: {fps}', (20, 120), scale=0.8, thickness=1, colorR=(0, 100, 255))

        ret_enc, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 75])
        if ret_enc:
            with frame_lock:
                current_jpeg_frame = buffer.tobytes()

        # Local preview window (optional, press 'q' to close)
        cv2.imshow("DrishtiSetu Node - YOLO11n Camera Feed", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

        time.sleep(0.02)

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    # Start HTTP streaming server on background thread
    server_thread = threading.Thread(target=run_http_server, daemon=True)
    server_thread.start()

    # Run camera YOLO processing loop
    camera_yolo_loop()
