# Architecture Traceability Index

- **Last Updated:** 2026-10-19 (`/architecture-review`, C-17 — [report](architecture-review-2026-10-19.md))
- **Engine:** Godot 4.7
- **TR registry:** [tr-registry.yaml](tr-registry.yaml) (version 3, 36 requirements)

## Coverage Summary

- **Total requirements:** 36
- **Covered:** 23 (64 %)
- **Partial:** 9 (25 %)
- **Gaps:** 4 (11 %)

History: 2026-08-13 — 24 TRs, 13 covered (54 %), 5 partial, 6 gaps.

## Full Matrix

| TR-ID | GDD | Requirement (short) | ADR(s) | Status | Note |
| --- | --- | --- | --- | --- | --- |
| TR-map-001 | region-map | Per-region / per-map state; static vs mutable fields | 0004, 0007 | ✅ | Data-only state; 0007 saves mutable fields only |
| TR-map-002 | region-map | ChapterMapDefinition per chapter, `load()` by `chapter_id` | 0001, 0002, 0007 | ⚠️ | Loading rule in 0001 guideline; chapter path convention / scene-flow ADR open (C-35) |
| TR-map-003 | region-map | `end_turn` pipeline, early exit, `turn_ended` after check | 0003, 0005, 0007 | ✅ | Order is a GDD rule in MapController; code C-51 |
| TR-map-004 | region-map | Clickable polygons; visual layer separate | 0002, 0004 | ⚠️ | View-refresh contract missing → Presentation ADR |
| TR-map-005 | region-map | Enemy AI target selection, sequential, budget | 0005 | ✅ | decide → apply loop |
| TR-map-006 | region-map | WinCondition (+ `erlik_foci`), `game_result` latch | 0004, 0007 | ⚠️ | `initial_owner` access + WinCondition-as-Resource-with-logic not decided |
| TR-army-001 | army | Owner-agnostic move validation, garrison, action, empty → NEUTRAL | 0003, 0004, 0005 | ✅ | Pattern coverage; intents via `can_move(…, mover)` |
| TR-army-002 | army | Arrival routing combat → purification → peaceful | 0002, 0005 + registry `spirit_state` | ✅ | Spirit state written only by `SpiritController` (D3) |
| TR-army-003 | army | Move-outcome preview from the same pure rules | — | ❌ | ADR "Move Resolution: pure Outcome + Apply" |
| TR-combat-001 | combat | Deterministic zero-dependency leaf | 0002 | ✅ | As built |
| TR-combat-002 | combat | Injected CombatConfig | 0003 | ✅ | As built |
| TR-combat-003 | combat | Battle report UI | — | ❌ | ADR "Presentation Layer & Reports" |
| TR-combat-004 | combat | Effective strength (M2) | 0006 | ⚠️ | Caller resolves (W7); exact `resolve(A, D, a_eff, d_eff)` signature open |
| TR-resource-001 | resource | Gold state, `starting_gold`, not carried | 0002, 0004, 0007 | ✅ | |
| TR-resource-002 | resource | Economy step F1/F2/F6/F7 | 0003, 0006 | ✅ | `M_c` outside the pipeline |
| TR-resource-003 | resource | Recruit action rules | 0003, 0004 | ✅ | Pattern coverage; lock from `game_result` |
| TR-resource-004 | resource | Per-region recruit counter / cap | 0004, 0007 | ✅ | Always 0 at save |
| TR-resource-005 | resource | Economy knobs data-driven | 0002, 0003 | ✅ | Config file name → C-18 |
| TR-resource-006 | resource | HUD income forecast = F2 (same pure function) | 0006 | ⚠️ | Shared pure income function → Move Resolution ADR |
| TR-spirit-001 | spirit | `corruption_level` field | 0004, 0007 | ✅ | |
| TR-spirit-002 | spirit | `ruh` + ordered `boons` (single source of truth) | 0004, 0006, 0007 | ✅ | Code still has `bozkurt_bonuses` (C-55) |
| TR-spirit-003 | spirit | Purification reuses CombatResolver; knob-independent | 0002, 0003 | ✅ | |
| TR-spirit-004 | spirit | Deterministic boon offer | 0003, 0004, 0005 | ✅ | Pattern coverage, no RNG |
| TR-spirit-005 | spirit | Counter-based Erlik spread | 0005 | ✅ | `SpreadDecision` |
| TR-spirit-006 | spirit | Shared additive modifier pipeline, derived records | 0006 | ✅ | `rebuild()` |
| TR-spirit-007 | spirit | Corruption visual layer | — | ❌ | Art bible C-50 + shader spec (no ADR) |
| TR-spirit-008 | spirit | Boon offer derived state, auto-modal ≤ 1, HUD chaining | 0006, 0007 | ⚠️ | Source of the `requires` "system active" flag undefined |
| TR-spirit-009 | spirit | Ruh gain + commit before `game_won`; sole writer | 0006 + registry `spirit_state` | ✅ | D3 |
| TR-spirit-010 | spirit | Spread telegraph | 0005 | ⚠️ | `target_id` every call ✅; HUD display → Presentation ADR |
| TR-concept-001 | concept | Menu → campaign → scene flow, Continue | 0001 | ✅ | `continue_requested` (D4) |
| TR-concept-002 | concept | Save/load between sessions | 0007 | ✅ | |
| TR-concept-003 | concept | Data-driven, extensible resources | 0002 | ⚠️ | No resource-list abstraction; gold is a hard field |
| TR-concept-004 | concept | Boons accumulate across scenes | 0001, 0006, 0007 | ✅ | |
| TR-concept-005 | concept | Modular expansion | 0001, 0002 | ✅ | |
| TR-concept-006 | concept | Localization, 11 languages | — | ❌ | ADR "Localization & Pixel-Font Pipeline" |
| TR-concept-007 | concept | Scene-end sequence on victory | 0001, 0007 | ⚠️ | `scene-flow.md` (C-35) + its ADR |

## Known Gaps

| TR | Suggested ADR | Priority |
| --- | --- | --- |
| TR-army-003 (+ TR-resource-006) | Move Resolution: pure Outcome + Apply | 1 — before C-38 / C-41 / C-45 |
| TR-combat-003 (+ TR-map-004, TR-spirit-010 display) | Presentation Layer & Reports | 2 — before C-41 / C-45 |
| TR-concept-007, TR-map-002 | Scene flow & chapter loading | 3 — after C-35 |
| TR-concept-006 | Localization & Pixel-Font Pipeline | 4 |
| TR-spirit-007 | (no ADR) art bible C-50 + shader spec | with C-50 / C-38 |

## Superseded Requirements

None deprecated. Revised 2026-10-19 (same intent, new text): TR-map-001/002/003/005/006,
TR-army-002, TR-combat-003, TR-spirit-002/003/004/006/007/008, TR-concept-003.
