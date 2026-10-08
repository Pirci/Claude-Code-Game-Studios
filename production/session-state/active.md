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
- C-05 (eaccf54): selected region gets 5×5 gold ◆ (1px #1C170F edge) on every vertex; centred with OUTLINE_PIXEL_OFFSET (-1,-1). Queued C-23 (selection click SFX — no audio system yet). NEXT: C-06 (tamga icons).
- C-06 (6e3b99e): tamgas generated (tools/asset-pipeline/generate_tamga_icons.gd → assets/art/ui/icons/icon_tamga_<id>.png, 9×9). MapState.player/enemy_tamga_id (Prolog oguz / erlik_beast — user chose horn mark for the beast). RegionNode.show_tamga_always = hook for C-07. Queued C-24 (.uid git policy decision). NEXT: C-07.
- C-07 (5a7aa9f): AccessibilitySettings (state) injected RootContext → Menu/Settings + GameContext. CB mode = tamgas always + inner light-tone contour on owned regions; names hidden → army+tamga centred; reduce_motion flag only (no animations yet). Session-only (C-16). NEXT: C-08.
- C-08 (aadbab3): End Turn/Main Menu min width 64; GameContext._update_focus_chain links Send Army ↕ End Turn (RegionInfoPanel.get_focus_target). Queued C-25 (initial focus for keyboard/gamepad — design decision). NEXT: C-09.
- C-09 (95d8f33): NumberFormatter.format_int + THOUSANDS_SEPARATOR key (fr/ru U+00A0). Used in HUD/region/info panel. Queued C-26 (to_lower in info panel → "runde" in German). NEXT: C-10.
- C-10 (1eb1b88): art-source/global_palette_ulus.gpl (94 colours, single source; .ase dropped) + tools/asset-pipeline/validate_palette.gd, run by tools/ci/run-tests.sh after tests. All 32 PNGs clean. Queued C-27 (no GitHub Actions workflow exists). NEXT: C-11.
- C-11 (7f0f5d5): game-concept.md watercolour passages → pixel art / art bible refs; only a historical note remains. NEXT: C-12 (ai-art-prompts.md rewrite).
- C-12 (0f64d19): ai-art-prompts.md rewritten for pixel art; AI output = concept reference only (bible §9 updated). NEXT: C-13 (/review-all-gdds).

## Session Extract — /review-all-gdds 2026-10-08
- Verdict: FAIL
- GDDs reviewed: 4 (region-map, army, combat, spirit) + concept + index
- Flagged for revision: region-map-system.md, spirit-system.md, army-system.md, combat-system.md (+ resource-system.md to write)
- Blocking issues: 7 — B1 no army production/gold sink; B2 Erlik overlay vs ENEMY owner; B3 purification not in arrival resolution; B4 spread owner + end_turn position; B5 corruption on conquest; B6 boon timing; B7 mid-turn win vs end-turn check
- Recommended next: resolve design decisions C-28…C-32 (start with C-28 production / C-29 Erlik model), then C-33 fixes, C-34 re-run
- Report: design/gdd/gdd-cross-review-2026-10-08.md
