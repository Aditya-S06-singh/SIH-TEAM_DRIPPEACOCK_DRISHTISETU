import cv2
import numpy as np
from ultralytics import YOLO
import cvzone
import time
import csv
import os
import urllib.request
import json
from datetime import datetime

CSV_FILE = "people_count.csv"

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

# Initialize Camera (Index 0 is default webcam / camera)
CAMERA_SOURCE = 0
print(f"Connecting to Camera Source ({CAMERA_SOURCE})...")
cap = cv2.VideoCapture(CAMERA_SOURCE)

# Set camera resolution (optional optimization)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)

SAVE_INTERVAL = 600
last_save_time = time.time()

# FPS and performance settings
SKIP_FRAMES = 2       # Run YOLO every 3rd frame (massive FPS boost)
frame_idx = 0
prev_time = time.time()
fps = 0
cached_boxes = []     # Store detections between skipped frames
people_count = 0

print("Camera feed active. Press 'q' in the camera window to exit.")

while True:
    ret, frame = cap.read()
    if not ret:
        print("Failed to capture image from camera. Retrying...")
        time.sleep(0.5)
        continue

    frame_idx += 1

    # Resize input frame to standard 960 width for fast, smooth processing
    frame = cv2.resize(frame, (960, 540))

    # Only run YOLO every (SKIP_FRAMES + 1) frames
    if frame_idx % (SKIP_FRAMES + 1) == 0:
        results = model(frame, imgsz=640, conf=0.25, classes=[0], verbose=False)

        cached_boxes = []
        if results[0].boxes is not None and len(results[0].boxes) > 0:
            boxes = results[0].boxes.xyxy.int().cpu().tolist()
            class_ids = results[0].boxes.cls.int().cpu().tolist()
            confs = results[0].boxes.conf.cpu().tolist()

            for box, cls_id, conf in zip(boxes, class_ids, confs):
                cached_boxes.append((box, cls_id, conf))

        people_count = len(cached_boxes)
        # Sync headcount to DrishtiSetu Sentinel Appwrite Cloud
        sync_to_appwrite(people_count)

    # Draw cached boxes on every frame so video remains smooth
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

    cv2.imshow("DrishtiSetu YOLO11n Camera Feed", frame)

    if cv2.waitKey(1) & 0xFF == ord("q"):
        break

cap.release()
cv2.destroyAllWindows()
