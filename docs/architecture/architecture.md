# ULUS: Blood of the Sky Wolf — Master Architecture

## Document Status

- **Version:** 1.0
- **Last Updated:** 2026-10-19
- **Engine:** Godot 4.7 (GDScript, static typing; Compatibility renderer; 2D canvas, 640×360 viewport)
- **GDDs Covered:** `game-concept.md`, `systems-index.md`, `region-map-system.md`,
  `army-system.md`, `combat-system.md`, `resource-system.md`, `spirit-system.md`
  (cross-review 2026-10-19: CONCERNS, resolved in C-53)
- **ADRs Referenced:** ADR-0001 … ADR-0012 (all **Accepted** 2026-10-19; ADR-0008 audio added by C-23, ADR-0009 localization by C-61, ADR-0010 move resolution by C-59, ADR-0011 presentation by C-60, ADR-0012 scene flow by C-62 —
  [architecture-review-2026-10-19.md](architecture-review-2026-10-19.md))
- **Requirements baseline:** [tr-registry.yaml](tr-registry.yaml) v3 — 36 TRs; coverage in
  [architecture-traceability.md](architecture-traceability.md)
- **Review mode:** lean
- **Technical Director Sign-Off:** 2026-10-19 — **CONCERNS** (approved with conditions; self-review,
  gate TD-ARCHITECTURE): (1) 4 of 36 TRs still lack an ADR → §7 (Move Resolution before C-38/C-41);
  (2) HIGH-risk engine domains verified on 4.7.1 or flagged (§1, C-58); (3) API boundaries minimal and
  implementable (§5), `bind_services` growth → QQ-01; (4) the only Foundation gap (Localization, as
  built) is low risk and does not block implementation
- **Lead Programmer Feasibility:** skipped — lean mode (not a phase gate)

---

## 1. Engine Knowledge Gap Summary

ULUS is a turn-based 2D game: no physics simulation, no 3D, no networking, no per-frame
gameplay loop. Most engine surface it touches is stable since 4.0. The model's training data
covers ~4.3; 4.4–4.7 are post-cutoff. The engine reference under
`docs/engine-reference/godot/` is verified for 4.6 only (refresh task **C-58**).

| Risk | Domain | Relevance to ULUS | Status |
| --- | --- | --- | --- |
| HIGH | GDScript language additions (4.5 `@abstract`, variadic args; 4.4 typed dictionaries) | `SaveStore` (`@abstract`), typed `Dictionary[StringName, RegionData]` for new state | `@abstract` verified on 4.7.1 (one-line form, body-less funcs); typed dicts verified |
| HIGH | Typed-array invariance (runtime) | `StatResolver` (`Array[StatModifier]`) | Verified 4.7.1: runtime error for untyped input; `.filter()` keeps typing; convert with `assign()` |
| MEDIUM | `FileAccess` return types (4.4), `JSON` number/precision behaviour, `DirAccess` rename | ADR-0007 save path | Verified 4.7.1 Linux; Windows rename + `user://` per OS unverified |
| MEDIUM | Accessibility (4.5 AccessKit) | Keyboard focus navigation, future screen-reader support | Not used yet; UX tasks (C-25, C-45) must check the 4.7 API before relying on it |
| LOW | 2D canvas rendering, pixel snap, integer scaling, Nearest filter | All map/UI drawing (`_draw`, `Control`) | Project settings checklist done (technical-preferences) |
| LOW | Signals (callable syntax), `RefCounted` lifetime, scene instancing | Whole architecture | Stable |
| n/a | Jolt (3D only), SMAA, D3D12 default, 3D IK | Not used | — |

Systems touching HIGH/MEDIUM domains: Save/Load (Foundation), Modifier pipeline
(Foundation), State (Foundation, typed dictionaries), Localization/fonts (TextServer, RTL —
covered by future ADR C-61).

---

## 2. System Layer Map

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ PRESENTATION   CampaignMap · RegionNode · AdjacencyLineDrawer · RegionInfoPanel│
│                (features/grid view nodes) · HUD (ui/hud) · Settings / Battle   │
│                report / Kök Böri modal / scene intro-outro (ui/screens)        │
│                Audio (features/audio, planned) · corruption overlay (C-50)     │
├──────────────────────────────────────────────────────────────────────────────┤
│ FEATURE        Enemy AI + Erlik spread decisions (features/ai, ADR-0005)       │
│                Spirit — Kök Böri/Ruh: SpiritController, boon catalog, offers   │
│                (features/bozkurt) · Campaign / scene flow (features/campaign,  │
│                C-35) · later: diplomacy, council, seasons, heroes, legacy      │
├──────────────────────────────────────────────────────────────────────────────┤
│ CORE           Turn flow & map orchestration — MapController (features/grid)   │
│                Army movement & arrival — ArmyController (features/army)        │
│                Combat resolution — CombatResolver (features/combat, leaf)      │
│                Economy — ResourceController (features/resources)               │
├──────────────────────────────────────────────────────────────────────────────┤
│ FOUNDATION     Context hierarchy — RootContext / MenuContext / GameContext     │
│                (ADR-0001) · DI via bind_services (ADR-0003) · Data-only state  │
│                — GameState, MapState, RegionData, AccessibilitySettings        │
│                (ADR-0004) · Modifier pipeline (features/modifiers, ADR-0006)   │
│                · Save/Load (features/save, ADR-0007) · Localization            │
│                (features/localization) · Content definitions (.tres)           │
├──────────────────────────────────────────────────────────────────────────────┤
│ PLATFORM       Godot 4.7 (SceneTree, Control, CanvasItem._draw, TextServer,    │
│                FileAccess/DirAccess, JSON, ResourceLoader for res:// only)     │
│                · OS file system (user://) · Steam (PC, later)                  │
└──────────────────────────────────────────────────────────────────────────────┘
```

**Not an event bus:** there is no Foundation-level event hub (forbidden pattern). Signals
are declared on the node/service that owns them ("call down, signal up").

| GDD system | Layer | Module(s) | Engine-risk note |
| --- | --- | --- | --- |
| Bölge Haritası / Tur Akışı | Core (+ Presentation views) | `features/grid` | LOW |
| Ordu | Core | `features/army` | LOW |
| Savaş Çözümü | Core | `features/combat` | LOW |
| Kaynak Yönetimi | Core | `features/resources` | LOW |
| Kök Böri / Ruh (+ Erlik bozulma/arındırma) | Feature | `features/bozkurt`, `features/ai` (spread) | LOW |
| Katmanlı Düşman (political AI) | Feature | `features/ai` (EnemyAIController); `enemy-layers.md` unwritten | LOW |
| Sahne Akışı & İlerleme | Feature | `features/campaign` (C-35/C-40) | LOW |
| Oyun Durumu | Foundation | `game/state` | MEDIUM (typed dicts) |
| Kayıt / Yükleme | Foundation | `features/save` | MEDIUM |
| Modifikatör hattı | Foundation | `features/modifiers` | HIGH-verified (typed arrays) |
| Yerelleştirme | Foundation | `features/localization` | MEDIUM (TextServer, RTL) |
| Erişilebilirlik | Foundation (state) + Presentation | `state/accessibility_settings.gd`, settings screen | MEDIUM (AccessKit later) |

---

## 3. Module Ownership

### Foundation

| Module | Owns | Exposes | Consumes | Engine APIs |
| --- | --- | --- | --- | --- |
| `RootContext` (`contexts/root_context`) | `GameState` lifecycle, `AccessibilitySettings`, `SaveController` (D4), `LocaleFontController`, `AudioController` (ADR-0008), the active context | `context_changed(name)`; `bind_services` calls down | Context request signals (`new_campaign_requested`, `continue_requested`, `quit_requested`, `return_to_menu_requested`) | `Node`, `load()` of context scenes on transition (ADR-0001 amendment), `add_child`/`remove_child`/`queue_free` |
| `MenuContext` | Menu UI state | Request signals | `AccessibilitySettings` | `Control` |
| `GameContext` | All in-game services (creates + wires them), view-node wiring | `return_to_menu_requested` | `GameState`, `AccessibilitySettings`, `SaveController`, chapter content | `Control`, `load()` chapter by `chapter_id` |
| `game/state` | Field data only (no logic) | Fields + pure getters | — | `RefCounted` |
| `features/modifiers` | `GameState.modifiers` (**derived**, sole writer `ModifierController`) | `StatResolver.resolve()`, `ModifierController.add_source/can_add/remove_source/rebuild`, `modifiers_changed` | `ModifierSource` content | `RefCounted`, `Resource` (content), typed arrays |
| `features/save` | Save files in `user://saves/` and `user://settings.json` | `SaveController.save_campaign/load_campaign/has_campaign`, `save_failed` | `GameState` (to/from dict), chapter content via `map_factory` | `FileAccess`, `DirAccess`, `JSON` (never `ResourceLoader` on `user://`) |
| `features/localization` | Active font theme per locale, number formatting | `LocaleFontController`, `NumberFormatter.format_int()` | `TranslationServer` locale | `TranslationServer`, `Theme`, TextServer |
| `features/audio` (ADR-0008) | SFX player pool, bus usage | `AudioController.play_sfx(id)` | `SfxLibrary` content | `AudioStreamPlayer`, `AudioServer` buses (`default_bus_layout.tres`) |
| Content (`.tres`) | Static definitions: `ChapterMapDefinition`, `RegionDefinition`, `WinCondition`, `CombatConfig`, economy config (C-37), `ModifierSource`, `BoonDefinition` (C-39) | Read-only resources | — | `Resource` from `res://` only |

### Core

| Module | Owns | Exposes | Consumes | Engine APIs |
| --- | --- | --- | --- | --- |
| `MapController` (`features/grid`) | Turn-flow orchestration, `MapState.selected_region_id`, `actions_remaining`, `current_turn`, `game_result` (C-51), applying AI intents | `select_region`, `attempt_move`, `end_turn`; signals `region_selected/deselected`, `army_moved`, `combat_occurred`, `income_collected`, `turn_ended`, `game_won`, `game_lost` | `ArmyController`, `CombatResolver`, `ResourceController`, `SpiritController`, AI services, `StatResolver`, `WinCondition` | `RefCounted`, signals |
| `ArmyController` (`features/army`) | Owner/army writes for moves & arrival branches 1/3 (+ branch-2 settlement after `SpiritController` decides) | `can_move(map, from, to, mover)`, `move_army`, `apply_combat_result`, `apply_peaceful_move` | `MapState` | `RefCounted` |
| `CombatResolver` (`features/combat`) | Nothing persistent (pure leaf) | `resolve(A, D) -> CombatResult` (M2: effective-strength inputs from the caller) | `CombatConfig` | `RefCounted` |
| `ResourceController` (`features/resources`) | `GameState.gold`, recruit counters | economy step (income F2, reinforcement F6, upkeep F7), recruit API, income forecast | `MapState`, `StatResolver` (`B_add`/`M_g`), corruption `M_c` | `RefCounted` |

### Feature

| Module | Owns | Exposes | Consumes | Engine APIs |
| --- | --- | --- | --- | --- |
| `EnemyAIController` (`features/ai`) | Nothing (pure) | `decide(map_state, acted) -> MoveIntent` | `MapState` | `RefCounted`, inner classes |
| `ErlikSpreadController` (`features/ai`) | Nothing (pure) | `decide(map_state, effective_interval) -> SpreadDecision` | `MapState` | `RefCounted`, inner classes |
| `SpiritController` (`features/bozkurt`, C-38/C-39) | **Sole writer** of `RegionData.corruption_level`, `GameState.ruh`, `GameState.boons` (registry `spirit_state`) | `apply_spread(region_id)`, `apply_purification(...)`, `pending_offer() -> Array[BoonDefinition]`, `pick_boon(boon_id)`; signals (offer available, ruh changed) | `ModifierController` (add_source / can_add), boon catalog, `StatResolver` (`ruh_gain`) | `RefCounted` |
| Campaign / scene flow (`features/campaign`, C-35/C-40, ADR C-62) | Scene sequence, victory persistence | TBD in ADR C-62 | `GameState`, `SaveController`, `SpiritController` | `Control` screens |

### Presentation

| Module | Owns | Exposes | Consumes |
| --- | --- | --- | --- |
| `CampaignMap`, `RegionNode`, `AdjacencyLineDrawer` | Drawing only | `region_clicked(id)` / `clicked(id)` | `RegionData` (read), `AccessibilitySettings`, `TamgaLibrary` |
| `RegionInfoPanel` | Panel UI | `send_army_pressed(from_id)` | `RegionData` (read), `NumberFormatter` |
| HUD, battle report, Kök Böri modal, move preview, spread telegraph | View state | UI signals | Controller signals + read-only state (contract: ADR C-60) |
| Settings screen | Settings UI | changes → `AccessibilitySettings` | `AccessibilitySettings` |

### Dependency diagram

```
                 RootContext ──owns──▶ GameState, AccessibilitySettings, SaveController
                     │ bind_services (call down)          ▲ signals up
            ┌────────┴────────┐                            │
        MenuContext       GameContext ──creates & wires──────────────────────────┐
                              │                                                  │
                         MapController ──▶ ArmyController ──▶ (MapState)         │
                          │  │  │  │ └───▶ CombatResolver (leaf) ◀── CombatConfig  │
                          │  │  │  └─────▶ ResourceController ──▶ StatResolver    │
                          │  │  └────────▶ SpiritController ──▶ ModifierController
                          │  └───────────▶ EnemyAIController / ErlikSpreadController (pure)
                          └──────────────▶ WinCondition (content rule)            │
                 views (CampaignMap, RegionInfoPanel, HUD) ◀── signals ── MapController
                 SaveController ◀── turn_ended (GameContext wiring) ──────────────┘
```

Feature folders never import each other's *view* nodes; services depend only downward
(Feature → Core → Foundation). `CombatResolver` has zero outside dependencies.

---

## 4. Data Flow

ULUS has **no per-frame gameplay update**: state changes only in response to input or
`end_turn`. Views redraw on signals (`queue_redraw()` / refresh), never by polling.

### 4.1 Player move (input → rules → state → views)

```
RegionNode.clicked(id) → CampaignMap.region_clicked(id) → GameContext
  → MapController.select_region(id)            (selection only; emits region_selected)
  → [Send Army] RegionInfoPanel.send_army_pressed → MapController.attempt_move(target)
       game_result != ONGOING → return false
       ArmyController.can_move(map, from, to, PLAYER) → false → return false
       moving = ArmyController.move_army(...)
       branch by target state (army §3.3):
         1 combat     → CombatResolver.resolve(A, D) → ArmyController.apply_combat_result
                        (emptied region → NEUTRAL; corruption untouched)
         2 purify     → SpiritController.apply_purification(...) (resolver reuse; Ruh)
                        → ArmyController settles survivors / loses force
         3 peaceful   → ArmyController.apply_peaceful_move
       actions_remaining −= 1 ; selection cleared
       ALL results committed  →  WinCondition.is_met(map)?  → game_result = WON → game_won (once)
  signals → GameContext refreshes views; HUD reads state
```
Synchronous direct calls down; signals up to the context. Preview (TR-army-003) uses the
same pure branch function — **ADR-0010** (`MoveResolver.resolve` → `MoveOutcome` → apply;
implemented as the first step of C-38).

### 4.2 End of turn (`MapController.end_turn`)

```
if game_result != ONGOING: return
(1) enemy AI: loop i < enemy_actions_per_turn:
        intent = EnemyAIController.decide(map, acted) ; null → break
        apply via ArmyController (mover = ENEMY, branches 1/3) ; emit combat_occurred / army_moved
    player has no regions → game_result = LOST → game_lost ; return      (early exit)
(2) spread: interval = StatResolver.resolve(&"erlik_spread_interval", map.erlik_spread_interval, mods)
        d = ErlikSpreadController.decide(map, interval)
        if d.is_spread_turn: map.last_erlik_spread_turn = current_turn
                             if d.target_id: SpiritController.apply_spread(d.target_id)
(3) economy: ResourceController (income F2 → gold; reinforcement F6; upkeep F7) → income_collected
(4) current_turn += 1 ; actions_remaining reset ; recruit counters reset
(5) lose check (no regions ∨ Erlik: erlik_power ≥ erlik_loss_threshold, C-49) → win check
    → (changed) game_lost / game_won ; MapState.loss_reason = NO_REGIONS | ERLIK (C-63)
    else turn_ended(new_turn)  → GameContext → SaveController.save_campaign(game_state)
                               → HUD refresh → player turn start: SpiritController offer (auto-modal ≤ 1)
```
Implemented: early exit, latch and `turn_ended` ordering (**C-51**), Erlik loss + `loss_reason`
(**C-63**), AI extraction (**C-19**); still open: spread step (2) → **C-38**.

### 4.3 Signal path (no event bus)

- Children signal up; parents call down (ADR-0001/0003). Contexts never call `get_parent()`.
- Services (`RefCounted`) emit signals connected by the context that created them; the
  context holds the references for the services' whole life.
- Cross-feature communication goes through the orchestrator (`MapController`) or the
  context, never sideways between features.

### 4.4 Save / load

```
Save (turn end only, while ONGOING):
  turn_ended → GameContext → SaveController.save_campaign(game_state)
    SaveSerializer.to_dict(game_state)        # gold, current_chapter, chapters_completed,
                                              # ruh, boons, map: turn, chapter_id,
                                              # last_erlik_spread_turn, per-region owner/army/corruption
    JSON.stringify(data, "\t", true, true) → SaveStore.write(tmp → .bak rotation → final)
  NOT saved: modifiers (derived), pending boon offer (derived), game_result, selection,
             content (geometry, adjacency, names, tamga ids)

Continue:
  MenuContext.continue_requested → RootContext → SaveController.load_campaign() -> LoadResult
    SaveStore.read (final → .bak → .tmp) → BOM strip → JSON.parse → validate (finite,
    integral, ranges, ids, chapter consistency) → from_dict(map_factory by chapter_id)
  OK → RootContext adopts GameState → GameContext → ModifierController.rebuild(from boons)
```
Victory persistence (chapters_completed, `map: null`) is owned by scene flow (ADR C-62).

### 4.5 Initialisation order

```
RootContext._ready():
  1. settings load (SaveController, settings.json) → AccessibilitySettings
  2. LocaleFontController (theme for locale)
  3. load()+instantiate MenuContext → bind_services(accessibility) → add_child
New campaign / Continue:
  4. GameState.new() (or LoadResult.state)
  5. remove_child(old) → old.queue_free() ; load()+instantiate GameContext
  6. GameContext.bind_services(game_state, accessibility, save_controller) → add_child
GameContext._ready() — creation order (each bind_services before first use):
  a. content: ChapterMapDefinition by chapter_id (new campaign → create_map_state())
  b. CombatResolver.bind_config(CombatConfig)
  c. ModifierController.bind_services(game_state) → rebuild(sources from boons)
  d. ArmyController, ResourceController(config), SpiritController(modifiers, catalog)
  e. EnemyAIController, ErlikSpreadController
  f. MapController.bind_services(map_state, game_state, army, resource, combat,
     spirit, enemy_ai, erlik, win_condition)   ← group into a services object (QQ-01)
  g. views: CampaignMap, RegionInfoPanel, HUD ← connect controller signals
```

### 4.6 Victory sequence

```
attempt_move → all results committed → game_won (once) → [lock: moves/end_turn/recruit rejected]
  → scene flow: pending Kök Böri offers, mandatory, one by one (SpiritController.pick_boon
    allowed under the lock) → persist completion (scene flow + SaveController) → outro
```
Threading: none. All flows run on the main thread; `ResourceLoader.load_threaded_request`
is reserved for a future loading screen (ADR-0001 amendment).

---

## 5. API Boundaries

Contracts programmers implement against (as built ✔ / planned ◻ with owning task).

```gdscript
# ── Foundation ─────────────────────────────────────────────────────────────
# RootContext ✔ (Continue ◻ C-56)
signal context_changed(context_name: StringName)
func _switch_to(context_name: StringName) -> void   # remove_child → queue_free → load() → bind → add_child

# MenuContext ✔ (continue_requested ◻ C-56)
func bind_services(accessibility: AccessibilitySettings) -> void
signal new_campaign_requested
signal continue_requested
signal quit_requested

# GameContext ✔ (save_controller ◻ C-56)
func bind_services(game_state: GameState, accessibility: AccessibilitySettings) -> void
signal return_to_menu_requested

# Modifiers ◻ C-55 (ADR-0006)
static func StatResolver.resolve(stat_id: StringName, base: float, modifiers: Array[StatModifier]) -> float
func ModifierController.add_source(source: ModifierSource) -> bool      # false: group clash / max_stacks
func ModifierController.can_add(source: ModifierSource) -> bool
func ModifierController.rebuild(sources: Array[ModifierSource]) -> void # clear + re-add
signal ModifierController.modifiers_changed(stat_id: StringName)

# Save ◻ C-56 (ADR-0007)
func SaveController.save_campaign(game_state: GameState) -> bool
func SaveController.load_campaign() -> LoadResult                        # code + state XOR error
signal SaveController.save_failed(reason: StringName)

# ── Core ───────────────────────────────────────────────────────────────────
# MapController ✔ (latch/early exit/turn_ended order ◻ C-51; AI services ✔ C-19)
func select_region(region_id: StringName) -> void
func attempt_move(target_id: StringName) -> bool      # false if not ONGOING / invalid
func end_turn() -> void                               # no-op unless ONGOING
signal turn_ended(new_turn: int)                      # only after the end check, while ONGOING
signal game_won
signal game_lost

# ArmyController ✔ (mover param ✔ C-19; emptied region → NEUTRAL ◻ C-52)
func can_move(map_state: MapState, from_id: StringName, to_id: StringName, mover: RegionData.Owner) -> bool
func move_army(map_state: MapState, from_id: StringName, to_id: StringName) -> int

# CombatResolver ✔ (effective strength ◻ M2, signature in ADR C-59)
func resolve(attacker_army: int, defender_army: int) -> CombatResolver.CombatResult

# ResourceController ✔ (recruit API ◻ C-37)
func collect_turn_income(map_state: MapState, game_state: GameState) -> int
func recruit(map_state: MapState, game_state: GameState, region_id: StringName, k: int) -> bool
func forecast_income(map_state: MapState, game_state: GameState) -> int   # same pure F2 as the step

# ── Feature ────────────────────────────────────────────────────────────────
# AI ✔ C-19 (ADR-0005); spread wired into end_turn ◻ C-38
func EnemyAIController.decide(map_state: MapState, acted: Array[StringName]) -> EnemyAIController.MoveIntent
func ErlikSpreadController.decide(map_state: MapState, effective_interval: int) -> ErlikSpreadController.SpreadDecision

# SpiritController ◻ C-38 / C-39 (registry spirit_state)
func apply_spread(region_id: StringName) -> void
func apply_purification(map_state: MapState, target_id: StringName, arriving: int) -> PurificationResult
func pending_offer() -> Array[BoonDefinition]          # derived: ruh ≥ boon_cost(n) and pool
func pick_boon(boon_id: StringName) -> bool            # allowed under the game_result lock
```

**Invariants callers must respect**
- Never write `corruption_level`, `ruh`, `boons` outside `SpiritController`; never write
  `modifiers` outside `ModifierController`; never iterate `modifiers` outside
  `features/modifiers` (forbidden `unkeyed_or_duplicate_bonus_summation`).
- AI services are pure (forbidden `ai_service_mutates_or_signals`).
- Never `load()` / `ResourceLoader` content from `user://` (forbidden `untrusted_resource_loading`).
- `bind_services` before `add_child`; contexts and services never reach up the tree.

**Guarantees modules give**
- `MapController`: `game_won`/`game_lost` at most once; `turn_ended` only for live games.
- `SaveController`: a failed save never destroys the previous loadable file.
- `StatResolver`: pure, deterministic; caller rounds and clamps.

Engine types in interfaces: `RefCounted`, `Resource` (content), `StringName`, typed
`Array[T]`, inner classes (qualified outside their script) — all verified on 4.7.1.

---

## 6. ADR Audit

| ADR | Engine Compat | Version | GDD Linkage | Conflicts with this document | Valid |
| --- | --- | --- | --- | --- | --- |
| ADR-0001 Context hierarchy | ✅ | 4.7 | ✅ | None (amended: `load()`, Continue) | ✅ |
| ADR-0002 Feature encapsulation | ✅ | 4.7 | ✅ | None | ✅ |
| ADR-0003 Dependency injection | ✅ | 4.7 | ✅ | `MapController.bind_services` arg growth → QQ-01 | ✅ |
| ADR-0004 State segregation | ✅ | 4.7 | ✅ | None (derived-state rule) | ✅ |
| ADR-0005 AI architecture | ✅ | 4.7 | ✅ | None (decide → apply loop) | ✅ |
| ADR-0006 Modifier pipeline | ✅ | 4.7 | ✅ | None (`max_stacks`, `rebuild`) | ✅ |
| ADR-0007 Save/load | ✅ | 4.7 | ✅ | None (RootContext owns controller) | ✅ |

Traceability: 23 ✅ / 9 ⚠️ / 4 ❌ of 36 TRs — see [architecture-traceability.md](architecture-traceability.md).
Decisions made in this document that are not yet ADRs are listed in §7.

---

## 7. Required ADRs

**Must have before the relevant code starts (Core):**
1. ~~**Move Resolution — pure Outcome + Apply** (C-59)~~ — done: **ADR-0010** → TR-army-003, TR-resource-006; also fixes
   the `CombatResolver` effective-strength signature (TR-combat-004) and the
   `SpiritController.apply_purification` call point. Before C-38 / C-41 / C-45.

**Should have before the relevant system is built:**
2. ~~**Presentation Layer & Reports** (C-60)~~ — done: **ADR-0011** → TR-combat-003, TR-map-004, TR-spirit-010 display;
   view-refresh contract, HUD/battle report/boon modal/preview/telegraph. Before C-41 / C-45.
3. ~~**Scene flow & chapter loading** (C-62)~~ — done: **ADR-0012** → TR-concept-007,
   TR-map-002; victory persistence order, chapter content path convention (`SceneDefinition.map_path`).
4. ~~**Localization & Pixel-Font Pipeline** (C-61) → TR-concept-006 (as built).~~ — done: ADR-0009 (C-61).

**Can defer to implementation:**
- ~~Audio architecture~~ — done: ADR-0008 (C-23).
- Corruption overlay rendering technique (shader spec with C-50).
- Debug tools (god mode, time scale) — a small tools spec when the first debug build is needed.
- Spirit `requires` gating source (QQ-02) — can live in ADR C-59 or the C-39 story.

---

## 8. Architecture Principles

1. **No globals, call down / signal up.** Long-lived objects are owned by a context and
   injected (`bind_services`); no autoloads, no event bus, no `get_parent()`.
2. **One writer per piece of state.** State classes are data-only; every shared field has
   exactly one writing service (registry `state_ownership`). Derived state is rebuilt by its
   writer, never saved.
3. **Rules are pure and shared.** Decisions (AI, spread, combat, arrival branch, income
   forecast) are pure deterministic functions used identically by preview, AI and apply —
   determinism makes every rule unit-testable and every outcome previewable.
4. **Content is not save data.** `.tres` content is loaded from `res://` by id; saves hold
   only player choices and mutable state as versioned JSON. "Save choices, derive effects."
5. **Features are encapsulated and depend downward.** Feature → Core → Foundation; leaves
   (`CombatResolver`) have zero outside dependencies; gameplay values are data-driven.

---

## 9. Open Questions

| ID | Question | Priority | Resolution path |
| --- | --- | --- | --- |
| QQ-01 | `MapController.bind_services` reaches 9+ arguments — group into a typed `GameServices` holder? | Medium | C-19 refactor (ADR-0003 note) |
| QQ-02 | What does a boon's `requires` check ("system active") read — chapter flag, feature presence, content data? | Medium | ADR C-59 or C-39 story |
| QQ-03 | ~~`WinCondition` is a content `Resource` with logic~~ — **resolved C-51:** kept; checks are pure functions of `MapState` (`is_met`, `conquered_neutral_count`, `foci_cleansed`) | Low | C-51 ✅ |
| QQ-04 | ~~How does `WinCondition` read `initial_owner`?~~ — **resolved C-51:** `RegionData.initial_owner`, copied from `RegionDefinition.owner` at map creation, content-derived and never saved (ADR-0007 rebuilds the map from content) | Medium | C-51 ✅ |
| QQ-05 | Name/location of the economy config resource (resource §7) | Low | C-37 |
| QQ-06 | `user://` folder follows `application/config/name` — set `use_custom_user_dir` before release? | Low | release checklist |
| QQ-07 | Windows `DirAccess.rename` overwrite semantics | Low | C-56 test on Windows |
| QQ-08 | Resource-list abstraction (herds later) — is a hard `gold` field acceptable until Perde 1? | Low | Perde 1 design (TR-concept-003) |
