# Sistem GDD İndeksi — Steppeborn: Path of the Sky Wolf

*Türkçe alt-başlık: Gök Kurt'un Yolu*
*Son Güncelleme: 2026-07-14*

Bu indeks tüm sistem GDD'lerini ve durumlarını takip eder. Yeni bir GDD
eklendiğinde buraya bir satır eklenmeli. Kaynak konsept: [game-concept.md](game-concept.md).

## Tasarım Sırası

Foundation → Core → Feature → Presentation → Polish

## Sistemler

| Sistem | Katman | Dosya | Durum | Öncelik |
| ---- | ---- | ---- | ---- | ---- |
| **Oyun Konsepti** | Foundation | [game-concept.md](game-concept.md) | Taslak (revize edildi) | — |
| **Bölge Fethi / Harita** | Core | [region-map-system.md](region-map-system.md) | Belgelendi (kod mevcut) | 1 |
| **Kaynak Yönetimi** (altın/sürü/ruh) | Core | `resource-system.md` | Yazılmadı (gelir kodu mevcut) | 1 |
| **Ordu & Birim Sistemi** | Core | [army-system.md](army-system.md) | Belgelendi (kod mevcut) | 1 |
| **Savaş Çözümü** (otomatik + rapor) | Core | [combat-system.md](combat-system.md) | Belgelendi (kod mevcut) | 1 |
| **Kök Böri / Ruh Sistemi** (imza) | Feature | [spirit-system.md](spirit-system.md) | Taslak yazıldı | 2 |
| **Katmanlı Düşman** (uluslar + Erlik) | Feature | `enemy-layers.md` | Yazılmadı | 2 |
| **Erlik Bozgunu & Arındırma** | Feature | `corruption-purification.md` | Yazılmadı | 2 |
| **Konsey (Altı Oğul)** | Feature | `council-system.md` | Yazılmadı | 3 |
| **Diplomasi** (ittifak/fetih) | Feature | `diplomacy-system.md` | Yazılmadı | 3 |
| **Mevsim / Çevre Etkisi** | Feature | `season-system.md` | Yazılmadı | 3 |
| **Kahraman Birimleri** | Feature | `hero-units.md` | Yazılmadı | 3 |
| **Miras / Bölünme** (final) | Feature | `legacy-division.md` | Yazılmadı | 4 |
| **Sahne Akışı & İlerleme** | Presentation | `scene-flow.md` | Yazılmadı | 4 |

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
  sahip — MVP sonrası ilk yazılacak GDD.
- Her GDD `/design-review` ile doğrulanmalı; ilişkili set tamamlanınca
  `/review-all-gdds`.
