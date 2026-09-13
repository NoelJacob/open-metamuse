#!/usr/bin/env python3
"""Reusable UI driver for the Pixel_9 emulator (emulator-5554).

Waits on real conditions (uiautomator text, focused package) instead of
blind sleeps, so login/capture runs are repeatable. stdlib only.
Usage: python3 drive.py <scenario>  (scenarios: login, shot)
"""
import re
import subprocess
import sys
import time

DEV = "emulator-5554"
AURA = "com.facebook.aura"


def adb(*args, timeout=30):
    r = subprocess.run(
        ["adb", "-s", DEV, *args],
        capture_output=True, text=True, timeout=timeout)
    return r.stdout.strip()


def dump():
    adb("shell", "uiautomator", "dump", "--compressed", "/sdcard/ui_auto.xml")
    out = adb("shell", "cat", "/sdcard/ui_auto.xml", timeout=60)
    nodes = []
    for m in re.finditer(r"<node[^>]*>", out):
        t = m.group(0)
        cls = re.search(r'class="([^"]+)"', t)
        txt = re.search(r'text="([^"]*)"', t)
        desc = re.search(r'content-desc="([^"]*)"', t)
        b = re.search(r"bounds=\"([^\"]+)\"", t)
        nodes.append({
            "cls": cls.group(1).split(".")[-1] if cls else "",
            "text": txt.group(1) if txt else "",
            "desc": desc.group(1) if desc else "",
            "bounds": b.group(1) if b else "",
        })
    return nodes


def center(bounds):
    m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", bounds)
    x1, y1, x2, y2 = map(int, m.groups())
    return (x1 + x2) // 2, (y1 + y2) // 2


def wait_text(s, timeout=60, package=AURA):
    """Wait until uiautomator shows text s in the target app."""
    t0 = time.time()
    while time.time() - t0 < timeout:
        try:
            for n in dump():
                if s in (n["text"] + n["desc"]):
                    return n
        except Exception:
            pass
        time.sleep(2)
    raise TimeoutError(f"timed out waiting for text: {s!r}")


def wait_focus(package=AURA, timeout=60):
    t0 = time.time()
    while time.time() - t0 < timeout:
        f = adb("shell", "dumpsys", "window", timeout=15)
        m = re.search(r"mCurrentFocus=Window\{[^ ]+ \S+ (\S+)/", f)
        if m and m.group(1) == package:
            return True
        time.sleep(2)
    raise TimeoutError(f"{package} never focused")


def tap(x, y):
    adb("shell", "input", "tap", str(x), str(y))


def tap_node(n):
    x, y = center(n["bounds"])
    tap(x, y)


def tap_text(s, timeout=60):
    tap_node(wait_text(s, timeout))


def type_text(s):
    # escape for `input text` (spaces -> %s)
    adb("shell", "input", "text", s.replace(" ", "%s").replace("&", "\\&"))


def shot(path):
    with open(path, "wb") as f:
        subprocess.run(["adb", "-s", DEV, "exec-out", "screencap", "-p"],
                       stdout=f, timeout=60)
    print("shot", path)


def cold_start():
    adb("shell", "am", "force-stop", AURA)
    time.sleep(1)
    adb("shell", "monkey", "-p", AURA, "-c",
        "android.intent.category.LAUNCHER", "1")
    wait_focus()


def login(email="test@example.com", code="000000"):
    """Full login drive to OTP submit. Returns when OTP screen likely up."""
    cold_start()
    field = wait_text("Mobile number or email", timeout=90)
    tap_node(field)
    time.sleep(1)
    type_text(email)
    tap_text("Continue", timeout=30)
    codebox = wait_text("Enter your code", timeout=60)
    return codebox


def scenario(name):
    if name == "login":
        login()
        shot("/tmp/auto-login.png")
    elif name == "shot":
        shot(sys.argv[2] if len(sys.argv) > 2 else "/tmp/auto-shot.png")
    else:
        raise SystemExit(f"unknown scenario {name}")


if __name__ == "__main__":
    scenario(sys.argv[1] if len(sys.argv) > 1 else "login")
