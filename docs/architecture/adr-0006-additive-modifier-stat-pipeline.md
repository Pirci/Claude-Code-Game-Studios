# ADR-0006: Additive Modifier / Stat Pipeline

## Status

Proposed

## Date

2026-10-18

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW — plain GDScript data classes and pure functions; no rendering/physics/post-cutoff APIs |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | None. (`duplicate_deep()` 4.5+ is relevant only to the future save/load ADR) |
| **Verification Required** | Typed `Array[StatModifier]` invariance in 4.7 (callers must pass an exactly typed array; `.filter()` results are untyped); `ModifierSource` `.tres` load path |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0003 (dependency injection — resolver is injected), ADR-0004 (state segregation — modifier list is data-only state) |
| **Enables** | Spirit/boon implementation (TR-spirit-006), council-system GDD, resource-system F2 (`B_add`/`M_g`) wiring (C-37), `CombatResolver` stat inputs |
| **Blocks** | Spirit (boons) and council implementation stories |
| **Ordering Note** | Save/Load ADR (C-16) serializes `GameState.modifiers`; keep `StatModifier` a plain field-only class so its `RefCounted → Resource` migration is mechanical (`ModifierSource` is a `Resource` from the start) |

## Context

### Problem Statement

`spirit-system.md` §3.4 states that boon effects are passive and additive
("etkisi yığılır"), and §6 requires the future council (Altı Oğul) bonuses to
share the **same additive modifier pipeline** without double-counting
(TR-spirit-006). `resource-system.md` F2 already consumes the pipeline's output
as `B_add` (flat) and `M_g` (multiplier). Today there is only
`GameState.bozkurt_bonuses: Array[float]` with `get_total_bozkurt_bonus()` — an
unkeyed, untyped-by-stat sum that cannot say *which* stat a bonus targets, *where*
it came from, or whether it was already counted. Without a decision, each system
(combat, resource, spirit, council) will grow its own bonus summation and
double-counting will be a matter of time.

### Constraints

- GDD: boon effects are **additive** and stack on repeat pick (spirit §3.4).
- GDD: resource F2 `turn_income = max(I_floor, floor((I_raw + B_add) × M_g))` — flat added before the multiplier.
- ADR-0004: state objects hold data + pure getters only; no logic.
- Technical preferences: no autoload singletons, no central signal hub; static typing mandatory; gameplay values data-driven.
- Determinism: results must be identical for identical state (tests, seeded boon offers).
- Must be serializable later (C-16).

### Requirements

- One pipeline for boons **and** council bonuses (and any future source).
- Prevent double-counting structurally, not by convention.
- Stat resolution is a pure function of (base value, modifier list).
- Add/remove a source's modifiers atomically (e.g. boon taken, council member lost).
- Percentages combine additively with each other (GDD wording); flats are added before percentages.

## Decision

Introduce a **source-keyed modifier list** (data, in `GameState`) and a **pure
`StatResolver`** (logic, in `features/modifiers/`), injected into consumers.

### Data model (data-only, ADR-0004)

- `StatModifier` (`RefCounted`, field-only): `source_id: StringName`
  (e.g. `&"boon:bereket"`, `&"council:oguz"`), `stat_id: StringName`
  (e.g. `&"gold_income"`, `&"army_attack"`), `kind: Kind` (`FLAT` | `PERCENT`),
  `value: float` (per stack), `stacks: int` (≥ 1).
- `GameState.modifiers: Array[StatModifier]` replaces `bozkurt_bonuses`
  (migration below).
- **Uniqueness invariant:** at most one `StatModifier` per
  `(source_id, stat_id, kind)`. Re-acquiring the same boon increments `stacks`
  on the existing record; it never appends a duplicate.
- `ModifierSource` (`extends Resource`, `.tres`, `@export`ed typed fields):
  `source_id: StringName`, `exclusive_group: StringName` (empty = none),
  `effects: Array[ModifierEffect]` where `ModifierEffect` (`Resource`) holds
  `stat_id`, `kind`, `value`. The group lives on the **source**, not on each
  modifier, and is checked **per source** at registration.

### Resolution (pure)

```
flat_sum(stat)    = Σ value × stacks   over kind == FLAT    and stat_id == stat
pct_sum(stat)     = Σ value × stacks   over kind == PERCENT and stat_id == stat
resolve(stat, base) = (base + flat_sum) × (1 + pct_sum)
```

Rounding is the **caller's** responsibility and follows its GDD (resource F2:
`floor`; combat: `ceil`). The resolver returns `float`.
`flat_sum` → resource `B_add`; `1 + pct_sum` → resource `M_g`.

Clamping (e.g. `M_g` 1.0–2.0) is also the caller's GDD range, applied after
resolution; the resolver does not know game ranges.

### Mutation (controller, ADR-0003)

`ModifierController` (a `RefCounted` service created by `GameContext` and injected via `bind_services`) is the only writer:
`add_source(source: ModifierSource)` / `remove_source(source_id)`. The controller expands a `ModifierSource` (loaded with `load()`, not a persistent `preload` chain) into `StatModifier` records.
It rejects (returns `false`, `push_warning`) a source whose non-empty
`exclusive_group` equals that of an already-registered source with a
**different** `source_id`. Sources representing the same effect (e.g. a
council member and a boon both granting +10% gold) share one group, so only
one can be active — this is how boon vs. council double-counting is
blocked. Re-adding the *same* `source_id` increments `stacks`. It emits
`modifiers_changed(stat_id: StringName)` (signal up) so HUD/consumers refresh.

### Architecture

```
ModifierSource (.tres, data)  ──add_source──▶ ModifierController (sole writer)
                                                   │ writes
                                                   ▼
                                       GameState.modifiers: Array[StatModifier]
                                                   │ read (pure)
                                                   ▼
                       StatResolver.resolve(stat_id, base, modifiers) -> float
                          ▲            ▲              ▲
                 ResourceController  CombatResolver  Spirit/Council UI
```

### Key Interfaces

```gdscript
class_name StatModifier extends RefCounted
enum Kind { FLAT, PERCENT }   # outside this file: StatModifier.Kind.FLAT
var source_id: StringName
var stat_id: StringName
var kind: Kind
var value: float
var stacks: int = 1

class_name StatResolver extends RefCounted
## Pure: no state, no signals.
## `modifiers` must be an exactly typed Array[StatModifier] (typed arrays are invariant;
## an untyped literal or .filter() result is not accepted).
static func resolve(stat_id: StringName, base: float, modifiers: Array[StatModifier]) -> float
static func flat_sum(stat_id: StringName, modifiers: Array[StatModifier]) -> float
static func percent_sum(stat_id: StringName, modifiers: Array[StatModifier]) -> float

class_name ModifierController extends RefCounted   # no tree/per-frame need
signal modifiers_changed(stat_id: StringName)
func bind_services(game_state: GameState) -> void
func add_source(source: ModifierSource) -> bool
func remove_source(source_id: StringName) -> void
```

### Scope notes

- Stat ids are data (`StringName` constants in one `stat_ids.gd` per consuming feature), not an enum, so new stats need no pipeline change.
- Non-numeric boon effects (e.g. Gök Kalkanı "Erlik yayılma hızı −%20", an interval) are expressed as a `PERCENT` modifier on stat `erlik_spread_rate`; how the consumer interprets it is that GDD's job (open item C-31).
- Multipliers that are **not** player-sourced (corruption `M_c`) stay outside the pipeline — they are per-region game rules, not accumulated bonuses.

## Alternatives Considered

### Alternative 1: Each system sums its own bonuses

- **Description**: Resource sums Bereket, combat sums Kurt Gücü, council adds its own.
- **Pros**: No new abstraction; fastest to start.
- **Cons**: Double-count risk is unmanaged; no single view of "what affects gold"; duplicated stacking rules; save format fragmented.
- **Rejection Reason**: Exactly the failure TR-spirit-006 exists to prevent.

### Alternative 2: Multiplicative stacking of every percentage

- **Description**: `Π(1 + p_i)`.
- **Pros**: Cannot exceed intuitive bounds as fast at low values; common in ARPGs.
- **Cons**: Contradicts GDD "toplamsal"; exponential growth on repeat boons; harder to read in UI ("+%20 total").
- **Rejection Reason**: GDD defines additive stacking; balance range %3–%15 is tuned for additive.

### Alternative 3: Godot `Resource`-based stat graph / node-attached stat components

- **Description**: Each unit/region owns a `StatBlock` node tree with modifiers attached.
- **Pros**: Per-entity buffs, familiar to ARPG devs.
- **Cons**: State scattered across nodes (violates ADR-0004); no per-entity stats exist in this game (bonuses are campaign-global); heavier.
- **Rejection Reason**: Over-engineered for campaign-global bonuses; revisit if per-unit effects appear.

## Consequences

### Positive

- Double-counting is prevented by the `(source_id, stat_id, kind)` uniqueness invariant plus `exclusive_group`.
- Single audit point: filtering `GameState.modifiers` by stat explains every bonus (UI tooltip, debug).
- Pure resolver → trivially unit-testable; matches resource F2 and spirit stacking text exactly.
- Data-only list serializes cleanly with the save/load migration (`StatModifier` becomes `Resource`; `ModifierSource` already is).

### Negative

- Replaces `bozkurt_bonuses` / `get_total_bozkurt_bonus()` (small code + test migration).
- Callers must remember to resolve through `StatResolver` (not read modifiers raw) — enforced by review.
- Float stacks: summing floats can drift; mitigated by caller rounding and tests using exact-representable values.

### Risks

| Risk | Mitigation |
|------|-----------|
| A system bypasses the resolver and re-sums bonuses | Code-review rule + grep check in CI for direct `modifiers` iteration outside `features/modifiers/` |
| `exclusive_group` forgotten when authoring a new source | `ModifierSource` validation test iterates all `.tres` sources and fails on duplicate effects |
| Percent sums exceed GDD ranges | Consumers clamp to GDD range; tuning knob table owns ranges |
| Non-numeric lütuf effects forced into stat form | Allowed to remain outside pipeline; decided per boon in C-31 |

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `spirit-system.md` §3.4 | Boon effects passive, additive, stack on repeat | `stacks` on a single record; additive `pct_sum` |
| `spirit-system.md` §6 / TR-spirit-006 | Council shares the additive pipeline; no double-count | Single list + uniqueness invariant + `exclusive_group` |
| `resource-system.md` F2 | `B_add` (flat) then `M_g` multiplier | `flat_sum` → `B_add`; `1 + pct_sum` → `M_g` |
| `combat-system.md` | Attack/defense strength boons (Kurt Gücü, Demir Post) | `army_attack` / `army_defense` stats resolved via `StatResolver` (formula integration in C-31/C-33) |
| `council-system.md` (not yet written) | Council bonuses | Council members are `ModifierSource`s |

## Performance Implications

- **CPU**: Resolution is O(n) over ≤ ~50 modifiers, called a handful of times per turn — negligible.
- **Memory**: A few dozen small objects.
- **Load Time**: None until save/load.
- **Network**: N/A.

## Migration Plan

1. Add `StatModifier`, `StatResolver`, `ModifierSource`, `ModifierController` under `game/features/modifiers/` with unit tests.
2. Replace `GameState.bozkurt_bonuses` with `modifiers`; remove `get_total_bozkurt_bonus()`; update `game_state.gd` and its tests (no production caller exists today).
3. Wire `ResourceController` F2 (`B_add`, `M_g`) when C-37 lands.
4. Register ownership/forbidden pattern in `docs/registry/architecture.yaml`.

**Rollback**: modifiers are additive to the codebase; reverting means restoring `bozkurt_bonuses`.

## Validation Criteria

- [ ] Unit test: same source added twice → one record, `stacks == 2`.
- [ ] Unit test: boon + council on the same stat sum once each; duplicate effect under another source in the same `exclusive_group` is rejected.
- [ ] Unit test: `resolve()` accepts a typed array built from a `.filter()` result via `Array[StatModifier]` conversion.
- [ ] Unit test: `resolve(base=5, flat=+1, pct=+0.2)` → `7.2`, and caller floor gives resource AC `floor(6 × 1.2) = 7`.
- [ ] No consumer iterates `GameState.modifiers` outside `features/modifiers/`.

## Related Decisions

- ADR-0003 (DI), ADR-0004 (state segregation).
- `design/gdd/spirit-system.md` §3.4–3.5, §4, §6; `design/gdd/resource-system.md` F2.
- Open follow-ups: C-16 (save/load serializes `modifiers`), C-31 (boon timing/MVP subset).
