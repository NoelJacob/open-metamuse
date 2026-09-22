#!/usr/bin/env bash
# Semantic visual-diff pipeline per local://paste-1..5.md.
# Usage: vd.sh <orig.png> <clone.png> <label>
# 1. core-native pixel gate (threshold 0.1 + antialiasing per paste-3)
# 2. GMSD edge-structure score (gate ~0.05 per paste-4/5)
# 3. interpret --source pixel region table (what changed, per paste-1)
# 4. MS-SSIM report score (size-aware, per paste-2)
set -u
ORIG="$1"; CLONE="$2"; LABEL="$3"
OUT="captures/diff-${LABEL}.png"
echo "=== $LABEL ==="
echo "--- core-native (threshold 0.1 + AA) ---"
blazediff-cli core-native "$ORIG" "$CLONE" "$OUT" -t 0.1 -a 2>&1 | grep -E 'different|identical|error' | head -n 2
echo "--- GMSD (gate ~0.05) ---"
blazediff-cli gmsd "$ORIG" "$CLONE" 2>&1 | grep -i -m1 'gmsd'
echo "--- MS-SSIM (report) ---"
blazediff-cli msssim "$ORIG" "$CLONE" 2>&1 | grep -i -m1 'score'
echo "--- SSIM (report) ---"
blazediff-cli ssim "$ORIG" "$CLONE" 2>&1 | grep -i -m1 'score'
echo "--- interpret regions (pixel source) ---"
blazediff-cli interpret "$ORIG" "$CLONE" --source pixel -t 0.1 -a --json > /tmp/vd-regions.txt 2>/dev/null
python3 -c "
import json
d = json.load(open('/tmp/vd-regions.json'))
print('pct:', round(d['diffPercentage'], 2), '| regions:', len(d['regions']))
for r in d['regions'][:12]:
    b = r['bbox']
    print(r['changeType'], f\"x{b['x']} y{b['y']} {b['width']}x{b['height']}\")
"
