# ADR-0006: Additive Modifier / Stat Pipeline

## Status

Accepted (2026-10-19 — `/architecture-review` C-17, [report](architecture-review-2026-10-19.md))

> **Amendment 2026-10-19 (C-53, cross-review W-F):** Gök Kalkanı is a `FLAT` modifier on
> `erlik_spread_interval` (C-31); `ModifierSource` gains `max_stacks`; persistence follows
> "save choices, derive effects" — `GameState.modifiers` is rebuilt on load from saved
> choices (`GameState.boons`, later council state) and is not serialized (ADR-0007 amended).

## Date

2026-10-18

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW — plain GDScript data classes and pure functions; no rendering/physics/post-cutoff APIs |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | ✅ Verified on 4.7.1 (C-17, 2026-10-19): typed arrays are invariant at **runtime** (an untyped array passed to `Array[StatModifier]` errors at call time, not parse time); `.filter()` on a **typed** array returns a typed array, on an untyped array an untyped one; the cast syntax `Array[StatModifier](x)` does not compile — convert with `typed.assign(src)`. Remaining: `ModifierSource` `.tres` load path |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0003 (dependency injection — resolver is injected), ADR-0004 (state segregation — modifier list is data-only state) |
| **Enables** | Spirit/boon implementation (TR-spirit-006), council-system GDD, resource-system F2 (`B_add`/`M_g`) wiring (C-39), effective combat strength computed by the caller of `CombatResolver` (M2), ADR-0007 (modifier rebuild on load) |
| **Blocks** | Spirit (boons) and council implementation stories |
| **Ordering Note** | `GameState.modifiers` is **derived** and never serialized (amendment 2026-10-19); ADR-0007 saves the choices (`boons`) and `ModifierController.rebuild()` restores the records on load. `StatModifier` stays a plain field-only `RefCounted`; `ModifierSource` is content (`Resource`, `res://` only), never saved |

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
- Must survive save/load (ADR-0007) — satisfied by rebuilding from saved choices.

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
  `max_stacks: int` (0 = unlimited — the **single owner** of a stack cap, C-17 D2),
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
A re-add that would exceed the source's `max_stacks` is rejected (`false`); eligibility
checks (e.g. spirit's boon pool) ask `ModifierController.can_add(source)` instead of
reading `stacks` themselves.

**Rebuild on load / context start (C-17, W2):** `rebuild(sources: Array[ModifierSource])`
**clears** `GameState.modifiers` and re-adds each source in order (one entry per saved
choice — e.g. the spirit feature maps `GameState.boons` → `BoonDefinition.modifier_source`).
`GameContext` calls it once during setup, before any consumer resolves, so a `GameState`
that survives across chapters never double-stacks. `SaveSerializer` stays pure and only
restores `boons`.

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
          ResourceController  MapController (combat A_eff/D_eff, spread interval)  Spirit/Council UI
          (CombatResolver itself stays a zero-dependency leaf — ADR-0002; it receives resolved values)
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
## an untyped literal or a .filter() result of an UNTYPED array is not accepted — runtime error;
## convert with `var t: Array[StatModifier] = []; t.assign(src)`).
static func resolve(stat_id: StringName, base: float, modifiers: Array[StatModifier]) -> float
static func flat_sum(stat_id: StringName, modifiers: Array[StatModifier]) -> float
static func percent_sum(stat_id: StringName, modifiers: Array[StatModifier]) -> float

class_name ModifierController extends RefCounted   # no tree/per-frame need
signal modifiers_changed(stat_id: StringName)
func bind_services(game_state: GameState) -> void
func add_source(source: ModifierSource) -> bool        # false on exclusive_group clash or max_stacks
func can_add(source: ModifierSource) -> bool
func remove_source(source_id: StringName) -> void
func rebuild(sources: Array[ModifierSource]) -> void   # clear + re-add (load / context start)
```

### Scope notes

- Stat ids are data (`StringName` constants in one `stat_ids.gd` per consuming feature), not an enum, so new stats need no pipeline change.
- Interval-type boon effects are ordinary stats: Gök Kalkanı is `FLAT +GOK_KALKANI_INTERVAL_BONUS` on `erlik_spread_interval` (C-31, `spirit-system.md` §3.5/§4.6). Range clamps of a *resolved value* (e.g. `M_g` 1.0–2.0) remain the caller's job; the resolver never clamps. Stack limits are **not** a caller clamp — they are enforced at write time by `max_stacks` (below), so no consumer ever reads `stacks` directly.
- **Stack caps (single owner, C-17 D2):** `ModifierSource.max_stacks` (the Gök Kalkanı `.tres` carries `GOK_KALKANI_MAX_STACKS` = 3). `ModifierController.add_source()` rejects a re-add that would exceed it; if the knob is lowered, `rebuild()` on the next load clips the extra picks. Boon catalog metadata (`boon_id`, name key, `requires`) lives in the spirit feature's `BoonDefinition` content resource, which references a `ModifierSource`; the pipeline knows only effects.
- **Persistence — save choices, derive effects (C-53):** `GameState.modifiers` is **derived state**. The saved choices (`GameState.boons`: picked `boon_id`s in order; later the council state) are the single source of truth; on load `ModifierController` rebuilds the records by re-adding each choice's source. This removes the "picks (`n`) vs stacks" double bookkeeping and lets rebalanced content apply to old saves.
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
- **Rejection Reason**: GDD defines additive stacking; boon values (flat +1, Arınma Ustalığı +20 %, `spirit-system.md` §3.5/§7) are tuned for additive.

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
- Save/load stays trivial: the modifier list is rebuilt from saved choices (ADR-0007 amended 2026-10-19); `StatModifier` never needs a serializer.

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
| Non-numeric lütuf effects forced into stat form | C-31 resolved: every MVP/M2 boon is a numeric stat (interval included); a future non-numeric effect may stay outside the pipeline by its GDD's decision |

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `spirit-system.md` §3.4 | Boon effects passive, additive, stack on repeat | `stacks` on a single record; additive `pct_sum` |
| `spirit-system.md` §6 / TR-spirit-006 | Council shares the additive pipeline; no double-count | Single list + uniqueness invariant + `exclusive_group` |
| `resource-system.md` F2 | `B_add` (flat) then `M_g` multiplier | `flat_sum` → `B_add`; `1 + pct_sum` → `M_g` |
| `combat-system.md` §4 "Etkin güç" | Attack/defense strength boons (Kurt Gücü, Demir Post) | `army_attack` / `army_defense` resolved by the caller (`MapController`) and passed to `CombatResolver` as effective strength (TR-combat-004, M2) |
| `council-system.md` (not yet written) | Council bonuses | Council members are `ModifierSource`s |

## Performance Implications

- **CPU**: Resolution is O(n) over ≤ ~50 modifiers, called a handful of times per turn — negligible.
- **Memory**: A few dozen small objects.
- **Load Time**: `rebuild()` at context start — O(boons), negligible.
- **Network**: N/A.

## Migration Plan

1. Add `StatModifier`, `StatResolver`, `ModifierSource`, `ModifierController` under `game/features/modifiers/` with unit tests.
2. Replace `GameState.bozkurt_bonuses` with `modifiers`; remove `get_total_bozkurt_bonus()`; update `game_state.gd` and its tests (no production caller exists today).
3. Wire `ResourceController` F2 (`B_add`, `M_g`) with the M1 boons (C-39; pipeline itself = C-55).
4. Register ownership/forbidden pattern in `docs/registry/architecture.yaml`.

**Rollback**: modifiers are additive to the codebase; reverting means restoring `bozkurt_bonuses`.

## Validation Criteria

- [ ] Unit test: same source added twice → one record, `stacks == 2`.
- [ ] Unit test: boon + council on the same stat sum once each; duplicate effect under another source in the same `exclusive_group` is rejected.
- [ ] Unit test: `resolve()` accepts the `.filter()` result of a typed `Array[StatModifier]` directly, and an untyped source after `assign()` conversion.
- [ ] Unit test: `resolve(base=5, flat=+1, pct=+0.2)` → `7.2`, and caller floor gives resource AC `floor(6 × 1.2) = 7`.
- [ ] No consumer iterates `GameState.modifiers` outside `features/modifiers/`.
- [ ] Unit test: a source with `max_stacks = 3` accepts 3 adds and rejects the 4th; `can_add()` reports it.
- [ ] Unit test: `rebuild()` twice with the same sources leaves identical records (no double stacks).
- [ ] Unit test: rebuilding modifiers from `GameState.boons = [bereket, bereket, gok_kalkani]` yields `gold_income` flat 2 and `erlik_spread_interval` flat 1.

## Related Decisions

- ADR-0003 (DI), ADR-0004 (state segregation).
- `design/gdd/spirit-system.md` §3.4–3.5, §4, §6; `design/gdd/resource-system.md` F2.
- Follow-ups: C-16 ✅ (ADR-0007), C-31 ✅ (boon timing/MVP subset), C-53 ✅ (this amendment); implementation C-55.
