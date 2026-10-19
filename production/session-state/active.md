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
