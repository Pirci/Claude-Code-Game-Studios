# ADR-0009: Localization & Pixel-Font Pipeline

## Status

Accepted (2026-10-19 — C-61; records the as-built pipeline from C-03…C-09, C-26 and adds a
glyph-coverage rule. Night-mode decision, recommended option accepted per user instruction;
re-validate at the next `/architecture-review`.)

## Date

2026-10-19

## Last Verified

2026-10-19 (Godot 4.7.1 — headless tests, Xvfb screenshots in en/de/ar)

## Decision Makers

Technical direction (night-mode autonomous run).

## Summary

ULUS ships in 11 languages (en, tr, de, fr, es, zh, ja, ko, ru, pt, ar) on a 640×360 pixel-art
canvas. Text must stay pixel-crisp in every script, including Arabic (RTL) and CJK. We keep one
CSV translation table with `tr()` keys, a pixel-font chain (Fusion Pixel 12px, GNU Unifont 16px)
used only at native sizes or integer multiples, a theme-wide font switch for Arabic, locale-driven
layout direction for content (the map is never mirrored), translator-owned format strings and
number grouping, and a test that every translation is drawable by its locale's native font.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | UI / Localization / Text |
| **Knowledge Risk** | MEDIUM — `TextServer` font import options and `language_support` predate the cutoff but were re-checked on 4.7.1; `TranslationServer.format_number()` does **not** group digits (verified 4.7.1) |
| **References Consulted** | `docs/engine-reference/godot/modules/ui.md`, `VERSION.md`, art bible §7 "Tipografi" |
| **Post-Cutoff APIs Used** | `Control.grab_focus(hide_focus)` / `has_focus(ignore_hidden_focus)` only indirectly (FocusReveal, C-25); none in the text pipeline |
| **Verification Required** | Arabic shaping/bidi read by a native speaker (manual); CJK legibility at 12px on real displays |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (RootContext owns `LocaleFontController`), ADR-0002 (`features/localization/`), ADR-0003 (injection), ADR-0007 (locale persisted in the settings file — C-56) |
| **Enables** | Every player-facing screen (C-35 scene flow, C-41/C-45 reports, C-54 narrative text keys) |
| **Blocks** | None |
| **Ordering Note** | Locale is session-only until the settings file (ADR-0007, C-56) |

## Context

### Problem Statement
Pixel fonts are crisp only at their native pixel size (or integer multiples); a glyph that falls
back to a font with another native size is scaled and blurs. Arabic needs RTL shaping and a
different font size; CJK needs regional glyph forms; long translations (German) must not break
the 640×360 layout; and translators — not code — must control word order, capitalisation and
number formatting.

### Current State (before this ADR)
Built incrementally (C-03…C-09: fonts, theme, settings language picker, Arabic switch, RTL;
C-26: `PER_TURN` format key) with rules spread across the art bible and coding standards but no
ADR (TR-concept-006 gap in the C-17 review).

### Constraints
- 640×360 canvas, integer scaling, nearest filtering (technical preferences).
- Font sizes only native or integer multiples: Fusion 12/24/36, Unifont 16/32 (art bible §7).
- No hardcoded player-visible text; default language English; 11 languages.
- No autoload; services injected (ADR-0003).

### Requirements
- One source of truth for strings, translator-friendly, diffable in git.
- Crisp glyphs for every string in every supported language.
- Arabic RTL content without mirroring the map.
- Locale-correct numbers (thousands separator) and word order.

## Decision

1. **Strings** — `game/assets/locale/translations.csv` (`key,en,tr,de,fr,es,zh,ja,ko,ru,pt,ar`),
   imported by Godot's CSV importer into compressed `.translation` files registered in
   `internationalization/locale/translations`; fallback `en`. Keys are `SCREAMING_SNAKE_CASE`;
   scenes put the key in `text` (auto-translated), scripts call `tr("KEY")`.
2. **Translator-owned formatting** — word order, units and case live in the translation:
   format keys carry placeholders (`PER_TURN` = `"%s / turn"`, de `"%s / Runde"`); code never
   calls `to_upper()` / `to_lower()` / `capitalize()` on player-visible text (C-26; Turkish
   i/İ, German noun capitals, ß).
3. **Numbers** — `NumberFormatter.format_int()` groups digits with the per-language
   `THOUSANDS_SEPARATOR` key (fr/ru U+00A0); Western digits in all languages.
4. **Font chain** — the project theme's default font is a `FontVariation`
   (`assets/fonts/default_font.tres`): Fusion Pixel 12px Latin → ja → ko → zh_hans → Unifont.
   Every font is imported with antialiasing off, hinting none, subpixel positioning off, MSDF off,
   mipmaps off, `allow_system_fallback = false`; the Fusion subsets set `language_support` so
   regional glyph forms follow the locale.
5. **Arabic** — `LocaleFontController` (`features/localization/`, owned by `RootContext`,
   re-applied on `NOTIFICATION_TRANSLATION_CHANGED`) switches the theme's default font **and**
   size to Unifont 16px when the language is `ar`, instead of per-glyph fallback (which would
   mix 12px and scaled 16px glyphs).
6. **Direction** — content containers use `LAYOUT_DIRECTION_APPLICATION_LOCALE` (Arabic → RTL);
   the map and map-anchored chrome stay `LTR` (map labels, the info panel frame) — geography is
   never mirrored.
7. **Language picker** — each language name is a pre-rendered pixel icon in its own font
   (`tools/asset-pipeline/generate_language_name_icons.gd`), because one theme font cannot draw
   every script at native size in the same list.
8. **Glyph coverage (new rule)** — every translated string must be fully covered by its
   locale's native font set (Fusion subsets for 10 languages, Unifont for `ar`). Symbols missing
   from Fusion Pixel — `−` U+2212, `⚠` U+26A0, `✕` U+2715, `✓` U+2713, U+202F — are **not used in
   text**: status symbols are drawn as pixel icons (added to the UI icon generator, e.g.
   `generate_ui_theme_icons.gd`, when a screen first needs them), and the loss sign is ASCII `-`. Enforced by `tests/unit/localization/glyph_coverage_test.gd`.
9. **Fit** — buttons grow with text (`custom_minimum_size.x` as floor), map labels truncate
   with `…` (`OVERRUN_TRIM_ELLIPSIS`); translator guideline: region names ≤ 12 characters (en).

### Architecture

```
translations.csv ──import──▶ *.translation ──▶ TranslationServer (locale, fallback en)
                                                   │ tr("KEY") / scene keys
                                                   ▼
RootContext ──owns──▶ LocaleFontController ──▶ project Theme.default_font / default_font_size
                       (ar → Unifont 16; else Fusion chain 12)
SettingsScreen ──▶ TranslationServer.set_locale(code) ──▶ NOTIFICATION_TRANSLATION_CHANGED
NumberFormatter.format_int(n) ◀── THOUSANDS_SEPARATOR key
```

### Key Interfaces

```gdscript
class_name LocaleFontController extends RefCounted
func _init(theme: Theme) -> void
func add_override(language: String, font: Font, size: int) -> void
func apply(locale: String) -> void

class_name NumberFormatter extends RefCounted
static func format_int(value: int) -> String
static func current_separator() -> String
static func group_digits(value: int, separator: String) -> String
```

### Implementation Guidelines
- New text: add the key + `en` to the CSV first, then the other columns; missing columns fall
  back to English.
- Never set a `font_size` override that is not a native size or integer multiple.
- A new symbol or script: run the glyph-coverage test; if it fails, draw an icon or pick a
  covered character — do not add a system-font fallback.
- New HUD/panel containers: decide explicitly — map-anchored → `LTR`, content → application locale.

## Alternatives Considered

### Alternative 1: gettext PO files
- **Pros**: plural forms, translator tools, per-language files. **Cons**: 11 files to keep in
  sync, less visible side-by-side review; no plural need yet. **Rejected for now** — revisit if
  plural forms are needed (Godot CSV has no plural support).

### Alternative 2: Vector (TTF/MSDF) font with smooth scaling
- **Cons**: breaks the pixel-art grid (art bible). **Rejected.**

### Alternative 3: Unifont 16px for every language
- **Pros**: one font, wide coverage. **Cons**: 16px body text does not fit the 640×360 layouts
  designed for 12px; Fusion is far more legible. **Rejected.**

### Alternative 4: Per-glyph fallback for Arabic (keep the 12px chain)
- **Cons**: Arabic glyphs come from a 16px font drawn at 12px → scaled, blurred. **Rejected** in
  favour of the theme-wide switch.

## Consequences

### Positive
- Every string is crisp in every language, and a test guards it.
- Translators own word order, capitalisation and units; code stays language-agnostic.
- Arabic works without mirroring the map.

### Negative
- One CSV invites merge conflicts when several people translate at once.
- Status symbols need pixel icons instead of text glyphs (small art cost).
- Arabic layouts are taller (16px lines); panels must grow, not clip.

### Neutral
- Locale persistence waits for the settings file (C-56).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| A translation adds a glyph Fusion lacks | Medium | Medium | `glyph_coverage_test.gd` fails CI |
| Long translations overflow HUD | Medium | Low | Buttons grow, labels ellipsize; de/ar screenshots per UI task |
| Arabic shaping or wording wrong | Medium | Medium | Native-speaker review before release |
| Plural forms needed later | Low | Medium | Migrate to PO (Alternative 1) |

## Performance Implications

| Metric | Expected | Budget |
|--------|----------|--------|
| Memory | Five pixel fonts (CJK subsets largest), well under 10 MB | 512 MB |
| CPU | Theme font swap only on locale change | 16.6 ms |

## Migration Plan
As-built — no code migration. C-61 adds this ADR and the glyph-coverage test. Follow-ups:
the status-symbol icons and the `-` loss sign land with the first UI that shows them (C-38 info
panel corruption rows, C-41/C-45 reports); locale persistence with C-56.

## Validation Criteria
- [x] All 11 locales load; every key renders with its native font set (`glyph_coverage_test.gd`).
- [x] `PER_TURN` has one placeholder in every language; de keeps "Runde" capitalised (`per_turn_label_test.gd`).
- [x] Thousands separator per language (`number_formatter_test.gd`).
- [x] Arabic switches the theme to Unifont 16 and back (`locale_font_controller_test.gd`).
- [ ] Native-speaker review of ar/zh/ja/ko strings (manual, before release).

## GDD Requirements Addressed

| Source | Requirement | How |
|--------|-------------|-----|
| TR-concept-006 (`game-concept.md`) | 11 languages via `tr()`/CSV, no hardcoded text | Decision 1–3 |
| Art bible §7 Tipografi | Native pixel sizes, Arabic Unifont 16, no programmatic case | Decision 2, 4, 5 |
| Art bible §4/§7 | Gain/loss and warning symbols readable | Decision 8 (icons, ASCII `-`) |

## Related
- ADR-0001, ADR-0003, ADR-0007 (settings file), `.claude/docs/coding-standards.md` "Localization Standards".
- Code: `game/features/localization/`, `game/contexts/root_context/root_context.gd`,
  `game/ui/screens/settings_screen.gd`, `game/assets/fonts/`, `game/assets/locale/`.
