# Architecture Traceability Index

- **Last Updated:** 2026-10-19 (C-61: TR-concept-006 → ADR-0009; C-59: TR-army-003, TR-resource-006, TR-combat-004 → ADR-0010; C-60: TR-combat-003, TR-map-004, TR-spirit-010 → ADR-0011; C-51: TR-map-006 code; C-62: TR-concept-007, TR-map-002 → ADR-0012, TR-spirit-007 closed by art bible + C-38; base: `/architecture-review` C-17 — [report](architecture-review-2026-10-19.md))
- **Engine:** Godot 4.7
- **TR registry:** [tr-registry.yaml](tr-registry.yaml) (version 3, 36 requirements)

## Coverage Summary

- **Total requirements:** 36
- **Covered:** 34 (94 %)
- **Partial:** 2 (6 %)
- **Gaps:** 0

History: 2026-08-13 — 24 TRs, 13 covered (54 %), 5 partial, 6 gaps.

## Full Matrix

| TR-ID | GDD | Requirement (short) | ADR(s) | Status | Note |
| --- | --- | --- | --- | --- | --- |
| TR-map-001 | region-map | Per-region / per-map state; static vs mutable fields | 0004, 0007 | ✅ | Data-only state; 0007 saves mutable fields only |
| TR-map-002 | region-map | ChapterMapDefinition per chapter, `load()` by `chapter_id` | 0001, 0002, 0007, 0012 | ✅ | `SceneDefinition.map_path` loaded on scene start / Continue (ADR-0012); code C-57 → C-40 |
| TR-map-003 | region-map | `end_turn` pipeline, early exit, `turn_ended` after check | 0003, 0005, 0007 | ✅ | Order is a GDD rule in MapController; code C-51 |
| TR-map-004 | region-map | Clickable polygons; visual layer separate | 0002, 0004, 0011 | ✅ | Passive views + `GameContext._refresh_views()` contract |
| TR-map-005 | region-map | Enemy AI target selection, sequential, budget | 0005 | ✅ | decide → apply loop |
| TR-map-006 | region-map | WinCondition (+ `erlik_foci`), `game_result` latch | 0004, 0007 | ✅ | C-51: `RegionData.initial_owner` copied from content at map creation (not saved, ADR-0007 rebuilds from `ChapterMapDefinition`); `WinCondition` = content `Resource` with pure checks; Erlik loss + `MapState.loss_reason` C-63 |
| TR-army-001 | army | Owner-agnostic move validation, garrison, action, empty → NEUTRAL | 0003, 0004, 0005 | ✅ | Pattern coverage; intents via `can_move(…, mover)` |
| TR-army-002 | army | Arrival routing combat → purification → peaceful | 0002, 0005 + registry `spirit_state` | ✅ | Spirit state written only by `SpiritController` (D3) |
| TR-army-003 | army | Move-outcome preview from the same pure rules | 0010 | ✅ | `preview_move` = `MoveResolver.resolve`; code with C-38 |
| TR-combat-001 | combat | Deterministic zero-dependency leaf | 0002 | ✅ | As built |
| TR-combat-002 | combat | Injected CombatConfig | 0003 | ✅ | As built |
| TR-combat-003 | combat | Battle report UI | 0010, 0011 | ✅ | `BattleReport.show_outcome(MoveOutcome)`; code C-41/C-45 |
| TR-combat-004 | combat | Effective strength (M2) | 0006, 0010 | ✅ | `resolve_effective(A, D, A_eff, D_eff)`; `MoveResolver` computes `A_eff`/`D_eff` (M2) |
| TR-resource-001 | resource | Gold state, `starting_gold`, not carried | 0002, 0004, 0007 | ✅ | |
| TR-resource-002 | resource | Economy step F1/F2/F6/F7 | 0003, 0006 | ✅ | `M_c` outside the pipeline |
| TR-resource-003 | resource | Recruit action rules | 0003, 0004 | ✅ | Pattern coverage; lock from `game_result` |
| TR-resource-004 | resource | Per-region recruit counter / cap | 0004, 0007 | ✅ | Always 0 at save |
| TR-resource-005 | resource | Economy knobs data-driven | 0002, 0003 | ✅ | Config file name → C-18 |
| TR-resource-006 | resource | HUD income forecast = F2 (same pure function) | 0006, 0010 | ✅ | `IncomeRules.turn_income` shared by economy step and HUD (C-37) |
| TR-spirit-001 | spirit | `corruption_level` field | 0004, 0007 | ✅ | |
| TR-spirit-002 | spirit | `ruh` + ordered `boons` (single source of truth) | 0004, 0006, 0007 | ✅ | Code: `GameState.boons` + derived `modifiers` (C-55); `ruh` with C-38 |
| TR-spirit-003 | spirit | Purification reuses CombatResolver; knob-independent | 0002, 0003 | ✅ | |
| TR-spirit-004 | spirit | Deterministic boon offer | 0003, 0004, 0005 | ✅ | Pattern coverage, no RNG |
| TR-spirit-005 | spirit | Counter-based Erlik spread | 0005 | ✅ | `SpreadDecision` |
| TR-spirit-006 | spirit | Shared additive modifier pipeline, derived records | 0006 | ✅ | `rebuild()`; implemented `features/modifiers/` (C-55) |
| TR-spirit-007 | spirit | Corruption visual layer | — (art bible) | ✅ | Art bible §4 "Bozulma Seviyeleri" (C-50) + `features/grid/corruption_stain.gd` (C-38); no ADR needed |
| TR-spirit-008 | spirit | Boon offer derived state, auto-modal ≤ 1, HUD chaining | 0006, 0007 | ⚠️ | Source of the `requires` "system active" flag undefined |
| TR-spirit-009 | spirit | Ruh gain + commit before `game_won`; sole writer | 0006 + registry `spirit_state` | ✅ | D3 |
| TR-spirit-010 | spirit | Spread telegraph | 0005, 0011 | ✅ | `HudPresenter` uses `ErlikSpreadController.decide` ("if now") |
| TR-concept-001 | concept | Menu → campaign → scene flow, Continue | 0001 | ✅ | `continue_requested` (D4) |
| TR-concept-002 | concept | Save/load between sessions | 0007 | ✅ | |
| TR-concept-003 | concept | Data-driven, extensible resources | 0002 | ⚠️ | No resource-list abstraction; gold is a hard field |
| TR-concept-004 | concept | Boons accumulate across scenes | 0001, 0006, 0007 | ✅ | |
| TR-concept-005 | concept | Modular expansion | 0001, 0002 | ✅ | |
| TR-concept-006 | concept | Localization, 11 languages | 0009 | ✅ | As built + glyph-coverage test (C-61) |
| TR-concept-007 | concept | Scene-end sequence on victory | 0001, 0007, 0012 | ✅ | `scene-flow.md` (C-35) + ADR-0012 pure `SceneFlow`; code C-40 |

## Known Gaps

| TR | Suggested ADR | Priority |
| --- | --- | --- |
| TR-concept-007, TR-map-002 | Scene flow & chapter loading | 3 — after C-35 |
| TR-spirit-007 | spirit | Corruption visual layer | — (art bible) | ✅ | Art bible §4 "Bozulma Seviyeleri" (C-50) + `features/grid/corruption_stain.gd` (C-38); no ADR needed |

## Superseded Requirements

None deprecated. Revised 2026-10-19 (same intent, new text): TR-map-001/002/003/005/006,
TR-army-002, TR-combat-003, TR-spirit-002/003/004/006/007/008, TR-concept-003.
