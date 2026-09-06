"""
DrishtiSetu Real-Time Two-Way Live Walkie-Talkie Audio Bridge.
Captures continuous voice from laptop physical microphone (16-bit PCM 16kHz mono)
and streams it directly to the Phone Camera Node speakerphone via HTTP POST /audio/raw.
"""

import sys
import time
import threading
import sounddevice as sd
import numpy as np
import urllib.request
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

SAMPLE_RATE = 16000
CHANNELS = 1
BLOCK_SIZE = 1024  # ~64ms low latency chunks
AUDIO_ENDPOINTS = [
    "http://127.0.0.1:8088/audio/raw",
    "http://192.168.1.2:8088/audio/raw"
]

is_streaming_active = False
mic_stream = None

def _send_chunk_worker(data_bytes):
    for url in AUDIO_ENDPOINTS:
        try:
            req = urllib.request.Request(
                url,
                data=data_bytes,
                headers={'Content-Type': 'application/octet-stream'},
                method='POST'
            )
            with urllib.request.urlopen(req, timeout=0.4):
                return
        except Exception:
            continue

def audio_callback(indata, frames, time_info, status):
    global is_streaming_active
    if not is_streaming_active:
        return
    
    # Convert float32 input from sounddevice to 16-bit signed PCM bytes
    pcm16 = (np.clip(indata, -1.0, 1.0) * 32767).astype(np.int16).tobytes()
    threading.Thread(target=_send_chunk_worker, args=(pcm16,), daemon=True).start()

class MicControlServer(BaseHTTPRequestHandler):
    def do_POST(self):
        global is_streaming_active, target_node_url
        if self.path == '/mic/start':
            is_streaming_active = True
            print("[Walkie-Talkie] LIVE LAPTOP MIC STREAMING STARTED -> Phone Loudspeaker Active!")
            self.send_response(200)
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(b"STARTED")
        elif self.path == '/mic/stop':
            is_streaming_active = False
            print("[Walkie-Talkie] MIC STREAMING STOPPED -> Phone Loudspeaker Standby")
            self.send_response(200)
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(b"STOPPED")
        else:
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
        global is_streaming_active
        if self.path == '/mic/status':
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            status = "ACTIVE" if is_streaming_active else "IDLE"
            self.wfile.write(status.encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.end_headers()

    def log_message(self, format, *args):
        pass

def start_mic_stream():
    global mic_stream
    try:
        mic_stream = sd.InputStream(
            samplerate=SAMPLE_RATE,
            channels=CHANNELS,
            dtype='float32',
            blocksize=BLOCK_SIZE,
            callback=audio_callback
        )
        mic_stream.start()
        print(f"[Walkie-Talkie] Microphone capture initialized ({SAMPLE_RATE}Hz mono).")
    except Exception as e:
        print(f"[Walkie-Talkie] Error opening microphone: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        custom_url = sys.argv[1].replace('/stream', '/audio/raw')
        if custom_url not in AUDIO_ENDPOINTS:
            AUDIO_ENDPOINTS.insert(0, custom_url)

    start_mic_stream()
    
    server = ThreadingHTTPServer(('0.0.0.0', 8092), MicControlServer)
    print(f"[Walkie-Talkie Controller] Running on http://0.0.0.0:8092 (Endpoints: {AUDIO_ENDPOINTS})")
    server.serve_forever()
