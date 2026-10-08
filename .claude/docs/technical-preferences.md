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

## Allowed Libraries / Addons

- **GDUnit4** — Otomatik test framework'ü

## Architecture Decisions Log

- **ADR-0001** (Proposed): Context-based hierarchical architecture — root_context → game_context / menu_context. → [adr-0001](../../docs/architecture/adr-0001-context-based-hierarchical-architecture.md)
- **ADR-0002** (Proposed): Feature encapsulation — her sistem kendi klasöründe, minimal dış bağımlılık. → [adr-0002](../../docs/architecture/adr-0002-feature-encapsulation.md)
- **ADR-0003** (Proposed): Dependency injection — bind_services() pattern ile servis bağlama. → [adr-0003](../../docs/architecture/adr-0003-dependency-injection.md)
- **ADR-0004** (Proposed): State segregation — game state objeleri sadece veri tutar, mantık controller'larda. → [adr-0004](../../docs/architecture/adr-0004-state-segregation.md)

> Tümü `/architecture-decision` ile geriye dönük yazıldı (as-built). Taze bir oturumda `/architecture-review` çalıştırıp doğruladıktan sonra Status → Accepted yapılabilir.

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
