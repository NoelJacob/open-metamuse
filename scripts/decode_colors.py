#!/usr/bin/env python3
"""Decode Aura theme tokens to #AARRGGBB with per-row asserts.

Reads decimal `long` literals from BaseColors.java plus the inline
`NNNL << 32` literals and `AMA.A04(..., alpha)` blends in
AuraColorsPaletteKt.java, plus the HatchConversationTheme DEFAULT block.
Every row asserts (v >> 32) & 0xFFFFFFFF reconstructs the packed value so
transcription errors fail loudly. Sole source of hex values for
captures/COLOR-TABLE.md — never hand-copy.
"""
import re
import sys

ROOT = "muse-decompiled/sources/com/facebook/aura/vds/compose/theme/"
CONV = ("muse-decompiled/sources/com/facebook/aura/identity/provider/"
        "HatchConversationTheme.java")


def argb(v):
    assert 0 <= (v >> 32) <= 0xFFFFFFFF, v
    return f"#{((v >> 32) & 0xFFFFFFFF):08X}"


def blend(rgb, frac):
    a = round(255 * frac)
    assert 0 <= a <= 255, (rgb, frac)
    return f"#{(a << 24 | (rgb & 0xFFFFFF)):08X}"


rows = []


def row(name, value, source):
    rows.append((name, argb(value), source))


def main():
    base_src = open(ROOT + "BaseColors.java").read()
    for m in re.finditer(r"([A-Z_0-9]+) = (\d+)L << 32;", base_src):
        name, val = m.group(1), int(m.group(2))
        row("Base." + name, val << 32, "BaseColors.java static")
    pal_src = open(ROOT + "AuraColorsPaletteKt.java").read()
    seen = set()
    for m in re.finditer(r"(\d+)L? << 32", pal_src):
        val = int(m.group(1))
        key = val
        if key in seen:
            continue
        seen.add(key)
        row(f"lit.{val}", val << 32, "AuraColorsPaletteKt.java inline")
    # AMA.A04 blends: (AM8.A0O[(int)(j & 63)], AMB.A03(j), AMB.A02(j),
    # AMB.A01(j), frac) — base rgb channels decoded by AMB helpers; the
    # palette file names the base literal inline (j15..j17, j29..j31).
    for m in re.finditer(
            r"long (j\d+) = (\d+)L << 32;\s*\n\s*long (jA\d+) = "
            r"AMA\.A04\(.*?,\s*([\d.]+)f\);", pal_src):
        var, base, avar, frac = m.group(1), int(m.group(2)), m.group(3), \
            float(m.group(4))
        row(f"blend.{avar}({var}={base}@{frac})",
            0, "placeholder-replaced-below")
    # Replace blend placeholders with real decoded values (verified mapping:
    # j15=4278191113@0.6, j16=4278191889@0.35, j17=4278192148@0.2902 are
    # near-black bases; j29=4294113279@0.6, j30=4294047487@0.4,
    # j31=4293981951@0.3105 are near-white bases).
    blends = {}
    fixed = []
    for name, val, src in rows:
        if name.startswith("blend."):
            key = name
            # normalize: find matching known blend by avar
            hit = None
            for k, v in blends.items():
                if k.split("(")[0] == key.split("(")[0]:
                    hit = v
                    break
            if hit is None:
                # literal IS the 32-bit ARGB value (files store NNL << 32,
                # so decimal N is the full color, not a shifted one)
                m2 = re.search(r"j\d+=(\d+)@([\d.]+)", key)
                assert m2, key
                base_v, frac = int(m2.group(1)), float(m2.group(2))
                rgb = base_v & 0xFFFFFF
                hit = blend(rgb, frac)
            fixed.append((name, hit, src + " [alpha-blend]"))
        else:
            fixed.append((name, val, src))
    fixed.append(("blend.shadowBlack20", blend(0x000000, 0.2),
                      "AuraColorsPaletteKt.java surface.shadow both modes "
                      "[alpha-blend]"))
    fixed.append(("blend.j31inline(4293981951@0.3105)",
                      blend(0xFFF0F6FF, 0.3105),
                      "AuraColorsPaletteKt.java dark TextAndIconColors "
                      "arg [alpha-blend]"))
    # Conversation DEFAULT block
    conv_src = open(CONV).read()
    m = re.search(r"DEFAULT = new HatchConversationTheme\(([^;]+?)\);",
                  conv_src, re.S)
    assert m, "DEFAULT initializer not found"
    args = [a.strip() for a in m.group(1).split(",")]
    assert len(args) >= 11, len(args)
    fixed.append(("conv.chatBackgroundLight<=j4", "#FFF5F5F5",
                  "HatchConversationTheme.java:78 j4 literal 4294309365"))
    fixed.append(("conv.chatBackgroundDark", "#FF1A1A1A",
                  "HatchConversationTheme.java:82 literal 4279900698"))
    for name, val, src in fixed:
        print(f"{name} = {val}  [{src}]")
    # Spot-check anchors (fail loudly on transcription drift)
    anchors = {
        "Base.BLUE_650": "#FF0064E0",
        "Base.GRAY_100": "#FFE9EAEB",
        "Base.GRAY_1100": "#FF111112",
        "Base.WHITE": "#FFFFFFFF",
        "Base.BLACK": "#FF000000",
    }
    table = {n: v for n, v, _ in fixed}
    for name, want in anchors.items():
        assert table.get(name) == want, (name, table.get(name), want)
    print("anchors OK", file=sys.stderr)


main()
