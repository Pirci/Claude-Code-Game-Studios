# ADR-0011: Presentation Layer & Reports

## Status

Accepted (2026-10-19 — C-60; night-mode decision, recommended option accepted per user
instruction; re-validate at the next `/architecture-review`. Screen-level UX is specified by
the UX tasks C-41 / C-45.)

## Date

2026-10-19

## Last Verified

2026-10-19 (against the as-built `GameContext`, `CampaignMap`, `RegionNode`, `RegionInfoPanel`,
`FocusReveal` on Godot 4.7.1)

## Decision Makers

Technical direction (night-mode autonomous run).

## Summary

Views are passive: they draw what the context hands them and send the player's intent up as
signals. `GameContext` is the single presenter: after every committed change it re-renders all
views from state with one `_refresh_views()` call. Derived display values (income forecast,
spread countdown and target, boon availability) come from small pure "view model" builders
that call the **same** pure rules the game uses (ADR-0010 `IncomeRules`, ADR-0005
`ErlikSpreadController.decide`). Reports and the boon offer are modal panels fed with data
objects (`MoveOutcome`, `SpreadDecision`, boon offer) and shown one at a time through a modal
queue that owns input and focus while open.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | UI / Presentation |
| **Knowledge Risk** | MEDIUM — Control focus API changed in 4.6 (GH-110250: `grab_focus(hide_focus)`, `has_focus(ignore_hidden_focus)`), already verified and wrapped by `FocusReveal` (C-25) |
| **References Consulted** | `docs/engine-reference/godot/modules/ui.md`, art bible §7 (panels, modal, focus), ADR-0009 (text) |
| **Post-Cutoff APIs Used** | `Control.grab_focus(true)` / `has_focus(true)` via `FocusReveal` |
| **Verification Required** | Modal input blocking with `physics_object_picking` map clicks (Area2D) — test in C-41 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (contexts own views), ADR-0002 (feature-owned scenes), ADR-0003 (injection), ADR-0004 (views read state, never write), ADR-0005 (`ErlikSpreadController.decide` for the telegraph), ADR-0009 (text/fonts), ADR-0010 (`MoveOutcome`, `preview_move`, `IncomeRules`) |
| **Enables** | C-37 HUD (gold + forecast), C-38 corruption rows + purification report, C-39 boon modal, C-41/C-45 battle report, move preview, spread telegraph |
| **Blocks** | None |
| **Ordering Note** | `TR-spirit-008`'s "required system active" flag for the boon pool is a C-39 content decision, not presentation |

## Context

### Problem Statement
Several screens are about to be built (HUD forecast, battle and purification reports, boon
offer, move preview, spread telegraph). Without a contract each would refresh itself
differently (polling, partial updates, direct service calls), modal popups could stack, map
clicks could leak through a modal, and derived numbers on screen could disagree with the rules.

### Current State (before)
`GameContext` already listens to `MapController` signals and calls `_refresh_map()` /
`_update_ui()`; `CampaignMap.refresh(map_state)` redraws regions; `RegionInfoPanel.show_region`
is fed `RegionData`; views emit `region_clicked` / `send_army_pressed`. No reports, modal
handling or HUD model exist.

### Constraints
- Call down, signal up; views never know their parent (technical preferences).
- No autoload / event bus; no state writes from views (ADR-0004).
- 640×360, pixel-art rules (no alpha fades, integer positions), Reduce Motion setting.
- Keyboard and mouse both first-class; focus visible only for keyboard users (C-25).

### Requirements
- One refresh rule that keeps every view consistent after any state change.
- Derived display values computed by the game's own pure rules.
- Reports show complete, already-computed results (no recomputation in the view).
- At most one modal at a time, in a defined order; map input blocked while a modal is open.

## Decision

1. **Passive views.** Every view exposes `show_*/refresh(data)` methods and intent signals;
   it never calls controllers, never writes state and never polls in `_process`.
   Feature-owned views live in their feature (`features/grid/` map + info panel,
   `features/combat/ui/battle_report.tscn`, `features/bozkurt/ui/purification_report.tscn`,
   `features/bozkurt/ui/boon_offer_modal.tscn`); the cross-feature HUD lives in `ui/hud/`.
2. **One presenter, full refresh.** `GameContext` is the only presenter. After any committed
   change signal (`MapController`, `SpiritController`, `ResourceController`,
   `ModifierController.modifiers_changed`) it calls `_refresh_views()`, which re-renders map,
   HUD and the info panel (if a region is selected) from current state. Full refresh is cheap
   (≤ 15 regions) — no per-field diffing.
3. **View models from the same rules.** `HudModel` (data) is built by a pure
   `HudPresenter.build(game_state, map_state, rules…)`: gold; income forecast =
   `IncomeRules.turn_income` (ADR-0010); turn and actions left; spread telegraph = turns until
   the next spread from `last_erlik_spread_turn` and the effective interval
   (`StatResolver` on `erlik_spread_interval`) plus `ErlikSpreadController.decide(map, interval)
   .target_id` ("if it happened now"); boon button state from the derived offer condition
   (spirit §3.4). Views get only the model.
4. **Reports are data-fed modals.** `BattleReport.show_outcome(outcome: MoveOutcome)` and
   `PurificationReport.show_outcome(outcome)` render the outcome as computed (branch, losses,
   remaining, dispersed, Ruh); the enemy turn produces **one** `TurnSummaryReport`
   (`Array[MoveOutcome]` + `SpreadDecision`) instead of one modal per enemy move. All use the
   `ModalPanel` theme variation (art bible §7).
5. **Modal queue.** A `ModalQueue` node under an overlay `CanvasLayer` in `GameContext` shows
   one modal at a time (FIFO), blocks map input (full-rect `MOUSE_FILTER_STOP` backdrop; map
   `Area2D` picking ignores events consumed by GUI), moves keyboard focus into the modal with
   `FocusReveal.focus_quietly` and restores the previous focus on close. Order per player turn:
   player-move report (right after the move) → at end of turn: `TurnSummaryReport` → dawn boon
   offer (≤ 1 automatic per turn start; HUD button may open it any time). Scene victory: the
   mandatory boon sequence then the outro (scene-flow, C-35/C-62).
6. **Preview and confirmation.** On hover with a source selected, `GameContext` asks
   `MapController.preview_move(to)` (ADR-0010) and shows the outcome in a small preview view;
   a failing purification needs a second click on the same target (state kept in `GameContext`
   as `_pending_confirm_target`, cleared on any other input).
7. **Motion.** State is committed before any animation; animations (spread stain, purification
   glow, report entry) are cosmetic, never gate input, and are skipped when Reduce Motion is on.
   Integer-step motion only (no alpha fades, no fractional scale — art bible §7).

### Architecture

```
            intent signals ▲                         ▼ show_*/refresh(data)
  CampaignMap · RegionInfoPanel · Hud · MovePreview · Reports · BoonOfferModal  (passive views)
                           ▲                                   ▼
                     GameContext (presenter) ── _refresh_views() after every committed change
                       │   │  builds HudModel via HudPresenter (pure) ── IncomeRules, ErlikSpreadController.decide, StatResolver
                       │   └─ ModalQueue (overlay CanvasLayer): one modal, input + focus owner
                       ▼ calls down
        MapController · SpiritController · ResourceController · ModifierController
                       │ signals up (outcomes, spread decisions, modifiers_changed)
```

### Key Interfaces

```gdscript
class_name HudModel extends RefCounted          # ui/hud/ — data only
var gold: int
var income_forecast: int
var turn: int
var actions_left: int
var spread_turns_left: int                     # 0 = spreads this end of turn
var spread_target_id: StringName                # "if it happened now"
var boon_offer_available: bool

class_name HudPresenter extends RefCounted      # pure
static func build(game_state: GameState, map_state: MapState,
		spread: ErlikSpreadController, economy: EconomyConfig) -> HudModel

# Views (signals up)
Hud: func show_model(model: HudModel) -> void ; signal end_turn_pressed, boon_button_pressed, menu_pressed
BattleReport / PurificationReport: func show_outcome(outcome: MoveOutcome) -> void ; signal closed
TurnSummaryReport: func show_turn(outcomes: Array[MoveOutcome], spread: ErlikSpreadController.SpreadDecision) -> void ; signal closed
BoonOfferModal: func show_offer(boon_ids: Array[StringName], mandatory: bool) -> void ; signal boon_picked(boon_id: StringName), deferred

class_name ModalQueue extends Control           # in GameContext overlay
signal drained
func push(modal: Control) -> void               # modal must emit `closed` (or boon_picked/deferred)
func is_open() -> bool
```

### Implementation Guidelines
- A new view gets data through one method and reports intent through signals; if it needs a
  number the rules compute, add it to a view model built from the rule, never re-derive it.
- `GameContext` handlers end with `_refresh_views()`; views do not refresh each other.
- Every modal: `ModalPanel` variation, keyboard-closable (`ui_accept` / `ui_cancel`), all text
  via `tr()` keys, symbols per ADR-0009 (icons, ASCII `-`).
- Test views by feeding data objects (no controllers needed); test `HudPresenter` as a pure
  function.

## Alternatives Considered

### Alternative 1: Views subscribe to controllers directly
- **Pros**: fewer lines in `GameContext`. **Cons**: views learn about services (tight
  coupling), refresh order becomes implicit, modal ordering impossible to reason about.
  **Rejected.**

### Alternative 2: Fine-grained per-field updates
- **Pros**: minimal redraw. **Cons**: many signals and partial-state bugs for ≤ 15 regions
  and one HUD. **Rejected** — full refresh is cheaper in complexity.

### Alternative 3: One report modal per enemy move
- **Cons**: modal spam at end of turn (attention budget, cross-review D6). **Rejected** for a
  single turn summary.

## Consequences

### Positive
- Views are trivially testable with data; numbers on screen equal the rules by construction.
- Modal order and input blocking are defined in one place.
- Adds no new state; presenter logic is pure.

### Negative
- `GameContext` grows (presenter + modal wiring); split into helper presenters when it exceeds
  readability (e.g. `HudPresenter`, a `ReportPresenter`).
- Full refresh redraws unchanged regions (acceptable at this scale).

### Neutral
- Visual feel (animation timing, report layout) stays in UX specs C-41 / C-45.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Map clicks leak through a modal (Area2D picking) | Medium | Medium | Backdrop + `ModalQueue.is_open()` guard in `GameContext._on_region_clicked`; C-41 test |
| Telegraph shown target differs from actual spread | Low (by design "if now") | Low | Label wording "if it happened now"; same `decide` call |
| `GameContext` becomes a god object | Medium | Medium | Extract presenters per area as they grow |

## Performance Implications

| Metric | Expected | Budget |
|--------|----------|--------|
| Full refresh | < 1 ms (≤ 15 regions + HUD) per committed change | 16.6 ms |
| Draw calls | Map + HUD + one modal well under 200 | < 200 |

## Migration Plan
Current code already follows decisions 1–2 for the map and info panel. Next steps land with
their tasks: `HudModel`/`HudPresenter` + `Hud` (C-37), corruption rows + `PurificationReport`
(C-38), `BoonOfferModal` + `ModalQueue` (C-39), `BattleReport`, `TurnSummaryReport`,
`MovePreview`, spread telegraph (C-41 / C-45). Rename `_refresh_map()` → `_refresh_views()`
when the HUD is added.

## Validation Criteria
- [ ] `HudPresenter.build` returns the F2 income and the same spread target as
      `ErlikSpreadController.decide` for a fixture map (unit test).
- [ ] With a modal open, a map click does not select a region (C-41 test).
- [ ] Closing a modal restores the previous keyboard focus.
- [ ] End of turn with 2 enemy moves shows exactly one summary report, then the dawn boon offer
      (if available), never two automatic offers in one turn start.
- [ ] Battle report values equal the applied `MoveOutcome` (C-41).

## GDD Requirements Addressed

| Source | Requirement | How |
|--------|-------------|-----|
| TR-combat-003 | Detailed battle report incl. dispersed survivors | Decision 4 |
| TR-map-004 | Visual layer separate from state; clickable polygons | Decisions 1–2 |
| TR-spirit-010 | Spread telegraph from the same pure rule | Decision 3 |
| TR-spirit-008 (presentation part) | Auto-modal ≤ 1 per turn start, HUD chaining, mandatory at victory | Decision 5 |
| spirit §3.2 / TR-army-003 | Preview + second click for failing purification | Decision 6 |

## Related
- ADR-0005, ADR-0009, ADR-0010; art bible §7 (panels, modal, focus); `FocusReveal` (C-25).
- Implementation: C-37, C-38, C-39, C-41, C-45.
