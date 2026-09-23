#!/usr/bin/env python3
"""Single backend for the Flutter clone: fixture HTTP on :8787.

Does for the Flutter app what `backend.py orig` mode does for the original:
one command serves everything the app needs. stdlib only.

Usage:
  python3 flutter-backend.py [port]   # default 8787

Data ownership (see also the header of backend.py): this file owns
everything under server/data/ today — threads.json, messages.json,
feed.json, connectors.json, profile.json, demo.jpg, paris-weekend.md,
paris-weekend.pdf. backend.py owns no data files (all orig demo content is
inline Jarvis shapes). New files get a `flutter-` or `orig-` prefix per
sole consumer; shared-by-both files keep bare names.
"""
import base64
import json
import os
import sys
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "data")


def _load(name, default):
    try:
        with open(os.path.join(DATA, name)) as f:
            return json.load(f)
    except OSError:
        return default


THREADS_JSON = _load("threads.json", [])
MESSAGES_JSON = _load("messages.json", {})
FEED_JSON = _load("feed.json", [])
CONNECTORS_JSON = _load("connectors.json", [])
PROFILE_JSON = _load("profile.json", {"user": {"id": "u1"}})
try:
    with open(os.path.join(DATA, "demo.jpg"), "rb") as f:
        DEMO_JPG = f.read()
except OSError:
    DEMO_JPG = b"\xff\xd8\xff\xe0" + bytes(1024)


def _data_bytes(name, default=b""):
    try:
        with open(os.path.join(DATA, name), "rb") as f:
            return f.read()
    except OSError:
        return default


PARIS_MD = _data_bytes("paris-weekend.md")
PARIS_PDF = _data_bytes("paris-weekend.pdf")

_TS = 1757300000000
_uid_n = [0]


def _uid(prefix):
    _uid_n[0] += 1
    return f"{prefix}{_uid_n[0]}_{int(time.time() * 1000) % 46656:05d}"


# Demo threads/chats served to the patched app over Jarvis HTTPS.
FEED_UNITS = [
    {"id": "f1", "kind": "suggestion", "title": "Good morning!",
     "subtitle": "Things to try today"},
    {"id": "f2", "kind": "reminder", "title": "Weekend getaway",
     "subtitle": "Don't forget your plans"},
    {"id": "f3", "kind": "tip", "title": "Try voice chat",
     "subtitle": "Ask me anything"},
    {"id": "f4", "kind": "news", "title": "Fresh updates",
     "subtitle": "Fresh updates for you"},
]
_uploaded = {}


# ---------------------------------------------------------------- fixtures
def _fixture_route(method, path, query, body):
    """Shared route table for the :8787 fixture mock (was index.js)."""
    port = _fixture_state.get("port", 8787)
    now = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    k = f"{method} {path}"
    if k == "POST /hatch/login":
        return 200, {"access_token": "tok_" + _uid(""), "user_id": "u1"}
    if k == "POST /hatch/auth/start":
        return 200, {"challenge_id": _uid("ch_")}
    if k == "POST /hatch/auth/send_otp":
        return 200, {"ok": True}
    if k == "POST /hatch/auth/confirm_otp":
        if body.get("code") == "123456":
            return 200, {"access_token": "tok_" + _uid(""),
                         "user_id": "u1"}
        return 401, {"error": "invalid code"}
    if k == "POST /hatch/auth/select_account":
        return 200, {"access_token": "tok_" + _uid(""),
                     "user_id": body.get("account_id") or "u1"}
    if k == "GET /hatch/fetch_vms":
        return 200, {"vms": [{"vm_id": "vm1",
                              "ws_url": f"ws://localhost:{port}/vm/vm1",
                              "status": "active"}]}
    if k == "POST /hatch/lease_vm":
        vid = _uid("vm_")
        return 200, {"vm_id": vid,
                     "ws_url": f"ws://localhost:{port}/vm/{vid}",
                     "status": "active"}
    if k == "POST /hatch/vm/wake":
        return 200, {"vm_id": body.get("vm_id") or "vm1", "status": "active"}
    if k == "POST /graphql":
        prompt = ((body.get("variables") or {}).get("prompt")
                  if isinstance(body.get("variables"), dict) else "")
        if isinstance(prompt, str) and "feed" in prompt:
            return 200, {"data": {"feed": {"units": FEED_UNITS}}}
        return 200, {"data": {"reply": {
            "text": str(prompt or "Hello from Muse!"), "cards": []}}}
    if k == "GET /api/session/list":
        return 200, {"threads": THREADS_JSON}
    if k in ("POST /api/session/rename", "POST /api/session/delete",
             "POST /api/session/archive"):
        return 200, {"ok": True}
    if k == "GET /api/chat/history":
        tid = query.get("thread_id", "")
        return 200, {"messages": MESSAGES_JSON.get(tid, [])}
    if k == "POST /api/chat/send":
        text = str(body.get("text", ""))
        cards = []
        if any(w in text.lower() for w in ("picture", "image", "photo")):
            cards = [{"kind": "image",
                      "url": f"http://localhost:{port}/api/demo-image",
                      "title": "demo.jpg"}]
        return 200, {"message": {"id": _uid("m_"), "role": "agent",
                                 "text": text, "ts": now, "cards": cards}}
    if k == "GET /api/feed":
        return 200, {"units": FEED_JSON}
    if k == "GET /api/connectors":
        return 200, {"connectors": CONNECTORS_JSON}
    if k == "GET /hatch/subscription":
        return 200, {"plan": "free", "credits": 100}
    if k == "GET /hatch/viewer/profile":
        return 200, PROFILE_JSON
    if k == "GET /api/demo-image":
        return ("__bytes__", DEMO_JPG, "image/jpeg")
    if k == "POST /api/fs/upload":
        # ponytail: single-request contract — bytes ride with the metadata,
        # and bytes_written is measured, never client-claimed.
        name = str(body.get("name", "upload.bin"))
        mime = str(body.get("mime", "application/octet-stream"))
        raw = base64.b64decode(str(body.get("bytes_b64", ""))) \
            if body.get("bytes_b64") else b""
        if len(raw) > 8 * 1024 * 1024:
            return 413, {"error": "too large"}
        _uploaded[name] = {"bytes": raw, "mime": mime}
        return 200, {"ok": True, "path": f"workspace/user/files/{name}",
                     "name": name, "mime": mime, "bytes_written": len(raw)}
    if k in ("GET /api/fs/raw", "GET /api/fs/thumbnail"):
        hit = _uploaded.get(str(query.get("name", "")))
        if not hit or not hit["bytes"]:
            return 404, {"error": "not found"}
        return ("__bytes__", hit["bytes"], hit["mime"])
    if k == "POST /hatch/accept_tos":
        return 200, {"ok": True}
    return 404, {"error": "not found"}


_fixture_state = {"port": 8787}

class _FixtureHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *a):
        pass

    def _handle(self):
        from urllib.parse import urlsplit, parse_qs
        u = urlsplit(self.path)
        query = {k: v[0] for k, v in
                 parse_qs(u.query).items()} if u.query else {}
        body = {}
        if self.command == "POST":
            try:
                length = int(self.headers.get("Content-Length", 0) or 0)
            except ValueError:
                length = 0
            raw = self.rfile.read(length) if length else b""
            if raw:
                try:
                    body = json.loads(raw)
                except ValueError:
                    return self._send(400, {"error": "invalid json"})
        print(f"{self.command} {u.path} "
              f"{json.dumps(body)[:120]}", flush=True)
        out = _fixture_route(self.command, u.path, query, body)
        if out[0] == "__bytes__":
            _, data, ctype = out
            self.send_response(200)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(data)
            return
        self._send(out[0], out[1])

    def _send(self, code, obj):
        data = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        self._handle()

    def do_POST(self):
        self._handle()

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()


def run_fixture(port=8787):
    _fixture_state["port"] = port
    srv = HTTPServer(("0.0.0.0", port), _FixtureHandler)
    print(f"mock on {port}", flush=True)
    srv.serve_forever()




if __name__ == "__main__":
    port = int(sys.argv[1] if len(sys.argv) > 1 else 8787)
    run_fixture(port)
