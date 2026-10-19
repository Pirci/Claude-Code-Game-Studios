# Sistem GDD İndeksi — ULUS: Blood of the Sky Wolf

*Türkçe alt-başlık: Gökkurt'un Kanı*
*Son Güncelleme: 2026-10-19* — son çapraz inceleme: [gdd-cross-review-2026-10-19.md](gdd-cross-review-2026-10-19.md) (**CONCERNS**, 0 engelleyici; uyarılar C-53 / C-49). Önceki: [2026-10-08](gdd-cross-review-2026-10-08.md) (FAIL)

Bu indeks tüm sistem GDD'lerini ve durumlarını takip eder. Yeni bir GDD
eklendiğinde buraya bir satır eklenmeli. Kaynak konsept: [game-concept.md](game-concept.md).

## Tasarım Sırası

Foundation → Core → Feature → Presentation → Polish

## Sistemler

| Sistem | Katman | Dosya | Durum | Öncelik | Bağımlılıklar |
| ---- | ---- | ---- | ---- | ---- | ---- |
| **Oyun Konsepti** | Foundation | [game-concept.md](game-concept.md) | Taslak (revize edildi) | — | — |
| **Oyun Durumu** (yalnızca veri: `GameState`, `MapState`, `RegionData` — ADR-0004) | Foundation | kod: `game/state/` (ayrı GDD yok; alanlar ilgili GDD'lerde) | Belgelenmiş (kod) | — | — |
| **Bölge Fethi / Harita** | Core | [region-map-system.md](region-map-system.md) | Designed | 1 | Ordu, Savaş, Kaynak, Ruh |
| **Kaynak Yönetimi** (altın + ordu üretimi; sürü arayüzü) | Core | [resource-system.md](resource-system.md) | Designed | 1 | Harita, Ordu, Ruh |
| **Ordu & Birim Sistemi** | Core | [army-system.md](army-system.md) | Designed | 1 | Savaş, Harita, Kaynak, Ruh |
| **Savaş Çözümü** (otomatik + rapor) | Core | [combat-system.md](combat-system.md) | Designed | 1 | Ordu, Harita, Ruh |
| **Kök Böri / Ruh Sistemi** (imza) | Feature | [spirit-system.md](spirit-system.md) | Designed | 2 | Harita, Ordu, Savaş, Kaynak, Oyun Durumu |
| **Katmanlı Düşman** (siyasi krallar; Erlik burada değil — C-29) | Feature | `enemy-layers.md` | Yazılmadı | 2 | Harita, Ordu, Kaynak |
| **Erlik Bozgunu & Arındırma** (MVP'de `spirit-system.md` §3.1–3.2, §3.6–3.7 kapsar; ayrı GDD planlı değil — C-29) | Feature | [spirit-system.md](spirit-system.md) | Designed (spirit içinde) | 2 | Ruh |
| **Konsey (Altı Oğul)** | Feature | `council-system.md` | Yazılmadı | 3 | Ruh (ADR-0006 hattı) |
| **Diplomasi** (ittifak/fetih) | Feature | `diplomacy-system.md` | Yazılmadı | 3 | Katmanlı Düşman |
| **Mevsim / Çevre Etkisi** | Feature | `season-system.md` | Yazılmadı | 3 | Kaynak |
| **Kahraman Birimleri** | Feature | `hero-units.md` | Yazılmadı | 3 | Ordu, Savaş (Yiğit Ruhu lütfu kilidi) |
| **Miras / Bölünme** (final) | Feature | `legacy-division.md` | Yazılmadı | 4 | Konsey |
| **Sahne Akışı & İlerleme** | Presentation | `scene-flow.md` | Yazılmadı (C-35) | 4 | Harita (oyun sonu §3.7), Ruh (sahne sonu sunumu) |
| **Erişilebilirlik ayarları** (renk körlüğü, bölge adları, hareketi azalt) | Presentation | art bible §7 + kod (C-07); ayrı GDD yok | Belgelenmiş (kod) | — | Harita |
| **Yerelleştirme** (11 dil, `LocaleFontController`) | Presentation | coding standards + kod; ayrı GDD yok | Belgelenmiş (kod) | — | — |
| **Tamga ikonları** (sahiplik işareti) | Presentation | art bible §5/§7 + region-map §7 | Belgelenmiş (kod, C-06) | — | Harita |

## Modüler Genişleme (Post-v1.0 — Mimari Hazır)

Aşağıdaki grand-strategy katmanları çekirdeği yeniden yazmadan ayrı feature
olarak eklenebilir (bkz. game-concept.md → Modülerlik Notu):

| Sistem | Durum |
| ---- | ---- |
| Derin Diplomasi (antlaşma tipleri, itibar) | Planlanmadı |
| Casus / İstihbarat | Planlanmadı |
| Ticaret Ağı | Planlanmadı |
| Araştırma / Gelişme Ağacı | Planlanmadı |

## Notlar

- **Kod öncülüğü**: Bölge fethi, ordu, savaş ve temel kaynak sistemleri kodda
  çalışır durumda (Prolog haritası). Bu sistemlerin GDD'leri kodu belgeleyecek
  şekilde geriye dönük yazılmalı (`/reverse-document`).
- **İmza sistem**: Kök Böri / Ruh Sistemi en yüksek anlatısal + mekanik değere
  sahip — GDD 2026-07-14'te yazıldı; C-29…C-33 ile çapraz inceleme bulguları işlendi.
- Her GDD `/design-review` ile doğrulanmalı; ilişkili set tamamlanınca
  `/review-all-gdds`.
