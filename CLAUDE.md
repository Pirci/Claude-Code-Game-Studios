# TURAN: Kızılelma — Game Studio Agent Architecture

Indie oyun geliştirme; 36 Claude Code subagent'ı, her biri kendi alanının sahibi.

- **Oyun**: TURAN: Kızılelma — sıra tabanlı strateji; kartla şehir kurma + kule savunması karışımı
  (tür pivotu 2026-11-14; yeniden tasarım `production/continuation.md` → C-103. Mevcut kod ve
  GDD'ler önceki büyük strateji tasarımını uygular).
- **Engine**: Godot 4.7 · GDScript (static typing) · GDUnit4 · Git (trunk-based)
- **İletişim dili**: Türkçe
- **Engine bilgisi kesintisi**: modelin Godot bilgisi ~4.3'te biter; 4.4–4.7 API'si için önce
  `docs/engine-reference/godot/` (VERSION.md, breaking-changes.md, deprecated-apis.md) okunur.

## Project Structure

@.claude/docs/directory-structure.md

## Technical Preferences

@.claude/docs/technical-preferences.md

## Coordination & Token Budget

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**Kullanıcı yönlendirir.** Kullanıcıya ait kararlar (tasarım seçimi, kapsam, yeni bağımlılık):
**Soru → Seçenekler (tek öneriyle) → Karar → Taslak → Onay.**

- Onaylanmış iş (kuyruk görevi, açık kullanıcı talimatı) yeniden onay istemeden uygulanır.
- Onaysız yeni dosya/çok dosyalı değişiklik: önce özet göster, sonra yaz.
- Kullanıcı talimatı olmadan commit yok ("devam" protokolü ve açık talimat = talimat).

Ayrıntı: `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` (gerekince okunur).

## Devam Protokolü ("devam" komutu)

Kullanıcı yalnızca **"devam"** yazarsa (büyük/küçük harf, "devam et", "Devam."
fark etmez): `production/continuation.md` dosyasını oku ve oradaki **Devam
Protokolü**'nü adım adım uygula — yarım kalan işi bitir, yoksa kuyruktaki ilk
`[ ]` görevi yap, doğrula, commit'le, indeksi güncelle. Her "devam" = bir görev.
Kapanmış görev tekrar yapılmaz; keşfedilen yeni işler kuyruğa eklenir.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md
