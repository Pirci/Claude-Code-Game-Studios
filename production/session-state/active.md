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

## Session Extract — /design-system resource-system (C-28) 2026-10-08
- Task: Designing resource-system GDD (C-28, fixes cross-review B1)
- Scope decision: gold income + army production fully defined; herds interface only (later act); Ruh stays in spirit-system
- File: design/gdd/resource-system.md
- Current section: §1–§11 all written (candidate A: cost 2, start 6, cap max(1,G_eff), enemy +1 every enemy region, income_floor 0, upkeep 0; sim in /tmp/ulus_sim — not in repo); next Phase 5 validation (self-check, registry, index, counter-updates); counter-updates to army/region-map/spirit/index pending after GDD
- Review mode: lean

## Session Extract — 2026-10-08 (milestones)
- User: keep current queue order, but Prolog demo + vertical slice must be in the queue so they are not forgotten.
- continuation.md: new "Kilometre Taşları" table — M1 Prolog Demo (C-35…C-42, ~6–8 wk), M2 Vertical Slice (C-43…C-48, ~3–4 mo). Protected: cannot be deferred/removed without user approval; checked at every "devam".
- Active task still C-28 (resource-system GDD, §1–§8 written).
- Status: Complete (Designed, pending /design-review in a fresh session). All 11 sections written.
- Provisional: herds inactive; enemy reinforcement is a temporary contract until enemy-layers.md; Bereket form deferred to C-31.
- Counter-updates done (army, region-map, spirit, index); registry seeded. Implementation = existing milestone task C-37 (M1); duplicate C-35 row removed.
- NEXT: queue order C-14 (/consistency-check); design follow-ups C-29…C-32.
<!-- CONSISTENCY-CHECK: 2026-10-08 | GDDs checked: 5 + art bible | Conflicts found: 2 (1 resolved) | Report: docs/consistency-report-2026-10-08.md -->
- C-14 (5ba890b): consistency check — K1 open (spirit formula copy / level-3 claim → C-33/C-31), K2 fixed (spirit visuals → art bible). Registry +3 constants. Failure log local only (gitignored).
- K1 (18df1d4): user chose level table CORRUPTION_PRODUCTION_MULTIPLIERS [1.0,0.75,0.5,0.0]; registry revised/deprecated; W8+W12 closed. NEXT: C-15.

## Session Extract — C-15 ADR-0006 (2026-10-18)
- ADR-0006 Additive Modifier / Stat Pipeline written (Proposed). Kararlar (kullanıcı onaylı): düz toplam sonra çarpan `(base+Σflat)×(1+Σpct)`; çift sayım = kaynak anahtarlı kayıt + `exclusive_group` (kaynak başına).
- Godot uzmanı: ModifierController RefCounted, typed-array değişmezliği notu, ModifierSource = Resource.
- Registry +3 (state `modifiers`, interface `stat_resolution`, forbidden `unkeyed_or_duplicate_bonus_summation`); traceability TR-spirit-006 ✅.
- NEXT: C-16 (Save/Load ADR). Not: spirit GDD'deki `bozkurt_bonuses` → `modifiers` göçü uygulamada (C-39).

## Session Extract — C-16 ADR-0007 (2026-10-18)
- ADR-0007 Save/Load Persistence (Proposed). Kullanıcı kararları: versiyonlu JSON + saf SaveSerializer (state RefCounted kalır; ADR-0004 göç planı kısmen supersede); tur sonu otomatik kayıt, tek slot.
- Godot uzmanı: .bak rotasyonu (rename-overwrite'a güvenme), kapat→rename sırası, LoadResult (static last_error yok), @abstract SaveStore, enum adı Error değil.
- Registry +3 (save_files, save_load, untrusted_resource_loading); ADR-0004/0006 notları; resource-system #6 çözüldü; TR-concept-002 ✅.
- NEXT: C-17 `/architecture-review` — AYNI OTURUMDA ÇALIŞTIRMA, taze oturum gerekir (bağımlılıklar: C-15 ✅, C-16 ✅, K-02 ✅, C-34 ❌ — C-34 bitmeden C-17 başlayamaz; sıradaki başlanabilir görev C-29).

## Session Extract — C-29 Erlik modeli (2026-10-18)
- Kullanıcı kararları: (B2) Erlik = bozulma katmanı, canavar = bozuk NÖTR bölge, ERLIK sahip türü yok; (B4) sahip spirit-system.md; end_turn: AI → Erlik yayılımı → gelir → tur+1 → kontrol; (D3) Canavarın İni seviye 3, Prolog aralığı 3.
- Güncellenen: spirit §3.6/§3.7/§6/AC8, region-map §3.4/§5/§6/AC1/AC4, resource-system adım numaraları (ekonomi 3., sayaç 4.), TR-map-003, systems-index, cross-review (B2/B4/D3 kapandı).
- Keşif: canavar nötr olunca Prolog'da ENEMY bölgesi kalmıyor → düşman AI/takviye boşta, game_lost tetiklenemez, denge yeniden doğrulanmalı → yeni görev C-49 (C-36'nın bağımlılığı).
- NEXT: C-30 (arındırma eylemi + fetihte bozulma, B3/B5).

## Session Extract — C-30 arındırma eylemi (2026-10-18, gece modu)
- Kullanıcı talimatı: "sabaha kadar devam, önerileni kabul et" → kararlar önerilen seçenekle verildi; continuation.md "Otonom Kararlar" tablosunda listeleniyor (sabah incelemesi).
- Karar: arındırma = ordu varışının 2. dalı (army §3.3: savaş → arındırma → barışçıl). Yabancı garnizon yok + bozuk → `CombatResolver(P, corruption_strength)`, P = gelen kuvvet; başarı: seviye 0 + Ruh + kalanlar yerleşir; başarısızlık (eşitlik dahil): gelen kuvvet tamamen kaybolur. 1 aksiyon. Düşman AI bozulmayı yok sayar.
- B5: fetih bozulmayı korur, Ruh vermez (seçenek A). Eşik tablosu 5/9/13, kayıp 2/4/6; Canavarın İni S=12 → 30 Ruh = ilk lütuf eşiği.
- Güncellenen: army §3.3/§3.4/§4/§5/§6/AC8–12, spirit §3.1/§3.2/§3.7/§4.1/§5/§6/AC11–14, combat §5/§6, region-map §3.3/§6, cross-review B3/B5 ✅, TR-army-002 + TR-spirit-003 revised, registry +2 (corruption_strength, corr_str_per_level).
- Yeni görev C-50 (bozulma seviyesi görseli + bilgi paneli satırı; C-38 bağımlılığı).
- Not: bu container'da Godot yok → kod görevlerinde test için kurulum gerekecek.
- NEXT: C-31 (lütuf zamanlaması, B6 + W9–W11, D5).

## Session Extract — C-31 lütuf zamanlaması (2026-10-18, gece modu)
- Kararlar (önerilen seçenek, "Otonom Kararlar" tablosunda): sunum = oyuncu tur başı (en fazla 1) veya sahne zaferi (zorunlu, sıralı); erteleme aynı 3 lütfu korur (HUD düğmesi, her tur başı yeniden); etki seçildiği an (ADR-0006 add_source); durum türetilir (ruh ≥ boon_cost(n) + uygun havuz) → kayıtta bayrak yok (TR-spirit-008, ADR-0007 notu).
- Katalog: stat_id/tür/gerektirir/yığılma sınırı sütunları; Bereket +1 altın (B_add), Kurt Gücü/Demir Post +1 etkin güç (combat §4 "Etkin güç", M2), Gök Kalkanı +1 tur (sınır 3, `last_erlik_spread_turn` sayacı), Sürü/Yiğit Ruhu kilitli. M1 havuzu: Arınma Ustalığı, Bereket, Gök Kalkanı. boon_index = seçilen lütuf sayısı.
- D5: doğrusal eğri korunur, hedef finalde 6–8 lütuf. W11: ödül seviyeyle artar, konsept metni düzeltildi.
- Güncellenen: spirit §3.4/3.5/3.6/3.7/3.8(yeni)/4/5/7/8, combat §3/§4/§6/AC7–8, resource F2 notu + açık soru #1, region-map §3.1, game-concept, cross-review B6/W9/W10/W11/D5, ADR-0007 örneği, registry +1 (bereket_gold_bonus), TR-spirit-008.
- NEXT: C-32 (tur ortası kazanma, B7 + W7, D4).

## Session Extract — C-32 kazanma/kaybetme (2026-10-18, gece modu)
- Kararlar (önerilen): B7 seçenek A — tur ortası zafer oyunu anında bitirir; `MapState.game_result` (ONGOING/WON/LOST) kilidi, sinyal bir kez, sonra hamle/tur bitirme/üretim reddedilir. Tur sonu kontrolü: kaybetme → kazanma.
- D4: kazanma = siyasi (düşman yok) + genişleme (başlangıçta nötr, odak hariç `conquered_neutral_count` ≥ gerekli) + `erlik_foci` arındırılmış; odak dışı bozulma engellemez. W7: eski `oyuncu_bölge − 1` sayımı kalktı (`initial_owner` bölüm verisinden).
- Güncellenen: region-map §3.3/§3.4/§3.6/§3.7(yeni)/§4/§5/§7/AC7–11, spirit §3.7, cross-review B7/W7/D4, TR-map-006, ADR-0007 notu (game_result kaydedilmez).
- Kod uyuşmuyor → yeni görev C-51 (game_result kilidi + sayım + erlik_foci + testler).
- NEXT: C-33 (GDD düzeltmeleri W1–W6 + bilgi notları).

## Session Extract — C-33 GDD düzeltmeleri (2026-10-18, gece modu)
- W1 army örneği (4v3 → army 2); W2 kaybedenin hayatta kalanları dağılır; W3 savaş sonrası 0 birlikli bölge NEUTRAL olur (sahipli 0 ordu yok); W4 Dal 3 `attacker_won = NOT draw_favors_defender`; W5 army §3.1–3.3 sahip-bağımsız (`mover`), region-map §3.5 "planlı (C-19)"; W6 eşitlik bozma her yerde `region_id` alfabetik + düşman bölgeleri `region_id` sırasıyla.
- Bilgi notları: indeks (tarih, bağımlılık sütunu, Oyun Durumu/erişilebilirlik/yerelleştirme/tamga satırları), konsept (tarih, sonraki adımlar), MapState alan listesi, AC9 renk körlüğü, `scene_id = chapter_id` (Prolog 1 → M1 sunumu Bereket, Gök Kalkanı, Arınma Ustalığı), yayılım aday kümesi formal + `last_erlik_spread_turn` güncelleme kuralı.
- TR-map-005, TR-army-001 revised. Kod düzeltmesi C-52 açıldı (W3 + W6).
- NEXT: C-34 `/review-all-gdds` yeniden (taze bağlamda daha iyi; gece modunda bu oturumda çalıştırılacak).

## Session Extract — /review-all-gdds 2026-10-19 (C-34)
- Verdict: CONCERNS
- GDDs reviewed: 5 system GDDs + concept + index (parallel reviewers: systems-designer = consistency, game-designer = holism + 3 scenarios)
- Flagged for revision: resource, spirit, region-map, army, game-concept, ADR-0005/0006/0007 (all Warning; index NOT set to Needs Revision → Designed)
- Blocking issues: None (B1–B7 hold; B6/W12/D3 partly)
- Recommended next: C-17 is next in queue but now depends on C-53 (fix W-A…W-I, S1-a, N7/N11c + ADR amendments) → do C-53 first
- Report: design/gdd/gdd-cross-review-2026-10-19.md
- Also: Godot 4.7.1 Linux downloaded to scratchpad/godot (session-only); `GODOT=<that> tools/ci/run-tests.sh` → 80/80 pass, palette 0 violations.

## Session Extract — C-53 çapraz inceleme düzeltmeleri (2026-10-19, gece modu)
- Rapor uyarıları kapatıldı (çözüm günlüğü raporun sonunda). Önemli kararlar: aynı tur ikinci lütuf seçimi HUD'dan serbest (otomatik modal tur başı ≤1); "seçimi sakla, etkiyi türet" — `GameState.boons` tek kaynak, modifikatörler yüklemede yeniden kurulur (ADR-0006/0007 amendment), `ModifierSource.max_stacks`; `turn_ended` kontrol sonrası + yalnızca ONGOING, 1. adım sonrası erken kayıp; ADR-0005 `SpreadDecision`; arındırma `draw_favors_defender`'dan bağımsız; hamle önizlemesi + yayılım göstergesi gereksinimi (başarısız arındırma ikinci onay).
- Kalanlar sahipli: C-49 (N1–N4, N9, W-B), C-36 (S1-e, beast tamga), C-44, C-54, C-35.
- NEXT: C-17 `/architecture-review` (ADR'leri Accepted yap). Not: kendi yazdığım ADR değişiklikleri taze gözle incelenmeli — C-17 bağımsız ajanlarla yapılacak.

## Session Extract — /architecture-review 2026-10-19 (C-17)
- Verdict: CONCERNS
- Requirements: 36 total — 23 covered, 9 partial, 4 gaps
- New TR-IDs registered: 11 (TR-army-003, TR-combat-004, TR-resource-001…006, TR-spirit-009/010, TR-concept-007); 15 revised; registry v3
- GDD revision flags: None (spirit §3.5/§5 aligned)
- Top ADR gaps: Move Resolution (pure Outcome + Apply), Presentation Layer & Reports, Scene flow & chapter loading (+ Localization)
- Report: docs/architecture/architecture-review-2026-10-19.md
- Decisions (recommended, night mode): D1 load() on transition; D2 ModifierSource.max_stacks sole owner; D3 SpiritController sole writer of spirit state (features/bozkurt/); D4 RootContext owns SaveController + continue_requested; AI decide→apply loop.
- All 7 ADRs → Accepted. New tasks C-57…C-62. NEXT: C-18 /create-architecture.

## Session Extract — C-18 /create-architecture (2026-10-19, gece modu)
- Written: docs/architecture/architecture.md v1.0 (layers, module ownership, data flows incl. end_turn + save/load + init order + victory, API boundaries, ADR audit all ✅, principles, QQ-01…08).
- TD self-review (TD-ARCHITECTURE): CONCERNS = approved with conditions (4 TR gaps → ADRs C-59…C-62). LP-FEASIBILITY skipped (lean).
- Required ADRs next: C-59 Move Resolution (before C-38/C-41), C-60 Presentation, C-62 Scene flow (after C-35), C-61 Localization.
- NEXT: C-19 (ADR-0005 implementation, code — Godot 4.7.1 in scratchpad for tests).

## Session Extract — C-19 ADR-0005 uygulaması (2026-10-19)
- game/features/ai/enemy_ai_controller.gd (MoveIntent, decide(map, acted)), erlik_spread_controller.gd (SpreadDecision, decide(map, interval), counter-based, alphabetical tie-break, target every call).
- MapController: decide → apply loop; conquered targets added to `acted` (preserves old snapshot behaviour); enemy moves via ArmyController.can_move/apply_* with mover=ENEMY.
- State fields: RegionData.corruption_level, MapState.erlik_spread_interval (4), last_erlik_spread_turn (0). Spread NOT wired into end_turn yet (C-38 with SpiritController).
- Tests: 104/104 (new: tests/unit/ai/* 18, army mover 4, map parity 2). Godot 4.7.1 Linux (scratchpad).
- NEXT: C-21 (koçboynuzu/kilim 9-slice frames — UI, needs screenshots).

## Session Extract — C-21 UI çerçeveleri (2026-10-19)
- tools/asset-pipeline/generate_ui_frames.gd → frame_primary_{normal,hover,pressed,disabled}.png (16×16), frame_modal.png (18×18); 9-slice margin 5; theme PrimaryButton / ModalPanel (StyleBoxTexture, modal TILE).
- Applied: EndTurnButton, NewCampaignButton, RegionInfoPanel send button (PrimaryButton); settings screen wrapped in Frame (ModalPanel).
- Tests 112/112 (ui_frames_theme_test 8). Screenshots via Xvfb: `xvfb-run -a -s "-screen 0 1920x1080x24" $G --path game --rendering-driver opengl3 --script scratchpad/shots/shot.gd -- <out> <locale>` (menu, settings, game_selected) — en/de checked visually.
- NEXT: C-22 (map ground + adjacency line palette).

## Session Extract — C-22 harita zemini + çizgi paleti (2026-10-19)
- ChapterMapDefinition.ground_color (#1A2614) + adjacency_line_color (#436129, opaque); AdjacencyLineDrawer.line_color; CampaignMap.set_line_color; GameContext Background (%Background) from chapter. Rule in bible §4: line = ground ramp +2 tones.
- Pixel check on Xvfb render: map area 0 off-palette colours. Tests 116/116 (map_palette_test 4).
- NEXT: C-23 (selection click SFX — needs audio ADR/design first; likely decision task).

## Session Extract — C-23 seçim sesi + ADR-0008 (2026-10-19)
- ADR-0008 Audio (Accepted): RootContext-owned persistent AudioController (Node; pool of 4 AudioStreamPlayer on SFX bus), default_bus_layout.tres (Music/SFX → Master), SfxLibrary resource (Dictionary[StringName, AudioStream]) at features/audio/data/sfx_library.tres.
- Placeholder SFX synthesized: game/assets/audio/sfx/sfx_ui_region_select.wav (45 ms, 620 Hz thock + noise tick, seeded).
- GameContext.bind_services(game_state, accessibility, audio = null) plays region_select on MapController.region_selected. Settings sliders now affect real buses.
- Tests 123/123 (audio_controller_test 7). Real-device audibility = manual check for the user.
- NEXT: C-24 (.uid git policy — decision task).

## Session Extract — C-24 .uid politikası (2026-10-19)
- Decision (recommended): commit .uid files (Godot 4.4+). Removed `*.uid` from game/.gitignore; 272 .uid added (no orphans). Scenes reference scripts by path, so no existing reference breaks.
- User note: on the Mac, if `git pull` complains about untracked .uid files, delete local *.uid (they were ignored before) and pull again; Godot adopts the committed UIDs.
- NEXT: C-25 (initial keyboard focus decision + implementation).

## Session Extract — C-25 başlangıç klavye odağı (2026-10-19)
- `FocusReveal` (game/ui/focus_reveal.gd, RefCounted static): `focus_quietly(control)` → `grab_focus(true)` (hidden focus); `reveal_on_navigation(viewport, event)` → hidden focus + ui_up/down/left/right/focus_next/prev/accept press → `owner.grab_focus()` (visible), event consumed (no move, no press).
- RootContext `_input` calls reveal; MenuContext (NewCampaign; Settings button after back), SettingsScreen (LanguageOption), GameContext (EndTurn) give quiet initial focus.
- Godot 4.7.1: `grab_focus(hide_focus)`, `has_focus(ignore_hidden_focus)`; project setting `show_focus_state_on_pointer_event` left default.
- Tests 131/131 (focus_reveal_test 8). Xvfb: no frame on open; first ↓ shows frame on New Campaign; second ↓ → Settings.
- NEXT: C-26 (PER_TURN key, 11 languages, no to_lower/to_upper on player-visible text).

## Session Extract — C-26 PER_TURN çeviri key'i (2026-10-19)
- translations.csv: `PER_TURN` = "%s / turn" (tr tur, de Runde, fr tour, es/pt turno, zh 回合, ja ターン, ko 턴, ru ход, ar دور). RegionInfoPanel: `tr("PER_TURN") % format_int(gold)`; GoldLabel named for tests.
- grep: no to_lower/to_upper/capitalize in game code. Tests 134/134 (per_turn_label_test 3). de: "Gold: 2 / Runde"; ar renders "ذهب: 2 / دور".
- NEXT: C-27 (GitHub Actions CI, headless Godot 4.7 + run-tests.sh).

## Session Extract — C-27 GitHub Actions CI (2026-10-19)
- `.github/workflows/tests.yml`: push(main)/PR/workflow_dispatch; ubuntu-24.04; Godot 4.7.1 zip from GitHub release, SHA512 pinned (4ccdab7a…2de9), cached in ~/godot; runs `tools/ci/run-tests.sh`; uploads game/reports on failure.
- Local proof: fresh clone (no .godot) → 134/134 + palette, exit 0; intentional failing test → run-tests.sh exit 100.
- coding-standards.md CI line updated to run-tests.sh / tests.yml.
- NEXT: C-49 (Prolog Erlik impact + loss condition decision).

## Session Extract — C-50 bozulma seviyesi görseli (2026-10-19)
- C-49 running in background (game-designer agent, opus): GDD edits + design/balance/prolog-balance-2026-10-19.md; integrate + commit when it reports. Also then update spirit §3.1 line "art bible'da henüz tanımsız → C-50" and AC10 pointer to art bible §4 "Bozulma Seviyeleri".
- Art bible: §4 "Bozulma Seviyeleri" (Bayer 4×4 density 25/50/75 %, body #33173D, edge #1A1719 2-on/1-off, glint #522961, 2px clean ownership band), UI palette "Erlik bilgisi" #A86BC4 (4.79→4.7), colour-blind row, §7 info panel corruption rows, §8 shader `instance uniform int level`.
- Mockups: production/qa/evidence/c50-corruption-levels-mockup{,-gray}.png. Tests 134/134.
- NEXT: integrate C-49, then C-51.

## Session Extract — C-52 boş bölge NEUTRAL + AI eşitlik bozma (2026-10-19)
- C-51 skipped for now (waits on C-49 loss-condition decision); C-52 done first.
- ArmyController.apply_combat_result: target army 0 after combat → owner NEUTRAL (corruption kept). EnemyAIController: enemies sorted by region_id; target tie → alphabetical region_id (`_id_less`).
- Tests 141/141 (army +4, combat +1, AI +2 / −1 superseded "first adjacent", map +1). GDD AC annotations untouched (C-49 agent editing GDDs).
- NEXT: integrate C-49 when the agent reports; then C-51.

## Session Extract — C-55 ADR-0006 değiştirici hattı (2026-10-19)
- game/features/modifiers/: StatModifier (Kind FLAT/PERCENT), ModifierEffect + ModifierSource (Resource; exclusive_group, max_stacks, effects: Array[ModifierEffect]), StatResolver (static resolve/flat_sum/percent_sum), ModifierController (bind_services(game_state), can_add, add_source, remove_source, rebuild; signal modifiers_changed(stat_id); caches _active_sources/_source_stacks rebuilt by rebuild()).
- GameState: bozkurt_bonuses/get_total_bozkurt_bonus removed → boons: Array[StringName] + modifiers: Array[StatModifier]. Fixture: tests/unit/modifiers/fixtures/fixture_gok_kalkani_source.tres (ResourceSaver output).
- run-tests.sh: grep guard for `.modifiers` outside features/modifiers|tests|addons (probe verified). Tests 157/157.
- Consumers (F2 B_add/M_g, boon catalog, GameContext rebuild call) → C-39.

## Session Extract — C-57 load() bağlamlar + bölüm haritası (2026-10-19)
- RootContext: MENU_SCENE_PATH/GAME_SCENE_PATH + load() on transition; _switch_to: remove_child(old) then queue_free(). GameContext: CHAPTER_MAP_PATH_FORMAT "res://features/grid/data/chapter_%d_map.tres" % current_chapter, assert on null. COMBAT_CONFIG preload kept (tiny); MenuContext SETTINGS_SCENE preload kept (small, non-persistent owner).
- Buttons fire on ui_accept RELEASE (ACTION_MODE_BUTTON_RELEASE) → tests send press+release; focus_reveal accept test strengthened (1st Enter reveals, 2nd presses).
- Tests 161/161 (contexts/root_context_transition_test 4). Avoid `git stash` while the C-49 agent edits design/ (risk of losing its edits).

## Session Extract — C-61 ADR-0009 localization (2026-10-19)
- ADR-0009 Accepted (as-built + glyph-coverage rule). Finding: U+2212 −, ⚠, ✕, ✓, U+202F absent from all Fusion Pixel subsets (only Unifont) → not used in text; ASCII "-" + pixel icons. glyph_coverage_test.gd reads translations.csv (imported translations are OptimizedTranslation → no key list).
- Indexes: architecture.md (ADR-0009), technical-preferences ADR log (+0009), traceability 24/36 covered, coding-standards localization bullets. Tests 163/163.
- C-58 agent (godot-specialist) resumed after 20-turn limit; C-49 agent still running.

## Session Extract — C-59 ADR-0010 move resolution (2026-10-19)
- ADR-0010 Accepted: MoveOutcome (features/army, data incl. target_*_after, dispersed, ruh_gain), MoveResolver.resolve(map, from, to, mover, modifiers) read-only with INVALID+reason, branch order COMBAT → PURIFICATION (player only) → PEACEFUL; apply via ArmyController.apply_outcome + SpiritController.apply_purification; MapController.preview_move; CombatResolver.resolve_effective (M2); IncomeRules.turn_income (F2) with EconomyConfig (C-37).
- Traceability 27/36 covered. Implementation = first step of C-38.

## Session Extract — C-60 ADR-0011 presentation (2026-10-19)
- ADR-0011 Accepted: passive views (feature-owned scenes; HUD in ui/hud/), GameContext sole presenter `_refresh_views()`, HudModel via pure HudPresenter (IncomeRules + ErlikSpreadController.decide + StatResolver interval), reports fed MoveOutcome, one TurnSummaryReport per enemy turn, ModalQueue (overlay CanvasLayer, backdrop blocks map, FocusReveal focus restore), preview + second click for failing purification, motion never gates input.
- Traceability 30/36 covered; remaining gap TR-concept-007 (scene flow, C-62 after C-35).

## Session Extract — C-38 adım 1: MoveResolver (2026-10-19)
- features/army/move_outcome.gd + move_resolver.gd (static validate() with REASON_*; resolve() COMBAT/PEACEFUL, W3 neutral, dispersed); ArmyController = can_move (delegates validate) + apply_outcome only (move_army/apply_combat_result/apply_peaceful_move removed); MapController.preview_move + _commit (shared by player/enemy); optional 8th bind_services arg move_resolver (GameContext injects).
- Tests 171/171 (army tests migrated; move_resolver_test 7: preview no-mutation, preview == applied, reasons, enemy merge).
- Remaining C-38: PURIFICATION branch (SpiritRules, SpiritController.apply_purification/apply_spread), spread application in end_turn, M_c penalty, corruption visuals (art bible C-50) + info panel rows + keys; Prolog data waits on C-49/C-36.

## Session Extract — C-58 motor referansı 4.7 (2026-10-19)
- godot-specialist updated docs/engine-reference/godot/* (12 files) from official 4.7 release notes, migration guide, CHANGELOG + 4.7.1 binary checks. Focus API (grab_focus(hide_focus)/has_focus(ignore_hidden_focus)/show_focus_state_on_pointer_event) is 4.6 (GH-110250). 4.7 font importer default hinting changed → font_import_settings_test.gd guards our flags.

## Session Extract — C-49 Prolog Erlik dengesi (2026-10-19)
- Agent decisions (recommended): Erlik loss erlik_power = Σ corruption ≥ 9 (end_turn step 5), no ENEMY in Prolog, tutorial L1 at dogu_bozkir (garrison 0), lair garrison 0 + data AC (region-map AC14), interval 3 kept. Fastest win T5, neglect loss T15, mid-scene boon T7 (E3).
- tools/balance/prolog_sim.py replays 12/12 lines (executed). New tasks C-63 (Erlik loss code; deps C-51, C-38), C-64 (balance replay on real controllers). C-36, C-42 now depend on C-63.
- spirit §3.1 / AC10 now point to art bible "Bozulma Seviyeleri" (C-50).

## Session Extract — C-38 adım 2: bozulma lekesi görseli (2026-10-19)
- features/grid/corruption_stain.gd: CPU-built 4 frames per region (Bayer 4×4 flat PackedInt32Array; inset −3 = outline + 2px band; dashed edge 2/1; glint 1/16), RegionNode draws texture, 3 fps, reduce_motion → frame 2; CampaignMap passes reduce_motion. Evidence: production/qa/evidence/c38-corruption-stain-{levels,zoom}.png; map render 0 off-palette colours.
- Engine quirk: `const X: Array[PackedInt32Array]` indexed with variables returns 0 (4.7.1) → documented in engine-reference current-best-practices.
- Tests 181/181 (corruption_stain_test 9). Remaining C-38: purification branch + SpiritController/SpiritRules + spread application + M_c + info panel rows.

## Session Extract — C-51 game_result kilidi (2026-10-19)
- MapState.GameResult {ONGOING, WON, LOST} + game_result; RegionData.initial_owner (from RegionDefinition, unsaved). WinCondition: erlik_foci, conquered_neutral_count, foci_cleansed, is_met requires ≥1 player region.
- MapController: attempt_move rejects when not ONGOING; apply → actions/selection → emit → win check → _finish(); end_turn: AI → early loss exit → income → turn++ → lose → win → else turn_ended. _is_lost() = no player regions (C-63 adds Erlik). GameContext HUD derived from game_result.
- Tests 190/190. NEXT: C-56 (ADR-0007 save/load; deps C-17 ✓, C-51 ✓) or continue C-38.

## Session Extract — C-63 Erlik kaybı (2026-10-19, ~07:15 UTC; session resumed after rate-limit pause 01:47→07:06)
- WinCondition.erlik_loss_threshold + static erlik_power() + loss_reason(); MapState.LossReason {NONE, NO_REGIONS, ERLIK} + loss_reason; MapController._lose(reason). Tests 196/196.
- C-35 agent resumed (scene-flow.md written, 892 lines) to apply cross-doc edits + report. When done: systems-index row, design review, scene-flow §3.7 wording → reason from MapState.loss_reason.

## Session Extract — C-35 scene-flow.md (2026-10-19 ~07:25)
- Written by game-designer agent (hit API limit, resumed), independent opus review: 3 blocking fixed → APPROVED (warnings W1–W6: Devam after defeat source of truth, quit during boon picks, art bible slow pan, class names → C-62, AC33–35 advisory, index row done).
- Cross edits applied by agent: region-map §6, spirit §3.4/§5/§6, resource §6, concept, ADR-0001/0007/0011 amendments (proposed for C-56/C-62), art bible §7.
- Owner questions: fixed Perde order?; Devam after defeat; victory-pending save.

## Session Extract — C-38 adım 3: arındırma + yayılım mantığı (2026-10-19 ~07:30)
- features/bozkurt: SpiritConfig (+data/spirit_config.tres), SpiritRules (corruption_strength, ruh_gain via StatResolver &"ruh_gain", production_multiplier), SpiritController (apply_purification, apply_spread; signals ruh_changed, corruption_changed). GameState.ruh.
- MoveResolver PURIFICATION branch (player only, P > S, Dal 1 loss, failure disperses all); MoveOutcome corruption_strength/purified/ruh_gain. MapController.bind_erlik_layer(spirit, spread, modifier_controller), _run_erlik_spread() step 2 (interval via StatResolver &"erlik_spread_interval"), signals purification_resolved/corruption_spread. ModifierController.get_modifiers(). ResourceController.forecast_income + M_c via IncomeRules.region_income. ChapterMapDefinition.erlik_spread_interval (3), RegionDefinition.starting_corruption.
- Tests 209/209 (purification_spread_test 13). Remaining C-38: info panel corruption rows + keys; Prolog data is C-36.

## Session Extract — C-38 kapandı (2026-10-19 ~07:35)
- Info panel rows (CORRUPTION, ERLIK_HOLD keys ×11; ↓-X penalty in #E87A7A; values #A86BC4); GameContext._show_region_info computes S/max/effective gold. Beast test S=12. Tests 212/212. Evidence production/qa/evidence/c38-info-panel-corruption-en-de-ar.png.
- NEXT: C-56 (save/load; consider ADR-0007 C-35 amendment S2 scene_entry as proposed).

## Session Extract — C-56 kayıt/yükleme (2026-10-19 ~07:50)
- features/save/: LoadResult (+CONTENT_MISSING), SaveSerializer (to_dict/to_text/from_text/from_dict/migrate; _as_int validation), SaveStore (@abstract write/read_candidates), FileSaveStore (tmp→.bak rotation, overridable _write_text/_rename/_remove), MemorySaveStore, SaveController (CAMPAIGN_SLOT, save_failed, newer-save guard).
- RootContext owns SaveController (public `save_store` injectable for tests), _on_continue, _create_map_state; MenuContext ContinueButton (primary when available); GameContext bind_services(..., save) + autosave in _on_turn_ended + keeps loaded map.
- run-tests.sh: runs tests/unit + tests/integration; grep guard for loaders in features/save (comments excluded). Tests 234/234.
- New task C-65 (settings persistence). ADR-0007 checklist 8/10.

## Session Extract — C-62 ADR-0012 (2026-10-19 ~08:00)
- ADR-0012 Accepted: pure SceneFlow (State enum incl. KOK_BORI_MARK_PAGES/PANEL, FlowStep actions), RootContext executes; NarrativeContext + ChapterSelectContext; modals in GameContext; CampaignDefinition/SceneDefinition.map_path replaces CHAPTER_MAP_PATH_FORMAT (C-40); S2 campaign + scene_entry slot; S3 at COMMIT. Traceability 34/36, gaps 0.
- C-54 agent (narrative-director) resumed after turn limit.

## Session Extract — C-65 ayar kalıcılığı (2026-10-19 ~08:05)
- SettingsSnapshot/SettingsSerializer (features/save), SaveController.SETTINGS_SLOT + save/load_settings; settings_changed chain SettingsScreen → MenuContext → RootContext._on_settings_changed; RootContext._apply_settings before locale fonts. SaveSerializer.as_int now public. Tests 239/239.

## Session Extract — C-36 Prolog verisi (2026-10-19 ~08:15)
- chapter_1_map.tres: sinir_bolge NEUTRAL/0/L3, dogu_bozkir 0/L1, win erlik_foci [sinir_bolge] + threshold 9, enemy_tamga_id "", starting_gold 6, interval 3. ChapterMapDefinition.starting_gold; GameContext uses it. erlik_beast tamga removed (icon, generator, art bible §5, region-map §7, tamga tests). prolog_data_test (4). Tests 243/243.

## Session Extract — C-54 + C-37 (2026-10-19 ~08:00 UTC)
- C-54 (narrative-director ajanı): design/narrative/narrative-voice.md + 45 key × 11 dil; zh Erlik 埃尔利克 birleşti; scene-flow Q8 kapandı; K-03 ana dil incelemesi. Commit 5cf8145.
- C-37: EconomyConfig(.tres), IncomeRules F1/F2/F3/F7, ResourceController (recruit_cap, remaining_cap, max_recruit, recruit, reinforce_enemies, pay_upkeep, reset_recruit_counters), RegionData.recruited_this_turn, MapController.recruit/forecast_income/army_recruited; RegionInfoPanel Ordu Topla (RecruitBox/RecruitMinus/RecruitPlus/RecruitConfirm/RecruitCost/RecruitCap/RecruitHint) + ReinforcementRow; GameContext _refresh_map re-shows selected region; HUD "Gold: X (+Y)". 8 key. Tests 259/259. New task C-66 (resource §9 feedback/SFX).
- NEXT: C-39 (Kök Böri çekirdeği).

## Session Extract — C-39 Kök Böri lütuf çekirdeği (2026-10-19 ~08:05 UTC)
- features/bozkurt: BoonDefinition, BoonCatalog (+data/boon_catalog.tres), BoonRules (static), SpiritConfig base_boon_cost/boon_cost_step/victory_pick_cap, SpiritRules.boon_cost/is_offer_pending/victory_pick_cap, SpiritController bind_boons/rebuild_boon_modifiers/next_boon_cost/is_offer_pending/current_offer/pick_boon + boon_picked signal.
- UI: ui/modal_queue.gd (ModalQueue: push/is_open/current/drained), features/bozkurt/ui/boon_offer_modal.gd + boon_card.gd, theme DivinePanel; ui/hud/hud_model.gd + hud_presenter.gd; game_context.tscn SpiritLabel + KokBoriButton; GameContext _refresh_views/_render_hud/_push_boon_offer/_on_boon_picked/_on_kok_bori_pressed, dawn offer in _on_turn_ended, mandatory chain in _on_game_won.
- Tests 277/277 (boon_offer_test, boon_flow_test, hud_presenter_test). New task C-67. NEXT: C-40 scene flow code (ADR-0012).

## Session Extract — C-40 sahne akışı (2026-10-19 ~13:30 UTC)
- Kullanıcı geldi: otomatik devam KAPALI, kararlar sorulacak, sayaç yok.
- C-40 bitti: features/campaign (SceneFlow, CampaignRules, Campaign/Scene/NarrativePage, SceneFlowConfig, ui/objective_panel, victory_card, defeat_screen), contexts/narrative_context, contexts/chapter_select_context, ui/confirm_dialog + input_guard; RootContext flow executor; GameContext up-signals + modals; SaveController scene_entry/save_completed; run-tests.sh fade guard. Tests 300/300. Yeni görev C-68.

## Session Extract — C-41 Prolog öğreticisi (2026-10-19)
- features/tutorial (TutorialRules, TutorialProgress, ui/hint_bubble), SettingsSnapshot.seen_hints + serializer, Settings reset button → MenuContext → RootContext, GameContext hint triggers + HUD ObjectiveBar (ObjectiveLabel/ProgressLabel/ShadowLabel), HudModel/HudPresenter objective+erlik, RegionNode objective mark, CampaignMap.set_objective_markers. design/ux/prolog-tutorial.md. Tests 312/312. Yeni görev C-69.

## Session Extract — C-69 (2026-10-19)
- NumberFormatter.ltr/fraction (LRI/PDI) everywhere numeric; ERLIK_SHADOW_VALUE single %s; ADR-0009 amendment. ui/panel_placement.gd + ModalQueue Placement (CENTER/TOP/BOTTOM, place, rect_for); objective panel bottom→top; hint bubble corners. icon_objective_marker_0/1.png via tools/asset-pipeline/generate_objective_marker.gd; RegionNode draws texture 1 fps. Tests 316/316.

## Session Extract — C-64 (2026-10-19)
- tests/integration/balance/prolog_replay.gd + prolog_balance_test.gd (12 lines, AC15 extras, pruned T4 search ~14s). Tests 322/322. resource Q2 closed. NEXT: C-42 (kullanıcıya sor).

## Session Extract — C-42 ilerleme (2026-10-19)
- Kararlar: export macOS + Windows; playtest'i kullanıcı oynar (ben protokol + şablon hazırlarım).
- tests/integration/campaign/prolog_playthrough_test.gd (yalnız UI düğmeleriyle Prolog → zafer → bölüm seçimi), RegionInfoPanel SendArmyButton adı.
- export_presets.cfg (Windows embed pck, macOS universal ad-hoc codesign=1, ETC2/ASTC açık), icon.png (tools/asset-pipeline/generate_app_icon.gd); .gitignore artık export_presets.cfg'yi takip eder.
- HATA: SaveSerializer.UTF8_BOM çıplak U+FEFF → export'ta silinip "" oluyordu → kayıt/ayar ilk karakteri kesiliyordu. Düzeltme "﻿" + strip_bom(); regresyon testi; run-tests.sh çıplak BOM bekçisi. Testler 324/324.
- production/qa/smoke-2026-10-19.md (PASS), production/qa/playtest-c42-protocol.md. Build'ler build/ (gitignored) kullanıcıya gönderildi.
- NEXT: kullanıcının playtest raporu → /playtest-report analyze → C-42 kapanışı.

## Session Extract — C-66 (2026-10-20)
- Kullanıcı önceliği: Demo (M1) + Vertical Slice (M2); sıra C-42 kapanışı → C-66 → C-43…C-48; tek öneri sun.
- ui/value_feedback.gd (ValueFeedback), RegionNode ordu etiketi (_army_feedback, nesil korumalı timer), GameContext _gold_feedback/_render_gold, AudioController SFX_RECRUIT/SFX_INCOME, sfx_library.tres, tools/asset-pipeline/generate_sfx.py. Testler 338/338. NEXT: C-43 (kullanıcı onayıyla) / C-42 playtest raporu.

## Session Extract — C-43 (2026-10-20)
- /team-level 5 adım, her adım kullanıcı onaylı. design/levels/perde1-dogu-curcet.md (0086685); GDD/ADR yayılımı (00c2da3 + narrative/registry). Simülasyon scratchpad/c43/perde1_sim.py (+ c43tools/perde1_sim_capital.py: takviye yalnız başkent). Seçilen: garnizon 2/4/4, E_r 1 yalnız curcet_otagi, AI R1 tur≥5 oran 3/2, R2 kapalı.
- Uygulama C-47'ye bağlandı (§13, 13 adım). NEXT: C-44 (lütuf tam kapsam + Erlik katmanı GDD) / C-42 playtest raporu.

## Session Extract — C-44 (2026-10-21)
- enemy-layers.md (yeni GDD), boon-balance-2026-10-21.md, gdd-cross-review-2026-10-21.md (CONCERNS; kararlar D1–D6, tümü uygulandı). Simülasyon: c43tools/boon_run.py (onaylı Perde 1 yapılandırması; container yeniden başladıysa scratchpad gitmiş olabilir).
- Önemli: güney "önce arındır" W20 (W14 değil) → C-47 BLOCKING ≤ T16. Demir Post/Kurt Gücü ≤ 3. Kampanya tohumu. decide(map_state, acted, defense_modifiers).
- NEXT: C-45 (M2 UX spec'leri; D3 vuruş eşiği satırı, Odak tehlikede, yayılım sayacı dahil) / C-42 playtest raporu.

## Session Extract — C-45 (2026-10-21)
- design/ux/hud.md, battle-report.md, boon-selection.md, scene-screens.md (Approved). Kararlar K1 yayılım sade, K2 vuruş eşiği her tur, K3 Cürcet x/3, K4 klavye bölge seçimi M2.
- Bulgu: savaş/arındırma raporu + tur özeti modalları kodda yok (Prolog demosunda da). Uygulama C-47'de.
- NEXT: C-46 (M2 sanat) / C-42 playtest raporu.

## Session Extract — C-46 ilerleme (2026-10-21)
- Kullanıcı: MCP ile pixel art aracı sordu → öneri Retro Diffusion MCP (palet zorlamalı, barındırılan); Aseprite MCP'leri yerel Aseprite ister, bulut oturumdan erişilemez. Karar: önce küçük varlıklar, illüstrasyonlara sonra bakılacak.
- tools/asset-pipeline/generate_env_forest.gd → maps/env/env_tree_healthy_01/02, env_tree_rotten_01/02, env_bridge_wood_01, env_otag_curcet_01; units/unit_kormos_forest_idle_0/1. tests/unit/art/env_forest_assets_test.gd. Testler 341/341, palet 46 PNG 0 ihlal.
- C-67 (C-46 içinde, 2026-10-22): generate_divine_ui.gd → theme/frame_divine.png (DivinePanel StyleBoxTexture, margin 7, content 8/6), icons/icon_boon_<id>.png ×5; BoonDefinition.icon; BoonCard ikon satırı (BoxContainer, uzun sözcükte vertical). tests/unit/bozkurt/boon_card_icon_test.gd. Testler 346/346. Kullanıcı: Aseprite'ı devreye aldığını söyleyince kurulum + kurallar kontrol listesi hazırlanacak.

## Session Extract — C-47 kırılımı (2026-10-22)
- production/epics/index.md (6 epic) + m2-breakdown.md (30 story C-70…C-99, kararlar §5). Kuyrukta C-48'den önce. C-47 şemsiye [~].
- Kararlar: AC21 ayar sırası attack_start_turn 5→6 → başkent takviyesi seyreltme → garnizon (kullanıcıyı beklemeden); sanat bloklamaz (yer tutucu); başlangıç C-70.
- Bulgu: boon_catalog Kurt Gücü/Demir Post max_stacks=0 (sınırsız) → C-80. C-41 kuyruk satırı [x] düzeltildi.
- C-70 (c8c01f0) ADR-0010 eki G1–G4. C-71: MoveOutcome.target_owner_before/reason, MoveIntent.reason, SpreadDecision.level_before, combat_occurred(outcome), corruption_spread(decision), GameContext night buffer. Testler 355/355. NEXT: C-72.

## Session Extract — C-72 (2026-10-23)
- ReportModal + BattleReport + PurificationReport; SceneDefinition.focus_heading/success/failed_key (C-92 UD kapandı); ModalQueue.push_avoiding (CENTER→BOTTOM→TOP, PanelPlacement); RegionNode.bounds_rect / CampaignMap.region_rect.
- Bulgu: başarısız arındırmada outcome.combat == null (tasarım gereği) → _report_data_ok yalnız COMBAT/başarılı arındırmada combat ister. Ritüel başlığı yalnız başarıda.
- Testler 364/364. Kanıt production/qa/evidence/c72-{battle,purify-failed,purify-ritual}.png. NEXT: C-73.

## Session Extract — C-73 (2026-10-23)
- TurnSummaryReport (game/ui/turn_summary_report.gd; has_events, attacks_on_player, MAX_ATTACKS 3), GameContext._push_turn_summary + _push_boon_offer(after_summary); HINT_SPREAD drained'de (_check_start_hint). icon_alert.png (generate_ui_theme_icons.gd). ReportModal._number_label.
- Karar: saldırı sayıları tek satır (HBox) + blok boşluğu 4 → 8 dilde sığar. Prolog playthrough _end_turn() özeti kapatır.
- Testler 374/374. NEXT: C-74.

## Session Extract — C-74 (2026-10-24)
- InputGuard: BoonOfferModal.new(guard_s) (_ready arm kartlar+Sonra; Esc defer butonu pasifse düşer), ConfirmDialog.new(key, guard_s), ChapterSelectContext.bind_services(..., guard_s) + Esc = menü. RootContext/GameContext flow_config.screen_input_guard_s geçirir.
- Bulgu: ModalQueue kuyruğunda bekleyen (ağaca girmemiş) modallar sızıyordu → NOTIFICATION_PREDELETE'te free.
- Testler 384/384. tests/integration/campaign/input_guard_all_modals_test.gd. NEXT: C-75.

## Session Extract — C-75 (2026-10-25)
- features/grid/region_focus_target.gd (Control, MOUSE_FILTER_IGNORE, LTR, has_focus(true) iken kontur, ui_accept → accepted), region_focus_rules.gd (saf, MIN_ALIGNMENT 0.38). RegionNode.accepted / get_focus_target; CampaignMap.region_accepted, focus_target, focus_order, _link_focus_neighbors (komşu yoksa kendine).
- GameContext: _on_region_accepted, _set_target_mode, _cancel_target_mode, _unhandled_input (Esc), _link_map_tab_order. RegionInfoPanel: toggle Send + PickTargetHint, set_awaiting_target, get_first_focus, get_send_button. PICK_TARGET_HINT 11 dil.
- Bulgu: Node2D altındaki kontroller Tab'a girmiyor → açık zincir. Testler 391/391. NEXT: C-76.
