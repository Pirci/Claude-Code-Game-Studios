# ADR-0003: Dependency Injection via bind_services

## Status

Proposed

## Date

2026-08-13

## Last Verified

2026-08-13

## Decision Makers

Technical direction (retroactive documentation of as-built architecture), validated by `godot-specialist`.

## Summary

Steppeborn uses **no autoload singletons** for game services or state. Instead,
services are plain GDScript classes (`RefCounted`) instantiated by their owning
context/orchestrator and wired together via explicit `bind_services(...)` /
`bind_config(...)` methods called after `.new()`. This makes every dependency
explicit, removes hidden global coupling, and keeps services testable in isolation.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW — RefCounted, signals, and `.new()` wiring stable since Godot 4.0 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm service lifetimes: a RefCounted service is freed when the last reference (its context var) is released |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (contexts create and own service instances) |
| **Enables** | ADR-0002 (feature services are injected, not reached into); testable systems |
| **Blocks** | None |
| **Ordering Note** | Establishes the wiring mechanism that feature encapsulation (ADR-0002) relies on. |

## Context

### Problem Statement

Autoload singletons are convenient but create hidden, global dependencies:
scripts can reference them from anywhere, load-order coupling appears, and systems
become impossible to test in isolation. We must decide how services obtain their
dependencies without relying on globals.

### Current State

Implemented. `project.godot` has **no `[autoload]` section**. Contexts instantiate
services with `.new()` and wire them via `bind_services(...)`. Example:
`GameContext._setup_controllers()` creates `ArmyController`, `ResourceController`,
`CombatResolver`, `MapController` and calls
`_map_controller.bind_services(map_state, game_state, army_controller, resource_controller, combat_resolver, win_condition)`
and `_combat_resolver.bind_config(COMBAT_CONFIG)`.

### Constraints

- **Technical**: GDScript's `_init()` cannot take named parameters, making
  constructor injection of large dependency lists awkward and positional-error-prone.
- **Compatibility**: Must support the context hierarchy (ADR-0001) and feature
  encapsulation (ADR-0002).

### Requirements

- No global singletons for services or state.
- Dependencies of every service are explicit and visible at the injection site.
- Services are unit-testable with mocked/stub dependencies (see `game/tests/unit/`).

## Decision

Use **manual dependency injection via `bind_services(...)`**.

- Services are plain classes extending `RefCounted` (promote to `Node` only if a
  service needs scene-tree lifecycle or per-frame processing — not the case for this
  turn-based game).
- The owning context/orchestrator:
  1. instantiates each service with `.new()`,
  2. calls `bind_services(...)` (or `bind_config(...)`) to inject dependencies,
  3. optionally runs a setup step once all services are wired.
- Injection is done **after** construction (not in `_init()`) so dependency lists
  are named and readable, and so a service can be constructed before its
  collaborators exist.
- Services communicate outward via signals (RefCounted supports `signal`/`emit`);
  callers connect to them — "call down, signal up".

### Architecture

```
Context (owner)
│  var _army := ArmyController.new()
│  var _combat := CombatResolver.new();  _combat.bind_config(COMBAT_CONFIG)
│  var _map := MapController.new()
│  _map.bind_services(map_state, game_state, _army, _resource, _combat, win_cond)
│
└── injected graph:
      MapController ──depends on──▶ ArmyController, ResourceController,
                                    CombatResolver, MapState, GameState, WinCondition
      (all passed in explicitly; nothing looked up globally)
```

### Key Interfaces

```gdscript
# Injection contract — each service exposes explicit wiring:
func bind_services(map_state: MapState, game_state: GameState,
        army_controller: ArmyController, resource_controller: ResourceController,
        combat_resolver: CombatResolver, win_condition: WinCondition) -> void

func bind_config(config: CombatConfig) -> void
```

### Implementation Guidelines

- Instantiate and wire in the owning context's `_setup_*` step; inject before use.
- Use `RefCounted` for services; they are freed automatically when the owning
  context (holding the only reference) is freed — no manual cleanup needed.
- If a service needs a timer or `await`, use `get_tree().create_timer()` from a Node
  context and pass results in; do not promote the service to Node just for that.
- Keep dependency lists honest: if `bind_services` grows very large, treat it as a
  smell and consider whether the orchestrator is doing too much (ADR-0002 boundaries).

## Alternatives Considered

### Alternative 1: Autoload singletons

- **Description**: Register services as Godot autoloads; reference them by global name.
- **Pros**: Zero wiring; reachable anywhere; convenient for prototyping.
- **Cons**: Hidden global dependencies; load-order coupling; untestable in isolation;
  changing one autoload can break unrelated code.
- **Estimated Effort**: Lower up front, much higher long-term.
- **Rejection Reason**: Reintroduces the exact tight coupling this architecture avoids.

### Alternative 2: Constructor injection via `_init()`

- **Description**: Pass all dependencies as `_init()` parameters.
- **Pros**: Dependencies guaranteed present at construction; single wiring point.
- **Cons**: GDScript `_init()` has no named parameters — long positional lists are
  error-prone; forces every collaborator to exist before the service is created.
- **Estimated Effort**: Comparable.
- **Rejection Reason**: Poor ergonomics for multi-dependency services; ordering
  rigidity. `bind_services` gives named, order-flexible wiring.

## Consequences

### Positive

- No global singletons; every dependency is explicit at the call site.
- Services are unit-testable with stubs/mocks (see `game/tests/unit/`).
- Load-order problems disappear — contexts control construction order.

### Negative

- More wiring boilerplate in contexts/orchestrators than autoloads would need.
- `bind_services` must be called before use; a forgotten call fails at runtime, not
  compile time.

### Neutral

- Services are constructed in two phases (`.new()` then `bind_services`), which must
  be understood by anyone extending them.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| `bind_services` not called before use → null-deref at runtime | Medium | Medium | Convention: wire immediately after `.new()` in `_setup_*`; unit tests exercise the wired path |
| Large `bind_services` lists signal an over-broad orchestrator | Medium | Low | Review against ADR-0002 feature boundaries; split if needed |
| A service later needing per-frame/tree lifecycle stays RefCounted | Low | Medium | Promote that specific service to `Node`; document the exception |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | n/a | Negligible — wiring happens once at context setup | 16.6 ms/frame |
| Memory | n/a | Services are lightweight RefCounted; freed with their context | 512 MB ceiling |
| Load Time | n/a | One-time construction on context load | — |

## Migration Plan

Not applicable — documents the as-built pattern. Any future service follows
`.new()` → `bind_services(...)` → use.

**Rollback plan**: N/A. Reverting to autoloads would reintroduce forbidden global coupling.

## Validation Criteria

- [ ] `project.godot` contains no `[autoload]` entries for game services/state.
- [ ] Every service receives its dependencies via `bind_services`/`bind_config`.
- [ ] Services can be constructed and tested with stub dependencies (unit tests exist).
- [ ] No service references another service via a global name.

## GDD Requirements Addressed

<!-- Foundational — a cross-cutting technical decision enabling testability. -->

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/combat-system.md` | Savaş Çözümü | Combat rules must be verifiable/testable | `CombatResolver` is injected and unit-tested in isolation |
| `design/gdd/region-map-system.md` | Bölge Fethi / Harita | Turn flow coordinates multiple systems | `MapController` receives army/resource/combat services via injection |

> Foundational — enables the testability required to validate gameplay formulas.

## Related

- Depends on ADR-0001; enables ADR-0002.
- Bans the autoload-singleton pattern (registered as a forbidden pattern).
- Implemented in: `game/contexts/game_context/game_context.gd`,
  `game/features/grid/map_controller.gd`, `game/features/combat/combat_resolver.gd`.
- Architecture principles: `.claude/docs/directory-structure.md` → "Mimari İlkeler".
