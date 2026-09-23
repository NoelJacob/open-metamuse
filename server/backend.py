#!/usr/bin/env python3
"""Single backend for the Muse parity work: fixture HTTP + orig intercept.

Replaces server/index.js (fixture mock :8787), server/orig/addon.py
(mitmproxy intercept for Meta hosts), server/orig/gwhttps.py (direct-TLS
gateway stub :9443 — native Tigon calls bypass the OS proxy), and
server/orig/gwprobe.py (raw-TLS byte logger :9443, --probe mode).
stdlib only (mitmproxy import is lazy so fixture/gateway modes run bare).

Usage:
  python3 backend.py fixture [--port 8787]   # was: node server/index.js
  python3 backend.py orig                    # orig manual exploration:
                                             # cert + mitm :8080 + gateway
                                             # :9443 in one foreground process
  python3 backend.py intercept                # -s server/backend.py for mitmdump
  python3 backend.py gateway [--port 9443]   # was: server/orig/gwhttps.py
  python3 backend.py probe [--port 9443]     # was: server/orig/gwprobe.py

Data lives in server/data/*.json; demo bytes in server/data/demo.jpg.
Route behavior is byte-identical to the files above, including quirks
(gw chat/history returns a non-object on purpose).
"""
import base64
import json
import os
import socket
import ssl
import sys
import threading
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
DEMO_THREADS = [
    {"session_id": "t1", "title": "Paris weekend",
     "snippet": "Day 1: Louvre, Seine cruise…", "channel": "main",
     "created_at_ms": _TS, "updated_at_ms": _TS + 400000,
     "unread_count": 0, "archived": False, "is_pinned": False,
     "pinned": False, "is_primary": True, "is_thread": True,
     "status": "active"},
    {"session_id": "t2", "title": "Sourdough recipe",
     "snippet": "500g flour, 375g water…", "channel": "main",
     "created_at_ms": _TS - 86400000, "updated_at_ms": _TS - 3600000,
     "unread_count": 0, "archived": False, "is_pinned": False,
     "pinned": False, "is_primary": False, "is_thread": True,
     "status": "active"},
]
DEMO_EVENTS = [
    {"event_name": "message.user", "message_id": "m1",
     "stream_lane": "main", "occurred_at_ms": _TS, "seq": 1,
     "payload": {"content": "Hey Muse, plan my weekend in Paris"}},
    {"event_name": "message.assistant", "message_id": "m2",
     "reply_to_message_id": "m1", "stream_lane": "main",
     "occurred_at_ms": _TS + 30000, "seq": 2,
     "payload": {"content": "Here is a 2-day plan.\n\nDay 1: Louvre in the morning, Seine cruise at sunset.\n\nDay 2: Montmartre and the Marais."}},
    {"event_name": "message.user", "message_id": "m3",
     "stream_lane": "main", "occurred_at_ms": _TS + 200000, "seq": 3,
     "payload": {"content": "Thanks! That looks great."}},
]
# ponytail: stateful demo — reply + picture join from the second fetch on.
_fetch_count = [0]
IMG_EVENT = {
    "event_name": "message.assistant", "message_id": "m-img-1",
    "reply_to_message_id": "m3", "stream_lane": "main",
    "occurred_at_ms": _TS + 300000, "seq": 4,
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
REPLY_EVENT = {
    "event_name": "message.assistant", "message_id": "m-reply-1",
    "reply_to_message_id": "m3", "stream_lane": "main",
    "occurred_at_ms": _TS + 250000, "seq": 5,
    "payload": {"content": "Glad you like it! Anything else I can plan for you?"},
}
GW_BASE_EVENT = {
    "event_name": "message.assistant", "message_id": "m-demo-1",
    "stream_lane": "main", "occurred_at_ms": 1789084800000, "seq": 1,
    "content": "Hello! I am Muse, running on the demo server.",
    "display_text": "Hello! I am Muse, running on the demo server.",
    "fallback_text": "Hello! I am Muse, running on the demo server.",
    "payload": {
        "content": "Hello! I am Muse, running on the demo server.",
        "display_text": "Hello! I am Muse, running on the demo server.",
        "fallback_text": "Hello! I am Muse, running on the demo server.",
        "text": "Hello! I am Muse, running on the demo server.",
    },
}
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
def _idea_card(cid, title, summary, detail=""):
    return {
        "id": cid,
        "buildStatus": "ready",
        "build_status": "ready",
        "iconUrl": "",
        "mimeType": "image/jpeg",
        "primaryLabel": "Try it",
        "secondaryLabel": "",
        "content": {
            "title": title,
            "summary": summary,
            "detailDescription": detail,
            "buildSummary": summary,
            "fitReason": "",
        },
    }


def _idea_cards_body():
    # ponytail: HatchEnvelope.ok + result per IdeaCardsResponseJson —
    # field names from the decompiled explore/repo contracts.
    return {
        "ok": True,
        "result": {
            "sections": [
                {"id": "s-morning",
                 "title": "Good morning",
                 "subtitle": "Things to try today",
                 "presentation": {"layout": "carousel"},
                 "cards": [
                     _idea_card("c1", "Plan my weekend",
                                "A 2-day Paris itinerary",
                                "Louvre, Seine cruise, Montmartre."),
                     _idea_card("c2", "Weekend getaway",
                                "Don't forget your plans",
                                "Pack list and reservations."),
                 ]},
                {"id": "s-learn",
                 "title": "Learn something new",
                 "subtitle": "Ideas for you",
                 "presentation": {"layout": "grid"},
                 "cards": [
                     _idea_card("c3", "Try voice chat",
                                "Ask me anything",
                                "Hands-free conversation."),
                     _idea_card("c4", "Fresh updates",
                                "Fresh updates for you",
                                "What changed this week."),
                 ]},
            ],
            "pagination": {"hasNextPage": False, "nextCursor": ""},
            "viewerState": {"hasBuiltIdea": False},
        },
    }


def _artifact_node(ref, name, source, updated_ms, preview_icon="",
                     kind="document"):
    # ponytail: shapes per ArtifactNodeJson/ArtifactCapabilitiesJson; the
    # Media segment filters the same artifacts payload client-side.
    return {
        "artifact_ref": ref,
        "display_name": name,
        "source": source,
        "created_at_ms": 1757300000000,
        "updated_at_ms": updated_ms,
        "last_activity_at_ms": updated_ms,
        "last_opened_at_ms": None,
        "is_pinned": False,
        "open_target": None,
        "preview": {"icon_url": preview_icon} if preview_icon else None,
        "capabilities": {"can_delete": True, "can_open": True,
                         "can_pin": True, "can_rename": True,
                         "can_share": True},
        "kind": kind,
    }


def _artifacts_body():
    # ponytail: HatchEnvelope.ok + result per UnifiedArtifactsResponseJson
    # (edges[{cursor,node}] + page_info); demo rows for docs + media.
    nodes = [
        _artifact_node("doc:weekend-plan", "Weekend plan",
                       "file", 1757300400000, kind="document"),
        _artifact_node("doc:sourdough-guide", "Sourdough guide",
                       "file", 1757290000000, kind="document"),
        _artifact_node("workspace/user/files/demo_0_ab12.jpg", "demo.jpg",
                       "file", 1757300600000, kind="image"),
        _artifact_node("workspace/user/files/paris-map.jpg", "paris-map.jpg",
                       "file", 1757295000000, kind="image"),
        _artifact_node("doc:paris-weekend.md", "paris-weekend.md",
                       "file", 1757296000000, kind="document"),
        _artifact_node("doc:paris-weekend.pdf", "paris-weekend.pdf",
                       "file", 1757297000000, kind="document"),
    ]
    return {
        "ok": True,
        "result": {
            "edges": [{"cursor": f"cur{i}", "node": n}
                      for i, n in enumerate(nodes)],
            "page_info": {"end_cursor": "", "has_next_page": False,
                          "has_previous_page": False, "start_cursor": ""},
        },
    }


def _demo_size(path):
    # ponytail: single source of truth for demo file sizes (fs/stat +
    # fs/library agree, or the viewer distrusts both).
    p = str(path)
    if "paris-weekend.pdf" in p:
        return len(PARIS_PDF)
    if "paris-weekend.md" in p:
        return len(PARIS_MD)
    if "paris-map" in p:
        return 48210
    if "demo" in p:
        return len(DEMO_JPG)
    return 0


def _fs_library_body():
    # ponytail: shared by the gateway and mitm transports (the app sends
    # fs/library both direct and proxied).
    entries = [
        {"modified_ms": 1757300600000, "name": "demo.jpg",
         "path": "workspace/user/files/demo_0_ab12.jpg",
         "size": len(DEMO_JPG)},
        {"modified_ms": 1757295000000, "name": "paris-map.jpg",
         "path": "workspace/user/files/paris-map.jpg", "size": 48210},
        {"modified_ms": 1757296000000, "name": "paris-weekend.md",
         "path": "workspace/user/files/paris-weekend.md",
         "size": len(PARIS_MD)},
        {"modified_ms": 1757297000000, "name": "paris-weekend.pdf",
         "path": "workspace/user/files/paris-weekend.pdf",
         "size": len(PARIS_PDF)},
    ]
    return {"ok": True, "result": {"entries": entries,
                                   "has_more": False, "total": 4}}


GOALS = [
    {"id": "g1", "title": "Plan weekend trip",
     "status": "active", "progress": 0.4},
    {"id": "g2", "title": "Learn sourdough",
     "status": "active", "progress": 0.1},
]
CONNS = [
    {"id": "whatsapp", "name": "WhatsApp", "linked": False},
    {"id": "telegram", "name": "Telegram", "linked": False},
    {"id": "messenger", "name": "Messenger", "linked": False},
]
_tos_accepted = [False]
_uploaded = {}
_hits = {}


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


# ------------------------------------------------------------------ gateway
def _gateway_route(method, path, query_raw, body_bytes=b""):
    """Shared route table for the direct-TLS :9443 stub (was gwhttps.py).

    Behavior preserved exactly, including chat/history returning a
    non-object result (deliberate client-behavior probe).
    """
    p = path.split("?")[0]
    n = _hits.get(p, 0) + 1
    _hits[p] = n
    print(f"HIT {method} {path} (#{n})", flush=True)
    if p.endswith("/api/session/list"):
        act = "archived" not in path
        ss = DEMO_THREADS if act else []
        return {"result": {"sessions": ss, "archived": not act},
                "sessions": ss, "archived": not act}
    if p.endswith("/chat/history"):
        return {"result": "BROKEN-NOT-AN-OBJECT",
                "has_more": False, "chat_events": "nope"}
    if p.endswith("/api/chat/unread-count"):
        return {"result": {"has_unread_threads": False},
                "has_unread_threads": False}
    if p.endswith("/api/feed/units"):
        return {"result": {"units": FEED_UNITS}, "units": FEED_UNITS}
    if "/api/idea-cards" in p:
        print("STUB idea-cards", flush=True)
        return _idea_cards_body()
    if p.endswith("/api/goals/list"):
        return {"result": {"goals": GOALS}, "goals": GOALS}
    if p.endswith("/api/library/artifacts"):
        items = [{"id": "a1", "title": "Weekend plan", "kind": "document"}]
        return {"result": {"items": items}, "items": items}
    if "/api/artifacts" in p:
        print("STUB artifacts", flush=True)
        return _artifacts_body()
    if p.endswith("/fs/library"):
        print("STUB fs-library", flush=True)
        return _fs_library_body()
    if p.endswith("/fs/stat"):
        try:
            _sp = json.loads(
                body_bytes.decode("utf-8", "replace") or "{}").get(
                "path", "")
        except Exception:
            _sp = ""
        print(f"STUB fs-stat path={_sp}", flush=True)
        return {"ok": True, "result": {
            "kind": "file", "modified_ms": 1757300000000,
            "path": _sp, "size": _demo_size(_sp)}}
    if p.endswith("/fs/read"):
        import base64 as _b64
        _rp, _off, _ln = "", 0, 0
        print("STUB fs-read (gateway: path unseen, serving PDF)", flush=True)
        _slice = PARIS_PDF[_off:_off + _ln] if _ln else PARIS_PDF[_off:]
        return {"ok": True, "result": {
            "data_base64": _b64.b64encode(_slice).decode(), "text": ""}}
    if p.endswith("/api/library/media"):
        items = [{"id": "d1", "kind": "image", "label": "demo.jpg",
                  "path": "workspace/user/files/demo_0_ab12.jpg"}]
        return {"result": {"items": items}, "items": items}
    if p.endswith("/api/spaces/list"):
        spaces = [{"id": "s1", "title": "Trip planning", "member_count": 2}]
        return {"result": {"spaces": spaces}, "spaces": spaces}
    if p.endswith("/api/memory/list"):
        mem = [{"id": "mem1", "title": "Weekend trip",
                "snippet": "Paris, 2 days"}]
        return {"result": {"entries": mem}, "entries": mem}
    if p.endswith("/api/connectors/list"):
        return {"result": {"connectors": CONNS}, "connectors": CONNS}
    if p.endswith("/api/subscription"):
        return {"result": {"plan": "free", "credits": 100},
                "plan": "free", "credits": 100}
    if p.endswith("/fs/upload"):
        return {"ok": True,
                "path": "workspace/user/files/demo_0_ab12.jpg",
                "bytes_written": len(DEMO_JPG)}
    if "/fs/thumbnail/" in p or "/fs/raw/" in p:
        # ponytail: serve demo bytes by filename; unknown names fall back
        # to the demo JPG so thumbnails never 404 offline.
        if "paris-weekend.pdf" in p:
            return ("__bytes__", PARIS_PDF, "application/pdf")
        if "paris-weekend.md" in p:
            return ("__bytes__", PARIS_MD, "text/markdown")

        return ("__bytes__", DEMO_JPG, "image/jpeg")
    if p.endswith("/seen") or "/seen" in p:
        return {"ok": True}
    return {"ok": True}


class _GatewayHandler(BaseHTTPRequestHandler):
    # ponytail: HTTP/1.0 + close — the client races keep-alive reuse
    # (POST bodies die as "client disconnected" on reused sockets).
    protocol_version = "HTTP/1.0"

    def handle_expect_100(self):
        # ponytail: the client posts bodies with Expect: 100-continue and
        # RSTs when we stay silent; answer Continue immediately.
        self.send_response_only(100)
        self.end_headers()
        return True

    def log_message(self, *a):
        pass

    def _route(self):
        try:
            length = int(self.headers.get("Content-Length", 0) or 0)
        except ValueError:
            length = 0
        if length:
            body = self.rfile.read(length)
        else:
            body = b""
        out = _gateway_route(self.command, self.path, "", body)
        if isinstance(out, tuple):
            _, data, ctype = out
            self.send_response(200)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return
        body = json.dumps(out).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        self._route()

    def do_POST(self):
        self._route()


def run_gateway(port=9443):
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain("/tmp/gwprobe/leaf.crt", "/tmp/gwprobe/leaf.key")
    srv = HTTPServer(("0.0.0.0", port), _GatewayHandler)
    srv.socket = ctx.wrap_socket(srv.socket, server_side=True)
    print(f"gwhttps on :{port}", flush=True)
    srv.serve_forever()


# --------------------------------------------------------------------- probe
def _probe_handle(conn, addr):
    print(f"conn from {addr}", flush=True)
    conn.settimeout(60)
    try:
        data = conn.recv(65536)
        n = 0
        while data:
            n += 1
            with open("/tmp/gwprobe/bytes.log", "ab") as f:
                f.write(f"\n--- frame {n} {len(data)}b ---\n".encode())
                f.write(data[:4096])
            print(f"frame {n}: {len(data)}b head={data[:64].hex()}",
                  flush=True)
            try:
                print(f"  text: {data[:400].decode('utf-8', 'replace')[:200]!r}",
                      flush=True)
            except Exception:
                pass
            data = conn.recv(65536)
    except socket.timeout:
        print("idle timeout, holding", flush=True)
        time.sleep(60)
    except Exception as e:
        print(f"err {e}", flush=True)
    finally:
        try:
            conn.close()
        except Exception:
            pass


def run_probe(port=9443):
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain("/tmp/gwprobe/leaf.crt", "/tmp/gwprobe/leaf.key")
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(("0.0.0.0", port))
    srv.listen(5)
    print(f"gwprobe on :{port}", flush=True)
    while True:
        raw, addr = srv.accept()
        try:
            conn = ctx.wrap_socket(raw, server_side=True)
        except Exception as e:
            print(f"tls fail {addr}: {e}", flush=True)
            raw.close()
            continue
        threading.Thread(target=_probe_handle, args=(conn, addr),
                         daemon=True).start()


# ----------------------------------------------------------------- intercept
def _mitm_routes():
    """Route table for the mitmproxy addon (lazy mitmproxy import)."""
    from mitmproxy.http import Response  # noqa: PLC0415

    seen = {}

    def log(flow, note=""):
        key = (f"{flow.request.method} "
               f"{flow.request.pretty_host}{flow.request.path}")
        seen[key] = seen.get(key, 0) + 1
        if seen[key] <= 3:
            print(f"FLOW {key} {note}", flush=True)

    def js(flow, obj, status=200):
        flow.response = Response.make(
            status, json.dumps(obj), {"Content-Type": "application/json"})

    def byts(flow, data, ctype="image/jpeg"):
        flow.response = Response.make(200, data, {"Content-Type": ctype})

    def request(flow):
        host = flow.request.pretty_host or ""
        if "auth.meta.com" in host or "facebook.com" in host:
            return
        path = flow.request.path.split("?")[0]
        if path.endswith("/api/session/list"):
            view = "archived" if "archived" in flow.request.path else "active"
            log(flow, "STUB jarvis-list")
            ss = DEMO_THREADS if view == "active" else []
            js(flow, {"result": {"sessions": ss,
                                 "archived": view == "archived"},
                      "sessions": ss, "archived": view == "archived"})
            return
        if path.endswith("/chat/history"):
            _fetch_count[0] += 1
            events = list(DEMO_EVENTS)
            if _fetch_count[0] > 1:
                events = events + [REPLY_EVENT, IMG_EVENT]
            log(flow, f"STUB jarvis-history n={_fetch_count[0]}")
            js(flow, {"result": {"chat_events": events, "has_more": False},
                      "has_more": False, "chat_events": events})
            return
        if path.endswith("/fs/upload"):
            log(flow, "STUB fs-upload")
            js(flow, {"ok": True,
                      "path": "workspace/user/files/demo_0_ab12.jpg",
                      "bytes_written": len(DEMO_JPG)})
            return
        if "/fs/thumbnail/" in path or "/fs/raw/" in path:
            # ponytail: same filename dispatch as the gateway branch —
            # serving JPG bytes for a .pdf row breaks the renderer.
            if "paris-weekend.pdf" in path:
                log(flow, "STUB fs-bytes pdf")
                byts(flow, PARIS_PDF, "application/pdf")
            elif "paris-weekend.md" in path:
                log(flow, "STUB fs-bytes md")
                byts(flow, PARIS_MD, "text/markdown")

            else:
                log(flow, "STUB fs-bytes")
                byts(flow, DEMO_JPG)
            return
        if path.endswith("/api/chat/unread-count"):
            log(flow, "STUB jarvis-unread")
            js(flow, {"result": {"has_unread_threads": False},
                      "has_unread_threads": False})
            return
        if path.endswith("/api/feed/units"):
            log(flow, "STUB feed-units")
            js(flow, {"result": {"units": FEED_UNITS}, "units": FEED_UNITS})
            return
        if "/api/idea-cards" in path:
            log(flow, "STUB idea-cards")
            js(flow, _idea_cards_body())
            return
        if path.endswith("/api/goals/list"):
            log(flow, "STUB goals-list")
            js(flow, {"result": {"goals": GOALS}, "goals": GOALS})
            return
        if "/api/goals/" in path and path.endswith("/detail"):
            log(flow, "STUB goals-detail")
            js(flow, {"result": {"goal": {"id": "g1",
                         "title": "Plan weekend trip", "status": "active",
                         "progress": 0.4,
                         "steps": ["Pick dates", "Book stay"]}},
                      "goal": {"id": "g1"}})
            return
        if path.endswith("/api/library/artifacts"):
            log(flow, "STUB library-artifacts")
            items = [{"id": "a1", "title": "Weekend plan",
                      "kind": "document"}]
            js(flow, {"result": {"items": items}, "items": items})
            return
        if path.endswith("/fs/library"):
            log(flow, "STUB fs-library")
            js(flow, _fs_library_body())
            return
        if path.endswith("/fs/stat"):
            try:
                _sp = json.loads(
                    flow.request.content.decode("utf-8", "replace")
                    or "{}").get("path", "")
            except Exception:
                _sp = ""
            log(flow, f"STUB fs-stat path={_sp}")
            js(flow, {"ok": True, "result": {
                "kind": "file", "modified_ms": 1757300000000,
                "path": _sp, "size": _demo_size(_sp)}})
            return
        if "/api/artifacts" in path:
            log(flow, "STUB artifacts")
            js(flow, _artifacts_body())
            return
        if path.endswith("/fs/read"):
            import base64 as _b64
            try:
                _body = json.loads(
                    flow.request.content.decode("utf-8", "replace") or "{}")
            except Exception:
                _body = {}
            _rp = str(_body.get("path", ""))
            _off = int(_body.get("offset", 0) or 0)
            _ln = int(_body.get("len", 0) or 0)
            log(flow, f"STUB fs-read path={_rp} off={_off} len={_ln}")
            if "paris-weekend.pdf" in _rp:
                _data, _mime = PARIS_PDF, "application/pdf"
            elif "paris-weekend.md" in _rp:
                _data, _mime = PARIS_MD, "text/markdown"
            elif "paris-map" in _rp or "demo" in _rp:
                _data, _mime = DEMO_JPG, "image/jpeg"
            else:
                _data, _mime = b"", "application/octet-stream"
            _slice = _data[_off:_off + _ln] if _ln else _data[_off:]
            js(flow, {"ok": True, "result": {
                "data_base64": _b64.b64encode(_slice).decode(),
                "text": "",
            }})
            return
        if path.endswith("/api/library/media"):
            log(flow, "STUB library-media")
            items = [{"id": "d1", "kind": "image", "label": "demo.jpg",
                      "path": "workspace/user/files/demo_0_ab12.jpg"}]
            js(flow, {"result": {"items": items}, "items": items})
            return
        if path.endswith("/api/spaces/list"):
            log(flow, "STUB spaces-list")
            spaces = [{"id": "s1", "title": "Trip planning",
                       "member_count": 2}]
            js(flow, {"result": {"spaces": spaces}, "spaces": spaces})
            return
        if path.endswith("/api/memory/list"):
            log(flow, "STUB memory-list")
            mem = [{"id": "mem1", "title": "Weekend trip",
                    "snippet": "Paris, 2 days"}]
            js(flow, {"result": {"entries": mem}, "entries": mem})
            return
        if path.endswith("/api/connectors/list"):
            log(flow, "STUB connectors-list")
            js(flow, {"result": {"connectors": CONNS}, "connectors": CONNS})
            return
        if path.endswith("/api/subscription"):
            log(flow, "STUB subscription")
            js(flow, {"result": {"plan": "free", "credits": 100},
                      "plan": "free", "credits": 100})
            return
        if path.endswith("/api/settings/notifications"):
            log(flow, "STUB notif-settings")
            js(flow, {"result": {"enabled": True}, "enabled": True})
            return
        if path.endswith("/api/settings/data-controls"):
            log(flow, "STUB data-controls")
            js(flow, {"result": {"improve_models": False},
                      "improve_models": False})
            return
        if path.endswith("/api/search"):
            log(flow, "STUB search")
            q = flow.request.query.decode("utf-8", "replace") if hasattr(
                flow.request, "query") else ""
            js(flow, {"result": {"results": [
                {"id": "t1", "title": "Paris weekend", "snippet": q}]},
                "results": []})
            return
        blocked = host.endswith(("meta.ai", "meta.com", "facebook.com",
                                 "fbcdn.net"))
        if blocked:
            log(flow)
            if path == "/graphql" and flow.request.content:
                try:
                    print("GQL", flow.request.content[:400]
                          .decode("utf-8", "replace"), flush=True)
                except Exception:
                    pass
        if flow.request.method == "POST" and path == "/graphql":
            log(flow, "STUB graphql")
            js(flow, {"data": {}})
            return
        if flow.request.method == "GET":
            if path == "/hatch/activation_statuses":
                log(flow, "STUB activation")
                js(flow, {
                    "has_hatch_access": True,
                    "has_cleared_acquisition": True,
                    "invite_code_entry_available": False,
                    "waitlist_available": False,
                    "has_provisioned_vm": True,
                    "waitlist_status": "not_waitlisted",
                    "has_redeemed_invite_code": True,
                    "ccv_status": "not_required",
                    "is_in_geoblocked_region": False,
                    "has_completed_hatch_activation": True,
                    "hatch_wearables_linked": False,
                    "is_nda_required": False,
                    "is_vm_type_selection_required": False,
                })
            elif path == "/hatch/viewer/profile":
                log(flow, "STUB profile")
                js(flow, {
                    "name": "Muse User",
                    "username": "muse.user",
                    "profile_picture_url": "",
                })
            elif path == "/hatch/tos_status":
                log(flow, "STUB tos")
                js(flow, {
                    "has_accepted_tos": _tos_accepted[0],
                    # ponytail: full disclosure per TosStatusResponseJson;
                    # stub copy (offline fixture) — accept echoes text+version.
                    "disclosure_title": "Terms of Service (stub)",
                    "disclosure_text": "Stub terms for offline testing.",
                    "disclosure_version": "stub-v1",
                    "disclosure_button_text": "Continue",
                    "disclosure_entities": [],
                    "disclosure_sections": [],
                })
            elif path == "/hatch/fetch_vms":
                log(flow, "STUB vms-probe")
                js(flow, {"vm_list": [{
                    "vm_id": "vm_stub1",
                    "vm_name": "stub",
                    "vm_state": "RUNNING",
                    "vm_type": "hatch_cvm",
                    "vm_ws_url": "wss://10.0.2.2:9443/gw",
                    "vm_auth_token": "tok_stub",
                    "vm_notary_tokens": {},
                    "default": True,
                }]})
            if flow.response is not None:
                return
        if flow.request.method != "POST" and (
                flow.response is not None or not blocked):
            return
        if path == "/hatch/auth/start":
            log(flow, "STUB start")
            js(flow, {"access_token": "tmp_stub1",
                      "id_for_aymh": "aymh_stub1"})
        elif path == "/hatch/auth/send_otp":
            log(flow, "STUB send_otp")
            js(flow, {
                "registration_state": "r",
                "auth_state": "st_stub1",
                "password_login_available": False,
            })
        elif path == "/hatch/auth/confirm_otp":
            log(flow, "STUB confirm_otp")
            js(flow, {
                "abra_access_token": "abra_stub",
                "abra_user_id": "1000001",
                "frl_access_token": "frl_stub",
                "frl_account_id": "1000001",
                "account_selection_required": False,
                "two_factor_required": False,
                "checkpoint_required": False,
            })
        elif path == "/hatch/login":
            log(flow, "STUB login-xchg")
            js(flow, {
                "access_token": "abra_stub",
                "abra_user_id": "1000001",
                "user_id": "1000001",
            })
        elif path == "/hatch/accept_tos":
            log(flow, "STUB accept-tos")
            _tos_accepted[0] = True
            # ponytail: decompiled contract — acceptTosConsent parses the
            # body as SuccessResponseJson and navigates only on success=true
            # (AuraActivationRepository.java:1495).
            js(flow, {"success": True})
            return
        if blocked and flow.response is None:
            log(flow, "STUB generic-blocked")
            if flow.request.method == "GET":
                js(flow, {})

    return request


try:
    request = _mitm_routes()
except ImportError:
    # Bare stdlib use (fixture/gateway/probe modes): no mitmproxy present.
    request = None


def _ensure_cert():
    """Mint the mitm-CA-signed :9443 leaf if /tmp/gwprobe was wiped."""
    import subprocess
    crt = "/tmp/gwprobe/leaf.crt"
    key = "/tmp/gwprobe/leaf.key"
    if os.path.exists(crt) and os.path.exists(key):
        return
    os.makedirs("/tmp/gwprobe", exist_ok=True)
    home = os.path.expanduser("~/.mitmproxy/mitmproxy-ca.pem")
    subprocess.run(
        ["openssl", "req", "-newkey", "rsa:2048", "-keyout", key,
         "-out", "/tmp/gwprobe/leaf.csr", "-nodes", "-subj", "/CN=10.0.2.2"],
        check=True, capture_output=True)
    subprocess.run(
        ["openssl", "x509", "-req", "-in", "/tmp/gwprobe/leaf.csr",
         "-CA", home, "-CAkey", home, "-CAcreateserial",
         "-out", crt, "-days", "30", "-extfile",
         "/dev/stdin", "-extensions", "v3"],
        input=b"subjectAltName=IP:10.0.2.2,DNS:localhost\n[v3]\n"
              b"subjectAltName=IP:10.0.2.2,DNS:localhost\n",
        check=True, capture_output=True)
    try:
        os.remove("/tmp/gwprobe/leaf.csr")
    except OSError:
        pass
    print("minted /tmp/gwprobe/leaf.crt", flush=True)


def _spawn_mitm():
    """Launch mitmdump in-process-adjacent with this file as its addon."""
    import subprocess
    return subprocess.Popen(
        ["mitmdump", "--listen-host", "0.0.0.0", "--listen-port", "8080",
         "--set", "connection_strategy=lazy", "-s", os.path.abspath(__file__)])


def _adb(*args):
    """Run adb against the emulator; return stdout ('' on failure)."""
    import subprocess
    try:
        r = subprocess.run(["adb", "-s", "emulator-5554", *args],
                           capture_output=True, text=True, timeout=30)
        return r.stdout.strip()
    except Exception:
        return ""


def _wait_device(timeout=180):
    """Block until the emulator shell answers (user boots it manually)."""
    import time
    t0 = time.time()
    while time.time() - t0 < timeout:
        if _adb("shell", "echo", "ok") == "ok":
            return True
        time.sleep(5)
    return False


def run_orig():
    """Manual original-app exploration: wait for the (manually booted)
    emulator, configure device proxy + grants, then serve cert + mitm +
    gateway. Prints OK when the user can launch the app. Ctrl-C stops."""
    import time
    print("waiting for emulator-5554 (boot it manually)...", flush=True)
    if not _wait_device():
        raise SystemExit("emulator-5554 never came online")
    _adb("shell", "settings", "put", "global", "http_proxy",
         "10.0.2.2:8080")
    _adb("shell", "settings", "put", "secure", "accessibility_enabled",
         "0")
    out = _adb("shell", "dumpsys", "package", "com.facebook.aura")
    import re
    for pm in sorted(set(re.findall(r"android\.permission\.[A-Z_]+",
                                    out))):
        _adb("shell", "pm", "grant", "com.facebook.aura", pm)
    _adb("shell", "appops", "set", "com.facebook.aura",
         "POST_NOTIFICATION", "allow")
    _ensure_cert()
    mitm = _spawn_mitm()
    gw = threading.Thread(target=run_gateway, kwargs={"port": 9443},
                          daemon=True)
    gw.start()
    # ponytail: readiness is observed, not assumed — poll both listeners.
    import socket
    t0 = time.time()
    while time.time() - t0 < 60:
        ok = True
        for port in (8080, 9443):
            try:
                socket.create_connection(("127.0.0.1", port),
                                         timeout=2).close()
            except OSError:
                ok = False
        if ok:
            break
        time.sleep(1)
    else:
        mitm.terminate()
        raise SystemExit("backend listeners never came up")
    print("OK — launch the Muse app in the emulator and browse.",
          flush=True)
    try:
        mitm.wait()
    except KeyboardInterrupt:
        pass
    finally:
        mitm.terminate()


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "fixture"
    if mode == "fixture":
        port = int(sys.argv[2] if len(sys.argv) > 2 else 8787)
        run_fixture(port)
    elif mode == "intercept":
        print("load as mitmdump addon: mitmdump -s server/backend.py ...",
              flush=True)
    elif mode == "gateway":
        port = int(sys.argv[2] if len(sys.argv) > 2 else 9443)
        run_gateway(port)
    elif mode == "probe":
        port = int(sys.argv[2] if len(sys.argv) > 2 else 9443)
        run_probe(port)
    elif mode == "orig":
        run_orig()
    else:
        raise SystemExit(f"unknown mode {mode}")
