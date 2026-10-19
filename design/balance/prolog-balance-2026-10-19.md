# Balance Check: Prolog (Doğuş) — Erlik model impact (C-49)

- **Date:** 2026-10-19
- **Task:** C-49 (`production/continuation.md`), closes C-34 report items W-A, W-B/N2, N1, N3, S1-e,
  D3 and routes N4/N9 (`design/gdd/gdd-cross-review-2026-10-19.md`)
- **Skill:** `/balance-check` (domain: economy + progression of one scene), night mode —
  decisions taken with the recommended option, recorded below for the owner's review
- **Method:** hand simulation that applies the GDD rules exactly (sections cited below); every
  reference line was computed twice, then replayed by an independent script with assertions —
  `tools/balance/prolog_sim.py` (`python3 -I tools/balance/prolog_sim.py`), executed 2026-10-19:
  **12/12 lines match**. The script re-implements the GDD rules (not the game code); task
  **C-64** replays the lines on the real controllers.

---

## Data Sources Analyzed

- `game/features/grid/data/chapter_1_map.tres` (graph, garrisons, gold, win condition — still the
  pre-C-29 data: lair `ENEMY` 6)
- `game/features/combat/data/combat_config.tres` (0.5 / 0.3 / 0.7 / 0.5, `draw_favors_defender`)
- `game/features/grid/map_controller.gd`, `win_condition.gd`, `chapter_map_definition.gd`,
  `region_definition.gd`, `game/features/ai/erlik_spread_controller.gd`,
  `enemy_ai_controller.gd`, `game/features/resources/resource_controller.gd` (read only)
- `design/gdd/resource-system.md` (F1–F4, §4), `spirit-system.md` (§3.2, §3.6–3.8, §4.1–4.6),
  `army-system.md` (§3.3, §4), `combat-system.md` (§4–5), `region-map-system.md` (§3.4–3.7),
  `game-concept.md` (pillars, Prolog, MVP hypothesis), `design/registry/entities.yaml`
- `design/gdd/gdd-cross-review-2026-10-19.md` (N1–N12, S1)

## Health Summary: **CONCERNS**

After the C-49 decisions, the M1 Prolog has a fastest win, a loss path and an in-scene Ruh
payoff, and it sits inside the 10–18 turn session target. Three things stay open: (1) the
numbers are checked by a rule replay (12/12), not yet by the game code (C-64), (2) unbounded Ruh stalling, which only matters once
boons carry into Perde 1 (C-44, M2), and (3) the deliberately wider waste tolerance needs the
owner's sign-off and a playtest (C-42).

---

## 1. Decisions (night mode — recommended option applied)

| # | Question | Chosen | Rejected | Why |
| --- | --- | --- | --- | --- |
| a | Prolog loss / political enemy (N2, W-B) | **Erlik's Shadow:** `erlik_power = Σ corruption_level`. The scene is lost when `erlik_power ≥ erlik_loss_threshold` (Prolog **9**), checked at `end_turn` step 5. The Prolog has **no `ENEMY`**: the political layer is the neutral tribe garrisons. | Turn limit T18; Otağ reaching L3 = loss; a hostile tribe (ENEMY + AI + F6); no loss in the tutorial | This option is themed and deterministic: +1 per spread, −L per purification, the same axis as Ruh. It is derived (no new state) and makes Pillar 3 load-bearing. An Otağ-based loss would almost never fire, because the min-army targeting skips a big Otağ. A hostile tribe overloads the tutorial (N7) and was too harsh in the old sim (4 wasted turns → loss). A turn cap is not Erlik. |
| b | Teaching tile (N1 + N3) | **Doğu Obası: garrison 0, corruption L1** (borders Otağ and the lair) | L2 teaching tile; Kutlu Dağ (a second front next to Otağ/Batı); framing the victory boon as "carried to Perde 1"; an in-scene Ruh sink | It gives the gentlest first purification (P ≥ 5, +10 Ruh, counts as a neutral). If ignored it ripens T3 → L2 and T6 → L3, which shows Erlik deepening before the beast. Being empty, it is the lightning rod that keeps the spread off Otağ. An L2 tile would ripen to L3 at T3. |
| c | N4 decoy-and-ripen, N9 conquest → Erlik | **No Prolog rule change; deferred to C-44** | Spread targets the most valuable tile; re-purify multiplier now; interval shrinking with territory now | The meter already charges for neglect. Steering is deterministic and telegraphed, so it counts as healthy mastery. Ruh stalling has no M1 consequence (no next scene). A conquest → Erlik rule would be the 7th coupled rule in a tutorial (N7). |
| d | Lair garrison (S1-e) | **0**, plus a data AC (region-map AC14) | Garrisoned beast (combat + purification = 2 stacks, 2 actions); purification strength including the garrison | With garrison 0 the winning move is always a purification and the win lands on that move. |
| e | `ERLIK_SPREAD_INTERVAL` (Prolog) | **3 (kept)** | 2; 4 (global default) | See §5: with 2, the neglect loss comes at T10 and the teaching tile ripens at T2. With 4, the neglect loss moves to T20, outside the 18-turn window. |

---

## 2. Rules used (exact)

| Rule | Source |
| --- | --- |
| `G_eff = floor(G_base × [1, .75, .5, 0][L])`; income = Σ over player regions (`I_floor` 0, `B_add` per Bereket) | resource F1, F2 |
| Cap `max(1, G_eff)` per region per turn, cost 2, no action, also allowed in a region captured this turn | resource F3, F4, §5 |
| `moving = army − 1`; branch 1 combat (foreign garrison), branch 2 purification (no foreign garrison + corrupted), branch 3 peaceful | army §3.1–3.3 |
| Combat Dal 1: attacker loses `ceil(D × 0.5)`; draw favours the defender | combat §4 |
| Purification: `S = 4L`, success iff `P > S`, survivors `P − ceil(S/2)`; on failure all P is lost; Ruh `10 L` | spirit §3.2, §4.1, §4.2 |
| Spread every `I_eff` turns (counter from 0): candidates have level < 3 and a corrupted neighbour; target = min army, ties alphabetical (`altai < bati_bozkir < dogu_bozkir < guney_vadi < otuken < sinir_bolge`) | spirit §3.6, §4.6 |
| `end_turn`: AI (none) → spread → income → turn+1 → lose (no regions / Erlik) → win; mid-turn win ends the scene | region-map §3.4, §3.6, §3.7 |
| Win: 3 of {Batı, Doğu, Kutlu Dağ, Bereket} owned + lair purified | region-map §3.6, §4 |
| Boons: cost `30 + 20n`; auto modal at turn start; HUD pick allowed the same turn | spirit §3.4, §4.4 |

## 3. Prolog data (C-49 — for C-36)

| Region | Owner | Garrison | Gold | Corruption | Adjacent |
| --- | --- | --- | --- | --- | --- |
| Oğuz Otağı `otuken` (O) | Player | 5 | 2 | 0 | B, D, A, G |
| Batı Obası `bati_bozkir` (B) | Neutral | 3 | 1 | 0 | O, A, G |
| Doğu Obası `dogu_bozkir` (D) | Neutral | **0** (was 3) | 1 | **1** (new) | O, L |
| Kutlu Dağ `altai` (A) | Neutral | 2 | 2 | 0 | O, B |
| Bereket Vadisi `guney_vadi` (G) | Neutral | 0 | 3 | 0 | O, B, L |
| Canavarın İni `sinir_bolge` (L) | **Neutral** (was ENEMY) | **0** (was 6) | 1 | **3** | D, G |

Other values: `starting_gold` 6, `actions_per_turn` 1, `erlik_spread_interval` 3, `erlik_foci [L]`,
`required_neutral_conquests` 3, `erlik_loss_threshold` 9 (start `erlik_power` 4),
`enemy_reinforcement_per_turn` 1 (inert), `enemy_tamga_id` empty.

---

## 4. Simulation results

### Line A — fastest (T5)

| T | Recruit; move | Income | Gold (end) | Player army | `erlik_power` | Ruh | Spread |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | O+2; O→A 6 v 2 (A 5) | 4 | 6 | 6 | 4 | 0 | — |
| 2 | O+2, G+1; O→G 2 | 7 | 7 | 9 | 4 | 0 | — |
| 3 | G+3; A→B 4 v 3 (B 2) | 8 | 9 | 10 | 5 | 0 | D → L2 |
| 4 | G+3, B+1; B→G merge (G 11) | 8 | 9 | 14 | 5 | 0 | — |
| 5 | G+3 (G 14); G→L P 13 > 12 → **WIN** | — | 3 | 11 | 2 | **30** | — |

15 recruits, 30 gold. The victory offer is boon #1. The teaching tile is skipped (the rusher's
choice).

**T4 is impossible (budget proof).** A T4 win needs 4 productive moves (3 neutrals + lair) and
≥ 14 troops at G or D by T4. Only G can hold such a stack, since D's cap is 1. If G is taken on
T1 with the main stack, then T2 and T3 conquests must come from Otağ. But Otağ is at 1 after T1
and reaches only 3 on T2 (moving 2 < A 3 / B 4 / D 5). G staging also costs 6 gold/turn against
5–7 income. If G is taken on T2 or T3, then G ≤ 11 by T4. C-34's "≈ T6" was one turn
pessimistic.

### Line E3 — engages Erlik, mid-scene boon (T8)

| T | Recruit; move | Income | Gold | Army | `erlik_power` | Ruh | Spread |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | O+2; O→G 6 | 5 | 7 | 7 | 4 | 0 | — |
| 2 | G+3; G→B 8 v 3 (B 6) | 6 | 7 | 8 | 4 | 0 | — |
| 3 | O+2, G+1; B→A 5 v 2 (A 4) | 8 | 9 | 10 | 5 | 0 | D → L2 |
| 4 | O+2, G+2; A→O merge (O 8) | 8 | 9 | 14 | 5 | 0 | — |
| 5 | O+2, G+2; O→D P 9 > 8 (D 5) | 9 | 10 | 14 | 3 | 20 | — |
| 6 | G+3, O+2; D→O merge (O 7) | 8 | 8 | 19 | 4 | 20 | D → L1 |
| 7 | O+2, G+2; O→D P 8 > 4 (D 7) → **boon via HUD** | 9 (+1 Bereket) | 9 | 21 | 3 | 30 → 0 | — |
| 8 | G+3 (G 14); G→L → **WIN** | — | 3 | 18 | 0 | 30 (36 with Arınma Ustalığı) | — |

Boon #2 costs 50, so there is no victory offer. 30–36 Ruh carries over.

**E1** (teaching tile on T1: O+2 → D P 6 > 4, +10; G corrupted by the T3 spread and purified on
T5, +10): **WIN T7**, Ruh 50 → 1 victory boon, 20 carried over.

### Line C — conquer, ignore Erlik (T1–T3 = A, then only recruiting)

| End of T | 3 | 6 | 9 | 12 | 15 |
| --- | --- | --- | --- | --- | --- |
| Spread | D → L2 | D → L3 | O → L1 (garrison 1) | A → L1 (garrison 1, alphabetical) | A → L2 |
| `erlik_power` | 5 | 6 | 7 | **8 (warning)** | **9 → LOST** |
| Income | 8 | 8 | 7 | 6 | 6 |

The army at G reaches 42 by T15. The player could have won from T5, so the meter is what
prevents a zombie game.

### Passive start P(w): only recruiting at Otağ for w turns, then best play

The passive Otağ army is 7, 9, then 7 + t; income is 2/turn. Passive spreads go D → L2 (T3),
D → L3 (T6), G → L1 (T9), G → L2 (T12), G → L3 (T15).

| w | Win | Ruh | Max `erlik_power` | Note |
| --- | --- | --- | --- | --- |
| 0 | T5 | 30 | 5 | = line A |
| 3 | T8 | 30 | 6 | A → B → G → merge → strike |
| 6 | T11 | 30 | 7 | |
| 8 | T13 | 40 | 7 | corrupted Bereket purified on the way (+10, −1) |
| 9 | T14 | 40 | 7 | |
| 12 | T17 | 50 | 8 | starts at 8/9; Bereket L2 must be purified by T15 |
| 13 | **LOST T15** if it conquers first; **WIN T19** if it purifies first | 60 | 9 / 8 | the decision Pillar 3 forces |
| ∞ | **LOST T15** | 0 | 9 | |

### Ruh and boons

| Line | Ruh before beast | Mid-scene boon | Victory boon | Ruh carried |
| --- | --- | --- | --- | --- |
| A (T5) | 0 | — | 1 | 0 |
| E1 (T7) | 20 | — | 1 | 20 |
| E3 (T8) | 30 at T7 | **1** | — | 30–36 |
| P(8) (T13) | 10 | — | 1 | 10 |
| Theoretical ceiling, ≥ 13 turns of thorough play | ≥ 50 | 1 | 1 | — |

Before C-49 the ceiling was ≈ 70 and the boon arrived only at victory. All three M1 boons now
have a visible in-scene effect when taken mid-scene.

---

## 5. Knob sensitivity

| `ERLIK_SPREAD_INTERVAL` | Neglect loss (X = 9) | Teaching tile ripens | Spreads before the T5 win | Verdict |
| --- | --- | --- | --- | --- |
| 2 | T10 | T2 (L2), T4 (L3) | 2 | Too harsh: a typical 10–12 turn scene is at the loss edge, and the T1–T2 window to purify D at P ≥ 5 is too short. Not fully simulated. |
| **3** | **T15** | T3, T6 | 1 | **Kept** |
| 4 | T20 | T4, T8 | 1 | The loss falls outside the 18-turn window, so zombie games return |

| `erlik_loss_threshold` | Neglect loss | Passive tolerance | Warning (X − 1) |
| --- | --- | --- | --- |
| 8 | T12 | w ≤ 11 (w = 12 loses) | T9 |
| **9** | **T15** | **w ≤ 12** (w = 13 only with purify-first) | **T12** |
| 10 | T18 | ≈ w ≤ 15 (estimate) | T15 |

---

## Outliers Detected

| Item/Value | Expected Range | Actual | Issue |
| --- | --- | --- | --- |
| Fastest win | Tutorial; session 10–18 turns | T5 | OK. A solved recipe (N5), acceptable for a tutorial |
| Waste tolerance | Approved C-28 target: ≤ 6 wasted turns | ≤ 12 | **Deliberate** (gentle tutorial, no political AI); owner to confirm |
| Ruh by stalling | Bounded per scene | Unbounded: ≈ 10 Ruh per 3 turns while the meter stays low | Matters only when boons carry over (M2) → C-44 |
| Victory offer for engaged players | ≥ 1 Kök Böri moment | None in E3 (30 < 50) | Intended trade-off: their Kök Böri moment is mid-scene |
| `enemy_reinforcement_per_turn` ch1 | Active | Inert | Documented (resource F6, registry) |
| Max army | ≤ 999 (UI 3 digits) | 23 reference / 42 idle | OK |

## Degenerate Strategies Found

- **Ruh stalling:** delay the win and purify every spread. The meter stays low and the player
  earns ≈ 10 Ruh / 3 turns, with no loss. Tedious (~12 extra turns per boon). It has no payoff
  in M1, but must be bounded before M2 (C-44 options: re-purify multiplier + per-scene purify
  counter, scene Ruh cap, turn cap).
- **Decoy steering (N4):** keep a garrison-1 tile as the spread magnet. Reclassified as healthy
  mastery, because the meter still rises +1 per spread and the target is telegraphed. In the
  Prolog, D fills this role automatically.
- **T1 trap (not degenerate, a teaching risk):** Otağ 5 → D moves 4 vs S 4 = failed
  purification, losing 4 troops on turn 1. Mitigated by the move preview + second confirm
  (spirit §3.2, C-53). The C-41 tutorial text must teach "recruit first".
- **Saving gold stays dominated (N5):** unchanged → C-44.

## Progression Analysis

The difficulty gradient is now 5 (D L1) → 9 (D L2, if ripened) → 13 (beast), instead of 13
first (N3). The meter gives a sawtooth: +1 every 3 turns, a drop on each purification, and a
warning at 8/9. Engaged lines have a purposeful move every turn (purify, consolidate, respond to
a spread). The rush line still has one consolidation turn (T4).

## Recommendations

| Priority | Issue | Suggested Fix | Impact |
| --- | --- | --- | --- |
| 1 | ~~Numbers checked by a rule replay script only (12/12), not by game code~~ **Done (C-64):** all 12 lines replayed on the real controllers match; exhaustive pruned search finds no T4 win (`tests/integration/balance/prolog_balance_test.gd`) | **C-64** ✅ | The table is now a regression test |
| 2 | Erlik loss not implemented | **C-63**: `WinCondition.erlik_loss_threshold` + `erlik_power` + `end_turn` step 5 | Without it the Prolog has no loss |
| 3 | Data still on the old model | **C-36**: the §3 table + region-map AC14 | Fastest line and loss depend on it |
| 4 | Meter and warning invisible | C-41 / C-45 spec, C-60 contract, C-54 text | Pillar 3 only works if it can be read |
| 5 | Ruh stalling, N9, N4 targeting | C-44 before M2 balance | Campaign boon curve (D5) |
| 6 | Waste tolerance ≤ 12 | Owner review; C-42 playtest logs turns-to-win, mid-scene boon rate, losses | Possibly X = 8 |

## Values That Need Attention

- `erlik_loss_threshold` = 9. If the playtest shows no felt pressure, use 8 (neglect loss
  T12). If testers lose, use 10.
- Doğu Obası L1 / garrison 0: keep it at L1, since L2 would ripen to L3 at T3.
- Otağ starting army 5 creates the T1 4-vs-4 trap. Keep it, because it teaches production
  before purification. It needs tutorial text.
- Hidden coupling: beast 30 Ruh = `BASE_BOON_COST`. It still holds for rushers. Engaged
  players get boon #1 mid-scene and carry the beast's 30 (registry note updated).

## Verdict: **CONCERNS** (M1-ready design; automated verification and the M2 items open)
