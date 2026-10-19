# Cross-GDD Review Report (re-run)

- **Date:** 2026-10-19
- **Skill:** `/review-all-gdds` (full — consistency + design theory + scenario walkthrough)
- **Task:** C-34 (re-run after the 2026-10-08 FAIL; fixes C-28…C-33)
- **GDDs Reviewed:** 5 system GDDs + concept + systems index
- **Systems Covered:** Bölge Haritası / Tur Akışı (`region-map-system.md`), Ordu (`army-system.md`),
  Savaş Çözümü (`combat-system.md`), Kaynak Yönetimi (`resource-system.md`),
  Kök Böri / Ruh (`spirit-system.md`); context: `game-concept.md`, `systems-index.md`,
  ADR-0005/0006/0007, entity + TR registries, spot-checked code (`map_controller.gd`,
  `win_condition.gd`, `combat_resolver.gd`, `army_controller.gd`, `resource_controller.gd`,
  `chapter_1_map.tres`)
- **Pillars:** Destanı Yaşa · Epik Ama Erişilebilir · İki Katmanlı Tehdit · Modüler İnşa
- **Anti-pillars:** Sandbox değil · Tam 4X değil · Multiplayer değil · Gerçek zamanlı değil · Kuru tarih simülasyonu değil
- **Entity registry:** populated (formulas + constants); used as the Phase 2 baseline.
- **Method:** Phase 2 and Phase 3 ran as parallel independent reviewers (systems-designer,
  game-designer); every worked example and AC number was recomputed. All arithmetic checks
  passed (combat Örnek 1–3 / AC1–3, 8, 9; army §4 table + AC8–11; spirit AC1/2/4/9/11/17,
  §4.4 cumulative cost 30/150/350/630/800; resource AC2–AC24).
- **Code gaps** that already have a fix task (C-19, C-36, C-38, C-51, C-52) are not counted as
  inconsistencies.

---

## Previous report — resolution check

| ID | Holds? | Note |
| --- | --- | --- |
| B1 | ✅ | `resource-system.md` owns income + production (F1–F7). Its Prolog validation evidence is stale → W-A |
| B2 | ✅ rules | Single overlay model everywhere. Residue: art bible beast tamga, old `.tres`/test (C-36) |
| B3 | ✅ | army §3.3 branch 2 = spirit §3.2 = combat §5 = registry = ACs |
| B4 | ✅ | AI → spread → economy → turn++ → check identical in all GDDs, TR-map-003, ADR-0005 diagram (ADR-0005 interface stale → W-E) |
| B5 | ✅ | Conquest keeps corruption (army §3.3, spirit §3.2, combat §5, ACs) |
| B6 | ◑ partly | Timing/deferral/derived state consistent; same-turn re-offer undefined (W-C); tier scope mismatch (W-H) |
| B7 | ✅ | `game_result` latch; `turn_ended`/autosave position undefined (W-D) |
| W1–W11 | ✅ | Verified one by one (W8 also holds though unmarked in the old report) |
| W12 | ◑ partly | spirit §3.1 fixed, AC10 still says "seviyeye göre renk" (W-I) |
| D3 | ◑ partly | Beast L3 + interval 3 in place; Erlik still ignorable, no fail state (N2 → C-49) |
| D4, D5 | ✅ | `erlik_foci`; linear curve + 6–8 boon target |
| D1, D2, D6, D7, D8 | open | Never claimed resolved; see N5–N10 |

---

## Consistency Issues

### Blocking (must resolve before architecture begins)

None.

### Warnings (should resolve before C-17 sets ADRs to Accepted)

⚠️ **W-A — `resource-system.md` Prolog validation still models the enemy-owned lair; AC15 cannot pass**
- §4 "Prolog doğrulaması", "1. tur örneği" ("Düşman AI inden en zayıf komşusu Doğu Obası'na
  saldırıyor: 5'e 3"), F6 example, §5 "en büyük ordu 19", AC15 ("4. turda zafer", "18. turdan
  önce zafer yok") assume the pre-C-29 model.
- Post-C-29 the lair is NEUTRAL L3 (S = 12 → source ≥ 14). Hand simulation: 14 army next to
  the lair is reachable on T4 at the earliest; fastest win ≈ T6. With no enemy, the "8 passive
  turns → no win before T18" bullet is unsupported. Registry `enemy_reinforcement_per_turn_ch1`
  is inert in Prolog.
- **Fix:** mark §4, the F5/F6 examples and AC15 "STALE until C-49" now; rewrite in C-49.

⚠️ **W-B — Prolog has no political enemy, no lose path, no turn cap** (pillar 3)
- Concept Pillar 3 "Her sahnede dış düşman … ve … Erlik birlikte var" vs region-map §3.6/§7,
  spirit §3.7: `game_lost` unreachable; nothing ends a passive scene.
- Already the user decision in **C-49**; must be decided before C-36 data and before C-17/C-18
  (ADR-0005 `EnemyAIController` is not exercised in the demo otherwise).

⚠️ **W-C — "max 1 offer per turn" vs derived pending state vs HUD button** (spirit §3.4, §5, AC15)
- State is derived from `ruh ≥ boon_cost(n)`; after a pick the HUD button is "pending" again
  if Ruh still covers the next cost. A second same-turn pick is undefined.
- **Options:** (a) transient unsaved `offered_this_turn` flag; (b) HUD opens only an offer
  already shown this turn; (c) allow multiple picks, drop "max 1".

⚠️ **W-D — Position of `turn_ended`, autosave and the end check undefined**
- region-map §3.4 names no signal; ADR-0007 autosaves "after … `turn_ended` is emitted" and
  "only while ONGOING"; current code emits `turn_ended` **before** the win/lose check, so a
  listener-based autosave could save a lost state. ADR-0007 also says victory is recorded by
  the autosave, but a mid-turn win never reaches a turn end (§3.7 latch).
- **Fix:** region-map §3.4: `turn_ended` fires after step 5 and only if ONGOING; victory
  persistence (boon picks → save) delegated to `scene-flow.md` (C-35); align ADR-0007 text.

⚠️ **W-E — ADR-0005 `ErlikSpreadController.decide(map_state) -> Array[StringName]` cannot express spirit §4.6**
- `I_eff` needs Gök Kalkanı stacks (`GameState.modifiers`, not in `map_state`); the
  `last_erlik_spread_turn` update "hedef bulunsun bulunmasın" cannot be expressed by a bare id
  list (empty = "not a spread turn" or "no candidate"?). Batch `decide()` over a snapshot differs
  from region-map §3.5 sequential processing when `enemy_actions_per_turn > 1` (moot at 1).
- **Fix:** ADR-0005 amendment (input: interval/effective interval; output: spread result incl.
  "spread turn" flag), noted for C-17.

⚠️ **W-F — ADR-0006 stale against C-31; boon data double-booked**
- ADR-0006 scope note: Gök Kalkanı = PERCENT on `erlik_spread_rate` vs spirit §3.5 FLAT +1 on
  `erlik_spread_interval`; "C-31 open" still listed.
- `ModifierSource` lacks the catalog's `boon_id` / `requires` / stack cap; the stack clamp
  `min(k, GOK_KALKANI_MAX_STACKS)` is the caller's job (resolver does not clamp) — say so.
- Catalog "+1"/"3" duplicate the knobs `GOK_KALKANI_INTERVAL_BONUS` / `GOK_KALKANI_MAX_STACKS`.
- spirit §3.4 counts `n = GameState.boons.size()` and says the save stores `ruh` + `boons`;
  ADR-0006/0007 serialize only `modifiers` (stacks), the JSON example has no `ruh`/`boons`.
  One source of truth is needed for "picks so far" (`n`) vs "stacks".

⚠️ **W-G — Data-model ownership gap** (region-map §3.1/§7)
- `RegionData` list omits `corruption_level` (TR-spirit-001, AC1), the per-turn recruit counter
  (resource §3.2) and `herd_per_turn` (resource §3.1).
- No GDD says where the scene override `ERLIK_SPREAD_INTERVAL = 3`, a boon-pool override or
  per-region initial corruption live (presumably `ChapterMapDefinition`).

⚠️ **W-H — Boon scope: concept tiers vs spirit §3.8**
- Concept "Kapsam Kademeleri": boon system = Vertical Slice; MVP #4 = "Temel arındırma + ruh
  kazanımı". spirit §3.8 puts the offer flow + 3-boon pool (needs ADR-0006 `ModifierController`)
  into M1. C-39's done criterion ("Ruh kazanımı testli; HUD'da görünür") does not cover it.
- **Fix:** harmonize the concept table and C-39 criteria with §3.8 (or shrink §3.8).

⚠️ **W-I — spirit AC10 still asserts a per-level colour ramp** (W12 residue)
- "seviyeye göre renk" vs spirit §3.1 (dither density, C-50) and art bible §5 (single
  "Bozulmuş (Erlik)" row). **Fix:** reword AC10, point to C-50.

### Info

- ℹ️ **Stale citations:** spirit §3.2 "(Savaş §7 'kaybeden taraf tamamen yok olur')" — now
  "dağılır" (C-33); spirit §3.7 `"A ≥ 7"` not in resource §4, "(C-33 / C-49)" → C-49; region-map
  §5 last bullet omits C-51, AC7/AC8/AC10 carry no gap marker; resource §3.1.3/§3.3 call Bereket a
  multiplier (flat `B_add` since C-31); Sürü Kutsaması "via F2" (F2 is gold-only); resource §6
  "karşı güncellemeler" and spirit §6 closing note are done to-do lists; ADR-0006 migration
  "when C-37 lands" → C-39; spirit §3.8 claims a C-44 `/balance-check` not in C-44's criteria.
- ℹ️ **Unqualified rules vs army branch 2:** army §5 "Hedef boş nötr (army=0): barışçıl
  işgal", AC5, §4 "Barışçıl işgal" and §5 "Kendi bölgene hareket: barışçıl birleşme" are wrong
  for corrupted targets (exactly the Prolog lair); §4 formulas still hard-code `PLAYER` (W5 residue).
- ℹ️ **Resource ranges:** F4 `recruit_cost` 1–5 vs §7 1–4; `R_min` 0–2 allows cap 0 vs F3/registry
  1–5; F2 `I_raw` 0–50 below Final scale; F2 "`B_add` MVP 0" although Bereket is in the M1 pool.
- ℹ️ **Coupling not stated:** spirit §3.1 does not say `CORRUPTION_PRODUCTION_MULTIPLIERS` also
  shrinks the recruit cap (resource F3 uses `G_eff`); spirit §6 omits Kurt Gücü/Demir Post → combat.
- ℹ️ **Purification vs knobs:** army §3.3/§4 and the registry `corruption_strength` ignore
  `P_eff` (spirit §4.1, M2). Combat §5 says "başarı = `attacker_won`": flipping
  `draw_favors_defender` would make ties succeed and change losses — decouple purification
  from that knob (success ⇔ `P_eff > S`, losses = Dal 1).
- ℹ️ **Wording:** region-map §5 "Beraberlikte boşalan bölge … engellemez" garbled; §5 "tüm
  komşular düşman veya army≤1" (second clause is the source); spirit §5 "Kök Böri'nin ilk
  görünüşü" vs concept "genesis" at scene opening (means first offer); `current_turn` start value
  (1) not stated (spirit §3.6 "first spread at end of turn 3" assumes it).
- ℹ️ **Headers:** spirit "Taslak (kod henüz yok)"; region-map/army/combat "Belgelenmiş (kod
  mevcut)" though large parts are planned.
- ℹ️ **Art bible §5** still gives the beast `tamga_id = erlik_beast` (region-map: neutral → no tamga) — C-36 cleanup.
- ℹ️ **ADR-0007:** production counters saved at turn end are always 0 (reset in step 4).
- ℹ️ **Registries:** no `resource` TR slug (C-17 adds); TR-spirit-005 not revised for counter-based
  spread; unregistered cross-system facts: `attacker_win_loss_ratio` (also drives purification
  losses), `ruh_per_level`, `erlik_spread_interval` (Prolog 3), `base_boon_cost`/`boon_cost_step`.
  Hidden coupling: beast 30 Ruh = first boon cost 30.
- ℹ️ **Task queue:** no implementation task for ADR-0006 (`ModifierController`/`StatResolver`,
  needed by the M1 pool) or ADR-0007 (save/load).

### 2a Dependency bidirectionality

All listed pairs are mutual: region-map ↔ {army, combat, resource, spirit}, army ↔ {combat,
resource, spirit}, combat ↔ spirit, resource ↔ spirit. Combat and resource need not list each
other. `systems-index.md` dependency column matches the §6 sections.

---

## Game Design Issues

### Blocking

None. No rule makes the Prolog unplayable or unwinnable (hand-sim fastest line ≈ T6:
T1 recruit 2 + claim Bereket Vadisi; T2–T3 recruit there, take Batı and Altay; T4–T5 merge to 15;
T6 purify the lair with P = 14 > 12 → win). Gates owned by planned tasks: **C-49 before C-36 /
C-42**, **C-35 before C-40**.

### Warnings

⚠️ **N1 — Ruh/boon loop has no in-scene payoff in the Prolog** (3a/3f/3g)
- Rational play: conquer → recruit → purify the focus last. Prolog Ruh ceiling ≈ 30 + 4 spreads ×
  10 = 70 → at most 1 boon (boon #2 costs 50); the only offer is the mandatory one at victory; gold
  is wiped at scene end → Bereket, Gök Kalkanı, Arınma Ustalığı have no observable M1 effect. The
  demo cannot validate "kaderimi ben seçiyorum".
- **Options (user):** seed an L1/L2 corrupted tile at Prolog start (mid-scene offer reachable);
  frame the victory pick as "carried to Perde 1"; give Ruh a scene-level payoff. Owner C-49/C-36/C-39.

⚠️ **N2 — Erlik ignorable, no failure state; pillar 3 not load-bearing** (3c/3f/3e; D3 partly)
- No ENEMY, no turn limit, Erlik never changes ownership → `game_lost` unreachable; spread costs
  ≈ 1 gold/turn per event (5–20 %); the L3 beast is a static wall (neglect strengthens nothing —
  contradicts Pillar 3 "biri ihmal edilirse diğeri güçlenir"). Passive play can drift into a zombie
  game. The MVP hypothesis ("çift katmanlı düşman … tatmin edici") is not testable. Owner **C-49**.

⚠️ **N3 — Flat-then-falling Prolog difficulty, dead-turn plateau, hardest purification first** (3e/3c)
- S = 12 constant while army grows 3–4/turn; T4–T5 are decision-free "recruit at Bereket Vadisi";
  the tutorial's first purification is the L3 beast with strict `P > S` and total loss on failure
  (one off-by-one ≈ 13 troops ≈ 3 turns of income). **Recommendation:** an L1/L2 teaching tile
  (P = 5 or 9) before the beast (also feeds N1). Owner C-36/C-41/C-49.

⚠️ **N4 — Erlik is steerable and farmable ("decoy and ripen")** (3c)
- Spread picks min army with alphabetical tie-break → a garrison-1 worthless tile absorbs spreads;
  ripen to L3, purify once (30 Ruh / 1 action instead of 3 × 10 / 3 actions). Faucet stays 10 Ruh
  per spread event (bounded), but neglect is nearly free. Purifying all sources ends the Erlik
  layer for the scene (no ex-nihilo seed). Tuning options for C-49/C-44: ripe-region side effect,
  spread prefers valuable tiles, re-purify multiplier, recurring seeds.

⚠️ **N5 — Saving gold is a false choice; Prolog is a solved recipe** (3d/3c)
- Caps reset every turn, gold earns nothing, recruit costs no action → "spend all at the highest-cap
  region" is dominant, contradicting resource §2 "Biriktirmek de gerçek bir seçenek olmalı". No RNG,
  no AI, no hidden info → solvable after one playthrough (acceptable for a tutorial if conscious).

⚠️ **N6 — No catch-up (D1) and two rules punish the trailing player** (3d)
- Enemy AI and Erlik both target the lowest-army candidate (`I_floor = 0`) → compounding hits on
  the weakest tile (scenario S2-a). Not visible in Prolog; risk for Perde 1+ (C-43/C-44).

⚠️ **N7 — Attention budget: 6 tracked systems from T4; no move-outcome preview or spread telegraph** (3b/3f; D6)
- Ownership/adjacency, garrison arithmetic, gold + caps, combat thresholds, corruption (S, penalty,
  spread clock/target), Ruh/offer. Purification alone has ~7 special rules (P = incoming only, strict
  `>`, total loss, garrison excluded, reinforcing own corrupted tile = attempt, AI ignores corruption,
  conquest does not purify). spirit §3.2 only says the result is "hesaplanabilir"; no GDD requires a
  pre-move forecast or a spread countdown/target indicator (grep: none in `design/`). Post-hoc battle
  reports add little in a fully deterministic visible system — a forecast is what helps.
  **Fix:** add the requirement to the GDDs now; UX specs in C-41/C-45.

⚠️ **N8 — Purification strength does not scale across the campaign; boon power curve flat** (3e)
- `CORR_STR_PER_LEVEL = 4` and max level 3 are global (only the interval has a scene override) →
  max S = 12 in every scene while economies grow (6 → 15 regions); M1 boons are +1 gold, +1 spread
  turn, +20 % Ruh. Options: per-scene `CORR_STR_PER_LEVEL` override / higher level cap; a more
  visible boon tier. Owner C-44.

⚠️ **N9 — Core-fantasy sentence has no mechanic** (3g)
- Concept "İmparatorluk büyüdükçe Erlik'in gölgesi de uzar" vs clock-only spread (spirit §3.6/§4.6).
  Option: spread interval or candidate pool depends on territory size / recent conquests (also helps N2).

⚠️ **N10 — Prolog climax lacks mythic agency; D7 fantasy split persists** (3g/3f)
- "Oğuz slays the beast" = "stack 14 and move"; Kök Böri appears only as an end modal; concept "Kök
  Böri sahne açılışında hedefi işaretler" has no mechanical home (scene-flow, C-35). region-map /
  army ("satranç taşı") / combat fantasies remain wargame arithmetic vs mythic resource/spirit.
  Options: ritual framing for the purifying move, narrative voice for combat/purification reports
  (narrative-director task — none queued).

⚠️ **N11 — Purification traps and the two-stack cost** (3a/3b/3c)
- (a) troops standing in a corrupted tile cannot purify it; (b) "capture corrupted tile → purify"
  needs 2 stacks + 2 actions; (c) reinforcing your own corrupted tile with ≤ S silently burns the
  troops — the only workaround (recruit in place, resource §3.1 R4) is not mentioned; (d) a corrupted
  empty neutral cannot simply be occupied. Pillar 2 test ("2–3 turda anlayabilir mi?") → playtest;
  consider a confirm/warning for a move that would be a failed purification.

⚠️ **N12 — Obsolete post-C-29 content; ordering contract under-specified**
- = W-A (resource §4/AC15/§11 Q7), plus `scene-flow.md` unwritten while region-map §3.7 and spirit
  §3.4/§5 already depend on it for [game_won → pending boons (mandatory, one by one) → outro].

### Economy (sources / sinks)

| Resource | Sources | Sinks | Condition |
| --- | --- | --- | --- |
| Gold | Σ floor(G_base × M_c) + B_add per turn (Prolog 2 → 9/10); start 6 per scene | Recruit 2/unit (no action); upkeep 0; wiped at scene end | Sink exists; snowball bounded by map; no catch-up (N6); saving dominated (N5) |
| Army | Recruit (cap, gold-limited ≈ 2.5–4.5/turn); start 5; enemy reinforcement (inert in Prolog) | Combat losses; purification ceil(S/2) or all; dispersal; 1 locked garrison/region | Unbounded accumulation (D2) — and the required Prolog path; overstack free |
| Ruh | Purification only: round(10·L·(1+0.2s)); Prolog ceiling ≈ 70 | Boons 30 + 20n | Closed, bounded loop; no Prolog payoff (N1); decoy-ripen (N4) |
| Actions | 1 / turn | Move / attack / purify (incl. failures) | The real scarce currency; dead turns while stacking (N3) |
| Regions | Conquest, purification settlement | Enemy AI (none in Prolog), draw-emptying → neutral | Monotone snowball in Prolog; no loss path (N2) |
| Corruption | Initial (beast L3); spread +1 per I_eff onto min-army candidate | Purification | Bounded ≤ 3/tile; time-driven not conquest-driven (N9); steerable (N4) |
| Boons | Ruh | — (permanent) | Gök Kalkanı capped 3; flat +1 soft cap; power curve flat (N8) |

### Previous D1–D8

| # | Status | Note |
| --- | --- | --- |
| D1 | open | `I_floor` 0; AI + Erlik both target the weakest tile (N6) |
| D2 | partly | Upkeep knob (U = 0); turtling is the designed Prolog path |
| D3 | partly | Beast mandatory (`erlik_foci`), L3, interval 3; ignoring spread still dominant (N2) → C-49 |
| D4 | addressed | C-32 |
| D5 | addressed (verify) | Linear 30 + 20n, target 6–8; Prolog ceiling 1 boon; verify in C-44 |
| D6 | open, mitigated | Turn-start-only offers, deferral; still 6 systems (N7) |
| D7 | open | N10; no narrative task queued |
| D8 | open (deferred) | No AI in Prolog; `enemy-layers.md` unwritten; `region_id` acts as AI priority at 1 action/turn |

### Pillar alignment

| System | Pillar(s) | Note |
| --- | --- | --- |
| Region map | Epik Ama Erişilebilir, İki Katmanlı Tehdit | Clean; fantasy analytical |
| Army | Epik Ama Erişilebilir, Modüler İnşa | Dry; purification rules add load (N11) |
| Combat | Epik Ama Erişilebilir | Pure math (D7) |
| Resource | Epik Ama Erişilebilir, Destanı Yaşa ("boyları toplayan kağan") | Saving claim not supported (N5) |
| Spirit | Destanı Yaşa, İki Katmanlı Tehdit | Strongest alignment; Prolog payoff weak (N1) |

Anti-pillars: no violations; "Kuru Tarih Simülasyonu değil" at risk (D7/N10).

---

## Cross-System Scenario Issues

Scenarios walked: 3
1. Purify Canavarın İni as the winning move of the Prolog while Ruh crosses the first boon threshold
2. `end_turn` where Erlik spread corrupts a player region the enemy AI attacked the same turn, then income
3. Conquer a corrupted garrisoned neutral, purify it next turn while a deferred boon offer is pending

### Blockers

None. No double rewards found.

### Warnings

⚠️ **S1-a — Commit ordering before the win signal is unspecified** (region-map, spirit, army)
- Pending boon is derived from `ruh` at read time. If a `game_won` handler runs before the Ruh grant
  is committed, no offer shows and the Kök Böri moment is skipped (signal-ordering race under
  call-down/signal-up). **Fix:** one sentence in region-map §3.3 + spirit §3.2: owner, army,
  corruption, Ruh and actions are all committed before the win check/emission; AC: after the final
  purification `game_won` fires and the offer is pending.

⚠️ **S1-b — First boon has no in-scene effect** — see N1.

⚠️ **S2-a — Correlated double hit** (region-map §3.5, spirit §4.6, army §3.3)
- A successful defence lowers army → the tile becomes the Erlik magnet the same end_turn; next turn
  reinforcing it with ≤ S burns the troops (N11). Real two-layer synergy but a D1 accelerator.
  Options: exclude tiles attacked this turn from spread, change the target rule, or UI warning.

⚠️ **S3-a — Two stacks, two actions** — standing garrison does not count toward P (N11).

⚠️ **S3-b — Same-turn chaining via the HUD button** — = W-C.

### Info

- ℹ️ **S1-c** Lock scope: region-map §3.7 does not say boon selection stays allowed under the lock
  (it must — the victory offers happen after `game_won`).
- ℹ️ **S1-d** 30 = 30 equality holds only with no earlier boon / no Arınma stack (hidden coupling, Info above).
- ℹ️ **S1-e** If C-49 gives the beast a garrison > 0, the final move becomes combat (no purification,
  no win that move). Keep garrison 0 in data + a data AC.
- ℹ️ **S2-b** If the AI takes the last player tile in step 1, spread/income/turn++ still run before
  LOST latches; add an early exit after step 1 (harmless but emits events on a dead game).
- ℹ️ **S2-c** The HUD income forecast ignores steps 1–2 (AI, spread); the spread target is
  deterministic and could be shown.
- ℹ️ **S3-c** Picking Arınma Ustalığı before a purification boosts it (+6 on L3) — consistent with
  "etki seçildiği an".
- ℹ️ **S3-d** "Aynı 3 lütuf" holds only while the eligible pool is constant (M2 `requires` gates);
  state that the offer is recomputed when opened.
- ℹ️ **S3-e** End-of-turn spread can deepen a freshly conquered thin tile (+4 S) — deterministic,
  visible at turn start; a planning hazard, not an exploit.

---

## GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
| --- | --- | --- | --- |
| resource-system.md | W-A stale Prolog validation / AC15; Bereket wording; ranges | Consistency | Warning |
| spirit-system.md | W-C same-turn offer; W-F boon data vs ADR-0006; W-I AC10; stale citations; S1-a | Consistency | Warning |
| region-map-system.md | W-D `turn_ended` position; W-G data model; S1-a/S1-c; wording | Consistency | Warning |
| army-system.md | Unqualified "barışçıl" rules vs branch 2; §4 PLAYER wording; N11 workaround | Consistency | Warning |
| game-concept.md | W-H tier table vs spirit §3.8 | Consistency | Warning |
| ADR-0005 / ADR-0006 / ADR-0007 | W-E, W-F, W-D | Architecture | Warning (before C-17) |

---

## Verdict: CONCERNS

No blocking issues. Warnings W-A…W-I and S1-a should be fixed before C-17 sets the ADRs to
Accepted; design warnings N1–N4/N9 belong to C-49 (Prolog pressure, teaching tile, loss
condition), N6/N8 to C-44, N7/N11 to the UX tasks (C-41/C-45) with a GDD requirement added now,
N10 to a narrative task.

### Follow-up tasks (queued in `production/continuation.md`)
- **C-53** — fix W-A…W-I, S1-a/S1-c, W-C, the Info citations/wording and add the move-forecast /
  spread-telegraph requirement (N7) + recruit-in-place note (N11c); ADR-0005/0006/0007 amendments.
  Blocks C-17.
- **C-49** — scope extended with N1–N4, N9, S1-e (teaching tile, loss condition, spread steering).
- **C-54** — narrative voice for combat/purification reports and Kök Böri framing (D7/N10).
- **C-55 / C-56** — ADR-0006 and ADR-0007 implementation tasks (missing from the queue).

---

## Resolution log (C-53, 2026-10-19)

| Item | Status | Where |
| --- | --- | --- |
| W-A | ✅ marked "ESKİMİŞ — C-49'a dek" (§4 table, 1. tur + F6 examples, §5, AC15, Q7) | resource-system.md |
| W-B | → C-49 (user decision: loss condition / pressure) | continuation C-49 |
| W-C | ✅ auto-modal max 1 per turn start; HUD may chain picks in the same turn; offer recomputed when opened (S3-d) | spirit §3.4, AC15 |
| W-D | ✅ `turn_ended` after step 5 and only while ONGOING; early LOST exit after step 1 (S2-b); victory persistence → scene-flow | region-map §3.4, AC8/AC12; ADR-0007 amendment; code C-51 |
| W-E | ✅ `decide(map_state, effective_interval) -> SpreadDecision`; sequential planning note | ADR-0005 amendment |
| W-F | ✅ Gök Kalkanı FLAT on `erlik_spread_interval`; `ModifierSource.max_stacks`; `BoonDefinition`; "save choices, derive effects" (`boons` single source, modifiers rebuilt on load) | ADR-0006/0007 amendments, spirit §3.4/§3.5, architecture registry |
| W-G | ✅ field ownership list for `RegionData` / `MapState` / `ChapterMapDefinition`; `current_turn` starts at 1 | region-map §3.1 |
| W-H | ✅ concept MVP #4 + tier table; C-39 done criterion | game-concept.md, continuation |
| W-I | ✅ AC10 → art bible layer rule (C-50) | spirit AC10 |
| S1-a / S1-c | ✅ all move results committed before `game_won`; boon picks exempt from the lock | region-map §3.3/§3.7, spirit §3.2, spirit AC20 |
| S1-e | → C-36 data AC (lair garrison 0) | spirit §3.2, continuation C-36 |
| N7 | ✅ requirement: move-outcome preview (+ second confirm for a failing purification) and spread telegraph; spec C-41/C-45 | spirit §3.2/§3.6, AC21 |
| N11c | ✅ recruit-in-place note | army §5, resource §5 |
| Info: purification vs `draw_favors_defender` | ✅ decoupled (success ⇔ `P_eff > S`, Dal 1 losses) | combat §5, spirit §3.2, army §4 |
| Info: stale citations / wording / headers / ranges | ✅ | all GDDs |
| Info: registry gaps | ✅ +4 constants (`attacker_win_loss_ratio`, `ruh_per_level`, `base_boon_cost`, `erlik_spread_interval`), TR-spirit-005 revised; `resource` TR slug → C-17 | registries |
| Info: art bible beast tamga | → C-36 | continuation C-36 |
| N1–N4, N9 | → C-49 | continuation C-49 |
| N5, N6, N8 | → C-44 (balance) / Perde 1 design | — |
| N10 | → C-54 | continuation |
| N12 | = W-A + C-35 | — |

## Resolution log (C-49, 2026-10-19)

Balance report: [`design/balance/prolog-balance-2026-10-19.md`](../balance/prolog-balance-2026-10-19.md).

| Item | Status | Where |
| --- | --- | --- |
| W-A | ✅ resource §4 rewritten with C-49 numbers (fastest T5, neglect loss T15, waste tolerance), F6 example generic, §5 max army, AC15 rewritten, Q7 answered | resource-system.md |
| W-B / N2 | ✅ Erlik loss: `erlik_power = Σ corruption_level ≥ erlik_loss_threshold` (Prolog 9) at `end_turn` step 5; no political ENEMY in the Prolog (deliberate) | region-map §3.6/§4/§7/AC13, spirit §3.7/§4.7/AC22 |
| N1 / N3 | ✅ teaching tile Doğu Obası L1 garrison 0 (P ≥ 5, +10 Ruh) before the L3 beast; mid-scene boon reachable ~T7 for engaged play | spirit §3.2/§3.8, resource §4 |
| N4 | ◑ Prolog: neglect now costs (meter); steering = healthy mastery; Ruh stalling has no M1 consequence → **C-44** | spirit §5 |
| N9 | ◑ deferred to **C-44** (campaign-scale rule); emergent Prolog link noted | spirit §5 |
| S1-e | ✅ lair garrison 0 decided + data AC | spirit §3.2, region-map AC14 |
| D3 | ✅ interval 3 verified (2 too harsh, 4 too slow) | spirit §3.7/§7 |
