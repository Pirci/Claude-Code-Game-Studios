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

## Architecture Decisions

Tümü **Accepted**; ayrıntı `docs/architecture/adr-00NN-*.md` (ilgili ADR işe başlamadan okunur),
genel resim `docs/architecture/architecture.md`.

| ADR | Karar (tek satır) |
|-----|-------------------|
| 0001 | Context hiyerarşisi: root_context → game / menu / narrative / chapter_select |
| 0002 | Feature encapsulation — sistem başına klasör |
| 0003 | Dependency injection — `bind_services()`; autoload yok |
| 0004 | State segregation — `state/` yalnız veri |
| 0005 | AI: saf `decide()` servisleri, MapController uygular |
| 0006 | `StatModifier` + saf `StatResolver`; `GameState.modifiers`'a doğrudan erişim yok |
| 0007 | Kayıt: versiyonlu JSON, saf `SaveSerializer`, atomik `.bak`; kullanıcı dosyası asla `load()` edilmez |
| 0008 | Ses: RootContext `AudioController`, `Master → Music/SFX`, `SfxLibrary` |
| 0009 | Yerelleştirme: tek CSV + `tr()`, yalnız native font boyutu, glif kapsama testi |
| 0010 | Hamle: saf `MoveResolver.resolve()` → `MoveOutcome`; uygulama yalnız outcome'u yazar |
| 0011 | Sunum: pasif görünümler, tek sunucu `GameContext`, `ModalQueue` |
| 0012 | Sahne akışı: saf `SceneFlow` durum makinesi, bölüm `load()` ile |

## Godot Project Settings

Ekran/ölçek/font ayarları `project.godot`'ta uygulanmış durumda (yukarıdaki değerler). GDScript
uyarıları (`untyped_declaration`, `inferred_declaration`, `unsafe_*`) WARN.

## Debug Tools

Geliştirme sırasında aşağıdaki debug araçları oluşturulmalı:

- **God Mode**: Haritada serbest hareket, sınırsız kaynak, tüm bölümler açık — hızlı test için
- **Time Scale kontrol**: `Engine.time_scale` ile oyun hızı ayarlama (debug + efekt amaçlı)
- **Visible Collision Shapes**: Editörde collision debug açık tutulmalı

## Engine Specialists

| Dosya / iş | Uzman |
|------------|-------|
| `.gd` | godot-gdscript-specialist |
| `.gdshader`, shader/material `.tres` | godot-shader-specialist |
| `.tscn` / `.scn`, UI, genel mimari | godot-specialist |

Tüm oyun kodu GDScript; C#, GDExtension, Unity/Unreal ve ağ uzmanları projeden kaldırıldı (2026-11-14).
