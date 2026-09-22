#!/usr/bin/env python3
"""Row-by-row bubble profiler for Muse parity.

Scans a screenshot for horizontal runs of dark (user) and grey (agent) bubble
pixels, prints absolute y-ranges so two builds can be compared row by row.

Usage: rows.py <image.png> [x0 x1]
"""
import subprocess
import sys
import tempfile
import os


def gray_pgm(img, x0, y0, x1, y1):
    out = tempfile.mktemp(suffix=".pgm")
    subprocess.run([
        "magick", img, "-crop", f"{x1 - x0}x{y1 - y0}+{x0}+{y0}", "+repage",
        "-colorspace", "Gray", out,
    ], check=True)
    return out


def load_pgm(p):
    with open(p, "rb") as f:
        f.readline()
        wh = f.readline()
        while wh.startswith(b"#"):
            wh = f.readline()
        w, h = map(int, wh.split())
        f.readline()
        return w, h, f.read()


def runs(rows, w, xa, xb, lo, hi, min_h):
    """Rows where the count of pixels in [lo,hi) exceeds half the span."""
    out = []
    start = None
    need = (xb - xa) // 3
    for y in range(len(rows) // w):
        cnt = 0
        base = y * w
        for x in range(xa, min(xb, w)):
            v = rows[base + x]
            if lo <= v <= hi:
                cnt += 1
        hit = cnt > need
        if hit and start is None:
            start = y
        elif not hit and start is not None:
            if y - start >= min_h:
                out.append((start, y - 1))
            start = None
    if start is not None and len(rows) - start >= min_h:
        out.append((start, len(rows) - 1))
    return out


def main():
    img = sys.argv[1]
    y0, y1 = 300, 2300
    xa, xb = 700, 1000  # right zone: user bubbles only
    p = gray_pgm(img, 0, y0, 1080, y1)
    w, h, data = load_pgm(p)
    os.unlink(p)
    dark = runs(data, w, xa, xb, 0, 60, 20)
    print(f"{img}: user-bubble runs (absolute y)")
    for a, b in dark:
        print(f"  {a + y0}-{b + y0}  h={b - a + 1}")


if __name__ == "__main__":
    main()
