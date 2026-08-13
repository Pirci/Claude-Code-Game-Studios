# Architecture Traceability Index

- **Last Updated:** 2026-08-13
- **Engine:** Godot 4.7

## Coverage Summary

- **Total requirements:** 24
- **Covered:** 13 (54%)
- **Partial:** 5 (21%)
- **Gaps:** 6 (25%)

## Full Matrix

| TR-ID | GDD | System | Requirement | ADR Coverage | Status |
|---|---|---|---|---|---|
| TR-map-001 | region-map-system | Bölge Fethi / Harita | Per-region persistent state across turns | ADR-0004 | ✅ |
| TR-map-002 | region-map-system | Bölge Fethi / Harita | Data-driven map from `ChapterMapDefinition` Resource | ADR-0002 | ⚠️ |
| TR-map-003 | region-map-system | Bölge Fethi / Harita | Turn-flow orchestration over injected systems | ADR-0003 | ✅ |
| TR-map-004 | region-map-system | Bölge Fethi / Harita | Clickable polygons + visual layer separated from state | ADR-0004 | ⚠️ |
| TR-map-005 | region-map-system | Bölge Fethi / Harita | Enemy AI target selection + action budget | — | ❌ |
| TR-map-006 | region-map-system | Bölge Fethi / Harita | Data-driven win/lose condition | ADR-0004 | ⚠️ |
| TR-army-001 | army-system | Ordu & Birim | Move validation + garrison + action consumption | ADR-0003 / ADR-0004 | ✅ |
| TR-army-002 | army-system | Ordu & Birim | Arrival resolution → combat or peaceful merge | ADR-0002 / ADR-0003 | ✅ |
| TR-combat-001 | combat-system | Savaş Çözümü | Deterministic auto-resolve as testable leaf | ADR-0002 | ✅ |
| TR-combat-002 | combat-system | Savaş Çözümü | Data-driven tuning via injected `CombatConfig` | ADR-0003 | ✅ |
| TR-combat-003 | combat-system | Savaş Çözümü | `CombatResult` → detailed battle report UI | — | ❌ |
| TR-spirit-001 | spirit-system | Kök Böri / Ruh | `RegionData.corruption_level` extension | ADR-0004 | ✅ |
| TR-spirit-002 | spirit-system | Kök Böri / Ruh | Ruh resource + persistent `boons` on `GameState` | ADR-0004 | ✅ |
| TR-spirit-003 | spirit-system | Kök Böri / Ruh | Purification reuses `CombatResolver` | ADR-0002 / ADR-0003 | ✅ |
| TR-spirit-004 | spirit-system | Kök Böri / Ruh | Deterministic seeded boon offer | ADR-0003 / ADR-0004 | ✅ |
| TR-spirit-005 | spirit-system | Kök Böri / Ruh | Erlik spread AI (deterministic, periodic) | — | ❌ |
| TR-spirit-006 | spirit-system | Kök Böri / Ruh | Shared additive modifier pipeline (boons + council) | — | ❌ |
| TR-spirit-007 | spirit-system | Kök Böri / Ruh | Corruption visual state (color by level) | — | ❌ |
| TR-concept-001 | game-concept | Sahne Akışı | Menu → campaign → scene flow with progress | ADR-0001 | ✅ |
| TR-concept-002 | game-concept | Kampanya İlerlemesi | Progress persists between sessions (save/load) | ADR-0004 | ⚠️ |
| TR-concept-003 | game-concept | Kaynak Yönetimi | 3 data-driven resources, extensible | ADR-0002 | ⚠️ |
| TR-concept-004 | game-concept | Kök Böri / Ruh | Boons accumulate across scenes within a run | ADR-0001 / ADR-0004 | ✅ |
| TR-concept-005 | game-concept | Modüler Genişleme | Grand-strategy expansion without core rewrite | ADR-0001 / ADR-0002 | ✅ |
| TR-concept-006 | game-concept | Yerelleştirme | 11-language localization via `tr()`/CSV | — | ❌ |

## Known Gaps

| TR-ID | Requirement | Suggested ADR | Priority |
|---|---|---|---|
| TR-map-005 | Enemy AI (implemented, undocumented) | AI Architecture | 1 (high — governs live code) |
| TR-spirit-005 | Erlik spread AI | AI Architecture (same) | 1 |
| TR-spirit-006 | Additive modifier pipeline (boons + council) | Additive Modifier / Stat Pipeline | 2 |
| TR-concept-002 | Save/load persistence | Save/Load Persistence | 3 |
| TR-combat-003 | Battle-report UI | Presentation / Report UI Boundary | 4 |
| TR-spirit-007 | Corruption visuals | (art/shader spec, not ADR) | 5 |
| TR-concept-006 | Localization | (coding-standards; ADR optional) | 5 |

## Superseded Requirements

None.
