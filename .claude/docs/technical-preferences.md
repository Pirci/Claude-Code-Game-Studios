# Technical Preferences

## Engine & Language

- **Engine**: Godot 4.7
- **Language**: GDScript (static typing zorunlu)
- **Rendering**: Godot 2D renderer (Canvas)
- **Physics**: Godot built-in 2D physics (Jolt default in 4.7)

## Display & Scaling

- **Art Style**: Pixel art (2026-10-07 itibarıyla; önceki yön sulu boyaydı)
- **Base Resolution**: 640 × 360 (×3 = 1080p, ×6 = 4K — tam kat ölçekleme)
- **Default Window Size**: 1920 × 1080
- **Scale Mode**: `viewport` (her şey 640×360'ta çizilip büyütülür — gerçek pixel grid)
- **Aspect**: `keep`
- **Integer Scaling**: Açık (`window/stretch/scale_mode="integer"`)
- **Texture Filter**: Nearest (`rendering/textures/canvas_textures/default_texture_filter=0`)
- **Pixel Snap**: `2d/snap/snap_2d_transforms_to_pixel` ve `snap_2d_vertices_to_pixel` açık
- **Fonts**: Pixel fontlar — MSDF, antialiasing, hinting ve subpixel **kapalı**, sistem font fallback'i kapalı.
  - **Fusion Pixel 12px** (OFL) — en/tr/de/fr/es/ru/pt + zh/ja/ko (`language_support` ile bölgesel glif biçimi)
  - **GNU Unifont 16px** (OFL) — Arapça; `LocaleFontController` dil `ar` olunca temayı Unifont 16'ya geçirir
  - Font boyutları sadece native boyut veya tam katı olabilir (Fusion: 12/24/36, Unifont: 16/32). Başka `font_size` override'ı fontu bozar.
- **FPS Limit**: 60 FPS (sıra tabanlı oyun, GPU gereksiz yüklenmemeli)

## Input & Platform

- **Target Platforms**: PC (Steam)
- **Input Methods**: Keyboard/Mouse (tek girdi yöntemi)
- **Primary Input**: Keyboard/Mouse — harita tıklama, menü navigasyonu; klavye ile Tab/ok tuşu odak gezinmesi desteklenir
- **Gamepad Support**: None (2026-10-08 kararı — hedeflenmiyor)
- **Touch Support**: None
- **Platform Notes**: Sadece PC (Steam). Konsol, mobil ve Steam Deck hedeflenmiyor (2026-10-08 kararı)

## Naming Conventions

- **Classes**: PascalCase (`ArmyController`, `BozkurtSpirit`)
- **Variables**: snake_case (`current_gold`, `army_size`)
- **Signals/Events**: snake_case, geçmiş zaman (`turn_ended`, `battle_resolved`, `chapter_unlocked`)
- **Files**: snake_case (`army_controller.gd`, `campaign_map.tscn`)
- **Scenes/Prefabs**: snake_case (`game_context.tscn`, `battle_report.tscn`)
- **Constants**: SCREAMING_SNAKE_CASE (`MAX_ARMY_SIZE`, `GOLD_PER_TURN`)

## Performance Budgets

- **Target Framerate**: 60 FPS
- **Frame Budget**: 16.6 ms
- **Draw Calls**: < 200 (2D harita + UI)
- **Memory Ceiling**: 512 MB (10 bölüm harita + asset'ler — preload stratejisiyle yönetilecek)

## Testing

- **Framework**: GDUnit4
- **Minimum Coverage**: Tüm formül/matematik fonksiyonları, state transitions, combat resolution
- **Required Tests**: Savaş çözümleme formülleri, kaynak hesaplamaları, Bozkurt bonus sistemi, bölüm unlock mantığı

## Forbidden Patterns

- **Negatif scale ile yön çevirme**: Node'un X scale'ini -1 ile çarpmak YASAK. Görsel çevirme için `Sprite2D.flip_h` kullan, fizik node'larını açıkça yeniden konumlandır. Negatif scale fizik alanlarını, collision shape'leri ve raycast'leri bozar — görsel olarak doğru gözükür ama fizik gerçeği farklıdır.
- **Global autoload singleton'lar**: Autoload kullanmak YASAK. Dependency injection ile servisler bağlanacak. Autoload'lar bağımlılık takibini imkansız kılar ve tight coupling yaratır.
- **Merkezi signal hub (Event Bus)**: Tek bir sınıfta tüm sinyalleri toplamak YASAK. Her sinyal, sahip olduğu node'da tanımlanmalı. "Call down, signal up" prensibi uygulanacak.
- **Kalıcı node'lardan büyük sahne preload'u**: Main game manager gibi asla ağaçtan çıkmayan node'lar büyük sahneleri preload etmemeli. Preload sadece küçük, yeniden kullanılabilir sahneler için ve kullanıldığı yere yakın olmalı (ör: oyuncu → mermi sahnesi). Büyük sahneler için `load()` veya `ResourceLoader.load_threaded_request()` kullan.
- **Sprite2D.position ile animasyon kaydırma**: Sprite'ı animasyon için kaydırırken `position` yerine `offset` kullan. `position` çocuk node'lara miras kalır (marker'lar, collision shape'ler kayar), `offset` sadece texture'ı etkiler. Position = oyun gerçeği, Offset = animasyon illüzyonu.
- **Dosya tipi bazlı klasörleme**: `scripts/`, `scenes/`, `art/` gibi dosya tipine göre klasörleme YASAK. Feature bazlı klasörleme kullan (ör: `features/combat/`, `features/army/`). Dosya tipine göre filtreleme zaten editörde yapılabiliyor.
- **Tight coupling**: Bir script'in doğrudan parent'ını bilmesi YASAK. Çocuk node'lar parent'a sinyal ile iletişim kurar, parent çocuğa doğrudan çağrı yapar ("call down, signal up").

## Version Control Notes

- **`.uid` dosyaları commit edilir** (Godot 4.4+ önerisi; C-24, 2026-10-19). Yeni script /
  shader eklerken yanındaki `.uid` de commit'e girer. Sahneler script'lere hâlâ yol ile
  referans verebilir; UID'ler klonlar arasında aynı kalır.
- `.godot/` ve `reports/` takip edilmez.

## Allowed Libraries / Addons

- **GDUnit4** — Otomatik test framework'ü

## Architecture Decisions Log

- **ADR-0001** (Accepted 2026-10-19): Context-based hierarchical architecture — root_context → game_context / menu_context. → [adr-0001](../../docs/architecture/adr-0001-context-based-hierarchical-architecture.md)
- **ADR-0002** (Accepted 2026-10-19): Feature encapsulation — her sistem kendi klasöründe, minimal dış bağımlılık. → [adr-0002](../../docs/architecture/adr-0002-feature-encapsulation.md)
- **ADR-0003** (Accepted 2026-10-19): Dependency injection — bind_services() pattern ile servis bağlama. → [adr-0003](../../docs/architecture/adr-0003-dependency-injection.md)
- **ADR-0004** (Accepted 2026-10-19): State segregation — game state objeleri sadece veri tutar, mantık controller'larda. → [adr-0004](../../docs/architecture/adr-0004-state-segregation.md)
- **ADR-0005** (Accepted 2026-10-19): AI mimarisi — saf `decide()` servisleri, MapController uygular. → [adr-0005](../../docs/architecture/adr-0005-ai-architecture.md)
- **ADR-0006** (Accepted 2026-10-19): Additive modifier / stat pipeline — kaynak anahtarlı `StatModifier` + saf `StatResolver`, çift sayım yok. → [adr-0006](../../docs/architecture/adr-0006-additive-modifier-stat-pipeline.md)
- **ADR-0008** (Accepted 2026-10-19, C-23): Ses mimarisi — RootContext'in kalıcı `AudioController`'ı, `Master → Music/SFX` bus düzeni, data-driven `SfxLibrary`. → [adr-0008](../../docs/architecture/adr-0008-audio-architecture.md)
- **ADR-0007** (Accepted 2026-10-19): Save/load — versiyonlu JSON + saf `SaveSerializer`, atomik `.bak` rotasyonu, tur sonu otomatik kayıt; ADR-0004 göç planını kısmen supersede eder. → [adr-0007](../../docs/architecture/adr-0007-save-load-persistence.md)
- **ADR-0012** (Accepted 2026-10-19, C-62): Scene flow & chapter loading — saf `SceneFlow` durum makinesi (RootContext eylemleri yürütür), `NarrativeContext` + `ChapterSelectContext`, harita üstü modallar `GameContext` `ModalQueue`'da, `CampaignDefinition`/`SceneDefinition.map_path` ile bölüm `load()`'u, kayıt S2 (`scene_entry` ikinci yuva) / S3. → [adr-0012](../../docs/architecture/adr-0012-scene-flow-chapter-loading.md)
- **ADR-0011** (Accepted 2026-10-19, C-60): Presentation layer — pasif görünümler (veri al, niyet sinyali gönder), tek sunucu `GameContext` her değişiklikten sonra `_refresh_views()`, aynı saf kurallardan `HudModel` (gelir tahmini, yayılım göstergesi), `MoveOutcome` ile beslenen rapor modalları, tek seferde bir modal (`ModalQueue`; harita girdisi kilitli, odak geri verilir). → [adr-0011](../../docs/architecture/adr-0011-presentation-layer-reports.md)
- **ADR-0010** (Accepted 2026-10-19, C-59): Move resolution — saf `MoveResolver.resolve()` → `MoveOutcome`, uygulama yalnız outcome'u yazar (`ArmyController.apply_outcome`, arındırmada `SpiritController.apply_purification`); önizleme / oyuncu / düşman aynı yol; `CombatResolver.resolve_effective` (M2), saf `IncomeRules` (F2 = HUD tahmini). → [adr-0010](../../docs/architecture/adr-0010-move-resolution-outcome-apply.md)
- **ADR-0009** (Accepted 2026-10-19, C-61): Localization & pixel-font pipeline — tek CSV + `tr()` key'leri, çevirmen sahipli biçim key'leri (`PER_TURN`), Fusion 12 / Unifont 16 zinciri (yalnız native boyut), Arapça tema geçişi, harita LTR / içerik locale yönü, glif kapsama testi (Fusion'da olmayan semboller ikon). → [adr-0009](../../docs/architecture/adr-0009-localization-pixel-font-pipeline.md)

> Tümü `/architecture-decision` ile yazıldı; `/architecture-review` (2026-10-19, C-17 — CONCERNS, bağımsız technical-director + godot-specialist incelemesi, düzeltmeler uygulandı) sonrası **Accepted**. Eksik ADR yok: Localization ADR-0009, Move Resolution ADR-0010, Presentation ADR-0011, Scene flow ADR-0012 ile kapandı (bkz. [rapor](../../docs/architecture/architecture-review-2026-10-19.md)).

## Godot Project Settings Checklist

Proje oluşturulduğunda aşağıdaki ayarlar yapılmalı:

- [x] `display/window/size/viewport_width`: 640
- [x] `display/window/size/viewport_height`: 360
- [x] `display/window/size/window_width_override`: 1920
- [x] `display/window/size/window_height_override`: 1080
- [x] `display/window/stretch/mode`: viewport
- [x] `display/window/stretch/scale_mode`: integer
- [x] `display/window/stretch/aspect`: keep (varsayılan)
- [x] `rendering/textures/canvas_textures/default_texture_filter`: Nearest (0)
- [x] `rendering/2d/snap/snap_2d_transforms_to_pixel`: true
- [x] `rendering/2d/snap/snap_2d_vertices_to_pixel`: true
- [ ] `debug/gdscript/warnings/untyped_declaration`: WARN
- [ ] `debug/gdscript/warnings/inferred_declaration`: WARN
- [ ] `debug/gdscript/warnings/unsafe_property_access`: WARN
- [ ] `debug/gdscript/warnings/unsafe_cast`: WARN
- [ ] `debug/gdscript/warnings/unsafe_call_argument`: WARN
- [x] `application/run/max_fps`: 60
- [x] `gui/theme/default_font_multichannel_signed_distance_field`: false (pixel font — varsayılan)

## Debug Tools

Geliştirme sırasında aşağıdaki debug araçları oluşturulmalı:

- **God Mode**: Haritada serbest hareket, sınırsız kaynak, tüm bölümler açık — hızlı test için
- **Time Scale kontrol**: `Engine.time_scale` ile oyun hızı ayarlama (debug + efekt amaçlı)
- **Visible Collision Shapes**: Editörde collision debug açık tutulmalı

## Engine Specialists

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist
- **Shader Specialist**: godot-shader-specialist
- **UI Specialist**: godot-specialist (ayrı UI specialist gerekmiyorsa)
- **Additional Specialists**: —
- **Routing Notes**: Tüm oyun kodu GDScript, shader'lar Godot Shading Language

### File Extension Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| `.gd` (GDScript) | godot-gdscript-specialist |
| `.gdshader` / `.tres` (shader/material) | godot-shader-specialist |
| `.tscn` / `.scn` (sahne dosyaları) | godot-specialist |
| `.gdextension` (native plugin) | godot-gdextension-specialist |
| General architecture review | godot-specialist |
