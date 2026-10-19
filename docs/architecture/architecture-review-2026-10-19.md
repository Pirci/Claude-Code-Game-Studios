# Architecture Review Report

- **Date:** 2026-10-19
- **Skill:** `/architecture-review full` (task C-17)
- **Engine:** Godot 4.7 (experiments on 4.7.1 Linux)
- **GDDs Reviewed:** 5 system GDDs + concept + index (`region-map`, `army`, `combat`, `resource`, `spirit`)
- **ADRs Reviewed:** 7 (ADR-0001 … ADR-0007)
- **Method:** two independent reviewers in parallel — `technical-director` (Phases 2–4, 6:
  traceability, cross-ADR conflicts, dependency order) and `godot-specialist` (Phase 5:
  engine audit with headless 4.7.1 experiments). Findings were merged, the fix list was
  applied in the same task, then statuses were set.
- **Previous review:** [architecture-review-2026-08-13.md](architecture-review-2026-08-13.md) (CONCERNS, 24 TRs)

---

## Traceability Summary

| | Before fixes | After fixes (this task) |
| --- | --- | --- |
| Total requirements | 36 (25 registered + 11 new) | 36 |
| ✅ Covered | 21 (58 %) | **23 (64 %)** |
| ⚠️ Partial | 11 | **9** |
| ❌ Gaps | 4 | **4** |

Changes since 2026-08-13: TR-map-005, TR-spirit-005 (ADR-0005) and TR-spirit-006 (ADR-0006)
gap → covered; TR-concept-002 partial → covered (ADR-0007). TR-army-002 and TR-spirit-009
became covered after this task named the sole writer of spirit state (registry
`spirit_state`, decision D3). Full matrix: [architecture-traceability.md](architecture-traceability.md).

### Coverage Gaps (no ADR)

| TR | Requirement | Suggested ADR | Domain | Engine risk |
| --- | --- | --- | --- | --- |
| TR-army-003 | Move-outcome preview from the same pure rule code that applies the move | **"Move Resolution: pure Outcome + Apply"** — priority 1 (before C-38, C-41, C-45); also hardens TR-resource-006 (shared pure income function) | Core / Gameplay | LOW |
| TR-combat-003 | Battle report UI | **"Presentation Layer & Reports"** (HUD, info panel, battle report, move preview, spread telegraph, boon modal view contract) | UI | LOW |
| TR-concept-006 | Localization, 11 languages, pixel-font swap | **"Localization & Pixel-Font Pipeline"** (as-built `LocaleFontController`) — or formally declare coding-standards the governing doc | UI / i18n | LOW–MEDIUM |
| TR-spirit-007 | Corruption visual layer | No ADR — art bible rule (C-50) + shader spec by godot-shader-specialist | Rendering | LOW |

Partial items and their missing piece are listed in the traceability index (scene flow /
chapter loading after C-35, `requires` gate source, effective-strength call signature,
WinCondition access to `initial_owner`, view-refresh contract, resource-list abstraction).

---

## Cross-ADR Conflicts

All conflicts were **text leftovers contradicting decisions already made**, plus one
ADR-vs-standard contradiction. All were fixed in this task.

| # | Type | Conflict | Resolution (applied) |
| --- | --- | --- | --- |
| B1 | Integration | Registry `ai_turn_execution` + forbidden pattern still had `ErlikSpreadController.decide(map_state) -> Array[StringName]` | Registry signature updated to `decide(map_state, acted) -> MoveIntent` / `decide(map_state, effective_interval) -> SpreadDecision` |
| B2 | State | ADR-0006 Ordering Note said ADR-0007 serializes `GameState.modifiers` (contradicting its own amendment) | Rewritten: modifiers derived, `rebuild()` on load; stale lines (l.24/34/58/226) fixed |
| B3 | Pattern | ADR-0004 body still instructed `Resource` migration + `ResourceSaver`/`ResourceLoader` on `user://` (forbidden `untrusted_resource_loading`) | Decision, guidelines, alternatives, consequences, risks, migration plan, validation, related — all marked superseded/rewritten; derived-state principle added |
| B4 | Pattern | ADR-0001 codified `const preload` of context scenes by the persistent root (project forbidden pattern) | **D1 = A:** `load()` on transition; chapter content loaded by `chapter_id`; code fix C-57 |
| W1 | Ownership | `max_stacks` had four homes (ModifierSource, BoonDefinition, knob, caller clamp) | **D2 = A:** `ModifierSource.max_stacks` sole owner, `ModifierController.can_add()`; caller clamp removed |
| W2 | Integration | Who rebuilds modifiers on load undefined; risk of double stacks | `ModifierController.rebuild(sources)` clears + re-adds, called by `GameContext` setup |
| W3 | Integration | ADR-0005 leftovers (`Array[intent]`, `SpiritConfig` base interval, `target_id` undefined off-turn, scratch copy) | Decide → apply loop (no copy); base interval = `MapState.erlik_spread_interval`; `target_id` every call; intents applied via owner-agnostic `can_move` |
| W4 | State | Writers of `corruption_level`, `ruh`, `boons` unregistered | **D3 = A:** `SpiritController` (`features/bozkurt/`) sole writer — registry `spirit_state` |
| W5 | Integration | ADR-0007 internal inconsistencies (`GameState \| null` vs `LoadResult`, tamga ids saved, stale risk row, `map: null`) | Fixed; consistency + `map: null` validation items added |
| W6 | Ownership | Continue flow created `GameState` outside its owner | **D4 = A:** RootContext owns `SaveController`; `MenuContext.continue_requested`; registry `context_transition` updated |
| W7 | Pattern | ADR-0006 listed `CombatResolver` as a resolver consumer (breaks ADR-0002 leaf rule) | Caller (`MapController`) resolves A_eff/D_eff; resolver stays a leaf |
| W8 | Dependency | Missing "Depends On" edges | 0002→0003, 0005→{0002, 0006}, 0007→0006 added |
| W9 | State | ADR-0004 described `bozkurt_bonuses` | Replaced by modifiers (derived) / ruh / boons / game_result |
| W10 | Engine | `@abstract` syntax disagreement | Verified 4.7.1: one-line `@abstract class_name …`, abstract func **without body**; engine-reference example corrected |
| W11 | Order | Autosave unsafe before `turn_ended` fix | C-56 depends on C-51 (queue) |

Info items (not blocking): MapController `bind_services` will exceed 8 args (group in
C-18); `features/bozkurt/` chosen as the spirit feature folder.

---

## ADR Dependency Order

Edges (after W8): 0002→{0001, 0003}; 0003→0001; 0004→0001; 0005→{0001, 0002, 0003, 0004, 0006};
0006→{0003, 0004}; 0007→{0001, 0003, 0004, 0006}. **No cycles.** (The latent 0006↔0007 cycle
disappeared with B2.)

Recommended implementation / acceptance order:
1. ADR-0001 Context hierarchy
2. ADR-0003 Dependency injection
3. ADR-0004 State segregation
4. ADR-0002 Feature encapsulation
5. ADR-0006 Modifier pipeline
6. ADR-0005 AI architecture · ADR-0007 Save/load (independent of each other)

Types referenced but defined in no ADR yet: `BoonDefinition` (spirit feature, C-39),
economy config resource (resource §7) — to be named in C-18 `architecture.md`.

---

## GDD Revision Flags

None from engine findings. Two GDD alignments were made as part of the fixes
(`spirit-system.md` §3.5 stack-cap owner, §5 tie rule wording) — no system needs
"Needs Revision".

---

## Engine Compatibility

- All 7 ADRs target Godot 4.7 and have an Engine Compatibility section; no deprecated API use.
- **Engine reference is stale for 4.7** (`breaking-changes.md`, `deprecated-apis.md`,
  `current-best-practices.md`, `modules/*` last verified for 4.6) — documentation gap, no ADR
  depends on a 4.7-only API → follow-up task C-58.
- Verified on 4.7.1 (godot-specialist experiments):
  - typed arrays: invariant at **runtime**; `.filter()` on a typed array returns a typed
    array; `Array[T](x)` does not compile → use `assign()` (ADR-0006 corrected);
  - `@abstract`: one-line class form, body-less abstract funcs, `SaveStore.new()` is a parse error;
  - JSON: numbers parse as float; `1e999` parses to INF; `int(INF)` = INT64_MIN; default
    stringify loses float precision; a UTF-8 BOM breaks parsing; parsed containers are
    untyped with String keys (ADR-0007 hardened: full precision, BOM strip, post-parse
    finite/integral/range checks, typed rebuild);
  - `DirAccess.rename_absolute` overwrites on Linux (Windows/macOS unverified — `.bak`
    rotation does not rely on it); `store_string()` returns bool.
- Unverified (implementation-time): Windows rename, `user://` per OS, `ResourceLoader`
  `CACHE_MODE_IGNORE`, deferred `queue_free` window (mitigated by `remove_child` guideline).
- Note: `user://` folder depends on `application/config/name` ("ULUS") — consider
  `use_custom_user_dir` before release.

### Per-ADR engine verdict
| ADR | Risk | Verdict |
| --- | --- | --- |
| 0001 | LOW | Accept (after `load()` amendment — done) |
| 0002 | LOW | Accept |
| 0003 | LOW | Accept |
| 0004 | LOW | Accept (superseded text cleaned — done) |
| 0005 | LOW | Accept (qualified inner-class names — done) |
| 0006 | LOW | Accept (typed-array text corrected — done) |
| 0007 | MEDIUM | Accept (JSON hardening — done) |

---

## Architecture Document Coverage

`docs/architecture/architecture.md` does not exist yet (C-18). Systems that currently have
only pattern coverage and must get an explicit home there: turn pipeline & signal ordering;
spirit service boundary (`SpiritController`, boon catalog, `requires` gating); presentation
layer; scene flow / campaign & chapter loading; economy config; localization; corruption
rendering; audio; debug tools (god mode / time scale per technical preferences).
`control-manifest.md` should follow acceptance (`/create-control-manifest`).

---

## Verdict: CONCERNS

- **Not FAIL:** no contradictory live decisions, no dependency cycles; every Core requirement
  has at least partial coverage.
- **Not PASS:** 4 coverage gaps (one Core: move preview) and 9 partial items remain.
- All blocking text conflicts (B1–B4) and warnings W1–W11 were fixed in this task, so the
  ADRs were set to **Accepted** (decisions D1–D4 taken with the recommended option under the
  user's night-mode instruction; listed in `production/continuation.md` → "Otonom Kararlar").

### Required ADRs (priority order)
1. Move Resolution: pure Outcome + Apply (TR-army-003; before C-38 / C-41 / C-45)
2. Presentation Layer & Reports (TR-combat-003; before C-41 / C-45)
3. Scene flow & chapter loading (after C-35; TR-concept-007, TR-map-002)
4. Localization & Pixel-Font Pipeline (TR-concept-006)

### Pre-gate checklist (for a later `/gate-check pre-production`)
| Item | State |
| --- | --- |
| `game/tests/unit/` | ✅ (80 tests, 13 suites) |
| `game/tests/integration/` | ✅ directory exists (no integration tests yet) |
| `.github/workflows/tests.yml` | ❌ (C-27) |
| `design/accessibility-requirements.md` | ❌ (`/ux-design`) |
| `design/ux/interaction-patterns.md` | ❌ (`/ux-design`) |
