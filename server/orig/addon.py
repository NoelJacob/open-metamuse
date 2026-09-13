"""orig Muse intercept addon: log everything, stub only known auth paths.

Pass-through by default so crash-reporting/config reach the real upstream;
the emulator trusts the mitmproxy CA, so TLS just works. Stubs answer the
exact wire shapes the decompiled login flow requires (see AuthWire recon).
"""

import json
import logging

from mitmproxy.http import Response

log = logging.getLogger("orig-addon")
_seen = {}
_tos_accepted = False

# ponytail: demo threads/chats served to the patched app over Jarvis HTTPS.
_TS = 1757300000000
_DEMO_THREADS = [
    {"session_id": "t1", "title": "Paris weekend",
     "snippet": "Day 1: Louvre, Seine cruise…", "channel": "main",
     "created_at_ms": _TS, "updated_at_ms": _TS + 400000,
     "unread_count": 0, "archived": False, "is_pinned": False,
     "pinned": False, "is_primary": True, "is_thread": True, "status": "active"},
    {"session_id": "t2", "title": "Sourdough recipe",
     "snippet": "500g flour, 375g water…", "channel": "main",
     "created_at_ms": _TS - 86400000, "updated_at_ms": _TS - 3600000,
     "unread_count": 0, "archived": False, "is_pinned": False,
     "pinned": False, "is_primary": False, "is_thread": True, "status": "active"},
]
_DEMO_EVENTS = [
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
_fetch_count = 0
_IMG_EVENT = {
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
_REPLY_EVENT = {
    "event_name": "message.assistant", "message_id": "m-reply-1",
    "reply_to_message_id": "m3", "stream_lane": "main",
    "occurred_at_ms": _TS + 250000, "seq": 5,
    "payload": {"content": "Glad you like it! Anything else I can plan for you?"},
}


def _bytes(flow, data, ctype="image/jpeg"):
    flow.response = Response.make(200, data, {"Content-Type": ctype})


def _demo_bytes():
    try:
        with open("/home/noel/Dev/open-metamuse/server/orig/demo.jpg",
                  "rb") as f:
            return f.read()
    except OSError:
        return b"\xff\xd8\xff\xe0" + bytes(1024)


def _log(flow, note=""):
    key = f"{flow.request.method} {flow.request.pretty_host}{flow.request.path}"
    _seen[key] = _seen.get(key, 0) + 1
    if _seen[key] <= 3:  # keep the log readable; full dump via mitmweb if needed
        log.warning("FLOW %s %s", key, note)


def _json(flow, obj, status=200):
    flow.response = Response.make(
        status, json.dumps(obj), {"Content-Type": "application/json"}
    )


def request(flow):
    global _tos_accepted
    host = flow.request.pretty_host
    path = flow.request.path.split("?")[0]
    if path.endswith("/api/session/list"):
        view = "archived" if "archived" in flow.request.path else "active"
        _log(flow, "STUB jarvis-list")
        sessions = _DEMO_THREADS if view == "active" else []
        _json(flow, {"result": {"sessions": sessions, "archived": view == "archived"},
                     "sessions": sessions, "archived": view == "archived"})
        return
    if path.endswith("/chat/history"):
        global _fetch_count
        _fetch_count += 1
        events = list(_DEMO_EVENTS)
        if _fetch_count > 1:
            events = events + [_REPLY_EVENT, _IMG_EVENT]
        _log(flow, f"STUB jarvis-history n={_fetch_count}")
        _json(flow, {"result": {"chat_events": events, "has_more": False},
                     "has_more": False, "chat_events": events})
        return
    if path.endswith("/fs/upload"):
        _log(flow, "STUB fs-upload")
        _json(flow, {"ok": True,
                     "path": "workspace/user/files/demo_0_ab12.jpg",
                     "bytes_written": len(_demo_bytes())})
        return
    if "/fs/thumbnail/" in path or "/fs/raw/" in path:
        _log(flow, "STUB fs-bytes")
        _bytes(flow, _demo_bytes())
        return
    if path.endswith("/api/chat/unread-count"):
        _log(flow, "STUB jarvis-unread")
        _json(flow, {"result": {"has_unread_threads": False},
                     "has_unread_threads": False})
        return
    blocked = host.endswith(("meta.ai", "meta.com", "facebook.com", "fbcdn.net"))
    if blocked:
        _log(flow)
        if path == "/graphql" and flow.request.content:
            try:
                log.warning("GQL %s", flow.request.content[:400].decode("utf-8", "replace"))
            except Exception:
                pass
    if flow.request.method == "POST" and path == "/graphql":
        _log(flow, "STUB graphql")
        _json(flow, {"data": {}})
        return
    if flow.request.method == "GET":
        if path == "/hatch/activation_statuses":
            _log(flow, "STUB activation")
            _json(flow, {
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
            _log(flow, "STUB profile")
            _json(flow, {
                "name": "Muse User",
                "username": "muse.user",
                "profile_picture_url": "",
            })
        elif path == "/hatch/tos_status":
            _log(flow, "STUB tos")
            _json(flow, {"has_accepted_tos": _tos_accepted})
        elif path == "/hatch/fetch_vms":
            _log(flow, "STUB vms-probe")
            _json(flow, {"vm_list": [{
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
    if flow.request.method != "POST" and (flow.response is not None or not blocked):
        return
    if path == "/hatch/auth/start":
        _log(flow, "STUB start")
        _json(flow, {"access_token": "tmp_stub1", "id_for_aymh": "aymh_stub1"})
    elif path == "/hatch/auth/send_otp":
        _log(flow, "STUB send_otp")
        _json(flow, {
            "registration_state": "r",
            "auth_state": "st_stub1",
            "password_login_available": False,
        })
    elif path == "/hatch/auth/confirm_otp":
        _log(flow, "STUB confirm_otp")
        _json(flow, {
            "abra_access_token": "abra_stub",
            "abra_user_id": "1000001",
            "frl_access_token": "frl_stub",
            "frl_account_id": "1000001",
            "account_selection_required": False,
            "two_factor_required": False,
            "checkpoint_required": False,
        })
    elif path == "/hatch/login":
        _log(flow, "STUB login-xchg")
        _json(flow, {
            "access_token": "abra_stub",
            "abra_user_id": "1000001",
            "user_id": "1000001",
        })
    elif path == "/hatch/accept_tos":
        _log(flow, "STUB accept-tos")
        _tos_accepted = True
        _json(flow, {"ok": True})
        return
    if blocked and flow.response is None:
        _log(flow, "STUB generic-blocked")
        if flow.request.method == "GET":
            _json(flow, {})
        else:
            _json(flow, {"ok": True})
