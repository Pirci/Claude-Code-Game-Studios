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

## Session Extract — 2026-10-08 (rename)
- Game renamed ASENA → **ULUS: Blood of the Sky Wolf**. GAME_TITLE = "ULUS" in all locales; GAME_SUBTITLE translated per locale; project.godot config/name="ULUS" (no colon — it is also the user:// folder name).

## Session Extract — 2026-10-08 (C-01)
- C-01 done (`656223d`): RegionNode draws via _draw() — opaque owner main tone fill, 1px dark-ramp outline, selection #EDC76B / hover #C99A3D outline. Tests 40/40. Screenshot pixel-checked.
- Screenshot method: temp SceneTree script (outside repo) instantiates root_context, calls _on_new_campaign, saves root.get_texture() as PNG (640×360). Run windowed, not headless.
- Godot now at /Applications/Godot.app → run tests with GODOT=/Applications/Godot.app/Contents/MacOS/Godot until C-20 fixes the default.
- NEXT: C-02 (map labels LabelSettings outline + ellipsis).
- C-01-fix (b276316): hover outline = #EDC76B per bible (no separate hover tone). C-20 (5371770): run-tests.sh auto-detects Godot — GODOT env no longer needed.
- C-02 (34ac70d): map labels use theme variation MapLabel (cream #F2E6C7, outline #1C170F, outline_size=2 = 1px each side) + ellipsis. Not LabelSettings (pins font_size, breaks Unifont swap). Bible §7 updated.
- Screenshot helper scripts live in /tmp/ulus_shot (shot.gd, zoom.gd) — temp, outside repo. NEXT: C-03.
- C-03 (db53df6): HUD theme variations HudBarTop/HudBarBottom/HudPanel (#1C150D @70%, 1px #8A6D4F). Bars wrapped in TopBarPanel/BottomBarPanel. Info panel → HudPanel. Bible §3 HUD border fixed to #8A6D4F. NEXT: C-04 (note: default "panel"/button styleboxes still old palette — C-04 scope).
- C-04 (5c8dc51): theme fully on Art Bible UI palette (Deri Kahve ramp styleboxes, font colours, SecondaryLabel), icons regenerated, bible contrast table floored to real WCAG values; ui_palette_contrast_test.gd guards it. Queued C-21 (koçboynuzu/kilim 9-slice frames) and C-22 (map ground + adjacency lines palette). NEXT: C-05.
