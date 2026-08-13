# ADR-0005: AI Architecture — Pure Decision Services

## Status
Proposed

## Date
2026-08-13

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW — turn-based decision logic over a region graph; no NavigationServer/pathfinding APIs, RefCounted + inner classes + signals stable since 4.0 |
| **References Consulted** | docs/engine-reference/godot/VERSION.md, breaking-changes.md, deprecated-apis.md, modules/navigation.md |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm extracted AI produces identical moves to the current inline `_run_enemy_ai()` (behavior-preserving refactor) |

> Validated by `godot-specialist` (2026-08-13): pattern is idiomatic for Godot 4.7,
> RefCounted lifecycle correct (no manual cleanup), no deprecated/post-cutoff APIs.
> Inner class recommended for the intent data type over a top-level class or Dictionary.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (contexts host services), ADR-0003 (DI via bind_services), ADR-0004 (state segregation) |
| **Enables** | spirit-system implementation (Erlik spread AI); future AI behaviors (diplomacy, hero AI) |
| **Blocks** | Erlik spread stories cannot start until this is Accepted |
| **Ordering Note** | Refactors existing enemy AI out of MapController; do before spirit-system implementation to avoid AI logic accreting in the orchestrator |

## Context

### Problem Statement
Enemy (political) AI is currently hardcoded inside `MapController._run_enemy_ai()`,
which both mutates state and emits gameplay signals. The signature spirit-system
adds a *second*, distinct AI behavior (Erlik corruption spread). game-concept.md
flags "two AI behaviors" as a technical risk. Without a defined home, all AI logic
accretes into the turn-flow orchestrator, making it large, coupled, and hard to
unit-test in isolation.

### Constraints
- No autoload singletons (registry: `autoload_singleton_coupling` forbidden).
- No logic in state objects (registry: `logic_in_state_objects` forbidden).
- Controllers are the sole mutators of state (ADR-0004); `game_state` owned by
  RootContext, mutated by GameContext controllers.
- Determinism required — GDD acceptance criteria mandate reproducible AI/spread.

### Requirements
- A single, consistent home and pattern for all AI decision logic.
- Each behavior independently unit-testable without running a full turn.
- Deterministic output for identical input state.
- Adding a new AI behavior = adding a feature, not editing the orchestrator.

## Decision

AI decision logic lives in **dedicated, injected, pure decision services** under
`game/features/ai/`.

- Each behavior is its own `RefCounted` service: `EnemyAIController` (political),
  `ErlikSpreadController` (corruption spread).
- Each exposes a **pure** `decide(map_state) -> Array[intent]` method: it *reads*
  `MapState` and returns a deterministic list of intents. It does **not** mutate
  state and does **not** emit gameplay signals.
- The orchestrator (`MapController`) receives them via `bind_services(...)`, calls
  `decide()` during `end_turn()`, then **applies** each intent using the
  already-injected `ArmyController` / `CombatResolver`, emitting the existing
  `combat_occurred` / `army_moved` signals. Mutation + signals stay centralized in
  the orchestrator ("call down, signal up", ADR-0004).
- Intent data uses **inner classes** (e.g. `EnemyAIController.MoveIntent`) — type-safe
  and scoped, avoiding both untyped Dictionaries and top-level file clutter.
- Determinism: tie-breaks are rule-based (lowest `army_count`, then `region_id`
  alphabetical). No RNG; if variety is later wanted, a seed lives in `GameState`.

### Architecture Diagram
```
game/features/ai/                     ← LEAF decision services (pure, no mutation)
├── enemy_ai_controller.gd            decide(map_state) -> Array[MoveIntent]
└── erlik_spread_controller.gd        decide(map_state) -> Array[StringName]

MapController.end_turn():             ← ORCHESTRATOR (mutates + signals)
   for intent in _enemy_ai.decide(_map_state):
       apply via _army_controller / _combat_resolver ; emit signals
   for region_id in _erlik.decide(_map_state):
       increment corruption via controller

Data flow:  MapController ──reads via──▶ AI service ──returns intents──▶ MapController applies
            (AI never writes state, never emits gameplay signals)
```

### Key Interfaces
```gdscript
# Pure decision leaf — no mutation, no signals. Intent is an inner class.
class_name EnemyAIController extends RefCounted

class MoveIntent:
    var from_id: StringName
    var to_id: StringName
    func _init(p_from: StringName, p_to: StringName) -> void:
        from_id = p_from
        to_id = p_to

func decide(map_state: MapState) -> Array[MoveIntent]

class_name ErlikSpreadController extends RefCounted
func bind_config(config: SpiritConfig) -> void   # spread interval etc.
func decide(map_state: MapState) -> Array[StringName]   # region_ids to corrupt
```

## Alternatives Considered

### Alternative 1: Unified AI coordinator
- **Description**: One injected `AICoordinator` with `run_turn(map_state)` handling
  both political AI and Erlik spread internally.
- **Pros**: Fewer injection points; single entry.
- **Cons**: Bundles two unrelated behaviors into one class; grows into a
  god-object as behaviors are added; harder to test one behavior in isolation.
- **Rejection Reason**: Violates the one-feature-one-concern goal of ADR-0002;
  poor testability.

### Alternative 2: Keep AI inline in MapController (status quo)
- **Description**: Leave `_run_enemy_ai()` in the orchestrator; add Erlik spread
  as another method there.
- **Pros**: Zero refactor.
- **Cons**: MapController grows unbounded; AI cannot be unit-tested without a full
  turn; the exact gap this review flagged (TR-map-005 undocumented, coupled).
- **Rejection Reason**: Does not scale to multiple AI behaviors; keeps AI untestable
  in isolation.

## Consequences

### Positive
- Each AI behavior is a pure, deterministic, independently unit-testable leaf.
- New AI behaviors (diplomacy, hero AI) slot in as new services, not orchestrator edits.
- MapController stays a thin applier; mutation + signals remain centralized.

### Negative
- One-time refactor to extract `_run_enemy_ai()` into `EnemyAIController.decide()`.
- Slightly more wiring (two more `bind_services` args on MapController).

### Risks
- **Behavior drift during extraction** → mitigate: keep the extraction
  behavior-preserving; existing map/turn tests must stay green; add isolated
  `EnemyAIController` tests asserting the same target-selection rule.
- **AI service tempted to mutate state directly** → mitigate: `decide()` returns
  intents only; the "AI returns intents, orchestrator applies" stance is registered.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| region-map-system.md | Enemy AI: lowest-army non-enemy neighbour target selection with per-turn action budget (TR-map-005) | `EnemyAIController.decide()` encodes the rule as a pure, tested function; MapController applies |
| spirit-system.md | Erlik spread AI: deterministic periodic corruption spread (TR-spirit-005) | `ErlikSpreadController.decide()` — same pure-service pattern, injected into the turn flow |
| game-concept.md | Two distinct AI behaviours (political + Erlik) manageable without coupling | Both are separate injected leaf services sharing one pattern |

## Performance Implications
- **CPU**: Negligible — turn-based, runs once per `end_turn()` over a handful of
  regions (Prolog: 6). Well within 16.6 ms.
- **Memory**: Two lightweight RefCounted services + a small intent array per turn.
- **Load Time**: None.
- **Network**: N/A (single-player).

## Migration Plan
1. Create `game/features/ai/enemy_ai_controller.gd` with `decide(map_state)` holding
   the current target-selection logic from `_run_enemy_ai()` (returns intents).
2. `MapController.end_turn()` calls `_enemy_ai.decide()` then applies intents via
   `ArmyController`/`CombatResolver`, emitting existing signals; delete the inline
   `_run_enemy_ai()`.
3. Add `EnemyAIController` to `GameContext._setup_controllers()` and MapController's
   `bind_services(...)`.
4. Add isolated unit tests for `EnemyAIController.decide()`; keep existing
   MapController/turn tests green (behavior-preserving).
5. When implementing spirit-system, add `ErlikSpreadController` the same way.

**Rollback plan**: Re-inline `decide()` back into MapController (reverse of step 1–2).

## Validation Criteria
- [ ] `EnemyAIController.decide()` returns the same moves the inline AI produced for
      identical `MapState` (regression parity).
- [ ] `EnemyAIController` is unit-tested in isolation with a stub `MapState`.
- [ ] AI services contain no state mutation and emit no gameplay signals.
- [ ] Adding `ErlikSpreadController` requires no change to `EnemyAIController`.

## Related Decisions
- Depends on ADR-0001, ADR-0003, ADR-0004.
- Enables spirit-system (Erlik spread) implementation.
- Documents/refactors code in `game/features/grid/map_controller.gd`.
