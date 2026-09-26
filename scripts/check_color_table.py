#!/usr/bin/env python3
"""Gate captures/COLOR-TABLE.md value cells.

Cell grammar: split each Light/Dark cell on `/`; every part must be exactly
`#AARRGGBB` (case-insensitive) or the literal `unverified`. Anything else
(prose, slot names, glosses) fails. Hex parts additionally must appear in
scripts/decode_colors.py output, except allowlisted screenshot-sampled
composites.

Prints `N confirmed cells, M declared-unverified`; exits 1 on any failure.
With `--strict`, also exits 1 when M > 0.
"""
import re
import subprocess
import sys

strict = "--strict" in sys.argv
lines = open("captures/COLOR-TABLE.md").read().split("\n")
bad = []
confirmed = 0
unverified = 0
for i, l in enumerate(lines, 1):
    if not l.startswith("|"):
        continue
    cells = [c.strip() for c in l.split("|")]
    if len(cells) < 5 or cells[2].strip().lower() == "light":
        continue  # header row
    if all(set(c.strip()) <= {"-", " "} for c in cells[2:4]):
        continue  # separator row
    for col in (cells[2], cells[3]):
        for part in [p.strip() for p in col.split("/")]:
            if part == "`unverified`":
                unverified += 1
                continue
            m = re.fullmatch(r"`?#[0-9A-Fa-f]{8}`?", part)
            if not m:
                bad.append(f"{i}: illegal cell part {part!r}")
                continue
            confirmed += 1
dec = subprocess.run(["python3", "scripts/decode_colors.py"],
                     capture_output=True, text=True)
decvals = set(re.findall(r"#[0-9A-Fa-f]{8}", dec.stdout))
allow = {"#5D5E5E", "#5D6063", "#FFFCFCFC", "#FF050505"}
for i, l in enumerate(lines, 1):
    if not l.startswith("|"):
        continue
    cells = [c.strip() for c in l.split("|")]
    if len(cells) < 5 or cells[2].strip().lower() == "light":
        continue
    for col in (cells[2], cells[3]):
        for part in [p.strip() for p in col.split("/")]:
            if part == "`unverified`":
                continue
            for t in re.findall(r"#[0-9A-Fa-f]{8}", part):
                if t.upper() not in {d.upper() for d in decvals} \
                        and t not in allow:
                    bad.append(f"{i}: {t} not in decoder output")
print(f"{confirmed} confirmed cells, {unverified} declared-unverified")
if bad:
    print("color-table gate failures:", file=sys.stderr)
    print("\n".join(bad), file=sys.stderr)
    raise SystemExit(1)
if strict and unverified > 0:
    print("strict: table has declared gaps", file=sys.stderr)
    raise SystemExit(1)
print("color-table format + decoder cross-check OK")
