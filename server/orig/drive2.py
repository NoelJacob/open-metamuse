#!/usr/bin/env python3
"""Shared UI driver for BOTH Muse apps on Pixel_9 (emulator-5554).

Same text-anchored primitives work unchanged on either app; only the
package and the funnel steps differ. Stateful: keeps last screenshot,
dump cache, and per-run log under /tmp/drive2/.

Usage:
  python3 drive2.py --app orig|ours <scenario> [args]
Scenarios:
  to_otp <email>     land on OTP screen (both apps)
  submit_otp <code>  type code digits via keyevents (both apps)
  shot <path>        screenshot to path
  dump               print text nodes with bounds
  tap_text <text>    wait-for + tap a text node
  funnel_ours        full ours-app funnel to main chat
"""
import argparse
import os
import re
import subprocess
import sys
import time

DEV = "emulator-5554"
PKGS = {"orig": "com.facebook.aura",
        "ours": "com.noeljacob.metamuse.openmetamuse"}
OUT = "/tmp/drive2"
os.makedirs(OUT, exist_ok=True)


def adb(*args, timeout=30):
    r = subprocess.run(["adb", "-s", DEV, *args],
                       capture_output=True, text=True, timeout=timeout)
    return r.stdout.strip()


def log(msg):
    line = f"[{time.strftime('%H:%M:%S')}] {msg}"
    print(line, flush=True)
    with open(f"{OUT}/run.log", "a") as f:
        f.write(line + "\n")


def dump():
    adb("shell", "uiautomator", "dump", "--compressed", "/sdcard/ui_d2.xml")
    out = adb("shell", "cat", "/sdcard/ui_d2.xml", timeout=60)
    nodes = []
    for m in re.finditer(r"<node[^>]*>", out):
        t = m.group(0)
        cls = re.search(r'class="([^"]+)"', t)
        txt = re.search(r'text="([^"]*)"', t)
        desc = re.search(r'content-desc="([^"]*)"', t)
        hint = re.search(r'hint="([^"]*)"', t)
        b = re.search(r'bounds="([^"]+)"', t)
        label = (txt.group(1) if txt and txt.group(1) else "") or \
                (hint.group(1) if hint and hint.group(1) else "") or \
                (desc.group(1) if desc and desc.group(1) else "")
        nodes.append({
            "cls": (cls.group(1).split(".")[-1] if cls else ""),
            "text": label,
            "desc": desc.group(1) if desc else "",
            "bounds": b.group(1) if b else "",
        })
    return nodes


def find_text(s, timeout=60):
    t0 = time.time()
    while time.time() - t0 < timeout:
        try:
            for n in dump():
                if s in (n["text"] + n["desc"]):
                    return n
        except Exception:
            pass
        time.sleep(2)
    raise TimeoutError(f"no node containing {s!r}")


def tap(x, y):
    adb("shell", "input", "tap", str(x), str(y))


def center(bounds):
    m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", bounds)
    x1, y1, x2, y2 = map(int, m.groups())
    return (x1 + x2) // 2, (y1 + y2) // 2


def tap_text(s, timeout=60):
    n = find_text(s, timeout)
    x, y = center(n["bounds"])
    tap(x, y)
    return n


def tap_field(timeout=60):
    """Tap center of first EditText (labels don't always focus fields)."""
    t0 = time.time()
    while time.time() - t0 < timeout:
        for n in dump():
            if n["cls"] == "EditText" and n["bounds"]:
                x, y = center(n["bounds"])
                tap(x, y)
                return n
        time.sleep(2)
    raise TimeoutError("no EditText found")

def cold_start(pkg):
    adb("shell", "am", "force-stop", pkg)
    time.sleep(1)
    adb("shell", "monkey", "-p", pkg, "-c",
        "android.intent.category.LAUNCHER", "1")
    t0 = time.time()
    while time.time() - t0 < 60:
        f = adb("shell", "dumpsys", "window", timeout=15)
        m = re.search(r"mCurrentFocus=Window\{[^ ]+ \S+ (\S+)/", f)
        if m and pkg in m.group(1):
            return True
        time.sleep(2)
    raise TimeoutError(f"{pkg} never focused")


def type_text(s):
    adb("shell", "input", "text", s.replace(" ", "%s"))


def keyevent(code):
    adb("shell", "input", "keyevent", code)


def shot(path):
    with open(path, "wb") as f:
        subprocess.run(["adb", "-s", DEV, "exec-out", "screencap", "-p"],
                       stdout=f, timeout=60)
    log(f"shot {path}")



def to_otp(pkg, email="test@example.com"):
    cold_start(pkg)
    tap_text("Mobile number or email", timeout=90)
    time.sleep(1)
    type_text(email)
    tap_text("Continue", timeout=30)
    find_text("Enter your code", timeout=60)
    log("at OTP screen")


def submit_otp(code="123456"):
    for ch in code:
        keyevent(f"KEYCODE_{ch}")
        time.sleep(1.5)
    log(f"typed {code}")


def measure(keys, path=f"{OUT}/measure.txt"):
    """Dump bounds of nodes matching keys; append to measure file."""
    with open(path, "a") as f:
        for n in dump():
            label = n["text"] or n["desc"]
            if label and any(k in label for k in keys):
                f.write(f"{n['cls']} | {label[:40]} | {n['bounds']}\n")
    log(f"measured {keys} -> {path}")


def funnel_ours(email="test@example.com"):
    """Ours-app funnel: landing -> OTP -> accounts -> connectors ->
    identity -> PIN -> ToS -> main. Ends on main chat."""
    pkg = PKGS["ours"]
    to_otp(pkg, email)
    submit_otp("123456")
    tap_text("Muse User", timeout=60)
    tap_text("Continue", timeout=60)
    tap_text("What should Muse call you?", timeout=60)
    tap_field(timeout=30)
    time.sleep(1)
    type_text("Noel")
    tap_text("Continue", timeout=30)
    tap_text("Set a 4-digit PIN", timeout=60)
    tap_field(timeout=30)
    time.sleep(1)
    type_text("1111")
    tap_text("Before you get started", timeout=60)
    tap_text("Continue", timeout=60)
    time.sleep(3)
    log("funnel complete (main expected)")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--app", default="orig", choices=PKGS)
    ap.add_argument("scenario")
    ap.add_argument("args", nargs="*")
    a = ap.parse_args()
    pkg = PKGS[a.app]
    if a.scenario == "to_otp":
        to_otp(pkg, *(a.args or ["test@example.com"]))
    elif a.scenario == "submit_otp":
        submit_otp(*(a.args or ["123456"]))
    elif a.scenario == "shot":
        shot(a.args[0] if a.args else f"{OUT}/shot.png")
    elif a.scenario == "dump":
        for n in dump():
            label = n["text"] or n["desc"]
            if label:
                print(f"{n['cls']} | {label[:40]} | {n['bounds']}")
    elif a.scenario == "tap_text":
        tap_text(" ".join(a.args))
    elif a.scenario == "measure":
        measure(a.args)
    elif a.scenario == "funnel_ours":
        funnel_ours()
    elif a.scenario == "cold":
        cold_start(pkg)
    else:
        raise SystemExit(f"unknown scenario {a.scenario}")


main()
