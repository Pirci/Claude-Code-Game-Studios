# ADR-0004: State Segregation

## Status

Proposed

## Date

2026-08-13

## Last Verified

2026-08-13

## Decision Makers

Technical direction (retroactive documentation of as-built architecture), validated by `godot-specialist`.

## Summary

Steppeborn keeps all long-term game state in dedicated **data-only** objects
(`GameState`, `MapState`, `RegionData`) that hold variables and light getters but
**no game logic** — mutation and rules live in controllers/services. This gives a
single, inspectable hierarchy of state that is easy to save, load, and debug, and
keeps functional code (controllers) cleanly separated from data.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW — plain data classes; save/load path (Resource) is a documented future step |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | None currently. `duplicate_deep()` (4.5+) is relevant to the future save/load migration |
| **Verification Required** | When save/load is implemented, verify `Resource` serialization and nested-copy semantics |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (RootContext owns the `GameState` lifecycle) |
| **Enables** | Save/load system (future); deterministic, testable state |
| **Blocks** | None |
| **Ordering Note** | A future save/load ADR will revisit the base-class choice (RefCounted → Resource). |

## Context

### Problem Statement

Without a clear home for state, data leaks into controllers and nodes ad hoc
(e.g. a lone `score` var on a player controller), making the true game state
scattered and hard to save, load, or debug. We need a single, well-defined place
for all long-term state, separated from the logic that mutates it.

### Current State

Implemented. `game/state/` holds three data-only classes, all `extends RefCounted`:

- `GameState` — campaign-level state: `current_chapter`, `gold`,
  `bozkurt_bonuses`, `chapters_completed`, `map_state`. Getters only
  (`is_chapter_unlocked`, `get_total_bozkurt_bonus`, `reset`).
- `MapState` — per-map state: `regions` dict, `current_turn`,
  `actions_remaining`, etc. Query getters only.
- `RegionData` — per-region state: owner, army_count, gold_per_turn, geometry.

All mutation happens in controllers (`MapController`, `ArmyController`,
`ResourceController`), never inside the state classes. No save/load exists yet.

### Constraints

- **Technical**: `RefCounted` has no built-in serialization; `Resource` does
  (`ResourceSaver`/`ResourceLoader`, `.tres`/`.res`).
- **Compatibility**: State is created/owned per ADR-0001 and mutated by injected
  controllers per ADR-0003.

### Requirements

- All long-term state lives in dedicated state objects, not scattered in controllers.
- State objects contain data + light getters only — no mutation logic, no side effects.
- State must be straightforward to serialize when save/load is added.

## Decision

Keep **long-term state in data-only objects, logic in controllers**.

- State classes (`GameState`, `MapState`, `RegionData`) hold fields and pure getters.
  They perform no mutation of the world and call no services.
- Controllers/services (ADR-0003) are the sole mutators of state; they receive state
  via injection and mutate it, emitting signals to notify observers.
- The state hierarchy is rooted at `GameState` (which references `MapState`, which
  references `RegionData`), giving a single traversable tree for debugging and
  (future) serialization.
- **Current base class: `RefCounted`.** This is sufficient while there is no
  persistence requirement. **When save/load is implemented, migrate the state
  classes to `Resource`** (see Migration Plan) to gain built-in serialization and
  `duplicate_deep()` for independent save slots.

### Architecture

```
GameState (RefCounted, data-only)          ← owned by RootContext (ADR-0001)
├── gold, current_chapter, bozkurt_bonuses, chapters_completed
└── map_state: MapState (data-only)
        ├── current_turn, actions_remaining, selected_region_id
        └── regions: { StringName -> RegionData (data-only) }

Mutation flow:  Controller ──writes──▶ State ; Controller ──signal──▶ observers
                (State never mutates itself or calls out)
```

### Key Interfaces

```gdscript
# Data-only — fields + pure getters, no mutation logic:
class_name GameState extends RefCounted
var gold: int
var map_state: MapState
func is_chapter_unlocked(chapter: int) -> bool
func get_total_bozkurt_bonus() -> float

# Controllers are the sole mutators (ADR-0003):
# MapController.end_turn() writes map_state.current_turn, emits turn_ended
```

### Implementation Guidelines

- Never add mutation/business logic to a state class; if a computed value is needed,
  a pure getter is acceptable, a side-effecting method is not.
- Never store long-term state on a node or controller — route it into a state object.
- When adding save/load: change `extends RefCounted` → `extends Resource`, annotate
  persisted fields with `@export`, and use `ResourceSaver.save(state, "user://…")`
  plus `duplicate_deep()` (Godot 4.5+) for independent copies of nested state.

## Alternatives Considered

### Alternative 1: State stored inside controllers/nodes (no segregation)

- **Description**: Each controller/node keeps its own state fields.
- **Pros**: Less indirection for tiny cases.
- **Cons**: State scatters across the codebase; no single place to save/load/inspect;
  the "lone score var on a player controller" anti-pattern; hard to debug.
- **Rejection Reason**: Defeats save/load and debuggability; the problem this ADR solves.

### Alternative 2: State objects as `Resource` from the start

- **Description**: Make `GameState`/`MapState`/`RegionData` extend `Resource` now.
- **Pros**: Built-in serialization immediately; `duplicate_deep()` available.
- **Cons**: `Resource` carries editor/import machinery and `.tres` identity semantics
  not needed until persistence exists; larger change with no current payoff.
- **Estimated Effort**: Moderate refactor (base class + `@export` annotations + test
  updates).
- **Rejection Reason (for now)**: No save/load requirement yet. Deferred to the
  Migration Plan — this is the intended path once persistence is designed.

## Consequences

### Positive

- Single, traversable hierarchy of all long-term state — easy to inspect and debug.
- Clean separation: controllers hold logic, state holds data.
- Deterministic and unit-test-friendly (state can be constructed directly in tests).

### Negative

- `RefCounted` state has no built-in persistence; save/load will require the
  documented `Resource` migration before it can ship.
- Slight indirection: controllers must be handed the state they mutate.

### Neutral

- The base-class choice (`RefCounted` today, `Resource` later) is an explicit,
  revisitable decision tied to the save/load milestone.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Save/load added without migrating to `Resource` → hand-rolled serialization | Medium | Medium | Follow the Migration Plan; write a save/load ADR that supersedes this base-class choice |
| Logic creeps into state classes over time | Medium | Medium | Code review rule: state = data + pure getters only |
| Long-term state added to a controller instead of a state object | Medium | Medium | Review: all persistent fields must live under `GameState` |
| Nested state shared between save slots (aliasing) after migration | Low | High | Use `duplicate_deep()` (4.5+) when copying `GameState` for a slot |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | n/a | Negligible — plain field access | 16.6 ms/frame |
| Memory | n/a | State tree is small (regions + scalars) | 512 MB ceiling |
| Load Time | n/a | Negligible now; future `Resource` load is one-time on save load | — |

## Migration Plan

**Current → save/load capable (triggered when a save/load system is designed):**

1. Change `GameState`, `MapState`, `RegionData` from `extends RefCounted` to
   `extends Resource`.
2. Annotate persisted fields with `@export` so they serialize.
3. Replace ad hoc copies with `duplicate_deep()` (Godot 4.5+) for independent slots.
4. Save via `ResourceSaver.save(game_state, "user://slot_N.tres")`; load via
   `ResourceLoader.load(...)`.
5. Update `game/tests/unit/` fixtures that construct state objects if instantiation
   changes.
6. Record the change in a new save/load ADR that supersedes this ADR's base-class
   choice.

**Rollback plan**: The `RefCounted` design remains valid for a persistence-free
build; reverting the migration is a base-class change back.

## Validation Criteria

- [ ] All long-term state lives in `game/state/` objects, not in controllers/nodes.
- [ ] State classes contain no mutation/business logic (data + pure getters only).
- [ ] Controllers are the sole mutators of state.
- [ ] `GameState` is the single root from which all campaign state is reachable.
- [ ] (Future) After migration, state serializes via `ResourceSaver` round-trip.

## GDD Requirements Addressed

<!-- Foundational — enables debuggable, testable, savable game state. -->

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/region-map-system.md` | Bölge Fethi / Harita | Per-region ownership, army counts, adjacency tracked across turns | `MapState`/`RegionData` hold this as data; `MapController` mutates it |
| `design/gdd/game-concept.md` | Bölüm ilerlemesi / kampanya | Chapter unlocks and cross-chapter progress persist | `GameState.chapters_completed` + `is_chapter_unlocked` (persistence via future migration) |

> Foundational — enables save/load, debugging, and deterministic tests across all systems.

## Related

- Depends on ADR-0001 (RootContext owns `GameState`); mutated by controllers per ADR-0003.
- Will be partially superseded by a future save/load ADR (base-class RefCounted → Resource).
- Implemented in: `game/state/game_state.gd`, `game/state/map_state.gd`,
  `game/state/region_data.gd`.
- Architecture principles: `.claude/docs/directory-structure.md` → "Mimari İlkeler".
