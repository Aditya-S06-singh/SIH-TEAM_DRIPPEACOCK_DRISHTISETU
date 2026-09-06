from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import threading

rooms = {}

class SignalingHandler(BaseHTTPRequestHandler):
    def _send_cors_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')

    def do_OPTIONS(self):
        self.send_response(200)
        self._send_cors_headers()
        self.end_headers()

    def do_GET(self):
        # /poll?room=xxx&role=xxx
        from urllib.parse import urlparse, parse_qs
        parsed = urlparse(self.path)
        qs = parse_qs(parsed.query)
        room = qs.get('room', ['default'])[0]
        role = qs.get('role', [''])[0]

        room_data = rooms.setdefault(room, {
            'offer': None,
            'answer': None,
            'caller_ice': [],
            'callee_ice': [],
            'status': 'idle'
        })

        self.send_response(200)
        self._send_cors_headers()
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(room_data).encode('utf-8'))

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length)
        data = json.loads(body.decode('utf-8')) if body else {}

        room = data.get('room', 'default')
        action = data.get('action') # 'offer', 'answer', 'ice', 'reset'
        room_data = rooms.setdefault(room, {
            'offer': None,
            'answer': None,
            'caller_ice': [],
            'callee_ice': [],
            'status': 'idle'
        })

        if action == 'offer':
            room_data['offer'] = data.get('offer')
            room_data['status'] = 'ringing'
            room_data['caller_ice'] = []
            room_data['callee_ice'] = []
            room_data['answer'] = None
        elif action == 'answer':
            room_data['answer'] = data.get('answer')
            room_data['status'] = 'connected'
        elif action == 'ice':
            role = data.get('role')
            candidate = data.get('candidate')
            if role == 'caller':
                room_data['caller_ice'].append(candidate)
            else:
                room_data['callee_ice'].append(candidate)
        elif action == 'reset':
            rooms[room] = {
                'offer': None,
                'answer': None,
                'caller_ice': [],
                'callee_ice': [],
                'status': 'idle'
            }

        self.send_response(200)
        self._send_cors_headers()
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({'status': 'ok'}).encode('utf-8'))

    def log_message(self, format, *args):
        pass

server = HTTPServer(('0.0.0.0', 8090), SignalingHandler)
print('P2P Signaling Server running on port 8090...')
server.serve_forever()
