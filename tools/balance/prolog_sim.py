#!/usr/bin/env python3
"""C-49 Prolog balance -- deterministic replay of the hand-simulated reference lines.

Written by the C-49 game-designer subagent (no shell): the tables in
design/balance/prolog-balance-2026-10-19.md were computed by hand and this script re-plays
them with assertions. Executed 2026-10-19: 12/12 lines match. Run from the repo root:
  python3 -I tools/balance/prolog_sim.py
A re-implementation of the GDD rules, not the game code — C-64 replays the lines on the real
controllers.

Rules (GDD sections):
  resource-system F1 (G_eff = floor(G_base * M_c)), F2 (income), F3 (cap = max(1, G_eff)),
                  F4 (cost 2, no action), R4/R5 (recruit in owned region, counter per turn)
  army-system §3.1-3.3 (moving = army-1; branch 1 combat / 2 purification / 3 peaceful)
  combat-system §4 Dal 1-3 (awr 0.5, dwr 0.3, dar 0.7, ddr 0.5, draw favours defender)
  spirit-system §4.1 (S = 4L, success iff P > S, loss ceil(S*0.5)), §4.2 (Ruh 10L*(1+0.2s)),
                §4.4 (boon cost 30 + 20n), §4.6 (spread: min army, alphabetical tie-break)
  region-map §3.4 (end_turn: AI -> spread -> income -> turn+1 -> lose/win check),
             §3.6 win (3 initially-neutral non-focus regions + foci purified + no ENEMY)
  C-49: Erlik loss  erlik_power = sum(corruption_level) >= erlik_loss_threshold (Prolog 9)
"""

M_C = [1.0, 0.75, 0.5, 0.0]           # CORRUPTION_PRODUCTION_MULTIPLIERS
CORR_STR_PER_LEVEL = 4
RUH_PER_LEVEL = 10
RECRUIT_COST = 2
R_MIN = 1
BASE_BOON_COST, BOON_COST_STEP = 30, 20

ALIAS = {"O": "otuken", "B": "bati_bozkir", "D": "dogu_bozkir", "A": "altai",
         "G": "guney_vadi", "L": "sinir_bolge"}


def ceil_frac(x, num, den):
    """ceil(x * num / den) in integers (avoids 0.7*10 float error)."""
    return -(-x * num // den)


QUARTERS = {0: 4, 1: 3, 2: 2, 3: 0}   # M_C in quarters -> exact floor(G_base * M_c)


def g_eff(r):
    return (r["gold"] * QUARTERS[r["corr"]]) // 4


def make_state(teaching=True, threshold=9, interval=3):
    regs = {
        "otuken":      dict(owner="P", army=5, gold=2, corr=0, adj=["bati_bozkir", "dogu_bozkir", "altai", "guney_vadi"]),
        "bati_bozkir": dict(owner="N", army=3, gold=1, corr=0, adj=["otuken", "altai", "guney_vadi"]),
        "dogu_bozkir": dict(owner="N", army=0 if teaching else 3, gold=1, corr=1 if teaching else 0, adj=["otuken", "sinir_bolge"]),
        "altai":       dict(owner="N", army=2, gold=2, corr=0, adj=["otuken", "bati_bozkir"]),
        "guney_vadi":  dict(owner="N", army=0, gold=3, corr=0, adj=["otuken", "bati_bozkir", "sinir_bolge"]),
        "sinir_bolge": dict(owner="N", army=0, gold=1, corr=3, adj=["dogu_bozkir", "guney_vadi"]),
    }
    for r in regs.values():
        r["rec"] = 0
    foci = ["sinir_bolge"]
    neutral_pool = [k for k, v in regs.items() if v["owner"] == "N" and k not in foci]
    return dict(r=regs, gold=6, ruh=0, n_boons=0, arinma=0, bereket=0, gok=0,
                turn=1, last_spread=0, interval=interval, actions=1, result="ONGOING",
                threshold=threshold, foci=foci, pool=neutral_pool, required=3,
                rows=[], events=[], max_army=5)


def erlik_power(s):
    return sum(r["corr"] for r in s["r"].values())


def cap(r):
    return max(R_MIN, g_eff(r))


def won(s):
    r = s["r"]
    if any(v["owner"] == "E" for v in r.values()):
        return False
    if any(r[f]["corr"] != 0 for f in s["foci"]):
        return False
    if not any(v["owner"] == "P" for v in r.values()):
        return False
    return sum(1 for k in s["pool"] if r[k]["owner"] == "P") >= s["required"]


def recruit(s, rid, k):
    reg = s["r"][ALIAS.get(rid, rid)]
    assert s["result"] == "ONGOING"
    assert reg["owner"] == "P", f"T{s['turn']} recruit in non-owned {rid}"
    assert k >= 1 and reg["rec"] + k <= cap(reg), f"T{s['turn']} cap {rid}: {reg['rec']}+{k}>{cap(reg)}"
    assert s["gold"] >= k * RECRUIT_COST, f"T{s['turn']} gold {s['gold']} < {k * RECRUIT_COST}"
    s["gold"] -= k * RECRUIT_COST
    reg["army"] += k
    reg["rec"] += k
    s["max_army"] = max(s["max_army"], reg["army"])


def move(s, src, dst):
    src, dst = ALIAS.get(src, src), ALIAS.get(dst, dst)
    R = s["r"]
    a, t = R[src], R[dst]
    assert s["result"] == "ONGOING" and s["actions"] > 0
    assert a["owner"] == "P" and a["army"] > 1 and dst in a["adj"], f"T{s['turn']} bad move {src}->{dst}"
    moving = a["army"] - 1
    a["army"] = 1
    if t["owner"] != "P" and t["army"] > 0:                    # branch 1: combat
        A, D = moving, t["army"]
        if A > D:
            t["owner"], t["army"] = "P", A - ceil_frac(D, 1, 2)
            s["events"].append(f"T{s['turn']} {src}->{dst} battle {A}v{D} won, {t['army']} left")
        elif D > A:
            t["army"] = D - ceil_frac(A, 3, 10)
            s["events"].append(f"T{s['turn']} {src}->{dst} battle {A}v{D} LOST")
        else:
            t["army"] = max(0, D - ceil_frac(D, 1, 2))
            if t["army"] == 0:
                t["owner"] = "N"
            s["events"].append(f"T{s['turn']} {src}->{dst} battle {A}v{D} draw (defender)")
    elif t["corr"] >= 1:                                       # branch 2: purification
        L = t["corr"]
        S = L * CORR_STR_PER_LEVEL
        if moving > S:
            gain = (L * RUH_PER_LEVEL * (10 + 2 * s["arinma"]) + 5) // 10   # round half up
            s["ruh"] += gain
            left = moving - ceil_frac(S, 1, 2)
            t["corr"] = 0
            if t["owner"] == "P":
                t["army"] += left
            else:
                t["owner"], t["army"] = "P", left
            s["events"].append(f"T{s['turn']} {src}->{dst} purify P{moving}>S{S} ok +{gain} Ruh, {t['army']} there")
        else:
            s["events"].append(f"T{s['turn']} {src}->{dst} purify P{moving}<=S{S} FAILED (all lost)")
    else:                                                      # branch 3: peaceful
        if t["owner"] == "P":
            t["army"] += moving
        else:
            t["owner"], t["army"] = "P", moving
    s["actions"] -= 1
    s["max_army"] = max(s["max_army"], max(v["army"] for v in R.values()))
    if won(s):                                                 # mid-turn win (C-32 latch)
        s["result"] = "WON"
        s["events"].append(f"T{s['turn']} WON mid-turn")


def pick_boon(s, boon_id):
    cost = BASE_BOON_COST + s["n_boons"] * BOON_COST_STEP
    assert s["ruh"] >= cost, f"T{s['turn']} Ruh {s['ruh']} < {cost}"
    s["ruh"] -= cost
    s["n_boons"] += 1
    if boon_id == "arinma_ustaligi":
        s["arinma"] += 1
    elif boon_id == "bereket":
        s["bereket"] += 1
    elif boon_id == "gok_kalkani":
        s["gok"] = min(3, s["gok"] + 1)
    s["events"].append(f"T{s['turn']} boon {boon_id} (cost {cost})")


def spread_target(s):
    R = s["r"]
    cands = [k for k, v in R.items()
             if v["corr"] < 3 and any(R[n]["corr"] >= 1 for n in v["adj"])]
    if not cands:
        return None
    return min(cands, key=lambda k: (R[k]["army"], k))


def end_turn(s):
    if s["result"] != "ONGOING":
        return
    R = s["r"]
    target = ""
    if s["turn"] - s["last_spread"] >= s["interval"] + s["gok"]:   # step 2
        t = spread_target(s)
        if t:
            R[t]["corr"] += 1
            target = f"{t}->L{R[t]['corr']}"
        s["last_spread"] = s["turn"]
    income = sum(g_eff(v) for v in R.values() if v["owner"] == "P")
    if any(v["owner"] == "P" for v in R.values()):
        income += s["bereket"]
    s["gold"] += income                                             # step 3
    s["rows"].append(dict(turn=s["turn"], income=income, gold=s["gold"],
                          army=sum(v["army"] for v in R.values() if v["owner"] == "P"),
                          power=erlik_power(s), ruh=s["ruh"], spread=target))
    s["turn"] += 1                                                  # step 4
    s["actions"] = 1
    for v in R.values():
        v["rec"] = 0
    no_regions = not any(v["owner"] == "P" for v in R.values())     # step 5: lose -> win
    if no_regions or (s["threshold"] > 0 and erlik_power(s) >= s["threshold"]):
        s["result"] = "LOST"
        s["events"].append(f"T{s['turn'] - 1} LOST at end of turn (Erlik power {erlik_power(s)})")
    elif won(s):
        s["result"] = "WON"


def passive_turn(s):
    """Recruit as much as possible at Otag, no move."""
    o = s["r"]["otuken"]
    k = min(cap(o) - o["rec"], s["gold"] // RECRUIT_COST)
    if k > 0:
        recruit(s, "O", k)


def run(name, script, passive=0, idle_rec=None, until=40, **kw):
    """script: list of per-turn lists of ('rec', id, k) / ('mv', a, b) / ('boon', id)."""
    s = make_state(**kw)
    for _ in range(passive):
        passive_turn(s)
        end_turn(s)
    for turn_ops in script:
        for op in turn_ops:
            if s["result"] != "ONGOING":
                break
            {"rec": lambda o: recruit(s, o[1], o[2]),
             "mv": lambda o: move(s, o[1], o[2]),
             "boon": lambda o: pick_boon(s, o[1])}[op[0]](op)
        end_turn(s)
        if s["result"] != "ONGOING":
            break
    while s["result"] == "ONGOING" and s["turn"] <= until:
        if idle_rec:
            g = s["r"][ALIAS[idle_rec]]
            k = min(cap(g) - g["rec"], s["gold"] // RECRUIT_COST)
            if k > 0:
                recruit(s, idle_rec, k)
        else:
            passive_turn(s)
        end_turn(s)
    return s


def report(name, s):
    print(f"\n== {name}: {s['result']} (turn {s['turn']}), Ruh {s['ruh']}, boons {s['n_boons']}, "
          f"max army {s['max_army']}")
    print(" turn | income | gold | army | erlik_power | ruh | spread")
    for r in s["rows"]:
        print(f" {r['turn']:>4} | {r['income']:>6} | {r['gold']:>4} | {r['army']:>4} | "
              f"{r['power']:>11} | {r['ruh']:>3} | {r['spread']}")
    for e in s["events"]:
        print("   ", e)


LINES = {
    "A fastest": dict(script=[
        [("rec", "O", 2), ("mv", "O", "A")],
        [("rec", "O", 2), ("mv", "O", "G"), ("rec", "G", 1)],
        [("rec", "G", 3), ("mv", "A", "B")],
        [("rec", "G", 3), ("rec", "B", 1), ("mv", "B", "G")],
        [("rec", "G", 3), ("mv", "G", "L")]],
        expect=("WON", 5, 30)),
    "E1 engaged-light": dict(script=[
        [("rec", "O", 2), ("mv", "O", "D")],
        [("rec", "O", 2), ("mv", "O", "G")],
        [("rec", "G", 3), ("mv", "G", "B")],
        [("rec", "O", 2), ("rec", "D", 1), ("mv", "D", "O")],
        [("rec", "O", 2), ("mv", "O", "G"), ("rec", "G", 1)],
        [("rec", "G", 3), ("rec", "O", 1), ("mv", "B", "G")],
        [("rec", "G", 3), ("mv", "G", "L")]],
        expect=("WON", 7, 50)),
    "E3 engaged mid-scene boon": dict(script=[
        [("rec", "O", 2), ("mv", "O", "G")],
        [("rec", "G", 3), ("mv", "G", "B")],
        [("rec", "O", 2), ("rec", "G", 1), ("mv", "B", "A")],
        [("rec", "O", 2), ("rec", "G", 2), ("mv", "A", "O")],
        [("rec", "O", 2), ("rec", "G", 2), ("mv", "O", "D")],
        [("rec", "G", 3), ("rec", "O", 2), ("mv", "D", "O")],
        [("rec", "O", 2), ("rec", "G", 2), ("mv", "O", "D"), ("boon", "arinma_ustaligi")],
        [("rec", "G", 3), ("mv", "G", "L")]],
        expect=("WON", 8, 36)),
    "C greedy conquest, never purify/strike": dict(script=[
        [("rec", "O", 2), ("mv", "O", "A")],
        [("rec", "O", 2), ("mv", "O", "G"), ("rec", "G", 1)],
        [("rec", "G", 3), ("mv", "A", "B")]], idle_rec="G",
        expect=("LOST", 15, 0)),
    "P inf passive forever": dict(script=[], expect=("LOST", 15, 0)),
    "P w=3": dict(passive=3, script=[
        [("rec", "O", 1), ("mv", "O", "A")],
        [("rec", "O", 2), ("mv", "A", "B")],
        [("rec", "O", 2), ("mv", "B", "G")],
        [("rec", "G", 3), ("rec", "O", 1), ("mv", "O", "G")],
        [("rec", "G", 3), ("mv", "G", "L")]], expect=("WON", 8, 30)),
    "P w=6": dict(passive=6, script=[
        [("rec", "O", 1), ("mv", "O", "A")],
        [("rec", "O", 2), ("mv", "A", "B")],
        [("rec", "O", 2), ("mv", "B", "G")],
        [("rec", "G", 3), ("rec", "O", 1), ("mv", "O", "G")],
        [("rec", "G", 3), ("mv", "G", "L")]], expect=("WON", 11, 30)),
    "P w=8": dict(passive=8, script=[
        [("rec", "O", 1), ("mv", "O", "A")],
        [("rec", "O", 2), ("mv", "A", "B")],
        [("rec", "O", 2), ("mv", "B", "G")],
        [("rec", "G", 3), ("rec", "O", 1), ("mv", "O", "G")],
        [("rec", "G", 3), ("mv", "G", "L")]], expect=("WON", 13, 40)),
    "P w=9": dict(passive=9, script=[
        [("rec", "O", 1), ("mv", "O", "A")],
        [("rec", "O", 2), ("mv", "A", "B")],
        [("rec", "O", 2), ("mv", "B", "G")],
        [("rec", "G", 3), ("rec", "O", 1), ("mv", "O", "G")],
        [("rec", "G", 3), ("mv", "G", "L")]], expect=("WON", 14, 40)),
    "P w=12": dict(passive=12, script=[
        [("rec", "O", 1), ("mv", "O", "A")],
        [("rec", "O", 2), ("mv", "A", "B")],
        [("rec", "O", 2), ("mv", "B", "G")],
        [("rec", "G", 3), ("rec", "O", 1), ("mv", "O", "G")],
        [("rec", "G", 3), ("mv", "G", "L")]], expect=("WON", 17, 50)),
    "P w=13 A-first (ignores the 8/9 warning)": dict(passive=13, script=[
        [("rec", "O", 1), ("mv", "O", "A")],
        [("rec", "O", 2), ("mv", "A", "B")]], expect=("LOST", 15, 0)),
    "P w=13 purify-first": dict(passive=13, script=[
        [("rec", "O", 1), ("mv", "O", "G")],
        [("rec", "G", 2), ("mv", "G", "B")],
        [("rec", "G", 2), ("rec", "B", 1), ("mv", "B", "A")],
        [("rec", "G", 2), ("rec", "A", 1), ("mv", "A", "B")],
        [("rec", "G", 2), ("rec", "B", 1), ("mv", "B", "G")],
        [("rec", "G", 3), ("mv", "G", "L")]], expect=("WON", 19, 60)),
}


if __name__ == "__main__":
    failures = 0
    for name, cfg in LINES.items():
        exp = cfg.pop("expect")
        s = run(name, **cfg)
        report(name, s)
        last_turn = s["turn"] if s["result"] == "WON" else s["turn"] - 1
        got = (s["result"], last_turn, s["ruh"] if s["result"] == "WON" else 0)
        ok = got == exp
        failures += not ok
        print(f"   expected {exp} -> {'OK' if ok else 'MISMATCH ' + str(got)}")
    print(f"\n{len(LINES) - failures}/{len(LINES)} lines match the hand-sim")
    raise SystemExit(1 if failures else 0)
