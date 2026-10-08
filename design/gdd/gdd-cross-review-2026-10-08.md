# Cross-GDD Review Report

- **Date:** 2026-10-08
- **Skill:** `/review-all-gdds` (full — consistency + design theory + scenario walkthrough)
- **GDDs Reviewed:** 4 system GDDs + concept + systems index
- **Systems Covered:** Bölge Fethi / Harita (`region-map-system.md`), Ordu (`army-system.md`),
  Savaş Çözümü (`combat-system.md`), Kök Böri / Ruh (`spirit-system.md`);
  context: `game-concept.md`, `systems-index.md`, `docs/architecture/adr-0005-ai-architecture.md`
- **Pillars:** Destanı Yaşa · Epik Ama Erişilebilir · İki Katmanlı Tehdit · Modüler İnşa
- **Anti-pillars:** Sandbox değil · Tam 4X değil · Multiplayer değil · Gerçek zamanlı değil · Kuru tarih simülasyonu değil
- **Entity registry:** `design/registry/entities.yaml` is an empty template. Consistency checks
  rely on full GDD reads only. Run `/consistency-check` (C-14) to populate it.

Key findings were spot-checked against the code: gold is only ever set (`game_context.gd`:
`_game_state.gold = 100`) and never spent; `map_controller.gd` checks the win condition
both after `attempt_move` and at the end of `end_turn`.

---

## Consistency Issues

### Blocking (must resolve before architecture begins)

🔴 **B1 — Army production has no owning GDD; gold has no sink; Prolog barely winnable**
- `game-concept.md` "MVP Tanımı" #2: "Bölge fethi + kaynak (altın) + ordu üretimi + hareket";
  Temel Döngü step 2: "Ordu üret (kaynak harca → birim)".
- `army-system.md` §7 has no production knob (only "Genişleme (planlı)" … "ordu bakım maliyeti");
  `resource-system.md` is "Yazılmadı" in the index; `region-map-system.md` §4 only adds income
  (`game_state.gold += tur_geliri`).
- Prolog data (`chapter_1_map.tres`): player starts with 5 army; merges move troops, combat only
  removes them, so the total never grows. Winning needs 3 conquests (neutral armies 3/3/2) **and**
  beating the 6-army lair (A ≥ 7) — only possible if the enemy AI drains itself first.
- **Options:** (a) write `resource-system.md` with production formula + cost; (b) add production
  to `army-system.md`; (c) change Prolog data / win condition until production exists.

🔴 **B2 — Erlik is modelled two incompatible ways**
- `spirit-system.md` §3.1/§3.2: Erlik = `corruption_level` overlay removed by purification;
  Ruh "Sadece arındırmadan kazanılır". `game-concept.md`: Prolog "İlk Erlik canavarı —
  arındırmanın tanıtımı".
- `region-map-system.md` §5, §8 AC1/AC7 and `chapter_1_map.tres`: "Canavarın İni" is an
  `owner = ENEMY` region (`enemy_tamga_id = erlik_beast`, `WIN_CONDITION_CH1` "slay the beast of
  Erlik") defeated by **conquest** → no Ruh, and it carries the enemy-king colour (Art Bible:
  rust orange = "Düşman kral (tümü)"; purple = "Sadece Erlik").
- **Options:** (a) the beast becomes a corrupted region that is purified; (b) add a third owner
  type (ERLIK); (c) declare the beast political-layer and move "ilk arındırma" to a separate
  corrupted Prolog region.

🔴 **B3 — Purification is not part of army arrival resolution**
- `army-system.md` §3.3 has only two branches: "Barışçıl … VEYA `army_count == 0`" and "Savaş";
  §6 claims "arındırma da ordu gönderimi kullanır".
- `spirit-system.md` §3.2 does not define: whether survivors occupy the region, whether ownership
  changes, how an owned + garrisoned + corrupted target resolves (fight first, then purify?), or
  whether purification costs `actions_remaining`.
- **Options:** third arrival branch owned by `army-system.md` §3.3, or a separate "purify" action
  defined in `spirit-system.md`.

🔴 **B4 — Ownership of Erlik spread / corruption and its end_turn position unresolved**
- Index lists "Erlik Bozgunu & Arındırma → `corruption-purification.md`" and "Katmanlı Düşman →
  `enemy-layers.md`" as separate systems, yet `spirit-system.md` §3.1/§3.6/§4 already defines
  corruption, purification and spread and owns `ERLIK_SPREAD_INTERVAL`, `CORR_STR_PER_LEVEL`;
  §6 also says "Katmanlı Düşman … Erlik yayılımı bu sistemin AI tarafı".
- `region-map-system.md` §3.4 fixes "(1) düşman AI → (2) gelir → (3) current_turn+=1 →
  (4) kontrol" (also AC4 and TR-map-003) — no spread step. ADR-0005 places `_erlik.decide()`
  after enemy AI, but no GDD does. Spread-before-income vs after-income changes the corruption
  penalty on that turn's income.
- **Decide:** (a) which GDD owns spread/corruption; (b) exact end_turn position (before AI /
  after AI before income / after income / at player-turn start); then update region-map §3.4 + AC4.

🔴 **B5 — Fate of corruption on conquest undefined** (scenario walkthrough)
- `combat-system.md` §3.3 "Kazanılırsa → hedef `owner = PLAYER`, `army_count = attacker_remaining`"
  — silent on `corruption_level`; `spirit-system.md` §3.2 "komşu/sahip olduğu bir bölgeden …"
  is ambiguous about attacking corrupted enemy regions.
- **Options:** (A) corruption persists (purify separately); (B) conquest auto-purifies (no Ruh);
  (C) corrupted enemy regions must be purified before they can be attacked.

🔴 **B6 — Boon offer timing and UI flow undefined**
- `spirit-system.md` §3.4 triggers an offer "Toplam Ruh eşiğine ulaştığında" (mid-scene);
  `game-concept.md`: "Sahne sonunda destan epilog + ruh lütfu". §5 allows deferral ("ertelerse")
  but no re-offer rule; whether effects apply this turn or next is unspecified (matters for
  "Bereket" +%10 gold vs same-turn income). Concept scope tiers put boons in Vertical Slice /
  Perde 1, but the GDD has no MVP subset.
- **Options:** immediate modal vs end_turn step vs scene end; effects next turn (safest).

🔴 **B7 — Mid-turn win vs end-of-turn check**
- `region-map-system.md` §3.3: "`attempt_move` sonrası: anında `game_won`"; §3.4 step 4 checks
  at turn end. Code does both. Undefined whether the game ends immediately or `end_turn` can
  still run (duplicate `game_won`, or AI conquering the last player region after a win).
  Simultaneous win + lose at turn end → code's `if win elif lose` gives win precedence, undocumented.
- **Options:** (A) mid-turn win ends the game immediately, `end_turn` never runs; (B) flag and
  skip; (C) only check at end_turn. Document precedence.

### Warnings

⚠️ **W1 — Wrong worked example** — `army-system.md` §4: "Hedefte 3 düşman varsa → savaş (4 vs 3),
saldıran kazanır, hedef army=3 (bkz. combat-system Örnek 1)". Combat Dal 1 gives 4 − ceil(1.5) = **2**;
Örnek 1 uses A = 5. *Quick edit.*

⚠️ **W2 — "Loser always wiped" vs draw survivors** — `combat-system.md` §7 "Kaybeden taraf her zaman
tamamen yok olur"; §3 "(büyük oranda) yitirir"; Örnek 3 / AC3 `attacker_remaining = 1`.
`army-system.md` §3.3 does not say where survivors go (code drops them). Define return/disband
or reword.

⚠️ **W3 — Draw can leave an owned region at 0 army** — A = D = 1 → `defender_remaining = 0`, owner
kept. Army §3.3 then treats it as peaceful ("VEYA `army_count == 0`"); a 0-army ENEMY region still
blocks `must_defeat_all_enemies`, a 0-army PLAYER region blocks `game_lost`. Define floor / revert
to neutral.

⚠️ **W4 — `draw_favors_defender` knob vs formula** — listed as tunable in combat §7; §4 Dal 3
hard-codes `attacker_won = false`. Code honours the knob (with `false`, 1v1 draw captures with 0 army).

⚠️ **W5 — region-map §3.5 documents ADR-0005 as current** — "`EnemyAIController.decide(map_state)` …"
while header says "Belgelenmiş (kod mevcut)"; ADR-0005 is Proposed, AI is inline `_run_enemy_ai()`.
Army §3.1 `can_move` requires "`owner == PLAYER`", §3.3 hard-codes "`owner = PLAYER`", so army §6
"düşman AI aynı taşıma kurallarını kullanır" does not hold. Mark planned or make rules owner-agnostic.

⚠️ **W6 — Tie-breaks differ** — region-map §4 "eşitlikte ilk bulunan"; spirit §4.6 "region_id
alfabetik ilk"; ADR-0005 "lowest army_count, then region_id alphabetical". Order of spending
`enemy_actions_per_turn` across enemy regions unspecified. *Quick edit (pick one).*

⚠️ **W7 — Win formula wording** — "ele geçirilen nötr sayısı" / AC7 "3 nötr ele geçirilip", but
`conquered_count = oyuncu_bölge_sayısı − 1` counts all owned regions (incl. the lair); off by one
if the start region is lost.

⚠️ **W8 — Income formula has no owner** — region-map §4 owns `Σ gold_per_turn` ("Kaynak Sistemi
ile ortak"); spirit §4.3 modifies it (corruption penalty + floor), "Bereket" +%10. AC5 fails once
corruption exists. Spirit §3.1 "seviye 3 = üretim durur" / AC7 "0" vs `PROD_PENALTY_PER_LEVEL =
0.25` → level 3 keeps 25 %.

⚠️ **W9 — Boons reference non-existent hooks** — "Sürü Kutsaması" (`herd_per_turn`; no herd field),
"Yiğit Ruhu" (hero units, no GDD), "Kurt Gücü"/"Demir Post" ±5 % on integer A/D of 2–6 → no effect;
combat §3 "üç girdiyle" lists two. Purification needs A > 4 × level; Prolog max army 5 → level 3
(12) unpurifiable.

⚠️ **W10 — "Gök Kalkanı" stacking breaks** — boons stack "aksi belirtilmedikçe"; `ceil(I / (1 −
0.20 × kalkan_sayisi))` divides by zero at 5 stacks, negative beyond. Cap or change formula. *Quick edit.*

⚠️ **W11 — Ruh scaling direction** — concept: "Erlik güçlendikçe … ruh kazanımı zorlaşır";
spirit §4.2 `ruh_gain` rises with `corruption_level`, nothing scales with corrupted-region count.

⚠️ **W12 — Spirit visuals stale vs Art Bible** — §3.1 "zehir yeşili → mor → siyah", AC10 "seviyeye
göre renk"; Art Bible: green = purified, corruption = purple-black dithered overlay that "sahiplik
rengini gizlemez", no per-level ramp. *Quick edit (point to Art Bible §4/§8).*

---

## Game Design Issues

### Blocking

None independent of B1 — the economy cannot be analysed until army production exists (B1).

### Warnings

⚠️ **D1 — No catch-up mechanic (snowball / death spiral)** — conquest → gold → army → conquest;
losing regions cuts income with no recovery valve. Real magnitude measurable only after B1.
Options: slower Erlik when trailing, cheaper boons when trailing, defensive bonus at < 3 regions.

⚠️ **D2 — Army has no time-based sink** — once production exists, no upkeep/attrition → turtling
accumulates unlimited army. Options: upkeep (e.g. 1 gold / 5 army), idle attrition, higher
attacker losses.

⚠️ **D3 — Erlik ignorable in Prolog** — no initial corruption, spread every 4 turns (~3 events in
a 12-turn scene) → < 10 % income impact; "İki Katmanlı Tehdit" not load-bearing early. Options:
start with 1–2 corrupted regions, interval 2, or require purification for the win (ties to B2).

⚠️ **D4 — Win condition scope** — political only vs political + spiritual (no corrupted regions)
is not stated anywhere; affects thematic closure (winning with visible corruption).

⚠️ **D5 — Boon cost curve** — `boon_cost(n) = 30 + n × 20` → 3 600 Ruh for 18 boons; either
unfundable at interval 4 or power creep at interval 2. Options: exponential cost, cap ~12,
diminishing tiers. Run `/balance-check` after B1–B4.

⚠️ **D6 — Attention budget at threshold** — ~4–5 active systems per turn (ownership, army position,
gold, corruption, Ruh/boon). Gate council (scene 3+) and season (scene 4) behind tutorialised scenes.

⚠️ **D7 — Player fantasy split** — map/army/combat read as dry wargame math ("satranç taşı"),
spirit as mythic ("Ülgen'in yeryüzündeki eli"); risks the "Kuru Tarih Simülasyonu değil"
anti-pillar. Narrative voice in combat reports / unit naming (narrative-director task).

⚠️ **D8 — Enemy AI predictable, no Erlik behaviour** — always weakest neighbour, 1 action;
acceptable for the Prolog tutorial, needs Erlik-flavoured behaviour from scene 2 (`enemy-layers.md`).

### Info
- ℹ️ Prolog layout creates good tempo pressure (lair next to 0-army Bereket Vadisi).
- ℹ️ Attacker loss ratio 0.5 is generous; tune after playtest.
- ℹ️ Deterministic boon selection (§4.5) is excellent for testing; add a campaign seed later, not RNG.
- ℹ️ Scene length: "10–18 tur" vs "20–35 dakika" implies ~1.5–2 min/turn — reconcile after playtest.
- ℹ️ Modular pillar has no interface contracts yet — check during `/architecture-review` (C-17).

### Resource source / sink

| Resource | Sources | Sinks | State |
| --- | --- | --- | --- |
| Gold | Region income at end_turn | **none defined** (B1) | Accumulates forever |
| Army | **none** (production undefined) | Combat losses | Monotonically decreasing |
| Ruh | Purification only | Boons only | Closed loop |
| Actions | 1 / turn | Move / attack (purify?) | Healthy scarcity |
| Regions | Conquest | Enemy AI conquest only | Snowball risk |
| Corruption | Erlik spread (every 4 turns) | Purification | Depends on interval |

### Pillar alignment

| System | Pillar(s) | Note |
| --- | --- | --- |
| Region map | Epik Ama Erişilebilir, İki Katmanlı Tehdit | Clean; fantasy analytical |
| Army | Epik Ama Erişilebilir, Modüler İnşa | Minor drift (dry) |
| Combat | Epik Ama Erişilebilir, İki Katmanlı Tehdit | Minor drift (pure math) |
| Spirit | Destanı Yaşa, İki Katmanlı Tehdit | Strongest alignment |

Anti-pillars: no violations; "Kuru Tarih Simülasyonu değil" at risk (D7).

---

## Cross-System Scenario Issues

Scenarios walked: 5
1. Conquer an enemy-owned, corrupted region → B5
2. End of turn with Erlik spread → B4 (+ income timing warning)
3. Purify a region and cross the boon threshold → B3, B6
4. Simultaneous win and lose conditions → B7
5. Win by conquering a corrupted enemy region → D4

Additional warnings: corruption penalty hitting income on the same turn it spreads; Erlik + AI both
hitting the last player region in one end_turn (ambiguous cause of loss); same-turn boon effect
on income.

---

## Info (documents)

- ℹ️ `systems-index.md`: "Son Güncelleme: 2026-07-14" stale; no dependency column; Game State,
  accessibility, localization, tamga not listed; note "spirit … MVP sonrası ilk yazılacak GDD"
  outdated (written). Nothing references `corruption-purification.md`.
- ℹ️ `game-concept.md`: "Son Güncelleme: 2026-07-14"; Sonraki Adımlar `/map-systems` and spirit
  GDD unchecked.
- ℹ️ `region-map-system.md` §3.1 MapState field list omits `enemy_actions_per_turn`,
  `player_tamga_id`, `enemy_tamga_id`; AC9 omits Colour-Blind Mode (tamga always visible).
- ℹ️ `spirit-system.md` §4.5 `scene_id` vs code `chapter_id`; §5 "ertelерse" (Cyrillic typo);
  §4.6 target set vs edge case "temiz komşu yoksa atlanır" mismatch.
- ℹ️ Dependency asymmetry: `army-system.md` lists spirit as a dependency; `spirit-system.md` §6
  does not list army.

---

## GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
| --- | --- | --- | --- |
| region-map-system.md | B4 end_turn order, B7 win timing, W5, W6, W7, W8 | Consistency | Blocking |
| spirit-system.md | B2, B3, B5, B6, W9–W12 | Consistency + Design | Blocking |
| army-system.md | B1, B3, W1, W5 | Consistency | Blocking |
| combat-system.md | B5, W2, W3, W4 | Consistency | Warning |
| *(not written)* resource-system.md | B1 — production + income formula owner | Consistency | Blocking |

---

## Verdict: FAIL

One or more blocking issues must be resolved before architecture (C-17 `/architecture-review`,
C-18 `/create-architecture`).

### Required actions before re-running
1. **B1** — Define army production (cost, formula, owner GDD); decide whether `resource-system.md`
   is written now.
2. **B2 + B4** — Decide the Erlik model (overlay vs owner type), the owner of spread/corruption
   (`spirit-system` vs `corruption-purification` vs `enemy-layers`), and its end_turn position;
   update `region-map-system.md` §3.4 + AC4 (and TR-map-003).
3. **B3 + B5** — Define purification as an action (branch or separate action, action cost,
   occupation) and corruption on conquest.
4. **B6** — Define boon offer timing, deferral and effect timing; mark the MVP subset.
5. **B7** — Define mid-turn win behaviour and win/lose precedence in `region-map-system.md`.
6. Then fix warnings W1–W12 (several are quick edits) and re-run `/review-all-gdds`.
