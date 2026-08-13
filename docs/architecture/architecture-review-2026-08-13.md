# Architecture Review Report

- **Date:** 2026-08-13
- **Engine:** Godot 4.7
- **GDDs Reviewed:** 5 (game-concept, region-map-system, army-system, combat-system, spirit-system)
- **ADRs Reviewed:** 4 (ADR-0001 … ADR-0004 — all `Proposed`)
- **Mode:** `/architecture-review` (full)

---

## Framing

All four ADRs are **cross-cutting structural** decisions (context hierarchy,
feature encapsulation, dependency injection, state segregation). There are
**zero system-specific ADRs**. Consequently structural requirements are covered
thoroughly, while individual-system technical decisions (AI, save/load, modifier
stacking, battle-report UI) are covered only implicitly "by following the
patterns," or not at all.

---

## Traceability Summary

- **Total requirements:** 24
- ✅ **Covered:** 13
- ⚠️ **Partial:** 5
- ❌ **Gaps:** 6

### Full Matrix

| TR-ID | GDD | Requirement | ADR Coverage | Status |
|---|---|---|---|---|
| TR-map-001 | region-map-system | Per-region persistent state (owner/army/income/adjacency/geometry) across turns | ADR-0004 | ✅ |
| TR-map-002 | region-map-system | Map data-driven from `ChapterMapDefinition` Resource, loadable per chapter | ADR-0002 | ⚠️ Partial |
| TR-map-003 | region-map-system | Turn-flow orchestration (AI→income→turn++→win-check) over injected systems | ADR-0003 | ✅ |
| TR-map-004 | region-map-system | Clickable region polygons + visual layer separated from state | ADR-0004 | ⚠️ Partial |
| TR-map-005 | region-map-system | Enemy AI (target selection + action budget) — **already coded** | — | ❌ GAP |
| TR-map-006 | region-map-system | Data-driven win/lose condition evaluation | ADR-0004 | ⚠️ Partial |
| TR-army-001 | army-system | Move validation + garrison rule + action consumption (logic in controller) | ADR-0003 / ADR-0004 | ✅ |
| TR-army-002 | army-system | Arrival resolution routes to combat or peaceful merge | ADR-0002 / ADR-0003 | ✅ |
| TR-combat-001 | combat-system | Deterministic auto-resolve as zero-dependency testable leaf | ADR-0002 | ✅ |
| TR-combat-002 | combat-system | Combat tuning data-driven via injected `CombatConfig` (.tres) | ADR-0003 | ✅ |
| TR-combat-003 | combat-system | `CombatResult` surfaced to UI as a detailed battle report | — | ❌ GAP |
| TR-spirit-001 | spirit-system | `RegionData` extended with `corruption_level` | ADR-0004 | ✅ |
| TR-spirit-002 | spirit-system | Ruh resource + persistent `boons` list on `GameState` | ADR-0004 | ✅ |
| TR-spirit-003 | spirit-system | Purification reuses `CombatResolver` (army vs corruption_strength) | ADR-0002 / ADR-0003 | ✅ |
| TR-spirit-004 | spirit-system | Deterministic seeded boon-offer selection | ADR-0003 / ADR-0004 | ✅ |
| TR-spirit-005 | spirit-system | Erlik spread AI (deterministic, periodic) — **2nd AI behavior** | — | ❌ GAP |
| TR-spirit-006 | spirit-system | Shared additive modifier pipeline (boons + council, no double-count) | — | ❌ GAP |
| TR-spirit-007 | spirit-system | Corruption visual state (color by level, distinguishable) | — | ❌ GAP |
| TR-concept-001 | game-concept | Menu → campaign → scene flow with persistent progress | ADR-0001 | ✅ |
| TR-concept-002 | game-concept | Campaign progress persists **between sessions** (save/load) | ADR-0004 | ⚠️ Partial |
| TR-concept-003 | game-concept | 3 data-driven resources (gold/herds/spirit), extensible | ADR-0002 | ⚠️ Partial |
| TR-concept-004 | game-concept | Boons accumulate across scenes within a run | ADR-0001 / ADR-0004 | ✅ |
| TR-concept-005 | game-concept | Modular grand-strategy expansion without core rewrite | ADR-0001 / ADR-0002 | ✅ |
| TR-concept-006 | game-concept | Localization: 11 langs via `tr()`/CSV, no hardcoded text | — | ❌ GAP |

---

## Coverage Gaps (no ADR exists)

- ❌ **TR-map-005** — region-map-system → Enemy AI target selection + action budget.
  - Suggested ADR: `/architecture-decision AI Architecture` — Domain: AI — Engine Risk: LOW
  - **Note: this decision is already implemented in `game/features/grid/map_controller.gd` (`_run_enemy_ai`) with no recorded rationale.**
- ❌ **TR-spirit-005** — spirit-system → Erlik spread AI (2nd AI behavior).
  - Covered by the same AI Architecture ADR above — Domain: AI — Engine Risk: LOW
- ❌ **TR-spirit-006** — spirit-system → Shared additive modifier pipeline (boons + council).
  - Suggested ADR: `/architecture-decision Additive Modifier / Stat Pipeline` — Domain: Systems — Engine Risk: LOW
  - The spirit GDD explicitly flags "çift sayım önlenmeli" (avoid double-counting).
- ❌ **TR-combat-003** — combat-system → Battle-report UI presentation of `CombatResult`.
  - Suggested ADR: `/architecture-decision Presentation / Report UI Boundary` — Domain: UI — Engine Risk: LOW
- ❌ **TR-spirit-007** — spirit-system → Corruption visual state (color by level).
  - Better served by an art/shader spec than an ADR — Domain: Rendering — Engine Risk: LOW
- ❌ **TR-concept-006** — game-concept → Localization (11 languages via `tr()`/CSV).
  - Covered by coding-standards; a dedicated ADR is optional — Domain: i18n — Engine Risk: LOW

---

## Cross-ADR Conflicts

**None.** The four ADRs are complementary and mutually reinforcing (ADR-0002,
ADR-0003, and ADR-0004 all build on ADR-0001's context hierarchy). No
data-ownership, integration-contract, performance-budget, dependency-cycle,
pattern, or state-authority contradictions.

**Cosmetic:** ADR-0002's decision text depends heavily on ADR-0003's injection
but lists only ADR-0001 under *Depends On*. Add ADR-0003 to ADR-0002's
dependency field.

---

## ADR Dependency Order (topologically sorted)

```
Foundation (no dependencies):
  1. ADR-0001  Context-Based Hierarchical Architecture
Depends on Foundation:
  2. ADR-0003  Dependency Injection        (requires ADR-0001)
  3. ADR-0004  State Segregation           (requires ADR-0001)
Depends on ADR-0001 + ADR-0003:
  4. ADR-0002  Feature Encapsulation       (requires ADR-0001; leans on ADR-0003 injection)
```

No cycles. **All four ADRs are still `Proposed`** — per `docs/CLAUDE.md`, stories
referencing a `Proposed` ADR are auto-blocked. Promote to `Accepted` (the purpose
of this review) before implementation stories proceed.

---

## GDD Revision Flags

None — no HIGH-RISK engine findings, so no GDD assumption contradicts verified
Godot 4.7 behaviour.

---

## Engine Compatibility

**Clean.** Confirmed by `godot-specialist` consultation.

- All ADRs target Godot 4.7 (version-consistent).
- No active post-cutoff API usage. `duplicate_deep()` (4.5+) correctly flagged in
  ADR-0004 as relevant to the future save/load migration only.
- Callable-based signals and `instantiate()` correctly mandated (ADR-0001).
- No deprecated-API references in any ADR.
- All 4 ADRs contain an Engine Compatibility section.

### Engine Specialist Findings (LOW severity — advisory)

1. **ADR-0001** — make the context-swap sequence explicit:
   `remove_child(old)` → `old.queue_free()` → `add_child(new)`, to close the
   "old context briefly interactable" window (already noted as a risk; this just
   spells out the mitigation in the implementation guidelines).
2. **ADR-0003** — reword the timer note so it is unambiguous that the owning
   *Node* context calls `get_tree().create_timer()` and passes the result to the
   RefCounted service (a RefCounted service cannot call `get_tree()`).
3. **ADR-0004** — RefCounted→Resource migration path is valid and already
   documented; no action.

---

## Architecture Document Coverage

No `docs/architecture/architecture.md` exists — nothing to validate. Authoring a
consolidated architecture document is optional and not blocking.

---

## Verdict: CONCERNS

The foundation is solid, internally consistent, and engine-correct. Several
**Core/Feature system requirements lack a governing ADR** — most notably
**enemy AI (TR-map-005), already implemented in
`game/features/grid/map_controller.gd` with no recorded decision.**

Borderline call: a Core-layer requirement uncovered leans toward FAIL, but since
the code exists, passes tests (30 GDUnit4 tests), and follows the established
injected-orchestrator patterns, the gap is *missing documentation of a decision*,
not an architectural hole — hence **CONCERNS**, not FAIL. No blocking conflicts
exist.

### Required ADRs (prioritised, most foundational first)

1. **AI Architecture ADR** — covers both the shipped political-enemy AI
   (TR-map-005) and the designed Erlik-spread AI (TR-spirit-005). Documents live
   code and unblocks the signature spirit system.
2. **Additive Modifier / Stat Pipeline ADR** — the shared boons + council
   contract the spirit GDD explicitly requires (TR-spirit-006). Needed before
   spirit/council implementation.
3. **Save/Load Persistence ADR** — promote ADR-0004's deferred RefCounted→Resource
   migration into its own decision (TR-concept-002).

### Pre-Gate Checklist

- ✅ `game/tests/unit/` and `game/tests/integration/` exist (project uses
  `game/tests/`, not root `tests/`).
- ❌ `.github/workflows/tests.yml` — run `/test-setup`.
- ❌ `design/ux/accessibility-requirements.md` — run `/ux-design`.
- ❌ `design/ux/interaction-patterns.md` — run `/ux-design`.

`/gate-check pre-production` is not yet appropriate until CI and UX/accessibility
docs exist.
