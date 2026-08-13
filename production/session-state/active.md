## Session Extract — /architecture-review 2026-08-13
- Verdict: CONCERNS
- Requirements: 24 total — 13 covered, 5 partial, 6 gaps
- New TR-IDs registered: 24 (registry was empty; version 1 -> 2)
- GDD revision flags: None
- Top ADR gaps: AI Architecture (enemy AI + Erlik spread), Additive Modifier / Stat Pipeline, Save/Load Persistence
- Report: docs/architecture/architecture-review-2026-08-13.md

## Follow-up — /architecture-decision AI Architecture 2026-08-13
- ADR-0005 written: docs/architecture/adr-0005-ai-architecture.md (Status: Proposed)
- Decision: dedicated injected pure decision services (EnemyAIController + ErlikSpreadController) under game/features/ai/; decide(map_state)->Array[intent], no mutation/no signals; MapController applies + emits. Intent = inner class MoveIntent.
- Covers gaps TR-map-005 (shipped enemy AI) + TR-spirit-005 (Erlik spread).
- GDD synced: region-map-system.md §3.5 now points at EnemyAIController.decide().
- Engine specialist: GREEN LIGHT (no post-cutoff APIs, RefCounted lifecycle correct).
- PENDING: registry update proposal (ai_turn_execution stance) awaiting user approval; remaining priority ADRs: Additive Modifier / Stat Pipeline, Save/Load Persistence.
