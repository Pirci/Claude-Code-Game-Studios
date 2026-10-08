# Consistency Check Report

- **Date:** 2026-10-08
- **Skill:** `/consistency-check` (full) — Task C-14
- **Registry entries checked:** 0 entities, 0 items, 3 formulas, 4 constants
  (`design/registry/entities.yaml`, seeded the same day by `/design-system resource-system`)
- **Documents scanned (6):** `army-system.md`, `combat-system.md`, `region-map-system.md`,
  `spirit-system.md`, `resource-system.md`, `design/art/art-bible.md` (task scope: GDDs ↔ art bible ↔ registry)
- **Method:** grep-first on registry names plus Turkish synonyms/values used in the GDDs;
  full-section reads only for hits.

---

## Conflicts Found (must resolve before architecture)

🔴 **K1 — `effective_region_income` (formula)** — **RESOLVED 2026-10-08**
- Registry (source `design/gdd/resource-system.md` F1):
  `floor(G_base × max(0, 1 − corruption_level × PROD_PENALTY_PER_LEVEL))`, output 0–5, integer.
- `spirit-system.md` §4.3 defines its own `efektif_uretim = base_uretim × max(0, 1 −
  corruption_level × PROD_PENALTY_PER_LEVEL)` — different variable names, **rounding undefined**.
- `spirit-system.md` §3.1 "seviye 3 = üretim durur" and AC7 "seviye 3 → **0**": with P = 0.25,
  level 3 keeps 25 %. Prolog regions (G_base ≤ 3) floor to 0, but 4–5 gold regions keep 1.
- **Resolution (user decision, option c):** the linear penalty is replaced by a data-driven
  table `CORRUPTION_PRODUCTION_MULTIPLIERS = [1.0, 0.75, 0.5, 0.0]` (owned by spirit-system):
  levels 1–2 unchanged, level 3 stops production in every region. Spirit §4.3 now supplies only
  `M_c` and points to resource F1 for the formula. Registry: formula revised,
  `prod_penalty_per_level` deprecated, `corruption_production_multipliers` added.
  Compared: (a) P = 0.25 + reword (5-gold regions keep 1 at level 3), (b) P = 0.34 (2-gold regions
  already 0 at level 2).

🔴 **K2 — Corruption visuals: spirit ↔ art bible** — **RESOLVED 2026-10-08**
- `spirit-system.md` §3.1: "Görsel: zehir yeşili → mor → siyah (seviyeye göre)".
- Art bible §4: corruption uses only Erlik Moru + Erlik Kömürü as a dithered stain layer that
  rides on top of the ownership colour; green (Bozkır Yeşili) means purified/healthy. Spirit §2
  ("mor-siyah çürüme → yeşil bozkır") already agreed with the bible — internal contradiction too.
- **Resolution:** §3.1 now points to art bible §4 (cross-review W12). Per-level depiction left open.

---

## Stale Registry Entries

None — all entries were written today from their source GDDs.

---

## Unverifiable References (no conflict, informational)

- ℹ️ `recruit_cost`: `army-system.md` mentions production (§6) but states no value.
- ℹ️ `starting_gold_ch1`, `enemy_reinforcement_per_turn_ch1`: `region-map-system.md` names them
  (§6) without values — correct, the value owner is `resource-system.md`.
- ℹ️ **Art bible gap:** `spirit-system.md` AC10 expects "seviyeye göre renk", but the art bible does
  not define how corruption levels are depicted (dither density vs stain size). Decide in C-30/C-31.
- ℹ️ **Code drift (not a GDD conflict):** `game_context.gd` hard-codes `gold = 100`; GDD says
  `starting_gold` = 6 from chapter data. Fixed by implementation task C-37.

---

## Clean Entries

✅ `prod_penalty_per_level` = 0.25 — agreed at scan time; deprecated after K1 resolution.
✅ `turn_income` — region-map §4 example ("tur geliri = 2") and AC5 agree with F2.
✅ `recruit_cap` — only referenced by its source GDD.
✅ Tamga IDs `oguz` / `erlik_beast` — region-map §7 agrees with art bible §5.

---

## Registry Corrections

Added 3 cross-GDD constants (user approved): `actions_per_turn` = 1 (source region-map),
`enemy_actions_per_turn` = 1 (source region-map), `garrison_minimum` = 1 (source army).
Not registered yet: `erlik_beast` entity — its owner type depends on decision B2 (C-29).

---

## Verdict: CONFLICTS FOUND

2 conflicts, **both resolved the same day** (K1 by user decision, K2 by reference fix). They
overlap cross-review findings W8 (level-3 part) and W12. Re-run `/consistency-check` after C-33.
