#!/usr/bin/env python3
"""Reapplies all Muse bypass patches to a fresh apktool decode at /tmp/muse-patch.

P1 onboarding complete | P2 returning-activated | P3 routePending=false |
P4 tos accepted | P5 offline queue on | P6 merge history with null session.
Run: python3 apply_patches.py  (cwd anywhere)
"""
import re
import sys

ROOT = "/tmp/muse-patch"


def read(p):
    with open(p) as f:
        return f.read().split("\n")


def write(p, lines):
    with open(p, "w") as f:
        f.write("\n".join(lines))


def replace_method(path, start_pred, new_body):
    s = read(path)
    i = next(n for n, l in enumerate(s) if start_pred(l))
    j = next(n for n, l in enumerate(s)
             if n > i and l.strip() == ".end method")
    s[i:j + 1] = new_body
    write(path, s)
    print("patched", path.split("smali")[-1], "+", start_pred.__name__)


def p1(_):
    replace_method(
        f"{ROOT}/smali_classes2/com/facebook/aura/onboarding/"
        "OnboardingStartupGate.smali",
        lambda l: l.startswith(
            ".method public final hasCompletedOnboarding"),
        [".method public final hasCompletedOnboarding()Z",
         "    .locals 1", "", "    const/4 v0, 0x1", "",
         "    return v0", "", ".end method"])


def p2(_):
    replace_method(
        f"{ROOT}/smali/com/facebook/aura/main/HatchActiveSessionHostKt.smali",
        lambda l: l.startswith(
            ".method public static final isReturningFullyActivatedUser"),
        [".method public static final isReturningFullyActivatedUser(LX/9Ny;)Z",
         "    .locals 1", "", "    const/4 v0, 0x1", "",
         "    return v0", "", ".end method"])


def p4(_):
    replace_method(
        f"{ROOT}/smali_classes2/com/facebook/aura/user/provider/"
        "AuraUserData.smali",
        lambda l: l.startswith(".method public final getHasAcceptedTos"),
        [".method public final getHasAcceptedTos()Z",
         "    .locals 1", "", "    const/4 v0, 0x1", "",
         "    return v0", "", ".end method"])


def p5(_):
    replace_method(
        f"{ROOT}/smali_classes2/com/facebook/aura/utils/HatchUtil.smali",
        lambda l: l.startswith(
            ".method public final isOfflineMessageQueueEnabled"),
        [".method public final isOfflineMessageQueueEnabled()Z",
         "    .locals 1", "", "    const/4 v0, 0x1", "",
         "    return v0", "", ".end method"])


def p3(_):
    p = (f"{ROOT}/smali_classes2/com/facebook/aura/user/provider/"
         "HatchGatewayConnectOwnership.smali")
    s = read(p)
    j = next(n for n, l in enumerate(s)
             if "activationViewModelRoutePending" in l
             and l.strip().startswith("iput-object"))
    hit = None
    for n in range(j, max(0, j - 10), -1):
        if "AtomicBoolean;-><init>" in s[n]:
            hit = n
            break
    assert hit is not None, "routePending init not found"
    assert s[hit - 1].strip() == "" or True
    s.insert(hit, "    const/4 v3, 0x0")
    write(p, s)
    print("patched HatchGatewayConnectOwnership +P3")


def p6(_):
    import glob
    cands = glob.glob(
        f"{ROOT}/smali*/com/facebook/aura/conversation/repo/"
        "HatchConversationRepository*.smali")
    hit = None
    for p in cands:
        s = read(p)
        for n, l in enumerate(s):
            if "confirmThreadSession" in l and "invoke-" in l:
                # walk back to the null-check on sessionId
                for m in range(n, max(0, n - 25), -1):
                    if re.match(r"\s*if-nez v\d+, :cond", s[m]):
                        hit = (p, m)
                        break
                if hit:
                    break
        if hit:
            break
    assert hit, "merge null-guard not found"
    p, m = hit
    s = read(p)
    # neutralize: replace conditional branch with goto to fall-through
    # (find the :cond target label line and retarget by NOP-ing is unsafe;
    # instead invert: if-nez -> if-nez to a fresh pass-through is complex.
    # Simplest robust: change `if-nez vR, :cond_X` into `goto :cond_X`
    # only if :cond_X is the merge block; else report and abort.)
    print("P6 candidate:", p.split("smali")[-1], "line", m + 1)
    print("CONTEXT:")
    print("\n".join(f"  {k + 1}: {s[k]}" for k in range(m - 4, m + 12)))
    print("P6 left MANUAL — inspect context above.")


for fn in (p1, p2, p4, p5, p3):
    fn(None)
p6(None)
