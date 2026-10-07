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
- RESOLVED 2026-10-07: ai_turn_execution stance + ai_service_mutates_or_signals approved by user (K-02). Remaining priority ADRs (C-15, C-16) and ADR-0005 implementation (C-19) are queued in production/continuation.md.

## Session Extract — 2026-10-07 (l10n, ASENA, pixel art, art bible)
- Game renamed Steppeborn → ASENA (all locales identical, Latin).
- Art direction switched watercolor → pixel art: 640×360 viewport, integer scaling, nearest, pixel snap.
- Fonts: Fusion Pixel 12px (latin/ja/ko/zh_hans woff2) + GNU Unifont 16px (Arabic); LocaleFontController (features/localization) swaps theme for `ar`.
- UI re-laid out for 640×360; pixel theme + generated icons (tools/asset-pipeline/*.gd); RTL fixes for map labels/info panel.
- Fixed: gdUnit4 bin/ was gitignored → tests never ran; restored + run-tests.sh fails if runner missing. 34/34 pass.
- Art Bible written: design/art/art-bible.md (9/9 sections, lean mode, AD sign-off skipped).
- Pending code follow-ups from art bible: opaque ownership colours (blue/rust/keçe grey), map label LabelSettings outline + ellipsis, HUD bar 70% backgrounds, tamga sprites, ◆ selection marks, accessibility settings (colour-blind mode, reduce motion, show/hide region names), theme palette → Bölüm 4 UI palette, validate_palette.gd, ai-art-prompts.md rewrite.
- Push blocked: Xcode license not accepted; commits ahead of origin — push via GitHub Desktop.
- NEXT: all open work is indexed in production/continuation.md (task queue C-01…C-18, user actions K-01/K-02). User types "devam" → follow its Devam Protokolü.
