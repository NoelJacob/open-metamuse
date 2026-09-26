#!/usr/bin/env python3
"""Convert decompiled Android drawables into browsable SVGs.

Usage:
    python3 scripts/extract_icons.py <out_dir> [--source res_dir] [--filter substr]

Walks every ``drawable*`` directory under ``--source`` (default
``muse-decompiled/resources/res``), converts Android VectorDrawable XML to SVG,
converts simple <shape> drawables, and copies raster images verbatim. Writes
``<out_dir>/MANIFEST.md`` accounting for every file seen, including the ones
skipped. Never writes to assets/.
"""
import argparse
import re
import shutil
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ANDROID = "{http://schemas.android.com/apk/res/android}"
RASTER = {".png", ".webp", ".jpg", ".jpeg", ".gif"}
# jadx appends the resource id in either order: "x_0x7f080000_res" or
# "x_0_res_0x7f080000". Strip both so the output folder reads cleanly.
RES_SUFFIX = re.compile(r"(_0x[0-9a-fA-F]+_res|_res_0x[0-9a-fA-F]+)$")
DOUBLE_UNDERSCORE = re.compile(r"__+")


def a(elem, name, default=None):
    """Read an android-namespaced attribute."""
    v = elem.get(ANDROID + name)
    return default if v is None else v


def num(value, default=0.0):
    """Parse a float out of '24dp' / '1.5' / '-2'."""
    if value is None:
        return default
    m = re.match(r"\s*(-?\d+(?:\.\d+)?)", str(value))
    return float(m.group(1)) if m else default


def color(value, unresolved):
    """Map a drawable color to an SVG color string.

    Returns the literal "none" as a *sentinel* meaning "emit no colour
    attribute at all", so the SVG inherits its default and Flutter can tint
    the whole icon with a single ColorFilter. Black and white both map to
    that sentinel for exactly this reason. Unresolvable refs (@drawable
    gradients, unknown themes) also become the sentinel and are reported.
    """
    if value is None:
        return "none"
    v = value.strip()
    named = {
        "@android:color/black": "#000000",
        "@android:color/white": "#FFFFFF",
        "@android:color/transparent": None,
    }
    if v in named:
        v = named[v]
        if v is None:
            return "none"
    if v.startswith("#"):
        if len(v) not in (4, 7, 9):
            return "none"
        body = v[1:].lower()
        if body in ("000", "000000", "00000000", "fff", "ffffff",
                    "ffffffff"):
            return "none"  # black/white: leave untinted for Flutter
        return v
    unresolved.add(value.strip())
    return "none"


def escape(text):
    return (text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
            .replace('"', "&quot;"))


def normalize_name(stem):
    """jadx appends _0x7f080000_res; strip it and collapse __ runs."""
    name = RES_SUFFIX.sub("", stem).strip("_")
    name = DOUBLE_UNDERSCORE.sub("_", name)
    return name or stem



def path_attrs(elem, unresolved):
    """Build SVG presentation attributes for one <path>, faithful to source.

    ``color()`` returns the "none" sentinel for black/white, in which case no
    attribute is emitted at all so Flutter can tint the icon uniformly.
    """
    out = []
    fill = color(a(elem, "fillColor"), unresolved)
    if fill != "none":
        out.append(f'fill="{escape(fill)}"')
    alpha = a(elem, "fillAlpha")
    if alpha is not None:
        out.append(f'fill-opacity="{num(alpha, 1.0)}"')
    stroke = color(a(elem, "strokeColor"), unresolved)
    if stroke != "none":
        out.append(f'stroke="{escape(stroke)}"')
        width = a(elem, "strokeWidth")
        if width is not None:
            out.append(f'stroke-width="{num(width)}"')
    if a(elem, "strokeLineCap"):
        out.append(f'stroke-linecap="{a(elem, "strokeLineCap")}"')
    if a(elem, "strokeLineJoin"):
        out.append(f'stroke-linejoin="{a(elem, "strokeLineJoin")}"')
    if a(elem, "fillType") == "evenOdd":
        out.append('fill-rule="evenodd"')
    if a(elem, "autoMirrored") == "true":
        out.append(f'transform="scale(-1,1) translate(-{_viewport[0]},0)"')
    return " ".join(out)


_viewport = [24.0, 24.0]


def group_transform(elem):
    """translate/scale/rotate from a <group>, honouring the pivot.

    Android scales and rotates *around* pivotX/pivotY, so a plain
    ``scale(sx sy)`` would push content off-canvas. Wrap it as
    translate(p) scale(s) translate(-p).
    """
    parts = []
    tx, ty = num(a(elem, "translateX")), num(a(elem, "translateY"))
    if tx or ty:
        parts.append(f"translate({tx} {ty})")
    px, py = num(a(elem, "pivotX")), num(a(elem, "pivotY"))
    sx, sy = num(a(elem, "scaleX"), 1.0), num(a(elem, "scaleY"), 1.0)
    if sx != 1.0 or sy != 1.0:
        if px or py:
            parts.append(f"translate({px} {py})")
        parts.append(f"scale({sx} {sy})")
        if px or py:
            parts.append(f"translate({-px} {-py})")
    rot = num(a(elem, "rotation"))
    if rot:
        parts.append(f"rotate({rot} {px} {py})")
    return " ".join(parts)


def convert_vector(root, unresolved):
    """Render a <vector> drawable to SVG text, faithful to the source."""
    global _viewport
    vw = num(a(root, "viewportWidth"), 0) or num(
        a(root, "width"), 24.0)
    vh = num(a(root, "viewportHeight"), 0) or num(
        a(root, "height"), 24.0)
    _viewport = [vw, vh]

    def fmt(v):
        return str(int(v)) if float(v).is_integer() else str(v)
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {fmt(vw)} '
           f'{fmt(vh)}" width="{fmt(vw)}" height="{fmt(vh)}">']
    out.extend(_render_children(root, unresolved, 1))
    out.append("</svg>")
    return "\n".join(out), vw, vh


def _render_children(node, unresolved, depth):
    """Emit <g>/<path> for a vector body, honoring groups and clip paths."""
    lines = []
    clips = []
    for child in node:
        tag = child.tag
        if tag == "path":
            data = a(child, "pathData")
            if not data:
                continue
            attrs = path_attrs(child, unresolved)
            lines.append(f'  <path d="{escape(data)}" {attrs}/>')
        elif tag == "group":
            transform = group_transform(child)
            clip = next((c for c in child if c.tag == "clip-path"), None)
            inner = _render_children(child, unresolved, depth + 1)
            if not inner:
                continue
            clip_attr = ""
            if clip is not None:
                data = a(clip, "pathData")
                if data:
                    cid = f"clip{len(clips)}"
                    clips.append(f'<clipPath id="{cid}">'
                                 f'<path d="{escape(data)}"/></clipPath>')
                    clip_attr = f' clip-path="url(#{cid})"'
            body = inner
            if transform or clip_attr:
                lines.append(f'{"  " * depth}<g'
                             + (f' transform="{escape(transform)}"'
                                if transform else "")
                             + clip_attr + ">")
                for ln in body:
                    lines.append("  " + ln)
                lines.append(f'{"  " * depth}</g>')
            else:
                lines.extend(body)
    return clips + lines if depth == 1 else lines


def gradient_defs(root, unresolved):
    """<linearGradient> from a <gradient> element; returns (defs, fill)."""
    stops = [c for c in root if c.tag == "item"]
    if not stops:
        return "", None
    parts = []
    for s in stops:
        c = color(a(s, "color"), unresolved)
        off = num(a(s, "offset"), 0.0)
        parts.append(f'<stop offset="{off}" stop-color="{escape(c)}"/>')
    return f'<defs><linearGradient id="grad">{"".join(parts)}'\
           f"</linearGradient></defs>", "url(#grad)"


def convert_shape(root, unresolved):
    """Render a simple <shape> drawable to SVG text."""
    kind = a(root, "shape", "rectangle")
    left, top = num(a(root, "left"), 0.0), num(a(root, "top"), 0.0)
    right, bottom = num(a(root, "right"), 24.0), num(a(root, "bottom"), 24.0)
    w, h = right - left, bottom - top
    defs, grad = gradient_defs(root, unresolved)
    fill = grad
    for child in root:
        if child.tag == "solid":
            fill = color(a(child, "color"), unresolved)
        elif child.tag == "gradient":
            _, fill = gradient_defs(child, unresolved)
    if fill is None:
        fill = "none"
    stroke = "none"
    sw = 0.0
    for child in root:
        if child.tag == "stroke":
            stroke = color(a(child, "color"), unresolved)
            sw = num(a(child, "width"), 1.0)
    radius = 0.0
    for child in root:
        if child.tag == "corners":
            radius = num(a(child, "radius"), 0.0)
    if kind == "oval":
        body = (f'<ellipse cx="{left + w / 2}" cy="{top + h / 2}" '
                f'rx="{w / 2}" ry="{h / 2}" fill="{escape(fill)}"')
    elif kind == "line":
        body = (f'<line x1="{left}" y1="{top}" x2="{right}" y2="{bottom}" '
                f'stroke="{escape(stroke)}" stroke-width="{sw}"')
    else:
        body = (f'<rect x="{left}" y="{top}" width="{w}" height="{h}" '
                f'rx="{radius}" fill="{escape(fill)}"')
    if stroke != "none" and kind != "line":
        body += f' stroke="{escape(stroke)}" stroke-width="{sw}"'
    body += "/>"
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 '
           f'{max(right, 24)} {max(bottom, 24)}" width="{max(right, 24)}" '
           f'height="{max(bottom, 24)}">{defs}{body}</svg>')
    return svg, max(right, 24), max(bottom, 24)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("out_dir")
    ap.add_argument("--source", default="muse-decompiled/resources/res")
    ap.add_argument("--filter", default=None,
                    help="only convert sources whose name contains this")
    args = ap.parse_args()

    src = Path(args.source)
    out = Path(args.out_dir)
    if not src.is_dir():
        print(f"source not found: {src}", file=sys.stderr)
        raise SystemExit(1)
    (out / "raster").mkdir(parents=True, exist_ok=True)

    rows, skipped = [], []
    counts = {"vector": 0, "shape": 0, "raster": 0, "skipped": 0}
    used = {}

    def unique(name, ext):
        n = name
        i = 2
        while (out / f"{n}{ext}").exists() or n in used:
            n = f"{name}_{i}"
            i += 1
        used[n] = True
        return n

    files = []
    for d in sorted(src.glob("drawable*")):
        if d.is_dir():
            files.extend(sorted(p for p in d.iterdir() if p.is_file()))

    for path in files:
        if args.filter and args.filter not in path.name:
            continue
        name = normalize_name(path.stem)
        if path.suffix.lower() in RASTER:
            dest = out / "raster" / f"{name}{path.suffix.lower()}"
            shutil.copy2(path, dest)
            counts["raster"] += 1
            rows.append((name, "raster", f"raster/{dest.name}", "-", "-"))
            continue
        if path.suffix.lower() != ".xml":
            skipped.append((name, f"unsupported extension {path.suffix}"))
            counts["skipped"] += 1
            continue
        try:
            root = ET.parse(path).getroot()
        except ET.ParseError as e:
            skipped.append((name, f"xml parse error: {e}"))
            counts["skipped"] += 1
            continue
        tag = root.tag
        unresolved = set()
        if tag == "vector":
            svg, vw, vh = convert_vector(root, unresolved)
            kind, npaths = "vector", svg.count("<path")
        elif tag == "shape":
            svg, vw, vh = convert_shape(root, unresolved)
            kind, npaths = "shape", 1
        elif tag == "bitmap":
            ref = (a(root, "src") or "").split("/")[-1]
            skipped.append((name, f"bitmap wrapper -> {ref or 'unknown'}"))
            counts["skipped"] += 1
            continue
        else:
            skipped.append((name, f"<{tag}> not convertible"))
            counts["skipped"] += 1
            continue
        final = unique(name, ".svg")
        (out / f"{final}.svg").write_text(svg + "\n")
        counts[kind] += 1
        row_kind = "unresolved" if unresolved else kind
        rows.append((final, row_kind, f"{final}.svg", f"{vw:g}x{vh:g}",
                     str(npaths)))
        if unresolved:
            rows[-1] = (final, row_kind, f"{final}.svg", f"{vw:g}x{vh:g}",
                        f"{npaths} ({','.join(sorted(unresolved))})")

    manifest = ["# Icon extraction manifest", "",
                f"source: `{src}`", f"output: `{out}`", "",
                f"{counts['vector']} vector, {counts['shape']} shape, "
                f"{counts['raster']} raster, {counts['skipped']} skipped", "",
                "| name | kind | output | viewport | paths |",
                "|---|---|---|---|---|"]
    for r in rows:
        manifest.append("| " + " | ".join(r) + " |")
    if skipped:
        manifest += ["", "## Skipped", ""]
        manifest += [f"- `{n}` — {why}" for n, why in sorted(skipped)]
    (out / "MANIFEST.md").write_text("\n".join(manifest) + "\n")

    print(f"{counts['vector']} vector, {counts['shape']} shape, "
          f"{counts['raster']} raster, {counts['skipped']} skipped")
    print(f"wrote {len(rows)} entries to {out / 'MANIFEST.md'}")
    if not rows:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
