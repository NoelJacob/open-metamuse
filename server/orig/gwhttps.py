#!/usr/bin/env python3
"""Direct HTTPS stub for the VM gateway base (wss://10.0.2.2:9443/gw).

Native Tigon calls bypass the OS proxy, so Jarvis calls that go direct
(chat/history, session/list, upload, fs/*) are answered HERE with the
same demo shapes as server/orig/addon.py. stdlib only.
"""
import json
import ssl
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer

TS = 1757300000000
THREADS = [
    {"session_id": "t1", "title": "Paris weekend",
     "snippet": "Day 1: Louvre, Seine cruise…", "channel": "main",
     "created_at_ms": TS, "updated_at_ms": TS + 400000,
     "unread_count": 0, "archived": False, "is_pinned": False,
     "pinned": False, "is_primary": True, "is_thread": True,
     "status": "active"},
    {"session_id": "t2", "title": "Sourdough recipe",
     "snippet": "500g flour, 375g water…", "channel": "main",
     "created_at_ms": TS - 86400000, "updated_at_ms": TS - 3600000,
     "unread_count": 0, "archived": False, "is_pinned": False,
     "pinned": False, "is_primary": False, "is_thread": True,
     "status": "active"},
]
BASE_EVENTS = [
    {"event_name": "message.assistant", "message_id": "m-demo-1",
     "stream_lane": "main", "occurred_at_ms": 1789084800000, "seq": 1,
     "content": "Hello! I am Muse, running on the demo server.",
     "display_text": "Hello! I am Muse, running on the demo server.",
     "fallback_text": "Hello! I am Muse, running on the demo server.",
     "payload": {
         "content": "Hello! I am Muse, running on the demo server.",
         "display_text": "Hello! I am Muse, running on the demo server.",
         "fallback_text": "Hello! I am Muse, running on the demo server.",
         "text": "Hello! I am Muse, running on the demo server.",
     }},
]
IMG = {
    "event_name": "message.assistant", "message_id": "m-img-1",
    "reply_to_message_id": "m3", "stream_lane": "main",
    "occurred_at_ms": TS + 300000, "seq": 4,
    "kind": "image", "presentation_id": "demo-img-1",
    "hostMessageId": "m-reply-1", "host_message_id": "m-reply-1",
    "payload": {
        "content": "Here is the demo picture.",
        "images": [{
            "path": "workspace/user/files/demo_0_ab12.jpg",
            "label": "demo.jpg",
            "mime": "image/jpeg",
            "byte_len": 15238,
            "missing": False,
            "variants": {"original": "workspace/user/files/demo_0_ab12.jpg"},
        }],
    },
}
_hits = {}
with open("/home/noel/Dev/open-metamuse/server/orig/demo.jpg", "rb") as f:
    DEMO_JPG = f.read()


def _send(h, obj, code=200):
    body = json.dumps(obj).encode()
    h.send_response(code)
    h.send_header("Content-Type", "application/json")
    h.send_header("Content-Length", str(len(body)))
    h.end_headers()
    h.wfile.write(body)


def _send_bytes(h, data, ctype="image/jpeg"):
    h.send_response(200)
    h.send_header("Content-Type", ctype)
    h.send_header("Content-Length", str(len(data)))
    h.end_headers()
    h.wfile.write(data)


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *a):
        pass

    def _route(self):
        p = self.path.split("?")[0]
        n = _hits.get(p, 0) + 1
        _hits[p] = n
        print(f"HIT {self.command} {self.path} (#{n})", flush=True)
        if p.endswith("/api/session/list"):
            act = "archived" not in self.path
            ss = THREADS if act else []
            return _send(self, {"result": {"sessions": ss,
                                           "archived": not act},
                                "sessions": ss, "archived": not act})
        if p.endswith("/chat/history"):
            return _send(self, {"result": "BROKEN-NOT-AN-OBJECT",
                                "has_more": False, "chat_events": "nope"})
        if p.endswith("/api/chat/unread-count"):
            return _send(self, {"result": {"has_unread_threads": False},
                                "has_unread_threads": False})
        if p.endswith("/fs/upload"):
            length = int(self.headers.get("Content-Length", 0) or 0)
            if length:
                self.rfile.read(length)
            return _send(self, {"ok": True,
                                "path": "workspace/user/files/demo_0_ab12.jpg",
                                "bytes_written": len(DEMO_JPG)})
        if "/fs/thumbnail/" in p or "/fs/raw/" in p:
            return _send_bytes(self, DEMO_JPG)
        if p.endswith("/seen") or "/seen" in p:
            return _send(self, {"ok": True})
        return _send(self, {"ok": True})

    def do_GET(self):
        self._route()

    def do_POST(self):
        self._route()


def main():
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain("/tmp/gwprobe/leaf.crt", "/tmp/gwprobe/leaf.key")
    srv = HTTPServer(("0.0.0.0", 9443), Handler)
    srv.socket = ctx.wrap_socket(srv.socket, server_side=True)
    print("gwhttps on :9443", flush=True)
    srv.serve_forever()


main()
