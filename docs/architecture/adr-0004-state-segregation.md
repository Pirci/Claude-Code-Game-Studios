# ADR-0004: State Segregation

## Status

Accepted (2026-10-19 — `/architecture-review` C-17, [report](architecture-review-2026-10-19.md)) — **partially superseded by ADR-0007 (2026-10-18)**: the `RefCounted → Resource` save/load migration (Decision bullet 4, Alternative 2 deferral, Migration Plan) is replaced by a JSON `SaveSerializer`; state classes stay `RefCounted`. The data-only segregation rule is unchanged.

## Date

2026-08-13

## Last Verified

2026-08-13

## Decision Makers

Technical direction (retroactive documentation of as-built architecture), validated by `godot-specialist`.

## Summary

ULUS keeps all long-term game state in dedicated **data-only** objects
(`GameState`, `MapState`, `RegionData`) that hold variables and light getters but
**no game logic** — mutation and rules live in controllers/services. This gives a
single, inspectable hierarchy of state that is easy to save, load, and debug, and
keeps functional code (controllers) cleanly separated from data.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW — plain `RefCounted` data classes; persistence is ADR-0007's JSON serializer |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | None. (`duplicate_deep()` was relevant only to the withdrawn `Resource` migration — superseded by ADR-0007.) |
| **Verification Required** | None — state stays `RefCounted`; copies (e.g. ADR-0005 scratch planning) use explicit copy routines |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (RootContext owns the `GameState` lifecycle) |
| **Enables** | ADR-0007 (save/load); deterministic, testable state |
| **Blocks** | None |
| **Ordering Note** | Resolved by ADR-0007: state stays `RefCounted`, persistence via JSON `SaveSerializer`. Sections below that describe the `Resource` migration are kept as history and marked superseded. |

## Context

### Problem Statement

Without a clear home for state, data leaks into controllers and nodes ad hoc
(e.g. a lone `score` var on a player controller), making the true game state
scattered and hard to save, load, or debug. We need a single, well-defined place
for all long-term state, separated from the logic that mutates it.

### Current State

Implemented. `game/state/` holds three data-only classes, all `extends RefCounted`:

- `GameState` — campaign-level state: `current_chapter`, `gold`,
  `chapters_completed`, `map_state` (as built also the legacy `bozkurt_bonuses` /
  `get_total_bozkurt_bonus()`, replaced by `modifiers` per ADR-0006 — C-55); planned
  `ruh`, `boons` (spirit-system, C-39). Getters only (`is_chapter_unlocked`, `reset`).
- `MapState` — per-map state: `regions` dict, `current_turn`,
  `actions_remaining`, etc. (planned `game_result`, `last_erlik_spread_turn` —
  region-map §3.1). Query getters only.
- `RegionData` — per-region state: owner, army_count, gold_per_turn, geometry.

All mutation happens in controllers (`MapController`, `ArmyController`,
`ResourceController`), never inside the state classes. Save/load: ADR-0007 (not yet built).

### Constraints

- **Technical**: `RefCounted` has no built-in serialization — ADR-0007 adds a pure
  JSON `SaveSerializer` instead of `ResourceSaver`/`ResourceLoader` (which would allow
  script instantiation from user files — forbidden pattern `untrusted_resource_loading`).
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
- **Base class: `RefCounted`** (final — ADR-0007). ~~When save/load is implemented,
  migrate the state classes to `Resource`~~ — *superseded by ADR-0007: persistence is a
  pure JSON `SaveSerializer`; state stays `RefCounted`.*
- **Derived state (amendment 2026-10-19, C-17):** a state field may hold *derived*
  data (e.g. `GameState.modifiers`, ADR-0006) when it has exactly one writer that can
  rebuild it from saved choices; derived fields are never serialized.

### Architecture

```
GameState (RefCounted, data-only)          ← owned by RootContext (ADR-0001)
├── gold, current_chapter, chapters_completed, ruh*, boons*, modifiers* (derived)
└── map_state: MapState (data-only)
        ├── current_turn, actions_remaining, selected_region_id, game_result*
        └── regions: { StringName -> RegionData (data-only) }

Mutation flow:  Controller ──writes──▶ State ; Controller ──signal──▶ observers
                (State never mutates itself or calls out)
* planned (C-39 / C-51 / C-55)
```

### Key Interfaces

```gdscript
# Data-only — fields + pure getters, no mutation logic:
class_name GameState extends RefCounted
var gold: int
var map_state: MapState
func is_chapter_unlocked(chapter: int) -> bool
# (legacy get_total_bozkurt_bonus() is removed by ADR-0006 / C-55)

# Controllers are the sole mutators (ADR-0003):
# MapController.end_turn() writes map_state.current_turn, emits turn_ended
```

### Implementation Guidelines

- Never add mutation/business logic to a state class; if a computed value is needed,
  a pure getter is acceptable, a side-effecting method is not.
- Never store long-term state on a node or controller — route it into a state object.
- ~~When adding save/load: change `extends RefCounted` → `extends Resource` …~~ —
  *superseded by ADR-0007* (`SaveSerializer.to_dict/from_dict`; never `ResourceSaver` /
  `ResourceLoader` on user files).

## Alternatives Considered

### Alternative 1: State stored inside controllers/nodes (no segregation)

- **Description**: Each controller/node keeps its own state fields.
- **Pros**: Less indirection for tiny cases.
- **Cons**: State scatters across the codebase; no single place to save/load/inspect;
  the "lone score var on a player controller" anti-pattern; hard to debug.
- **Rejection Reason**: Defeats save/load and debuggability; the problem this ADR solves.

### Alternative 2: State objects as `Resource`

- **Description**: Make `GameState`/`MapState`/`RegionData` extend `Resource`.
- **Pros**: Built-in serialization; `duplicate_deep()` available.
- **Cons**: `Resource` carries editor/import machinery and `.tres` identity semantics;
  loading `.tres` from `user://` can instantiate scripts (unsafe for player-editable saves).
- **Rejection Reason**: Rejected definitively by ADR-0007 (2026-10-18) in favour of a
  pure JSON serializer; the earlier "deferred migration" plan is withdrawn.

## Consequences

### Positive

- Single, traversable hierarchy of all long-term state — easy to inspect and debug.
- Clean separation: controllers hold logic, state holds data.
- Deterministic and unit-test-friendly (state can be constructed directly in tests).

### Negative

- `RefCounted` state has no built-in persistence; ADR-0007's serializer must be kept
  in step with every new saved field (round-trip tests guard it).
- Slight indirection: controllers must be handed the state they mutate.

### Neutral

- The base-class choice is settled (`RefCounted`, ADR-0007).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| A new state field is forgotten by the JSON serializer | Medium | Medium | ADR-0007 round-trip tests over every state class; review rule: new field ⇒ serializer + test |
| Logic creeps into state classes over time | Medium | Medium | Code review rule: state = data + pure getters only |
| Long-term state added to a controller instead of a state object | Medium | Medium | Review: all persistent fields must live under `GameState` |
| Derived state (modifiers) serialized or written by a second writer | Low | Medium | Registry: modifiers derived, sole writer `ModifierController` (ADR-0006) |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | n/a | Negligible — plain field access | 16.6 ms/frame |
| Memory | n/a | State tree is small (regions + scalars) | 512 MB ceiling |
| Load Time | n/a | Negligible; JSON load is one-time at Continue (ADR-0007) | — |

## Migration Plan

~~Current → save/load capable via `Resource` migration~~ — **superseded by ADR-0007**
(2026-10-18). No migration of the state base class is planned. Remaining state work:
replace `bozkurt_bonuses` with `modifiers` (ADR-0006, C-55); add `ruh`/`boons` (C-39) and
`game_result` / `last_erlik_spread_turn` (C-51, C-38) as plain fields.

## Validation Criteria

- [ ] All long-term state lives in `game/state/` objects, not in controllers/nodes.
- [ ] State classes contain no mutation/business logic (data + pure getters only).
- [ ] Controllers are the sole mutators of state.
- [ ] `GameState` is the single root from which all campaign state is reachable.
- [ ] State round-trips through ADR-0007's `SaveSerializer` (never `ResourceSaver`).
- [ ] Derived fields (`modifiers`) are rebuilt by their sole writer, never serialized.

## GDD Requirements Addressed

<!-- Foundational — enables debuggable, testable, savable game state. -->

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/region-map-system.md` | Bölge Fethi / Harita | Per-region ownership, army counts, adjacency tracked across turns | `MapState`/`RegionData` hold this as data; `MapController` mutates it |
| `design/gdd/game-concept.md` | Bölüm ilerlemesi / kampanya | Chapter unlocks and cross-chapter progress persist | `GameState.chapters_completed` + `is_chapter_unlocked` (persistence: ADR-0007) |

> Foundational — enables save/load, debugging, and deterministic tests across all systems.

## Related

- Depends on ADR-0001 (RootContext owns `GameState`); mutated by controllers per ADR-0003.
- Partially superseded by ADR-0007 (persistence; the `Resource` migration is withdrawn).
- ADR-0006: `GameState.modifiers` is derived state under this ADR's derived-state rule.
- Implemented in: `game/state/game_state.gd`, `game/state/map_state.gd`,
  `game/state/region_data.gd`.
- Architecture principles: `.claude/docs/directory-structure.md` → "Mimari İlkeler".
