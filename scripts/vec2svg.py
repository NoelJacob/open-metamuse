#!/usr/bin/env python3
"""Convert Android vector drawables to SVG.

Handles <vector> with <path> (fillColor, fillType, pathData) and nested
<group> (translate/scale/rotate). Everything else (selectors, shapes,
gradients, layer-lists, theme refs like ?attr/ and @android:color) is
reported and skipped — convert those by hand.

Usage:
  python3 scripts/vec2svg.py <input-dir> <output-dir>
  python3 scripts/vec2svg.py muse-decompiled/resources/res/drawable assets/icons

Fail-hard: non-vector files are listed as skipped, never silently dropped.
"""
import os
import re
import sys
import xml.etree.ElementTree as ET

NS = "{http://schemas.android.com/apk/res/android}"
FILLTYPE = {"evenOdd": "evenodd", "nonZero": "nonzero"}


def color(v):
    if v is None:
        return None
    if v.startswith("?") or (v.startswith("@") and "android:color" in v):
        return None  # theme/system ref — needs a hand-picked value
    m = re.fullmatch(r"#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})", v)
    return v if m else None


def convert(src, dst):
    try:
        root = ET.parse(src).getroot()
    except ET.ParseError as e:
        return f"parse error: {e}"
    if root.tag != "vector":
        return "not a <vector> (selector/shape/gradient — hand-convert)"
    vw = root.get(NS + "viewportWidth", "24")
    vh = root.get(NS + "viewportHeight", "24")
    w = root.get(NS + "width", vw + "dp").rstrip("dp")
    h = root.get(NS + "height", vh + "dp").rstrip("dp")

    out = [f'<svg xmlns="http://www.w3.org/2000/svg" '
           f'width="{w}" height="{h}" viewBox="0 0 {vw} {vh}">']
    skipped = []

    def emit_path(el):
        d = el.get(NS + "pathData")
        if not d:
            return
        fill = color(el.get(NS + "fillColor", "#000000"))
        if fill is None:
            skipped.append(el.get(NS + "fillColor"))
            fill = "#000000"
        ft = FILLTYPE.get(el.get(NS + "fillType", ""), "")
        rule = f' fill-rule="{ft}"' if ft else ""
        stroke = el.get(NS + "strokeColor")
        extra = ""
        if stroke and (sc := color(stroke)):
            extra = (f' stroke="{sc}" stroke-width="'
                     f'{el.get(NS + "strokeWidth", "1")}"')
        out.append(f'<path d="{d}" fill="{fill}"{rule}{extra}/>')

    def walk(el, depth=0):
        for child in el:
            tag = child.tag.split("}")[-1]
            if tag == "path":
                emit_path(child)
            elif tag == "group":
                tx = child.get(NS + "translateX", "0")
                ty = child.get(NS + "translateY", "0")
                sx = child.get(NS + "scaleX", "1")
                sy = child.get(NS + "scaleY", "1")
                rot = child.get(NS + "rotation", "0")
                px = child.get(NS + "pivotX", "0")
                py = child.get(NS + "pivotY", "0")
                parts = []
                if (tx, ty) != ("0", "0"):
                    parts.append(f"translate({tx} {ty})")
                if rot != "0":
                    parts.append(f"rotate({rot} {px} {py})")
                if (sx, sy) != ("1", "1"):
                    parts.append(f"scale({sx} {sy})")
                if parts:
                    out.append(f"<g transform=\"{' '.join(parts)}\">")
                    walk(child, depth + 1)
                    out.append("</g>")
                else:
                    walk(child, depth + 1)
            elif tag == "clip-path":
                skipped.append("clip-path")
            else:
                skipped.append(tag)

    walk(root)
    out.append("</svg>")
    with open(dst, "w") as f:
        f.write("\n".join(out) + "\n")
    if skipped:
        uniq = sorted(set(skipped))
        return f"ok with notes: {uniq}"
    return "ok"


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: vec2svg.py <input-dir> <output-dir>")
    srcdir, dstdir = sys.argv[1], sys.argv[2]
    os.makedirs(dstdir, exist_ok=True)
    done, skipped = 0, []
    for fn in sorted(os.listdir(srcdir)):
        if not fn.endswith(".xml"):
            continue
        name = fn[:-4] + ".svg"
        res = convert(os.path.join(srcdir, fn), os.path.join(dstdir, name))
        if res == "ok":
            done += 1
        else:
            skipped.append(f"{fn}: {res}")
    print(f"converted: {done}")
    for s in skipped:
        print(f"skipped: {s}")


main()
