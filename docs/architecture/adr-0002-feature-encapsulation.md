# ADR-0002: Feature Encapsulation

## Status

Proposed

## Date

2026-08-13

## Last Verified

2026-08-13

## Decision Makers

Technical direction (retroactive documentation of as-built architecture), validated by `godot-specialist`.

## Summary

Steppeborn organizes source code by **feature** (cohesive folders under
`game/features/`), not by file type (`scripts/`, `scenes/`, `art/`). Each feature
groups its code, scenes, and data resources together, depends minimally on outside
code, and follows a layered dependency direction: leaf features (e.g. combat) have
zero outside dependencies, while orchestrator features (e.g. grid/map) depend on
injected leaf services.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW — folder organization is engine-agnostic; Godot does not care where files live |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (contexts instantiate and orchestrate feature services) |
| **Enables** | Modular grand-strategy expansion (systems-index Post-v1.0 layers) |
| **Blocks** | None |
| **Ordering Note** | Assumes the context hierarchy from ADR-0001 exists to host feature services. |

## Context

### Problem Statement

Organizing code by file type (`scripts/`, `scenes/`, `assets/`) scatters a single
feature's pieces across the tree and encourages diffuse, hard-to-track dependencies
— exactly the coupling problem that makes systems hard to change, test, and
onboard. We need a folder convention that keeps related code together and makes
cross-feature dependencies explicit and minimal, so new grand-strategy layers can
be added without rewriting the core.

### Current State

Implemented. `game/features/` contains `grid/`, `army/`, `combat/`, `resources/`,
`diplomacy/`, `bozkurt/`, `campaign/`, `audio/`. Data resources are co-located in
`feature/data/` (e.g. `combat/data/combat_config.tres`,
`grid/data/chapter_1_map.tres`). `combat/combat_resolver.gd` is a pure leaf with no
outside dependencies; `grid/map_controller.gd` orchestrates army/resource/combat
services injected into it.

### Constraints

- **Technical**: GDScript has no namespaces; encapsulation is a convention, not
  enforced by the compiler (unlike C# namespaces). `class_name` registers a type
  globally, which can silently break encapsulation.
- **Compatibility**: Must interoperate with the context hierarchy (ADR-0001) and
  dependency injection (ADR-0003).

### Requirements

- Group each feature's code, scenes, and data resources under one folder.
- Keep leaf features free of outside dependencies; concentrate dependencies in
  orchestrators.
- Make cross-feature dependencies explicit (injected, not reached-into).

## Decision

Organize `game/` **by feature**, not by file type.

- Each feature is a folder under `game/features/<feature>/` containing its scripts,
  scenes, and a `data/` subfolder for its `.tres` resources.
- Dependency direction is layered:
  - **Leaf features** (e.g. `combat`) have zero outside code dependencies — pure,
    reusable, trivially testable.
  - **Orchestrator features** (e.g. `grid`) depend on leaf services, which are
    **injected** (ADR-0003), never reached into via global lookups.
- Cross-feature communication is **call down, signal up**: an orchestrator calls
  down into injected services and connects to their signals; a service never
  reaches back to its caller.
- Non-feature top-level folders remain: `contexts/` (orchestration, ADR-0001),
  `state/` (data, ADR-0004), `ui/` (shared shell/screens), `assets/` (shared art,
  audio, fonts, shaders, locale), `tests/`, `debug/`.

### Architecture

```
game/
├── contexts/          orchestration (ADR-0001)
├── features/          ← feature-encapsulated modules
│   ├── combat/        LEAF — zero outside deps (combat_resolver, combat_config)
│   │   └── data/      combat_config.tres
│   ├── army/          LEAF-ish — army_controller
│   ├── resources/     LEAF-ish — resource_controller
│   ├── grid/          ORCHESTRATOR — map_controller depends on army+resources+combat
│   │   └── data/      chapter_1_map.tres, region definitions
│   └── diplomacy/ bozkurt/ campaign/ audio/
├── state/             data-only (ADR-0004)
├── ui/                shared UI shell (hud/, screens/)
└── assets/            shared art/audio/fonts/shaders/locale

Dependency direction:  contexts ──▶ orchestrator features ──▶ leaf features
                       (nothing points back up)
```

### Key Interfaces

Feature services expose a `bind_services(...)`/`bind_config(...)` method for
injection (ADR-0003) and communicate outward via signals. Example (leaf):

```gdscript
# game/features/combat/combat_resolver.gd
class_name CombatResolver extends RefCounted   # public API → class_name justified
signal combat_resolved(result: CombatResult)
func bind_config(config: CombatConfig) -> void
func resolve(attacker_army: int, defender_army: int) -> CombatResult
```

### Implementation Guidelines

- **`class_name` policy**: register a global `class_name` only for types intended to
  be referenced across features (public APIs, injected service types, data types).
  Internal helper scripts should omit `class_name` and be referenced by relative
  path, to avoid silently widening a feature's public surface.
- **Data co-location**: keep a feature's tunable data in `feature/data/*.tres`.
- **Prefer injection over `preload`** for cross-feature resources; where `preload`
  is used, rely on Godot's UID system (enabled by default in 4.x) so paths survive
  renames. Document any cross-feature `preload` as an intentional dependency.
- **Adding a new grand-strategy layer** = adding a new feature folder + injecting it
  where needed; do not modify unrelated features.

## Alternatives Considered

### Alternative 1: Organize by file type

- **Description**: Top-level `scripts/`, `scenes/`, `assets/` folders.
- **Pros**: Familiar; trivial to set up.
- **Cons**: A feature's pieces are scattered; encourages diffuse dependencies;
  editors can already filter by type, so the folders add no value.
- **Estimated Effort**: Same.
- **Rejection Reason**: Actively encourages the coupling this project is avoiding.

### Alternative 2: Flat structure (all scripts in one folder)

- **Description**: No folder hierarchy; everything in `game/`.
- **Pros**: Zero navigation depth.
- **Cons**: No cohesion signal; unmanageable past a handful of files; merge-conflict
  prone.
- **Rejection Reason**: Does not scale to a systems-heavy grand-strategy game.

## Consequences

### Positive

- Related code/scenes/data live together; cohesion is visible in the tree.
- Leaf features are reusable and testable in isolation (see `game/tests/unit/`).
- New systems slot in as new folders without touching existing ones.
- Fewer merge conflicts — developers work within distinct feature folders; conflicts
  concentrate in the (simpler-to-reason-about) orchestration layer.

### Negative

- Encapsulation is convention-only in GDScript (no compiler enforcement); discipline
  required, especially around `class_name`.
- Deciding what constitutes a "feature" is a judgment call that needs periodic review.

### Neutral

- Cross-feature dependencies must be made explicit via injection, adding a small
  amount of wiring code in orchestrators/contexts.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| `class_name` on internal types silently breaks encapsulation | Medium | Medium | `class_name` reserved for public APIs; review in code review |
| Hardcoded `preload` paths couple features and break on move | Low | Low | Rely on UID-based paths; prefer injection; document intentional cross-feature preloads |
| "Feature" boundaries drift over time into a tangle | Medium | Medium | Revisit boundaries at each milestone; keep leaf features dependency-free |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | n/a | No runtime impact — folder layout is compile/organization-time only | 16.6 ms/frame |
| Memory | n/a | No impact | 512 MB ceiling |
| Load Time | n/a | No impact | — |

## Migration Plan

Not applicable — documents the as-built layout. New features follow the convention.

**Rollback plan**: N/A.

## Validation Criteria

- [ ] Every gameplay system lives under `game/features/<feature>/`, not a type folder.
- [ ] Leaf features (e.g. combat) have no `preload`/reference to other features.
- [ ] Orchestrators receive dependencies via injection, not global lookup.
- [ ] No file-type top-level folders (`scripts/`, `scenes/`) exist under `game/`.

## GDD Requirements Addressed

<!-- Foundational — enables the modular expansion promised in the systems index. -->

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/systems-index.md` | Modüler Genişleme (Post-v1.0) | "grand-strategy katmanları çekirdeği yeniden yazmadan ayrı feature olarak eklenebilir" | Each new layer is an isolated feature folder injected where needed |
| `design/gdd/combat-system.md` | Savaş Çözümü | Auto-resolve combat as a self-contained, testable rule set | `features/combat` is a zero-dependency leaf with unit tests |

> Foundational — enables modular growth; no single gameplay requirement mandates the
> folder convention itself.

## Related

- Depends on ADR-0001 (Context-Based Hierarchical Architecture).
- Works with ADR-0003 (Dependency Injection) and ADR-0004 (State Segregation).
- Implemented in: `game/features/*`, `game/tests/unit/*`.
- Architecture principles: `.claude/docs/directory-structure.md` → "Mimari İlkeler".
