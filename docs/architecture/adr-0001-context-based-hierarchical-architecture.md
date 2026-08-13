# ADR-0001: Context-Based Hierarchical Architecture

## Status

Proposed

## Date

2026-08-13

## Last Verified

2026-08-13

## Decision Makers

Technical direction (retroactive documentation of as-built architecture), validated by `godot-specialist`.

## Summary

Steppeborn needs a scene/lifecycle structure that cleanly separates fundamentally
different game modes (main menu vs. in-game) while preserving long-lived state
across transitions and avoiding global autoload singletons. We adopt a
context-based hierarchy: a persistent `RootContext` scene owns `GameState` and
orchestrates transitions between swappable child "context" scenes (`MenuContext`,
`GameContext`), each of which builds and tears down its own service tree.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW — core node/scene lifecycle, stable since Godot 4.0 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/current-best-practices.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm context swap timing (deferred `queue_free()`) does not leave the old context briefly interactable during a transition |

> **Note**: Knowledge Risk is LOW. This ADR relies only on APIs stable since
> Godot 4.0 (`_ready`, `queue_free`, `preload`, `instantiate`, `add_child`,
> callable-based signals). No re-validation needed on minor engine upgrades.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (foundational) |
| **Enables** | ADR-0002 (Feature Encapsulation), ADR-0003 (Dependency Injection), ADR-0004 (State Segregation) |
| **Blocks** | Any epic requiring scene flow between menu and gameplay |
| **Ordering Note** | This is the base architectural decision — the other three foundational ADRs assume this structure exists. |

## Context

### Problem Statement

The game has fundamentally distinct modes with different rules, UI, and service
needs — the main menu and in-game play (and, later, potentially a separate
battle-resolution or diplomacy view). These modes must be able to load, run, and
unload independently, while some state (the campaign `GameState`) must survive the
transition between them. We must decide how the scene tree is structured and how
long-lived state is owned and passed, before more systems are built on top of it.

### Current State

Implemented and working (committed "Menu and first map"). `RootContext extends
Node` is the main scene; it instantiates exactly one context child at a time and
owns `GameState`. This ADR documents that as-built decision so future work has a
recorded rationale and constraint set.

### Constraints

- **Technical**: Godot's built-in `SceneTree.change_scene_to_packed()` replaces
  the entire root, which would discard any persistent state held at the root.
- **Compatibility**: Must not rely on autoload singletons (see ADR-0003) — state
  ownership must be explicit and injected.
- **Resource**: Solo/small team — the structure must be simple to reason about and
  testable in isolation.

### Requirements

- Support at least two contexts (menu, game) with clean load/unload lifecycles.
- Preserve `GameState` across a menu → game transition and discard it on game → menu.
- Each context owns its own services; no context references its parent directly.
- No global singletons for game services or state.

## Decision

Use a **persistent root context with swappable child contexts**.

- `RootContext extends Node` is the Godot main scene. It:
  - owns the long-lived `GameState` instance,
  - preloads context scenes as `const` `PackedScene`s,
  - instantiates exactly one context at a time via
    `_switch_to(context_name: StringName)`, calling `queue_free()` on the outgoing
    context and `instantiate()` on the incoming one,
  - connects to each context's outbound signals to drive transitions,
  - injects long-lived state into a context via `bind_services(...)` **before**
    the context enters the tree.
- Contexts (`MenuContext`, `GameContext`) are swappable children representing
  distinct modes. Each builds its own controllers/services in `_ready()` and tears
  them down when freed.
- Communication follows **call down, signal up**: `RootContext` calls down into
  contexts (`bind_services`, direct method calls) and listens to signals up from
  them (`new_campaign_requested`, `return_to_menu_requested`, `quit_requested`).
  A context never references `get_parent()`.

### Architecture

```
RootContext (Node, main scene)          ← owns GameState, orchestrates transitions
│  const MENU_SCENE / GAME_SCENE (preload)
│  var _game_state: GameState
│  signal context_changed(context_name)
│
├── (one active child at a time)
│
├── MenuContext (Control)               ← signals up: new_campaign_requested, quit_requested
│      builds menu UI / services
│
└── GameContext (Control)               ← bind_services(game_state); signals up: return_to_menu_requested
       builds gameplay controllers/services in _ready()

Data flow:  RootContext ──call down (bind_services / methods)──▶ Context
            RootContext ◀──signal up (requests / events)──────── Context
```

### Key Interfaces

```gdscript
# RootContext
signal context_changed(context_name: StringName)
func _switch_to(context_name: StringName) -> void   # &"menu" | &"game"

# GameContext
func bind_services(game_state: GameState) -> void    # called BEFORE add_child
signal return_to_menu_requested

# MenuContext
signal new_campaign_requested
signal quit_requested
```

### Implementation Guidelines

- Call `bind_services(...)` **before** `add_child(context)` so the context's
  `_ready()` can rely on injected state.
- Reconnect all context signals every time a context is instantiated — connections
  are severed when the old context is freed.
- Use callable-based signal syntax (`sig.connect(_handler)`), never the deprecated
  string form.
- Contexts that hold external resources (timers, threaded loads) should clean up in
  `_exit_tree()`; `queue_free()` guarantees node removal but not custom teardown.

## Alternatives Considered

### Alternative 1: Built-in `SceneTree.change_scene_to_packed()`

- **Description**: Use Godot's native scene switcher to replace the running scene.
- **Pros**: Zero custom orchestration code; idiomatic for simple games.
- **Cons**: Replaces the entire root node, so any state held at the root is
  destroyed on every transition. Would force a separate persistence mechanism
  (autoload or file) for `GameState`.
- **Estimated Effort**: Lower up front, higher later (state persistence bolted on).
- **Rejection Reason**: Cannot preserve `GameState` across transitions without
  reintroducing a global, which ADR-0003 forbids.

### Alternative 2: Autoload-based GameState + built-in scene switching

- **Description**: Move `GameState` to an autoload singleton and use native scene
  switching between menu and game.
- **Pros**: Simplest switching logic; no custom root orchestration.
- **Cons**: Introduces a global singleton — hidden dependencies, load-order
  coupling, and untestable-in-isolation state. Directly contradicts the project's
  no-autoload stance.
- **Estimated Effort**: Comparable.
- **Rejection Reason**: Violates the dependency-injection / no-global-singleton
  principle (ADR-0003).

### Alternative 3: Single monolithic scene with visibility toggling

- **Description**: One always-loaded scene containing menu and game subtrees,
  toggled by `visible`.
- **Pros**: No instantiation/teardown cost; state trivially shared.
- **Cons**: All modes are always in memory and processing; no clean isolation;
  service lifecycles blur together; scales poorly as contexts grow (battle view,
  diplomacy view).
- **Rejection Reason**: Defeats the isolation goal and does not scale to the
  planned grand-strategy contexts.

## Consequences

### Positive

- Clean separation of modes; each context is independently loadable/testable.
- `GameState` ownership is explicit and injected, not global.
- Central, single place (`RootContext`) to reason about all transitions.
- Extensible: new contexts (battle-resolution, diplomacy) slot in without touching
  existing ones — supports the modular grand-strategy expansion in the systems index.

### Negative

- Signals must be manually reconnected on every context instantiation; a missed
  connection fails silently.
- `RootContext` is a coupling point that must know about every context it can spawn.

### Neutral

- Long-lived vs. transient state must be consciously partitioned (root vs. context).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Deferred `queue_free()` leaves old context briefly alive/interactable during a swap | Medium | Low | Remove the outgoing context from the tree (or disable input) before adding the new one; verify visually during transitions |
| Signal not reconnected after re-instantiation → silently lost events | Medium | Medium | Centralize all context signal wiring in `_switch_to`; add an integration test per context |
| `bind_services()` called after `add_child()` → `_ready()` sees null state | Low | High | Enforce "bind before add" convention; document in the context interface |
| Missing `_exit_tree()` cleanup leaks external resources | Low | Medium | Contexts holding timers/threads implement `_exit_tree()` |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | n/a | Negligible steady-state; brief spike on context swap (free + instantiate) | 16.6 ms/frame (60 FPS) |
| Memory | n/a | Only one context resident at a time (menu OR game) | 512 MB ceiling |
| Load Time | n/a | Context instantiation on transition; scenes preloaded as `const` | < 1s per transition |

## Migration Plan

Not applicable — this documents the as-built architecture. No migration required.
If a future refactor introduces additional contexts, they follow the same
instantiate-in-`_switch_to` + `bind_services` pattern.

**Rollback plan**: N/A (foundational, already implemented). Reverting would require
adopting Alternative 1 or 2 and re-solving state persistence.

## Validation Criteria

- [ ] Menu → game → menu transition preserves and then correctly discards `GameState`.
- [ ] Only one context is present in the tree at any settled point.
- [ ] No `[autoload]` entries exist in `project.godot`.
- [ ] All context outbound signals have a live connection after each transition
      (integration test).

## GDD Requirements Addressed

<!-- Foundational decision — no single GDD requirement mandates it; it enables the
     scene flow and the modular expansion promised in the systems index. -->

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/systems-index.md` | Modüler Genişleme (Post-v1.0) | "grand-strategy katmanları çekirdeği yeniden yazmadan ayrı feature olarak eklenebilir" | New game modes are added as new contexts under `RootContext` without modifying existing contexts |
| `design/gdd/game-concept.md` | Sahne Akışı & İlerleme (planned) | Menu → campaign flow with persistent campaign progress | `RootContext` owns `GameState` and drives menu↔game transitions |

> Foundational — no direct gameplay GDD requirement. Enables: scene flow
> (`scene-flow.md`, not yet written) and all in-game systems that run inside
> `GameContext`.

## Related

- Enables ADR-0002 (Feature Encapsulation), ADR-0003 (Dependency Injection),
  ADR-0004 (State Segregation).
- Implemented in: `game/contexts/root_context/root_context.gd`,
  `game/contexts/game_context/game_context.gd`,
  `game/contexts/menu_context/menu_context.gd`.
- Architecture principles: `.claude/docs/directory-structure.md` → "Mimari İlkeler".
