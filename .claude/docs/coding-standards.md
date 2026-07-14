# Coding Standards

- All game code must include doc comments on public APIs
- Every system must have a corresponding architecture decision record in `docs/architecture/`
- Gameplay values must be data-driven (external config), never hardcoded
- All public methods must be unit-testable (dependency injection over singletons)
- Commits must reference the relevant design document or task ID
- **Commit messages**: Use Conventional Commits format — `feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`. Reference the story or task ID in the body (e.g., `Story: EPIC-001-S02`).
- **Verification-driven development**: Write tests first when adding gameplay systems.
  For UI changes, verify with screenshots. Compare expected output to actual output
  before marking work complete. Every implementation should have a way to prove it works.

## GDScript Standards

- **Static typing zorunlu**: Tüm değişkenler, parametreler ve dönüş değerleri tip belirtmeli.
  Dinamik tipleme kabul edilmez. Editör uyarıları açık tutulmalı (untyped_declaration: WARN).
- **`$` node erişimi kullanma**: `$NodeName` yerine `@export` ile node referansları bağla.
  `$` erişimi tip güvenliği sağlamaz ve refactor'da kırılganlaşır.
- **Script düzeni** (GDScript style guide sırası):
  1. `class_name`
  2. `extends`
  3. Sinyaller (`signal`)
  4. Enum'lar
  5. Sabitler (`const`)
  6. `@export` değişkenler
  7. Public değişkenler
  8. Private değişkenler (`_` prefix)
  9. `@onready` değişkenler
  10. `_ready()`, `_process()`, `_physics_process()` (yaşam döngüsü)
  11. Public metotlar
  12. Private metotlar (`_` prefix)
- **Preload kuralları**:
  - Küçük, sık kullanılan sahneler için `preload()` kullan (ör: mermi, efekt)
  - Preload'u kullanıldığı yere yakın tut — sahip olan node ağaçtan çıkınca referans da temizlenmeli
  - Büyük sahneler (bölüm haritaları, menüler) için `load()` veya `ResourceLoader.load_threaded_request()` kullan
  - Kalıcı node'lardan (root_context gibi) asla büyük sahne zinciri preload etme
- **Yön çevirme**: `Sprite2D.flip_h` kullan, `scale.x = -1` YASAK (bkz. technical-preferences.md → Forbidden Patterns)
- **Sprite animasyonu**: Sprite kaydırma için `offset` kullan, `position` değil. Position = oyun gerçeği, Offset = görsel ayarlama.
- **Ekran dışı optimizasyon**: Ekran dışındaki düşmanlar/NPC'ler için `VisibleOnScreenNotifier2D` veya `VisibleOnScreenEnabler2D` kullan — gereksiz process/physics çağrısı önlenir.

## Localization Standards

- **Varsayılan dil**: İngilizce (en). Tüm UI metinleri İngilizce yazılır.
- **Çeviri dosyası**: `assets/locale/translations.csv` — tek CSV, tüm diller yan yana.
- **Metin key formatı**: `SCREAMING_SNAKE_CASE` — ör: `NEW_CAMPAIGN`, `BATTLE_REPORT`, `CHAPTER_1_TITLE`
- **Hardcoded metin YASAK**: Tüm oyuncu-görünür metinler translation key üzerinden `tr()` fonksiyonu ile çağrılmalı.
  Sahne dosyalarında doğrudan key yazılır (Godot otomatik `tr()` uygular), script'lerde `tr("KEY")` kullanılır.
- **Dinamik metin**: Format string'lerde `tr()` ile birleştir: `"%s: %d" % [tr("GOLD"), amount]`
- **Yeni metin eklerken**: Önce `translations.csv`'ye key + en sütununu ekle, sonra diğer dilleri doldur.
  Çeviri eksik kalabilir — `locale/fallback="en"` sayesinde İngilizce gösterilir.
- **Desteklenen diller**: en, tr, de, fr, es, zh, ja, ko, ru, pt, ar (11 dil)

# Design Document Standards

- All design docs use Markdown
- Each mechanic has a dedicated document in `design/gdd/`
- Documents must include these 8 required sections:
  1. **Overview** -- one-paragraph summary
  2. **Player Fantasy** -- intended feeling and experience
  3. **Detailed Rules** -- unambiguous mechanics
  4. **Formulas** -- all math defined with variables
  5. **Edge Cases** -- unusual situations handled
  6. **Dependencies** -- other systems listed
  7. **Tuning Knobs** -- configurable values identified
  8. **Acceptance Criteria** -- testable success conditions
- Balance values must link to their source formula or rationale

# Testing Standards

## Test Evidence by Story Type

All stories must have appropriate test evidence before they can be marked Done:

| Story Type | Required Evidence | Location | Gate Level |
|---|---|---|---|
| **Logic** (formulas, AI, state machines) | Automated unit test — must pass | `tests/unit/[system]/` | BLOCKING |
| **Integration** (multi-system) | Integration test OR documented playtest | `tests/integration/[system]/` | BLOCKING |
| **Visual/Feel** (animation, VFX, feel) | Screenshot + lead sign-off | `production/qa/evidence/` | ADVISORY |
| **UI** (menus, HUD, screens) | Manual walkthrough doc OR interaction test | `production/qa/evidence/` | ADVISORY |
| **Config/Data** (balance tuning) | Smoke check pass | `production/qa/smoke-[date].md` | ADVISORY |

## Automated Test Rules

- **Naming**: `[system]_[feature]_test.[ext]` for files; `test_[scenario]_[expected]` for functions
- **Determinism**: Tests must produce the same result every run — no random seeds, no time-dependent assertions
- **Isolation**: Each test sets up and tears down its own state; tests must not depend on execution order
- **No hardcoded data**: Test fixtures use constant files or factory functions, not inline magic numbers
  (exception: boundary value tests where the exact number IS the point)
- **Independence**: Unit tests do not call external APIs, databases, or file I/O — use dependency injection

## What NOT to Automate

- Visual fidelity (shader output, VFX appearance, animation curves)
- "Feel" qualities (input responsiveness, perceived weight, timing)
- Platform-specific rendering (test on target hardware, not headlessly)
- Full gameplay sessions (covered by playtesting, not automation)

## CI/CD Rules

- Automated test suite runs on every push to main and every PR
- No merge if tests fail — tests are a blocking gate in CI
- Never disable or skip failing tests to make CI pass — fix the underlying issue
- Engine-specific CI commands:
  - **Godot**: `godot --headless --script tests/gdunit4_runner.gd`
  - **Unity**: `game-ci/unity-test-runner@v4` (GitHub Actions)
  - **Unreal**: headless runner with `-nullrhi` flag
