> Eski özetler: `production/session-state/archive.md` (rutin okunmaz). Burada en fazla son 4 özet tutulur.

## Session Extract — C-92 (2026-10-26)
- TutorialRules: HINT_ENEMY_KING, HINT_CAPITAL, hint_enemy_king(map_state), hint_for_selection(region, capital_ids). GameContext: _check_start_hint düşman kağanı; _on_hint_dismissed → _check_start_hint zinciri.
- tests/integration/campaign/perde1_hints_test.gd (5), tutorial_test (+2). Testler 505. Bulgu C-102: hamle önizleme UI yok. NEXT: C-93.

## Session Extract — C-93 (2026-10-26)
- ChapterSelectContext: bind_services(..., newly_unlocked, reduce_motion, audio); _scene_node/_locked_button/_on_action_focused/_announce_unlock/is_unlock_glowing; SelectPanel, StatusLine, StateIcon, NameLabel, Teaser, NewMark, LockedButton. RootContext: OUTRO_NARRATIVE'dan gelişte unlocked = next_chapter.
- NumberFormatter.isolate (FSI). İkonlar icon_chapter_{completed,available,available_glow,locked,new}.png.
- tests/unit/campaign/chapter_select_nodes_test.gd (5). Testler 510. NEXT: C-94.

## Session Extract — Rename + genre (2026-11-14)
- Game renamed ULUS → **TURAN: Kızılelma** (user request). GAME_TITLE = "TURAN", GAME_SUBTITLE = "Kızılelma" in all 11 locales (proper noun, untranslated). project.godot config/name="TURAN" (no colon — user:// folder name; old saves under app_userdata/ULUS are not migrated). export_presets: TURAN.exe / TURAN.zip, com.turan.prologdemo. Palette file → art-source/global_palette_turan.gpl.
- Left unchanged on purpose (dated records / already-built C-42 artefacts): smoke-2026-10-19.md, playtest-c42-protocol.md, architecture-review-2026-10-19.md, old rows in continuation.md.
- Genre (user decision): strategy + card city-builder + tower defence + turn-based. game-concept.md Hızlı Anlatım / Temel Kimlik updated + "Tür Revizyonu" note; mechanics sections, GDDs and code still describe the old grand-strategy design. Redesign queued as C-103 (needs user decisions). NEXT: ask user whether M2 (C-94…) continues before C-103.

## Session Extract — Token optimizasyonu (2026-11-14)
- Kurallar: CLAUDE.md + coordination-rules (orkestrasyon/brif/kademe/okuma disiplini) + context-management yeniden yazıldı; technical-preferences ADR tablosu kısaltıldı.
- Ajanlar 49 → 36 (Unity/Unreal/C#/GDExtension/ağ silindi), protokol bloğu kısa; 31 skill yalnız `/ad` ile çağrılır.
- continuation.md yalnız açık işler; kapananlar continuation-archive.md; active.md ≤ 4 özet (eskiler archive.md). `QUIET=1 tools/ci/run-tests.sh`.
- Yeni görev C-104 (ajanların yeni türe uyarlanması, C-103'e bağlı). NEXT: kullanıcı kararı — C-103 mü, C-94 mü.
