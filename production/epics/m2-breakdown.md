# C-47 — M2 Kod Parçalaması (Epic + Story) — Onaylı 2026-10-22

*Taslak · producer · 2026-10-22 · review-mode: lean (PR-EPIC / QL-STORY-READY atlandı) · repo'ya yazılmadı*

**Kaynaklar:** `design/levels/perde1-dogu-curcet.md` §4–§7, §11, §13; `design/gdd/enemy-layers.md` §3, §8 (AC1–AC22);
`spirit-system.md` §3.5, §4.5, AC4/AC25–AC29; `combat-system.md` §4 "Etkin güç"; `scene-flow.md` §3.1, §3.4, §3.10;
`resource-system.md` F6; `design/ux/hud.md` §5, §12; `battle-report.md` §8–§9; `boon-selection.md` §9, AC1–AC12;
`scene-screens.md` §0, E4, E5; `gdd-cross-review-2026-10-21.md` D1–D6; ADR-0005/0007/0010/0011/0012.

## 0. Kod taraması (2026-10-22, grep) — neyin olduğu, neyin olmadığı

| Alan | Durum |
| --- | --- |
| `EnemyAIController.decide(map_state, acted)` | Yalnız eski "en düşük ordulu komşu" kuralı. `EnemyAIProfile`, R1, `MoveIntent.reason`, `defense_modifiers` girdisi **yok** |
| `ResourceController.reinforce_enemies` | Tüm ENEMY bölgelere +E_r. `enemy_reinforcement_region_ids` **yok** |
| `ChapterMapDefinition` | `decor`, `enemy_reinforcement_region_ids`, `enemy_ai_profile` alanları **yok** |
| `MapDecor*` | **yok** |
| `CombatResolver` | Yalnız `resolve(A, D)`; `resolve_effective` **yok**; `MoveResolver` `army_attack`/`army_defense` okumuyor |
| `boon_catalog.tres` | Kurt Gücü ve Demir Post var (`requires = effective_power`) ama **`max_stacks = 0`** (sınırsız) → 3 olmalı (AC27/AC28); `active_systems = []` |
| `campaign_seed`, `SceneDefinition.boon_pool_ids` | **yok** (kayıt biçiminde de yok) |
| `combat_occurred` sinyali | Hâlâ `(from_id, to_id, CombatResult)` — G1; `MoveOutcome`'da `target_owner_before` / `reason` yok (G2); `SpreadDecision.level_before` yok (G3) |
| `BattleReport` / `PurificationReport` / `TurnSummaryReport` | **yok** |
| `InputGuard` | `VictoryCard`, `ObjectivePanel`, `DefeatScreen`, anlatıda **var**; `BoonOfferModal` ve `ChapterSelectContext`'te **yok** |
| Klavyeyle bölge seçimi | **yok** (`features/grid`'de `focus_mode` yok); `_awaiting_target` var, `PICK_TARGET_HINT` yok |
| HUD M2 (`spread_turns_left`, `focus_at_risk`, `StrikeThreshold`, düşman bölgesi sayacı) | **yok** |
| Perde 1 içeriği (`chapter_2_map.tres`, `perde1_dogu`, `CHAPTER_2_*`, `HINT_ENEMY_KING`, `CHAPTER_1_TEASER`) | **yok** (csv'de anahtar bulunmadı) |
| `DEFEAT_REASON_ERLIK` | Var (Prolog'a bağlı metin) — sahneden bağımsız yeniden yazım gerekli |
| ADR ekleri | ADR-0005 (R1, profil, `P_eff`, D6) ve ADR-0011 (dekor, HUD sayacı, tamga) ekleri **var**. **ADR-0010 eki (G1–G4) yok; ADR-0007 eki (`campaign_seed`) yok** |
| `tr-registry.yaml` | enemy-layers için TR-ID **yok** → story'lerde `TR-enemy-???` (C-99'da kayda girer) |
| Varlıklar | Orman dekoru + körmös PNG'leri **var** (C-46) — §13 adım 6 tamam; Perde 1 illüstrasyonları yok (C-46) |

**İndeks tutarsızlığı (yan bulgu):** `continuation.md` kuyruğunda C-41 satırı hâlâ `[ ]`, oysa Tamamlananlar'da C-41 kayıtlı
(2026-10-19). Kuyruğa eklerken düzeltilmeli.

---

## 1. Epic listesi (6)

| # | Slug | Kapsam (modül) | Yönetici ADR'ler | Kapsanan GDD/UX gereksinimleri |
| --- | --- | --- | --- | --- |
| E1 | `m2-reports-input` | Sunum: savaş/arındırma raporu, tur özeti, ortak girdi koruması, klavyeyle bölge seçimi + hedef seçim modu (`ui/`, `features/*/ui`, `GameContext`) | ADR-0011 (birincil), ADR-0010 (+ yeni ek G1–G4), ADR-0009 | `battle-report.md` §8–§9 (G1–G4); `enemy-layers.md` AC13, §3.4; `hud.md` A-4, A-7, B1, B6, §5.6; `boon-selection.md` AC8; `scene-screens.md` §0.2–§0.3, AC-E5-6 |
| E2 | `m2-enemy-layers` | Siyasi düşman AI'ı + takviye listesi (`features/ai`, `features/resources`, `MapController` çağrı noktası) | ADR-0005 (+ ekler 10-20/10-21), ADR-0006, ADR-0010 | `enemy-layers.md` §3.2–§3.5, F-E1–F-E3, AC1–AC12, AC14, AC19, AC20; seviye §4.2–§4.3; cross-review D6 |
| E3 | `m2-boons-effective-power` | Lütuf sistemi M2: etkin güç, Kurt Gücü / Demir Post, sahne havuzu, kampanya tohumu, lütuf modalı M2 (`features/combat`, `features/army`, `features/bozkurt`, `features/save`) | ADR-0006 (birincil), ADR-0010, ADR-0007 (+ yeni ek: `campaign_seed`), ADR-0011 | `combat-system.md` §4 "Etkin güç"; `spirit-system.md` §3.5, §4.5, AC4, AC25–AC29; `scene-flow.md` §3.4 (tohum), §3.10 (`boon_pool_ids`); `boon-selection.md` AC7, AC9; cross-review D2, D4 |
| E4 | `m2-map-hud` | Harita dekor katmanı + okunabilirlik + HUD M2 satırları (`features/grid`, `ui/hud`, bilgi paneli) | ADR-0011 (+ ek 10-20), ADR-0004, ADR-0009 | Seviye §7.2–§7.8, kabul #5–#7; `hud.md` §5.1–§5.5, H1–H10, L1–L7, A-1/A-2; `spirit-system.md` §3.6 (sayaç, Odak tehlikede); `enemy-layers.md` §10; cross-review D3, S2-a; scene-screens K3 |
| E5 | `m2-perde1-content` | Perde 1 verisi + sahne akışı + metin (`features/grid/data`, `features/campaign/data`, `assets/locale`, `ChapterSelectContext`) | ADR-0012 (birincil), ADR-0009, ADR-0002 | Seviye §2, §3, §6, §13 #5/#7/#8; `scene-flow.md` §3.1, §3.9, §3.10; `scene-screens.md` E1 (AC-E1-8/9), E4 (AC-E4-1/7/8), E5 (AC-E5-1…9), §7 anahtarlar |
| E6 | `m2-perde1-validation` | Denge replay'i, ölçümler, uçtan uca oynanış, kanıt, belge güncellemeleri (`tests/integration/balance`, `tests/integration/campaign`, `production/qa/evidence`) | ADR-0005, ADR-0007, ADR-0012 | Seviye §13 #9–#13, kabul #1–#12; `enemy-layers.md` AC15, **AC21 (BLOCKING)**, AC22; cross-review D1, D5 |

---

## 2. Story listesi — uygulama sırasıyla (C-70 … C-99, 30 story, her biri ~yarım gün)

Tip: L = Logic · I = Integration · UI · V = Visual/Feel · C = Config/Data · D = Belge (ADR/GDD).
"(UD)" = **uygulamada doğrulanacak** (taslakta kaynak yeterince okunmadı / ölçüm gerekiyor).

### (a) Prolog demosunu da iyileştiren işler

| ID | Başlık | Epic | Tip | Bağımlı | Kabul kriterleri (kaynak) | Test kanıtı |
| --- | --- | --- | --- | --- | --- | --- |
| C-70 | **ADR-0010 eki: rapor verisi (G1–G4)** — `combat_occurred(outcome: MoveOutcome)`, `MoveOutcome.target_owner_before` + `reason: StringName`, `SpreadDecision.level_before`, GameContext tur tamponu + `show_turn(outcomes, spread)` | E1 | D | — | battle-report §8 G1–G4 tek yerde tanımlı; ADR-0005 `MoveIntent.reason` ile uyumlu; Accepted (lean: TD öz-inceleme) | `docs/architecture/adr-0010-…md` eki |
| C-71 | **Kod: G1–G4 uygulaması** — sinyal imzası, outcome alanları (oyuncu + düşman yolu), yayılım öncesi seviye, tur tamponu sıfırlama | E1 | L | C-70 | outcome düşman hamlesinde `mover`/`target_owner_before` doğru; `SPREAD` vs `DEEPENED` ayrılır; tampon `end_turn` başında boş; mevcut testler yeşil | `tests/unit/army/move_outcome_report_fields_test.gd`, `tests/unit/ai/spread_decision_level_test.gd` |
| C-72 | **BattleReport + PurificationReport modalları** — ozan dizesi + etiketli sayı satırları, hedef bölge adı, `PanelPlacement`, `REPORT_SCATTERED`, `PURIFY_FAILED_HINT` | E1 | UI | C-71 | battle-report §9: her sayı = outcome alanı (fixture testi); dize seçimi sırası; beraberlikte dağılan; başarısız arındırmada Ruh satırı yok; `outcome == null` → modal yok + uyarı; iç ≤ 288 px; Enter/Space/Esc kapatır | `tests/unit/ui/battle_report_text_test.gd` + `production/qa/evidence/c72-reports-en-de-ru-ar.png` |
| C-73 | **TurnSummaryReport + sıralama** — tek özet (düşman hamleleri + yayılım), olaysız gecede modal yok, `ERLIK_SHADOW_WARNING` koşulu, şafakta özet → en çok 1 lütuf, `NO_REGIONS` sırası | E1 | I | C-72 | battle-report §9: 2 düşman hamlesi + yayılım → tek özet, ardından ≤1 otomatik lütuf; son bölge düşmanla düşerse özet yok, doğrudan yenilgi; enemy-layers AC13 (strike → `BATTLE_LOST_DEFENSE`, HELD yok); Q9 balon `drained` sonrası | `tests/integration/campaign/turn_summary_flow_test.gd` |
| C-74 | **Ortak girdi koruması + Esc kuralı tamamlama** — `InputGuard` `BoonOfferModal`'a (zorunlu, şafak, HUD, yükleme sunumları) ve `ChapterSelectContext`'e; rapor modallarına | E1 | I | C-72 | boon-selection AC8; scene-screens §0.3, AC-E5-6; hud A-4 (Esc tablosu her modal türünde: rapor = Devam, ertelenebilir lütuf = Ertele, zorunlu / E2 / E4 etkisiz) | `tests/integration/campaign/input_guard_all_modals_test.gd` |
| C-75 | **Klavyeyle bölge seçimi (K4) + hedef seçim modu (A5)** — bölgeler odaklanabilir, ok tuşları komşuluğa göre `focus_neighbor`, `ui_accept` seçer; `Ordu Gönder` basılı stil + `PICK_TARGET_HINT`, Esc iptal; M2 salt-okunur satırlar odaklanmaz | E1 | UI | — | hud A-7 (fare olmadan bir tur oynanır), B6, §10.3 kural 5–6; FocusReveal ile uyumlu; ok-komşuluk eşlemesi (UD: RTL'de yön) | `tests/unit/grid/region_focus_neighbors_test.gd` + `production/qa/evidence/c75-keyboard-turn.md` |
| C-76 | **`DEFEAT_REASON_ERLIK` sahneden bağımsız (11 dil) + `×`/`→` glif testi** — narrative-director metni; `glyph_coverage_test`'e `×` `→` denetimi; sonuca göre `BOON_STACK` biçimi | E5 | C | — | seviye §13 #5; scene-screens Q11, AC-E4-1/7/8 (fr/de/ru/ar taşma yok); hud L6; AC-V1 yasak sözcük testi | `tests/unit/localization/glyph_coverage_test.gd` (genişletilir) + `production/qa/evidence/c76-defeat-erlik-fr-de-ru-ar.png` |

### (b) Perde 1'i oynanabilir yapan çekirdek

| ID | Başlık | Epic | Tip | Bağımlı | Kabul kriterleri (kaynak) | Test kanıtı |
| --- | --- | --- | --- | --- | --- | --- |
| C-77 | **ADR-0007 eki + kampanya tohumu kaydı** — `GameState.campaign_seed`, serializer alanı (eski kayıt → 0, şema sürümü), Yeni Sefer'de üretim, S1–S3 / Yeniden Dene / Devam Et'te sabit | E3 | L | — | scene-flow §3.2 tablo, §3.4 tohum maddesi; spirit AC29 "tohum kayıttan geri yüklenir"; eski kayıt yüklenir (UD: şema sürüm artışı mı, varsayılan alan mı — ADR ekinde karar) | `tests/unit/save/save_serializer_campaign_seed_test.gd` + ADR-0007 eki |
| C-78 | **Lütuf sunumu: tohum + sahne havuzu** — `BoonRules` seed'e `campaign_seed`; `SceneDefinition.boon_pool_ids` (boş = tüm katalog) + Prolog verisi `[arinma_ustaligi, bereket, gok_kalkani]` + scene-flow §3.10 lint | E3 | L | C-77 | spirit AC4 (seed 0 = eski çıktı), AC25 (yeniden deneme aynı 3'lü), AC26, AC29; testte tohum enjekte | `tests/unit/bozkurt/boon_offer_seed_pool_test.gd` |
| C-79 | **Etkin güç** — `CombatResolver.resolve_effective(A, D, A_eff, D_eff)`; `MoveResolver` oyuncu tarafına `army_attack` / `army_defense` (ceil) uygular; arındırmada `A = P_eff`, `D` modifikatörsüz; önizleme aynı yol | E3 | L | — | combat §4 "Etkin güç" formülleri + örnek (Kurt Gücü 1, A=4, D=4 → Dal 1, kayıp 2); modifikatörsüz sonuçlar birebir aynı (regresyon); düşman `A_eff = A` | `tests/unit/combat/combat_effective_power_test.gd` |
| C-80 | **Kurt Gücü / Demir Post etkinleştirme** — katalogda `max_stacks = 3` (ikisi de; şu an 0), `active_systems += effective_power`; Prolog'un `boon_pool_ids` ile korunduğunu doğrula | E3 | L | C-78, C-79 | spirit AC27, AC28 (3 yığından sonra havuz dışı, `rebuild()` sınır kadar, `n = boons.size()`); AC18 → AC26 ile güncellenir (Prolog'da M1 üçlüsü dışı yok); cross-review D2 | `tests/unit/bozkurt/boon_stack_caps_test.gd` |
| C-81 | **Lütuf modalı M2** — `×N/MAX`, `(son)`, `Kalan: X` (iki etiket, `→` yok), tavana ulaşmış lütuf kartta yok, havuz < 3 birleşik kart | E3 | UI | C-80, C-76 | boon-selection AC7, AC9 (6 dilde ≤ 281 px; sığmazsa figür gizli), AC12; `BOON_STACK`, `BOON_STACK_LAST`, `BOON_REMAINING` 11 dil | `production/qa/evidence/c81-boon-m2-ru-de-ar-zh-tr-en.png` + `tests/unit/bozkurt/boon_card_stack_label_test.gd` |
| C-82 | **AI R1 + `EnemyAIProfile`** — profil Resource (4 alan), `bind_config`, `decide(map_state, acted, defense_modifiers)`, R1 + F-E2 savunma tutma, `P_eff` (StatResolver), `MoveIntent.reason = &"strike"`; MapController modifikatörleri geçirir | E2 | L | C-79 | enemy-layers AC1–AC10, AC19, AC20 (13 test adı seviye §13'te); varsayılan profil Prolog davranışını birebir korur (kabul #6) | `tests/unit/ai/enemy_ai_counterattack_test.gd` |
| C-83 | **F6 takviye bölge listesi + bölüm veri alanları** — `ChapterMapDefinition.enemy_reinforcement_region_ids` + `enemy_ai_profile` → `MapState`; boş liste = eski davranış; AI ele geçirdiği listede bölgeye aynı tur +E_r | E2 | L | C-82 | enemy-layers AC11 (3 test), AC12 (başkent 8 turda 12), AC14; resource F6; kayıt/yükleme etkilenmez (UD: alan kaydedilmez, bölüm verisinden gelir) | `tests/unit/resources/reinforcement_region_list_test.gd` |
| C-84 | **Dekor veri modeli** — `MapDecorItem` (layer, ayak, `bound_region_id`, min/max bozulma, fps, saf `is_visible(level)`), `MapDecor` (öğeler + su dikdörtgenleri), `ChapterMapDefinition.decor = null` | E4 | L | — | seviye §7.6; `unit/grid/map_decor_item` (çürük 0'da gizli / 1'de görünür; sağlıklı max=0; -1 sınırsız) | `tests/unit/grid/map_decor_item_test.gd` |
| C-85 | **`MapDecorLayer` çizimi** — `CampaignMap.set_decor()` (`build_map` öncesi), çizim sırası (GROUND → çizgiler → PROP → RegionNode → OVERLAY, ayak-y sıralı), nehir kodla + `#476B8F` kıyı, `refresh()` zincirinde bozulma görünürlüğü, körmös 2 kare 2 fps, `_process` yalnız gerektiğinde, Hareketi Azalt kare 0 | E4 | V | C-84 | seviye §7.3, §7.6, §10; kabul #6 (null decor → Prolog aynı), #7 (kayıt/yükleme sonrası dekor eşit — dekor türetilir) | `tests/integration/grid/map_decor_layer_test.gd` + `production/qa/evidence/c85-decor-layer.png` |
| C-86 | **Harita okunabilirliği** — ENEMY bölgede sahip tamgası her zaman (renk körlüğü modundan bağımsız), nötrde yok; `adjacency_line_color` `#5C8F5C` (bölüm verisi); kontrast testleri | E4 | L | — | seviye §7.8 #2–#3, kabul #5 (≥ 3:1); hud A-2; Prolog etkilenmez (UD: Prolog'da ENEMY yok — doğrula) | `tests/unit/ui/map_readability_contrast_test.gd` |
| C-87 | **HUD modeli M2 (saf)** — `spread_turns_left`, `focus_at_risk`, düşman bölgesi sayacı (payda = sahne başı düşman bölgesi sayısı), kırmızı uyarı önceliği, `StrikeThreshold.min_force` | E4 | L | C-82 | hud H1–H4, H8, H9, H10; F-E1 ile çapraz test (aynı fonksiyon); seviye `unit/ui/hud_presenter` (sayaç geri sayar, yayılım turunda 0) | `tests/unit/ui/hud_presenter_m2_test.gd` |
| C-88 | **HUD + bilgi paneli M2 görünümleri** — Gölge hücresi 2. segment (`SPREAD_COUNTDOWN` / `SPREAD_THIS_TURN_END` / `FOCUS_AT_RISK` + piksel ikon), ilerleme satırına `PROGRESS_ENEMY_REGIONS`, panelde `ENEMY_STRIKE_THRESHOLD` satırı, takviye satırı liste filtresi; 11 dil key | E4 | UI | C-87, C-83 | hud H5, H6, B4, L1 (≤ 40 px, de/ru/ar), L2 (panel ≤ 285 px), L3, L4, A-1; P1 performansı (UD: ölçüm C-98'de) | `production/qa/evidence/c88-hud-m2-en-de-ru-ar.png` + `tests/unit/ui/info_panel_rows_test.gd` |
| C-89 | **Perde 1 harita verisi** — `chapter_2_map.tres`: 8 bölge, 9 komşuluk (kiriş dahil), garnizon 2/4/4, `WinCondition` (2 nötr, tüm düşman, `erlik_foci = [curuk_koru]`, eşik 9), `starting_gold 6`, aralık 3, profil, F6 listesi, `decor` yerleşimi (§7.5), renkler | E5 | C | C-83, C-85, C-86 | seviye §3, §4, §6, §7.5; `unit/grid/win_condition` 4 testi; `unit/grid/map_decor_geometry` (prop poligon dışı, üst bar + 4 altı, nehir y150 üstü, overlay bağlı bölgede, bölge başına ≤ 5 prop); başlangıç `erlik_power = 4`; curuk_koru P ≥ 13 doğrulaması (UD) | `tests/unit/grid/perde1_map_data_test.gd`, `tests/unit/grid/map_decor_geometry_test.gd` |
| C-90 | **Perde 1 sahnesi + kampanya** — `SceneDefinition` `perde1_dogu` (`chapter_id 2`, `map_path`, G-1..G-3, O-1..O-2, `objective_region_ids = [curcet_otagi]`, `boon_pool_ids` (UD: boş = tüm katalog mu), `teaser_key`), `campaign.tres` K = 2, `CAMPAIGN_END` sayfaları, illüstrasyonsuz düz zemin | E5 | I | C-89, C-78 | scene-flow §3.1, §3.10 içerik lint'i (kimlik 1…K boşluksuz); scene-screens AC-E1-8, AC-E1-9; Prolog zaferi → E5 (Perde 1 AVAILABLE) | `tests/integration/campaign/campaign_content_test.gd` (genişletilir) |
| C-91 | **Perde 1 metinleri (11 dil)** — seviye §2 key listesi (`CHAPTER_1_TEASER`, `CHAPTER_2_*`, `WIN_CONDITION_CH2`, `HINT_ENEMY_KING`, `HINT_CAPITAL`, `REGION_*` ×8, `CAMPAIGN_END_DEMO_1`); Cürcet/Jurchen sözlüğü; önce `en` | E5 | C | C-90 | seviye §13 #8; AC-E1-7 (≤ 3 / ≤ 2 satır, L6); glif kapsama; AC-V1 kuru hesap sözcük testi; ana dil incelemesi K-03'e eklenir | `tests/unit/localization/glyph_coverage_test.gd` + L6 testi yeşil |
| C-92 | **Perde 1 sahne içi tetikleyiciler** — `HINT_ENEMY_KING` (ilk tur, bir kez), `HINT_CAPITAL` (başkent ilk önizleme), odak önizleme / arındırma raporunda `CHAPTER_2_HUNT_*` / `CLEANSED_*` (UD: `SceneDefinition.focus_*_key` alanı mı, `chapter_id` kuralı mı — C-54 önerisi) | E5 | I | C-91, C-72 | seviye §2 "Anlatı tetikleyicileri"; enemy-layers §3.4; ipucu modal açıkken bekler (hud B2) | `tests/integration/campaign/perde1_hints_test.gd` |
| C-93 | **E5 bölüm seçimi M2** — iki satırlı düğüm (ad + durum/teaser), `teaser_key`, durum ikonları (yer tutucu piksel ikon; gerçek sanat C-46), yeni açılma parıltısı (Hareketi Azalt'ta sabit), `LOCKED` odaklanabilir, Esc = Ana Menü | E5 | UI | C-90, C-74 | scene-screens AC-E5-1…AC-E5-9 (AC-E5-6 C-74'te); `sfx_chapter_unlock` yalnız SfxLibrary girdisi varsa (ses açık) | `production/qa/evidence/c93-chapter-select-de-ru-ar.png` + `tests/unit/campaign/chapter_select_nodes_test.gd` |

### (c) Denge replay'i + ölçümler

| ID | Başlık | Epic | Tip | Bağımlı | Kabul kriterleri (kaynak) | Test kanıtı |
| --- | --- | --- | --- | --- | --- | --- |
| C-94 | **Perde 1 denge replay'i** (gerçek controller, C-64 kalıbı) — N-fast, S-purify, Mixed, no-purify, pasif, 3 boş tur; ilk AI vuruşu turu | E6 | I | C-82, C-83, C-89 | seviye §13 #10, kabul #2–#4; enemy-layers AC15 (fark çıkarsa replay esas, belge güncellenir); pasif T15 Erlik kaybı; 3 boş tur T15 öncesi zafer yok | `tests/integration/balance/perde1_balance_test.gd` |
| C-95 | **AC21 kapısı: S-purify ≤ T16 (BLOCKING)** — replay sonucu; geçmezse seviye verisi ayarı (bkz. Karar 1), tablo yeniden üretilir, Kök Böri'nin sözü değişmez | E6 | I | C-94 | enemy-layers AC21; seviye kabul #11; cross-review D1; diğer senaryolar hedef aralığında kalır (T10–18) | `perde1_balance_test.gd` içinde `test_s_purify_wins_by_turn_16` + `design/balance/perde1-replay-<tarih>.md` |
| C-96 | **AC22 ölçümleri + kabul/erteleme kaydı** — T5 sonrası AI adayı tur oranı (H2), felç + yeniden arındırma Ruh/tur (H3), GK1 / Bereket1 giriş varyantları (H4: pasif + GK1 > T18 → eşik 9 → 8), N4/N5/N6/N8/N9 | E6 | I | C-95, C-80 | enemy-layers AC22; seviye kabul #12; H2 düşükse başkent F-E2 muafiyeti **kullanıcıya sorulur**; H3 aşılırsa ×0.5 yedeği açılır (spirit §3.7); spirit §5 işaretçileri güncellenir | `tests/integration/balance/perde1_measurements_test.gd` + rapor `design/balance/perde1-replay-<tarih>.md` |
| C-97 | **Perde 1 uçtan uca oynanış** — UI düğmeleriyle Prolog zaferi → E5 → intro → E2 → zafer → outro → `CAMPAIGN_END` → menü; kayıt/yükleme sonrası dekor + sahiplik eşit; Yeniden Dene tohumu korur | E6 | I | C-90, C-91, C-93, C-73 | seviye §13 #11, kabul #7; scene-flow AC (S2/S3, Devam Et `map = null` → E5, AC-E5-9); spirit AC25 akış düzeyinde | `tests/integration/campaign/perde1_playthrough_test.gd` |

### (d) Cila / kanıt / belge

| ID | Başlık | Epic | Tip | Bağımlı | Kabul kriterleri (kaynak) | Test kanıtı |
| --- | --- | --- | --- | --- | --- | --- |
| C-98 | **Görsel kanıt + performans** — nehir üst sınırı `_top_bar_height()+4` ölçümü, Perde 1 haritası (ağaç yoğunluğu, çürük ağaçlar), HUD L1–L7 / A-1 gri tonlama, raporlar 11 dil (en/de/ru/ar asgari), HUD P1 ≤ 1.6 ms | E6 | V | C-97, C-88, C-72 | seviye kabul #8; §7.3 açık ölçüm; hud L1–L7, A-1, P1; battle-report "Yerleşim ve yerelleştirme" | `production/qa/evidence/c98-perde1-*.png` + `production/qa/evidence/c98-perf.md` |
| C-99 | **Belge kapanışı** — seviye §12 tablosu (region-map, resource, spirit, scene-flow, art bible, narrative-voice, entities.yaml), `tr-registry.yaml` enemy-layers TR-ID'leri + yeni ADR ekleri, `architecture.md` §4 `end_turn` notu, seviye §5 simülasyon tablosu → replay değerleri | E6 | D | C-96, C-97 | seviye §13 #13; enemy-layers §6 karşı güncellemeler kapalı; `/architecture-review` için TR kapsamı güncel | Belge diff'i; `tr-registry.yaml` TR-enemy-* ✅ |

**Toplam:** 30 story — L 12 · I 9 · UI 5 · V 2 · C 3 · D 3 (D story'leri tip tablosu dışı; belge görevi).
**Kritik yol:** C-79 → C-82 → C-83 → C-89 → C-94 → C-95 (AC21) → C-96. Paralel kollar: E1 (C-70…C-75), C-77/C-78, C-84…C-88.
**Kaba süre:** 30 × 0,5 gün = 15 gün + %20 tampon ≈ 18 iş günü (tek geliştirici, "devam" başına bir story). AC21 başarısız olursa C-95 1–2 tur tekrar (+1–2 gün).

---

## 3. Story'ye dönüşmeyen / kapsam dışı maddeler

| Madde | Neden |
| --- | --- |
| §13 adım 6 — `generate_env_forest.gd` + varlıklar | **Bitti** (C-46, `dc6982f`); yalnız C-85/C-89 kullanır |
| Perde 1 illüstrasyonları (5), Prolog illüstrasyonları (C-68), Kök Böri figürü, kart belirme dither'i, E5 durum ikonlarının gerçek sanatı, `DefeatPanel` teması (AC-E4-6), kilim zemin, 24 px başlık kartları | Sanat — C-46 / C-68 sahibi; kod tarafı düz zemin / yer tutucu ile çalışır (AC-E1-9) |
| Birim sprite'ları (harita sayı etiketiyle) | C-46'nın açık sorusu; M2 AC'si yok → Karar 2 |
| Ses yönü (müzik/ambiyans, rapor SFX, ses ipuçları, `sfx_chapter_unlock`, ret sesi) | `audio-director` girdisi yok (seviye §8, battle-report Q8) — ayrı görev olarak kuyruğa (öneri: C-100, C-48 öncesi isteğe bağlı) |
| AI niyet önizlemesi | K8 — M3'e ertelendi |
| Yayılım hedefinin haritada işaretlenmesi, saldırıya uğrayan bölge işareti | hud §5.1 / seviye §7.8 — cila, M2 AC'si değil |
| R2 savunma kaydırması | Seviye §4.2 — KAPALI |
| `BATTLE_HELD_DEFENSE` üretimi | W-5 — Perde 1 üretmez; anahtar korunur, kod gerekmez |
| Perde 2 bağlantısı ötesi | Seviye §14 UNRESOLVED; K = 2 |
| ×0.5 Ruh yedeği, eşik 9 → 8, başkent F-E2 muafiyeti | Koşullu — yalnız C-96 ölçümü tetiklerse (kendi görevleri o zaman açılır) |
| 12 maddelik playtest, medyan T10–15 (kabul #9, #10), enemy-layers AC16–AC18 | ADVISORY, kullanıcı oynar → C-48 (`/vertical-slice`) kapsamında |
| Ana dil incelemesi (Perde 1 metinleri) | K-03'e eklenir (kullanıcı aksiyonu) |
| `TURN_SUMMARY_QUIET`, gelir/takviye özette | battle-report Q5/Q6 — bilinçli olarak yok |
| AccessKit / ekran okuyucu | Kapsam dışı (scene-screens Q9) |

---

## 4. Kullanıcıya gidecek kapsam kararları (3, her biri tek öneri)

1. **AC21 başarısız olursa ayar sırası.** Öneri: C-95'te replay S-purify > T16 çıkarsa önce `attack_start_turn` 5 → 6, yetmezse başkent takviyesi (`curcet_otagi` E_r) 1 → her 2 turda 1 (UD: tamsayı veri biçimi), garnizon en son; her adımda diğer senaryolar T10–18'de kalmalı. Bu sırayı şimdiden onaylamak C-95'i kullanıcı beklemeden kapatır; Kök Böri'nin sözü değişmez (D1).
2. **Sanat C-47'yi bloklamasın.** Öneri: Perde 1 illüstrasyonları, E5 ikonları, `DefeatPanel` teması ve birim sprite'ları C-46'da kalır; C-47 story'leri düz zemin / yer tutucu ikonla "Done" sayılır (AC-E1-9 zaten bunu karşılıyor). Birim sprite'ları M2'de **yapılmaz** (sayı etiketi kalır) — C-48 vertical slice incelemesinde yeniden değerlendirilir.
3. **Kuyruk yerleşimi.** Öneri: C-70…C-99 kuyruğa C-48'den önce eklenir; C-47 bunların şemsiyesi olarak `[~]` kalır ve hepsi `[x]` olunca kapanır (kilometre taşı koruma kuralı gereği C-47 birleştirilmez/silinmez). C-42 kullanıcı playtest'ini beklerken (a) grubu (C-70…C-76) başlayabilir — Prolog demosunu da iyileştirdiği için C-42 playtest'inden önce bitirilmesi tercih edilir.


---

## 5. Kullanıcı kararları (2026-10-22)

1. **AC21 tutmazsa ayar sırası:** `attack_start_turn` 5 → 6 → başkent takviyesi seyreltme → garnizon (en son). Kök Böri'nin sözü değişmez. C-95 bu sırayla kullanıcıyı beklemeden kapanır, sonuç bildirilir.
2. **Sanat C-47'yi bloklamaz:** story'ler düz zemin / yer tutucu ikonla Done sayılır; sanat C-46'da kalır. Birim sprite'ları M2'de yok, C-48'de yeniden değerlendirilir.
3. **Kuyruk:** C-70…C-99 kuyruğa C-48'den önce eklendi; C-47 şemsiye `[~]`, hepsi `[x]` olunca kapanır. Başlangıç: (a) grubu, C-70.

> Not: `/create-stories` ayrı story dosyaları yerine story'ler bu belgede (§2) ve `production/continuation.md` kuyruğunda tutulur (proje kuyruğu tek doğruluk kaynağı).
