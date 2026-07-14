# Technical Preferences

## Engine & Language

- **Engine**: Godot 4.7
- **Language**: GDScript (static typing zorunlu)
- **Rendering**: Godot 2D renderer (Canvas)
- **Physics**: Godot built-in 2D physics (Jolt default in 4.7)

## Display & Scaling

- **Base Resolution**: 1920 × 1080 (strateji haritası için yüksek çözünürlük, sulu boya detayı korunmalı)
- **Default Window Size**: 1920 × 1080
- **Scale Mode**: `canvas_items`
- **Aspect**: `keep`
- **Integer Scaling**: Kapalı (sulu boya sanat stili, piksel-mükemmellik gerekmiyor)
- **MSDF Fonts**: Açık — tüm fontlarda MSDF aktif olmalı (bulanık font önlemi)
- **FPS Limit**: 60 FPS (sıra tabanlı oyun, GPU gereksiz yüklenmemeli)

## Input & Platform

- **Target Platforms**: PC (Steam)
- **Input Methods**: Keyboard/Mouse (birincil), Gamepad (opsiyonel)
- **Primary Input**: Keyboard/Mouse — harita tıklama, menü navigasyonu
- **Gamepad Support**: Partial (post-launch hedef)
- **Touch Support**: None
- **Platform Notes**: Steam Deck uyumluluğu post-launch değerlendirilecek

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

- **ADR-001**: Context-based hierarchical architecture — root_context → game_context / menu_context
- **ADR-002**: Feature encapsulation — her sistem kendi klasöründe, minimal dış bağımlılık
- **ADR-003**: Dependency injection — bind_services() pattern ile servis bağlama
- **ADR-004**: State segregation — game state objeleri sadece veri tutar, mantık controller'larda

## Godot Project Settings Checklist

Proje oluşturulduğunda aşağıdaki ayarlar yapılmalı:

- [ ] `display/window/size/viewport_width`: 1920
- [ ] `display/window/size/viewport_height`: 1080
- [ ] `display/window/size/window_width_override`: 1920
- [ ] `display/window/size/window_height_override`: 1080
- [ ] `display/window/stretch/mode`: canvas_items
- [ ] `display/window/stretch/aspect`: keep
- [ ] `debug/gdscript/warnings/untyped_declaration`: WARN
- [ ] `debug/gdscript/warnings/inferred_declaration`: WARN
- [ ] `debug/gdscript/warnings/unsafe_property_access`: WARN
- [ ] `debug/gdscript/warnings/unsafe_cast`: WARN
- [ ] `debug/gdscript/warnings/unsafe_call_argument`: WARN
- [ ] `application/run/max_fps`: 60
- [ ] `gui/theme/default_font_multichannel_signed_distance_field`: true

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
