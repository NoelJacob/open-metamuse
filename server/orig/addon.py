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
    host = flow.request.pretty_host or ""
    if "auth.meta.com" in host or "facebook.com" in host:
        return
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
    if path.endswith("/api/feed/units"):
        _log(flow, "STUB feed-units")
        units = [
            {"id": "f1", "kind": "suggestion", "title": "Good morning!",
             "subtitle": "Things to try today"},
            {"id": "f2", "kind": "reminder", "title": "Weekend getaway",
             "subtitle": "Don't forget your plans"},
            {"id": "f3", "kind": "tip", "title": "Try voice chat",
             "subtitle": "Ask me anything"},
            {"id": "f4", "kind": "news", "title": "Fresh updates",
             "subtitle": "Fresh updates for you"},
        ]
        _json(flow, {"result": {"units": units}, "units": units})
        return
    if path.endswith("/api/goals/list"):
        _log(flow, "STUB goals-list")
        goals = [
            {"id": "g1", "title": "Plan weekend trip",
             "status": "active", "progress": 0.4},
            {"id": "g2", "title": "Learn sourdough",
             "status": "active", "progress": 0.1},
        ]
        _json(flow, {"result": {"goals": goals}, "goals": goals})
        return
    if "/api/goals/" in path and path.endswith("/detail"):
        _log(flow, "STUB goals-detail")
        _json(flow, {"result": {"goal": {"id": "g1",
                     "title": "Plan weekend trip", "status": "active",
                     "progress": 0.4,
                     "steps": ["Pick dates", "Book stay"]}},
                     "goal": {"id": "g1"}})
        return
    if path.endswith("/api/library/artifacts"):
        _log(flow, "STUB library-artifacts")
        items = [{"id": "a1", "title": "Weekend plan",
                  "kind": "document"}]
        _json(flow, {"result": {"items": items}, "items": items})
        return
    if path.endswith("/api/library/media"):
        _log(flow, "STUB library-media")
        items = [{"id": "d1", "kind": "image", "label": "demo.jpg",
                  "path": "workspace/user/files/demo_0_ab12.jpg"}]
        _json(flow, {"result": {"items": items}, "items": items})
        return
    if path.endswith("/api/spaces/list"):
        _log(flow, "STUB spaces-list")
        spaces = [{"id": "s1", "title": "Trip planning",
                   "member_count": 2}]
        _json(flow, {"result": {"spaces": spaces}, "spaces": spaces})
        return
    if path.endswith("/api/memory/list"):
        _log(flow, "STUB memory-list")
        mem = [{"id": "mem1", "title": "Weekend trip",
                "snippet": "Paris, 2 days"}]
        _json(flow, {"result": {"entries": mem}, "entries": mem})
        return
    if path.endswith("/api/connectors/list"):
        _log(flow, "STUB connectors-list")
        conns = [
            {"id": "whatsapp", "name": "WhatsApp", "linked": False},
            {"id": "telegram", "name": "Telegram", "linked": False},
            {"id": "messenger", "name": "Messenger", "linked": False},
        ]
        _json(flow, {"result": {"connectors": conns}, "connectors": conns})
        return
    if path.endswith("/api/subscription"):
        _log(flow, "STUB subscription")
        _json(flow, {"result": {"plan": "free", "credits": 100},
                     "plan": "free", "credits": 100})
        return
    if path.endswith("/api/settings/notifications"):
        _log(flow, "STUB notif-settings")
        _json(flow, {"result": {"enabled": True}, "enabled": True})
        return
    if path.endswith("/api/settings/data-controls"):
        _log(flow, "STUB data-controls")
        _json(flow, {"result": {"improve_models": False},
                     "improve_models": False})
        return
    if path.endswith("/api/search"):
        _log(flow, "STUB search")
        q = flow.request.query.decode("utf-8", "replace") if hasattr(
            flow.request, "query") else ""
        _json(flow, {"result": {"results": [
            {"id": "t1", "title": "Paris weekend", "snippet": q}]},
            "results": []})
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
            _json(flow, {
                "has_accepted_tos": _tos_accepted,
                # ponytail: full disclosure per TosStatusResponseJson; stub
                # copy (offline fixture) — accept must echo text+version.
                "disclosure_title": "Terms of Service (stub)",
                "disclosure_text": "Stub terms for offline testing.",
                "disclosure_version": "stub-v1",
                "disclosure_button_text": "Continue",
                "disclosure_entities": [],
                "disclosure_sections": [],
            })
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
        _json(flow, {
            "ok": True,
            "has_accepted_tos": True,
            "disclosure_version": "stub-v1",
        })
        return
    if blocked and flow.response is None:
        _log(flow, "STUB generic-blocked")
        if flow.request.method == "GET":
            _json(flow, {})
        else:
            _json(flow, {"ok": True})
