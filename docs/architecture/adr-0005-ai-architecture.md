# ADR-0005: AI Architecture — Pure Decision Services

## Status
Accepted (2026-10-19 — `/architecture-review` C-17, [report](architecture-review-2026-10-19.md))

> **Amendment 2026-10-19 (C-53, cross-review W-E):** `ErlikSpreadController.decide()`
> takes the effective interval and returns a `SpreadDecision` (spread-turn flag + target),
> so the counter-based spread of `spirit-system.md` §3.6/§4.6 is expressible; batch vs
> sequential planning for `enemy_actions_per_turn > 1` is specified below.

> **Amendment 2026-10-20 (C-43, Perde 1 level — [`design/levels/perde1-dogu-curcet.md`](../../design/levels/perde1-dogu-curcet.md) §4.2):**
> `EnemyAIController.decide()` gains the **R1 counter-strike rule**, driven by a data resource
> `EnemyAIProfile` (`attack_start_turn = 5`, ratio 3/2; the default profile keeps the previous
> lowest-army behaviour, so the Prolog is unchanged). Contract stays pure and deterministic
> (no mutation, no signals, no randomness; at most 1 move per turn):
> - **R1:** turn ≥ `attack_start_turn`; source E (army ≥ 2), target an adjacent PLAYER region P;
>   A = E.army − 1; strike only if A > P.army **and** 2A ≥ 3·P.army (ratio ≥ 1.5, integer math).
>   Order: weakest P, largest A, alphabetical `from`, alphabetical `to`.
> - **Defence hold:** if E has another adjacent player region (and E.army − 1 ≥ 2), E does not strike.
> - **R2 defence shifting:** disabled. **Otherwise:** `null` (wait).
> - The AI never enters NEUTRAL regions and ignores `corruption_level` (spirit-system §3.7).
> - `MoveIntent` gains `reason: StringName` (Perde 1: `&"strike"`); the presentation layer
>   (ADR-0011 battle report) uses it to pick `BATTLE_HELD_DEFENSE` / `BATTLE_LOST_DEFENSE`.
> - Determinism is a tested property (`test_..._is_deterministic_across_runs`).

> **Amendment 2026-10-21 (C-44, [`design/gdd/enemy-layers.md`](../../design/gdd/enemy-layers.md)):**
> - **`EnemyAIProfile` fields (final):** `attack_start_turn: int` (Perde 1: 5), `strike_ratio_num: int` (3),
>   `strike_ratio_den: int` (2), `strike_enabled: bool` (Perde 1: true; default profile: false = legacy
>   lowest-army behaviour). No other fields; reinforcement values stay in `ChapterMapDefinition`.
> - **Defence hold (single definition):** E holds iff it has **two or more** adjacent PLAYER regions **and**
>   `E.army − 1 ≥ 2` (the second clause belongs to the source).
> - **Effective defence input:** the AI reads the player's **effective** defence, not raw army: in R1 every
>   `P.army` is replaced by `P_eff = ceil(resolve(&"army_defense", P.army))` (`P_eff = 0` when `P.army = 0`),
>   i.e. the same value `CombatResolver.resolve_effective` uses for the defender (combat-system §4 "Etkin güç").
>   `decide()` stays **pure**: the caller (`MapController`) passes the player's defence modifiers as an explicit
>   input and `decide()` calls the pure `StatResolver` (ADR-0006); no service lookup, no mutation, no signals.
>   The enemy itself still receives no modifiers (`A_eff = A`). Consequence: an R1 strike always satisfies
>   `A > D_eff`, so it always wins (Dal 1). Order key uses `P_eff` (weakest `P_eff`, largest `A`, alphabetical
>   `from`, alphabetical `to`).
> - **Tests:** `_reads_effective_defense_from_modifiers`, `_empty_target_ignores_modifiers`,
>   `_does_not_mutate_inputs` (enemy-layers AC19–AC20).

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
| **Depends On** | ADR-0001 (contexts host services), ADR-0002 (`features/ai/` feature folder), ADR-0003 (DI via bind_services), ADR-0004 (state segregation), ADR-0006 (caller resolves the effective spread interval via `StatResolver`) |
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
- Each exposes a **pure** `decide(...)` method: it *reads* `MapState` (plus explicit
  inputs) and returns a deterministic **intent** — `EnemyAIController` the next
  `MoveIntent` (or `null`), `ErlikSpreadController` a `SpreadDecision`. It does **not**
  mutate state and does **not** emit gameplay signals.
- The orchestrator (`MapController`) receives them via `bind_services(...)`, calls
  `decide()` during `end_turn()`, then **applies** each intent through the same
  owner-agnostic rules the player uses — `ArmyController.can_move(…, mover = ENEMY)`
  and the arrival branches 1/3 of `army-system.md` §3.3 (combat / peaceful; a region
  emptied by combat becomes `NEUTRAL`) — emitting the existing `combat_occurred` /
  `army_moved` signals. Mutation + signals stay centralized in the orchestrator
  ("call down, signal up", ADR-0001/ADR-0003).
- Intent data uses **inner classes** (e.g. `EnemyAIController.MoveIntent`) — type-safe
  and scoped, avoiding both untyped Dictionaries and top-level file clutter.
- Determinism: tie-breaks are rule-based (lowest `army_count`, then `region_id`
  alphabetical). No RNG; if variety is later wanted, a seed lives in `GameState`.

### Architecture Diagram
```
game/features/ai/                     ← LEAF decision services (pure, no mutation)
├── enemy_ai_controller.gd            decide(map_state, acted) -> MoveIntent (null = none)
└── erlik_spread_controller.gd        decide(map_state, effective_interval) -> SpreadDecision

MapController.end_turn():             ← ORCHESTRATOR (mutates + signals)
   var acted: Array[StringName] = []
   for i in _map_state.enemy_actions_per_turn:          # decide → apply loop = sequential
       var intent := _enemy_ai.decide(_map_state, acted)
       if intent == null: break
       apply via _army_controller (can_move mover=ENEMY, branches 1/3) ; emit signals
       acted.append(intent.from_id)
   # effective interval: base = _map_state.erlik_spread_interval (chapter content),
   # + Gök Kalkanı via StatResolver.resolve(&"erlik_spread_interval", base, modifiers)
   var spread := _erlik.decide(_map_state, effective_interval)
   if spread.is_spread_turn:
       _map_state.last_erlik_spread_turn = _map_state.current_turn
       if spread.target_id != &"": _spirit.apply_spread(spread.target_id)   # spirit feature = sole corruption writer

Data flow:  MapController ──reads via──▶ AI service ──returns intents──▶ MapController applies
            (AI never writes state, never emits gameplay signals)
```

**Sequential semantics (C-53, simplified C-17):** the GDD rule processes enemy regions
one after another, each seeing the result of the previous move. The orchestrator
therefore calls `decide()` once per action and applies the result before the next call
(decide → apply loop); `acted` lists regions that already moved this turn (each enemy
region moves at most once). No scratch copy of `MapState` is needed.

**Naming outside the defining script (verified 4.7.1, C-17):** inner classes resolve
unqualified only inside their own script. Callers write `EnemyAIController.MoveIntent`,
`Array[EnemyAIController.MoveIntent]` and `ErlikSpreadController.SpreadDecision` (the
existing `CombatResolver.CombatResult` is the working precedent).

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

## Next move of the first enemy region (region_id order) not in `acted` that can move;
## null when none. Callers outside this script: `EnemyAIController.MoveIntent`.
func decide(map_state: MapState, acted: Array[StringName]) -> MoveIntent

class_name ErlikSpreadController extends RefCounted
## No config: the base interval is chapter content (`MapState.erlik_spread_interval`) and
## the effective interval (base + Gök Kalkanı stacks, capped by ModifierSource.max_stacks)
## is resolved by the caller via StatResolver (ADR-0006) — this service never reads modifiers.
func decide(map_state: MapState, effective_interval: int) -> SpreadDecision

class SpreadDecision extends RefCounted:
    var is_spread_turn: bool = false   # current_turn − last_erlik_spread_turn ≥ effective_interval
    var target_id: StringName = &""    # computed on EVERY call: the candidate the rule picks for
                                       # the current state (HUD telegraph, TR-spirit-010);
                                       # empty when no candidate (counter still resets on a spread turn)
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
1. Create `game/features/ai/enemy_ai_controller.gd` with `decide(map_state, acted)`
   holding the target-selection logic from `_run_enemy_ai()` (returns the next intent),
   including the C-33 rules (region_id tie-break and processing order — C-52 lands them
   inline first).
2. `MapController.end_turn()` runs the decide → apply loop (budget
   `enemy_actions_per_turn`), applying each intent via `ArmyController` (owner-agnostic
   `can_move`, branches 1/3, emptied region → `NEUTRAL`) and `CombatResolver`, emitting
   existing signals; delete the inline `_run_enemy_ai()`.
3. Add `EnemyAIController` to `GameContext._setup_controllers()` and MapController's
   `bind_services(...)`.
4. Add isolated unit tests for `EnemyAIController.decide()`; keep existing
   MapController/turn tests green (behavior-preserving).
5. When implementing spirit-system, add `ErlikSpreadController` the same way.

**Rollback plan**: Re-inline `decide()` back into MapController (reverse of step 1–2).

## Validation Criteria
- [ ] The decide → apply loop produces the same moves the inline AI produced (after C-52)
      for identical `MapState` (regression parity).
- [ ] With `enemy_actions_per_turn = 2`, the second move sees the result of the first.
- [ ] `ErlikSpreadController.decide()` returns `target_id` on non-spread turns too, and
      `is_spread_turn = true` with empty `target_id` when no candidate exists.
- [ ] `EnemyAIController` is unit-tested in isolation with a stub `MapState`.
- [ ] AI services contain no state mutation and emit no gameplay signals.
- [ ] Adding `ErlikSpreadController` requires no change to `EnemyAIController`.

## Related Decisions
- Depends on ADR-0001, ADR-0003, ADR-0004.
- Enables spirit-system (Erlik spread) implementation.
- Documents/refactors code in `game/features/grid/map_controller.gd`.
- **Implemented (C-19, 2026-10-19):** `game/features/ai/enemy_ai_controller.gd`,
  `game/features/ai/erlik_spread_controller.gd` (+ `game/tests/unit/ai/`); MapController
  decide → apply loop; spread service wired into `end_turn` by C-38 (needs SpiritController).
