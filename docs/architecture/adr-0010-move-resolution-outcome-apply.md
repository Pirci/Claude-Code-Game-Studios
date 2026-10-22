# ADR-0010: Move Resolution — Pure Outcome + Apply

## Status

Accepted (2026-10-19 — C-59; night-mode decision, recommended option accepted per user
instruction; re-validate at the next `/architecture-review`.)

> **Amendment 2026-10-22 (C-70 — report data contract, [`design/ux/battle-report.md`](../../design/ux/battle-report.md) §8 G1–G4):**
> The battle / purification reports and the dawn turn summary (ADR-0011 Decision 4–5) read
> only `MoveOutcome` and `SpreadDecision`; nothing in a report re-derives rules. Four data gaps
> are closed here. All new fields are **data**, filled by the pure decider that already owns
> them; `MapController` still only applies and emits.
>
> 1. **G1 — one signal shape per branch.** `MapController.combat_occurred(outcome: MoveOutcome)`
>    replaces `(from_id, to_id, result: CombatResult)`, symmetric with
>    `purification_resolved(outcome)`; `army_moved(from_id, to_id, army_count)` is unchanged
>    (peaceful moves have no report). Player and enemy moves emit through the same `_emit_move`.
> 2. **G2 — who held the target, and why the move happened.** `MoveOutcome` gains
>    `target_owner_before: RegionData.Owner` (written by `MoveResolver.resolve()` from the map it
>    already reads — the report can say "the enemy took our camp" vs. "we took theirs") and
>    `reason: StringName` (empty for player moves; for enemy moves `MapController` copies
>    `MoveIntent.reason` — ADR-0005 amendment 2026-10-21, e.g. `&"strike"`). `reason` never
>    changes resolution; `MoveResolver` ignores it.
> 3. **G3 — spread vs. deepen.** `ErlikSpreadController.SpreadDecision` gains `level_before: int`
>    (the target's `corruption_level` at decision time; 0 when there is no target). Report text:
>    `level_before == 0` → `TURN_SUMMARY_SPREAD`, `≥ 1` → `TURN_SUMMARY_DEEPENED`.
>    `MapController.corruption_spread(decision: SpreadDecision)` replaces
>    `corruption_spread(region_id)` so the view receives the decision as decided.
> 4. **G4 — one summary per night.** `GameContext` owns a night buffer
>    (`Array[MoveOutcome]` + the night's `SpreadDecision`). It is cleared when the player ends
>    the turn (before `MapController.end_turn()`); enemy outcomes (`mover == ENEMY`) and the
>    spread decision are appended from the signals above during `end_turn()`; on `turn_ended`
>    the view calls `TurnSummaryReport.show_turn(outcomes, spread)` (ADR-0011 signature) and
>    pushes it on `ModalQueue` **before** the dawn boon offer. If `end_turn()` ends in
>    `game_lost` / `game_won`, the buffer is discarded — the defeat / victory screens tell the
>    story (battle-report Q3). Player moves are not buffered: their report opens right after the
>    move. A night with no enemy outcome and no spread opens no summary (battle-report Q5).
>
> Validation (C-71): enemy `MoveOutcome` has `mover == ENEMY`, correct `target_owner_before`
> and `reason == &"strike"` when the profile struck; `level_before` distinguishes SPREAD /
> DEEPENED; the buffer is empty at the start of every `end_turn()`; existing preview-equals-
> apply tests stay green. Implementation: C-71 (data + signals), C-72 / C-73 (views).

## Date

2026-10-19

## Last Verified

2026-10-19 (design against the as-built `MapController` / `ArmyController` / `CombatResolver`
on Godot 4.7.1; no new engine APIs)

## Decision Makers

Technical direction (night-mode autonomous run).

## Summary

A move's result is computed by **one pure function** that reads the map and returns a
`MoveOutcome` (branch, losses, remaining, resulting owner/army/corruption, Ruh); applying a
move only **writes** that outcome. The move preview (TR-army-003), the player's move, and
every enemy move use the same function, so the preview can never disagree with the result.
The same pattern covers the income forecast (TR-resource-006: one pure F2 function for the
economy step and the HUD) and fixes the effective-strength signature of `CombatResolver`
(TR-combat-004).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | Core / Gameplay rules |
| **Knowledge Risk** | LOW — plain GDScript `RefCounted` data + pure functions |
| **References Consulted** | `VERSION.md`; ADR-0005/0006 verification notes (typed arrays invariant at runtime) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None beyond unit tests |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (`CombatResolver` stays a zero-dependency leaf), ADR-0003 (services injected), ADR-0004 (data-only state), ADR-0005 (decide → apply loop), ADR-0006 (`StatResolver` for effective strength, `ruh_gain`, F2 bonuses) |
| **Enables** | C-38 purification (arrival branch 2 + `SpiritController.apply_purification`), C-37 HUD income forecast, C-41/C-45 move preview + failed-purification confirmation, M2 attack/defense boons |
| **Blocks** | C-38 (its first step implements this ADR) |
| **Ordering Note** | `SpiritController` remains the sole writer of `corruption_level` / `ruh` (registry `spirit_state`, D3); this ADR only defines **when** it is called and **with what** |

## Context

### Problem Statement
Arrival resolution (army §3.3: combat → purification → peaceful) currently lives inline in
`MapController.attempt_move` and `_apply_enemy_move`, mixed with mutation and signals. The GDDs
now require a **pre-move forecast** with exactly the result the move will have (spirit §3.2
"Hamle önizlemesi", N7 / C-53), a confirmation before a failing purification, and an HUD
income forecast equal to the economy step (resource F2). Re-implementing the rules for the
preview would drift; calling the mutating path on a copy of the map is heavy and error-prone.

### Current State (before)
`MapController.attempt_move`: validate → `move_army` (mutates source) → branch on target →
`ArmyController.apply_combat_result` / `apply_peaceful_move` → signals. `_apply_enemy_move`
duplicates the branch choice. Purification (branch 2) is not built yet (C-38). Income:
`ResourceController.collect_turn_income` sums `gold_per_turn` directly.

### Constraints
- Deterministic, no RNG; same state → same outcome (tests, preview).
- `CombatResolver` must stay a leaf (ADR-0002): no knowledge of modifiers or spirit.
- Spirit state written only by `SpiritController` (D3); army fields by `ArmyController`.
- Static typing; no autoload; signals up from `MapController` only.

### Requirements
- One rule implementation for preview, player move and enemy move.
- Preview never mutates state and is cheap enough to run on every hover.
- Outcome carries everything a preview/report needs (branch, losses, remaining, dispersed
  survivors, purification success, Ruh, resulting owner/army/corruption).

## Decision

1. **`MoveOutcome`** (`features/army/move_outcome.gd`, `RefCounted`, data only) describes one
   move completely — including the target's state **after** the move.
2. **`MoveResolver`** (`features/army/move_resolver.gd`, `RefCounted` service, injected by
   `GameContext` into `MapController`) has one public method,
   `resolve(map_state, from_id, to_id, mover, modifiers) -> MoveOutcome`, which **only reads**.
   It validates (owner, adjacency, garrison > 1, player action budget) — returning
   `Branch.INVALID` with a reason instead of `null` — and picks the branch in army §3.3 order:
   1. **COMBAT** — foreign garrison (`owner != mover` and `army_count > 0`):
      `CombatResolver.resolve_effective(A, D, A_eff, D_eff)` (decision 5); emptied target →
      `NEUTRAL`, army 0 (W3); losing attacker's survivors are `dispersed`.
   2. **PURIFICATION** — `mover == PLAYER`, no foreign garrison, `corruption_level ≥ 1`:
      `P = moving`, `S = SpiritRules.corruption_strength(level)`, `resolve(P, S)` (no defence
      modifier, no `draw_favors_defender` — spirit §3.2); success iff `P > S`; success sets
      corruption 0, Ruh = `SpiritRules.ruh_gain(level, modifiers)`, survivors settle; failure
      disperses the whole force and changes nothing else.
   3. **PEACEFUL** — otherwise: merge into own region or occupy.
   Enemy moves never produce PURIFICATION (corruption is ignored for `mover == ENEMY`).
3. **Apply** — `MapController` is the only caller that commits an outcome:
   `ArmyController.apply_outcome(map_state, outcome)` writes source/target `owner` and
   `army_count`; for `Branch.PURIFICATION`, `SpiritController.apply_purification(outcome)`
   writes `corruption_level` and `ruh` (sole writer, D3). Then `MapController` decrements the
   player action budget and emits signals (`combat_occurred`, `purification_resolved`,
   `army_moved`) carrying the outcome. `attempt_move(to_id)` = `resolve` + apply;
   `_apply_enemy_move(intent)` = `resolve(…, ENEMY, …)` + apply.
4. **Preview** — `MapController.preview_move(to_id) -> MoveOutcome` resolves from the current
   selection without applying. UI (C-41/C-45) shows it on hover; a PURIFICATION outcome with
   `purified == false` requires a second click to confirm (spirit §3.2). Contract: with no
   state change in between, `preview_move(t)` and the outcome applied by `attempt_move(t)` are
   field-for-field equal.
5. **Effective strength (TR-combat-004, M2)** — `CombatResolver` gains
   `resolve_effective(attacker_army, defender_army, attacker_strength, defender_strength)`
   implementing combat §4 "Etkin güç" (branch by strengths; losses from the *opponent's*
   strength; remaining from own troop count); `resolve(a, d)` stays and equals
   `resolve_effective(a, d, a, d)`. `MoveResolver` computes
   `A_eff = ceil(StatResolver.resolve(&"army_attack", A, modifiers))` only when the attacker is
   the player, `D_eff` likewise with `army_defense` when the defender is the player; purification
   uses `S` unmodified. The resolver stays a leaf.
6. **Income (TR-resource-006)** — `IncomeRules` (`features/resources/income_rules.gd`, pure
   static): `region_income(region, multipliers)` = `floor(G_base × M_c)` and
   `turn_income(map_state, owner, modifiers, config)` = F2
   `max(I_floor, floor((I_raw + B_add) × M_g))` with `B_add`/`M_g` from `StatResolver`
   (`M_g` clamped to its GDD range 1.0–2.0 inside `IncomeRules`; an owner with no regions
   gets 0 whatever `I_floor` is — resource AC). Knobs come from an `EconomyConfig` resource
   (`I_floor`, `M_g` range, recruit cost …) introduced with C-37 (TR-resource-005).
   `ResourceController.collect_turn_income` and the HUD forecast both call it.

### Architecture

```
            hover                         click / AI intent
UI ──preview_move(to)──▶ MapController ──attempt_move(to) / _apply_enemy_move(intent)
                              │ resolve (read-only)
                              ▼
                        MoveResolver ──▶ CombatResolver.resolve_effective (leaf)
                              │        ──▶ SpiritRules.corruption_strength / ruh_gain (pure)
                              │        ──▶ StatResolver (A_eff, D_eff, ruh_gain)
                              ▼
                        MoveOutcome ──(preview: returned to UI)
                              │ apply (commit path only)
                 ┌────────────┴─────────────┐
     ArmyController.apply_outcome   SpiritController.apply_purification (branch 2)
                              │
                 signals up: combat_occurred / purification_resolved / army_moved (outcome)

ResourceController.collect_turn_income ─┐
HUD income forecast ────────────────────┴──▶ IncomeRules.turn_income (pure F2)
```

### Key Interfaces

```gdscript
class_name MoveOutcome extends RefCounted
enum Branch { INVALID, COMBAT, PURIFICATION, PEACEFUL }
var branch: Branch = Branch.INVALID
var invalid_reason: StringName = &""      # &"not_owner", &"not_adjacent", &"single_garrison", &"no_actions"
var mover: RegionData.Owner
var from_id: StringName
var to_id: StringName
var moving: int                           # source.army_count - 1
var combat: CombatResolver.CombatResult = null   # COMBAT and PURIFICATION
var corruption_strength: int = 0          # S (PURIFICATION)
var purified: bool = false
var ruh_gain: int = 0
var dispersed: int = 0                    # attacker troops that vanish
var source_army_after: int = 1
var target_owner_after: RegionData.Owner
var target_army_after: int
var target_corruption_after: int

class_name MoveResolver extends RefCounted
func bind_services(combat: CombatResolver, spirit_rules: SpiritRules) -> void
func resolve(map_state: MapState, from_id: StringName, to_id: StringName,
		mover: RegionData.Owner, modifiers: Array[StatModifier]) -> MoveOutcome

# CombatResolver (leaf) — added
func resolve_effective(attacker_army: int, defender_army: int,
		attacker_strength: int, defender_strength: int) -> CombatResult

# MapController — added/changed
func preview_move(to_id: StringName) -> MoveOutcome
signal purification_resolved(outcome: MoveOutcome)

class_name IncomeRules extends RefCounted
static func region_income(region: RegionData, corruption_multipliers: Array[float]) -> int
static func turn_income(map_state: MapState, owner: RegionData.Owner,
		modifiers: Array[StatModifier], config: EconomyConfig) -> int
```

### Implementation Guidelines
- `MoveResolver.resolve` must not write to `map_state` or emit signals; a test snapshots the
  map before/after `preview_move` and asserts equality.
- Apply never re-derives a value: everything written comes from the outcome.
- `combat_occurred` keeps its current arguments during the migration; new listeners use the
  outcome-carrying signals.
- `SpiritRules` (pure: `corruption_strength`, `ruh_gain`) lives in `features/bozkurt/` with
  `SpiritController`; `MoveResolver` depends on it through injection, not a global.

## Alternatives Considered

### Alternative 1: Preview by running the real move on a cloned map
- **Pros**: no new types. **Cons**: deep copies of `MapState`/`GameState` on every hover,
  signals must be suppressed, spirit writer would be called on a fake state (breaks D3).
  **Rejected.**

### Alternative 2: Separate preview calculator in the UI
- **Pros**: fastest to write. **Cons**: two rule implementations drift — exactly what
  TR-army-003 forbids. **Rejected.**

### Alternative 3: Command objects (`MoveCommand.execute/undo`)
- **Pros**: undo support. **Cons**: undo is not a design requirement; heavier than a data
  outcome; still needs a pure resolve inside. **Rejected** (an outcome can later back a command
  if undo is ever wanted).

## Consequences

### Positive
- Preview, player move, enemy move and reports share one rule path → no drift.
- Reports (combat / purification) get a complete record without recomputation.
- `CombatResolver` gains effective strength without learning about modifiers.
- Easy, exhaustive unit tests on `MoveResolver` (pure).

### Negative
- One more data class and service; `MapController` becomes thinner but must route outcomes.
- `ArmyController.apply_combat_result` / `apply_peaceful_move` are replaced by
  `apply_outcome` (test migration).

### Neutral
- Enemy AI keeps deciding with `EnemyAIController.decide` (ADR-0005); only application changes.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Preview and apply diverge through a later edit | Low | High | Contract test: preview == applied outcome for every branch |
| `MoveResolver` accidentally mutates state | Low | High | Snapshot test around `preview_move` |
| Effective-strength rounding differs from combat GDD examples | Medium | Medium | Combat §4 example (Kurt Gücü, A=4, D=4) as a unit test |

## Performance Implications

| Metric | Expected | Budget |
|--------|----------|--------|
| CPU per preview | O(1) + O(modifiers) ≈ microseconds; on hover only | 16.6 ms |
| Memory | One `MoveOutcome` per hover | negligible |

## Migration Plan
1. **First step of C-38** (C-38 already depends on C-59): add `MoveOutcome`, `MoveResolver`,
   `ArmyController.apply_outcome`, `MapController.preview_move`; route `attempt_move` and
   `_apply_enemy_move` through them for COMBAT/PEACEFUL with behaviour parity (existing tests
   stay green), then add PURIFICATION with `SpiritRules` + `SpiritController.apply_purification`.
2. **C-37** (recruit + HUD): add `IncomeRules`, switch `ResourceController` to it, HUD forecast.
3. **M2 boons** (Kurt Gücü / Demir Post): add `CombatResolver.resolve_effective`, `A_eff/D_eff`
   in `MoveResolver`.
4. **C-41/C-45**: hover preview UI + failed-purification second click.

## Validation Criteria
- [ ] For COMBAT, PURIFICATION (success and failure) and PEACEFUL: `preview_move(t)` equals the
      outcome applied by `attempt_move(t)` field-for-field.
- [ ] `preview_move` leaves `MapState`/`GameState` unchanged (snapshot test).
- [ ] Enemy move into a corrupted region resolves as COMBAT or PEACEFUL, never PURIFICATION;
      corruption unchanged.
- [ ] spirit AC11: level 2, P = 9 → purified, Ruh +20, army 5; P = 8 → whole force dispersed,
      target unchanged.
- [ ] combat §4 example: Kurt Gücü 1 stack, A = 4, D = 4 → `A_eff = 5`, attacker_remaining 2.
- [ ] `ResourceController.collect_turn_income` and the HUD forecast return the same F2 value
      (resource AC: `I_raw = 5, B_add = 1, M_g = 1.0` → 6).

## GDD Requirements Addressed

| Source | Requirement | How |
|--------|-------------|-----|
| TR-army-003 / spirit §3.2 "Hamle önizlemesi" | Deterministic preview from the same rules; confirm failing purification | Decisions 2–4 |
| TR-resource-006 / resource F2 | HUD forecast equals the economy step | Decision 6 |
| TR-combat-004 / combat §4 "Etkin güç" | Effective strength without breaking the leaf | Decision 5 |
| army §3.3 | Branch order combat → purification → peaceful; enemy uses 1 and 3 | Decision 2 |
| registry `spirit_state` (D3) | `SpiritController` sole writer | Decision 3 |

## Related
- ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006; `architecture.md` §4.1.
- Implementation: C-38 (step 1), C-37 (income), M2 boons, C-41/C-45 (preview UI).
