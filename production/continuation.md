# Devam İndeksi — ASENA

> **Tek doğruluk kaynağı.** Kullanıcı "devam" yazdığında iş buradan sürdürülür.
> Görev listesi, durumlar ve tamamlanan işlerin kaydı burada tutulur;
> `production/session-state/active.md` yalnızca oturum notlarıdır.

- **Son güncelleme:** 2026-10-07
- **Son commit:** `da43161` (art bible)
- **Proje evresi:** Concept (`production/stage.txt`)
- **Aktif görev:** — (yok; sıradaki: C-01)

---

## Devam Protokolü

Kullanıcı yalnızca **"devam"** yazdığında (büyük/küçük harf, "devam et", "Devam."
fark etmez) şu adımlar **sırayla** uygulanır:

1. **Durumu oku:** bu dosya → `production/session-state/active.md` →
   `git log --oneline -5` → `git status --short`.
   (Git: `~/Applications/GitHub Desktop.app/Contents/Resources/app/git/bin/git` —
   sistem git'i Xcode lisansına takılıyor.)
2. **Yarım kalan iş var mı?** Bir görev `[~]` durumundaysa veya çalışma ağacında
   commit'lenmemiş değişiklik varsa → **önce o görevi tamamla.** Baştan başlama:
   dosyalara ve commit'lere bakarak neyin bittiğini tespit et, kalan kısmı yap.
3. **Sıradaki görevi seç:** kuyruktaki **ilk `[ ]`** görev — bağımlılıkları `[x]`
   olmalı. Bağımlılığı bitmemişse önce bağımlılığı yap. Görev atlanmaz.
4. **Duyur ve başla:** kullanıcıya tek satırla "Sıradaki: C-XX — … (plan: …)" yaz;
   görevi `[~] (tarih)` olarak işaretle. "devam" komutu, kuyrukta tanımlı olan
   bu görevi uygulamak için onay sayılır. Görevin içinde **kullanıcıya ait bir
   karar** (tasarım seçimi, kapsam, yeni bağımlılık) çıkarsa sorulur.
5. **Doğrula:** testler (`tools/ci/run-tests.sh`), UI işlerinde ekran görüntüsü,
   görevin "Bitti kriteri".
6. **Kapat:** commit at (Conventional Commits, gövdede `Task: C-XX`) → görevi
   `[x] <commit>` yap → "Tamamlananlar" tablosuna ekle → üstteki "Son commit /
   Aktif görev" alanlarını güncelle → `active.md`'ye kısa özet yaz.
7. **Bir sonraki göreve geçme** — kullanıcının bir sonraki "devam"ını bekle
   (her "devam" = bir görev).

**Kurallar**
- `[x]` olan görev **tekrar yapılmaz.** Sonradan hatalı olduğu anlaşılırsa yeni
  bir düzeltme görevi (`C-XX-fix`) eklenir.
- Çalışırken yeni bir iş keşfedilirse **o an yapılmaz** — kuyruğun sonuna yeni
  ID ile eklenir (kaynağı ve gerekçesiyle).
- Bir görev ertelenecekse `[-] ertelendi: <sebep>` yazılır; sessizce atlanmaz.
- Kullanıcı başka bir iş isterse o yapılır; bitince bu dosyaya "Tamamlananlar"
  olarak işlenir, kuyruk sırası bozulmaz.
- Push kullanıcı işidir (K-01) — Xcode lisansı kabul edilene kadar.

Durum işaretleri: `[ ]` bekliyor · `[~]` devam ediyor · `[x]` bitti · `[-]` ertelendi

---

## Kullanıcı Aksiyonu Bekleyenler

| ID | Durum | İş | Not |
| --- | --- | --- | --- |
| K-01 | [ ] | **Push:** origin'e gönderilmemiş commit'ler | GitHub Desktop → "Push origin". Kalıcı çözüm: terminalde `sudo xcodebuild -license` |
| K-02 | [ ] | **Karar:** `ai_turn_execution` registry güncelleme önerisi | /architecture-review (2026-08-13) sonrası onay bekliyor — bkz. `active.md` |

## Görev Kuyruğu

| ID | Durum | Görev | Kaynak | Bağımlı | Bitti kriteri |
| --- | --- | --- | --- | --- | --- |
| C-01 | [ ] | Sahiplik renkleri opak mini rampalara: oyuncu `#47A3E8`, düşman `#C45A2A`, nötr `#6B655A`, seçim 1px altın kontur (`region_node.gd`) | Art bible §4 | — | Ekran görüntüsü + testler |
| C-02 | [ ] | Harita etiketleri: `LabelSettings` krem + 1px `#1C170F` kontur, `text_overrun_behavior` ellipsis | §4, §7 | — | en/ar/de ekran görüntüsü |
| C-03 | [ ] | HUD üst/alt bara ~%70 opak `#1C150D` zemin + 1px kenarlık | §7 | — | Ekran görüntüsü |
| C-04 | [ ] | Tema paleti → UI paleti (panel `#1C150D`, kenarlık `#8A6D4F`, metin renkleri); `generate_ui_theme_icons.gd` renkleri + ikonları yeniden üret | §4, §7 | — | Ekran görüntüsü, kontrast tablosuyla eşleşme |
| C-05 | [ ] | Seçili bölge köşelerine 2px `◆` işaretleri | §4, §7 | C-01 | Ekran görüntüsü |
| C-06 | [ ] | Tamga ikonları: oyuncu + 5 kral 7×7 (üretici script) → bölge merkezinde `Sprite2D`, data-driven `tamga_id` | §5, §7 | C-04 | Ekran görüntüsü + testler |
| C-07 | [ ] | Erişilebilirlik ayarları: Renk Körlüğü Modu, Hareketi Azalt, Bölge Adlarını Göster/Gizle + 11 dil çeviri key'leri | §7 | C-02, C-06 | Ayar başına ekran görüntüsü + testler |
| C-08 | [ ] | Buton taban genişlikleri (ör. Tur Bitir ≥64px) + dinamik buton `focus_neighbor_*` | §7 | — | Uzun dillerde (de/ru) ekran görüntüsü |
| C-09 | [ ] | Binlik ayırıcı: dil bazlı çeviri key'i + sayı biçimlendirme yardımcısı + birim testi | §7 | — | Testler |
| C-10 | [ ] | Global palet dosyası `art-source/global_palette_asena.gpl` + `tools/asset-pipeline/validate_palette.gd` + CI'a bağla | §8 | — | Mevcut asset'ler doğrulayıcıdan geçer (veya ihlaller listelenir) |
| C-11 | [ ] | `game-concept.md`'deki kalan sulu boya ifadelerini art bible'a yönlendir (MDA "Duygu", oturum seviyesi, ilhamlar) | Tutarlılık | — | grep "sulu boya" yalnızca tarihsel notta |
| C-12 | [ ] | `design/art-reference/ai-art-prompts.md`'yi pixel art kurallarına göre yeniden yaz (veya /asset-spec ile değiştir) | §9 | — | Art bible kurallarıyla uyumlu prompt seti |
| C-13 | [ ] | `/review-all-gdds` | Technical Setup gate | — | Rapor dosyası |
| C-14 | [ ] | `/consistency-check` (GDD'ler ↔ art bible ↔ entity registry) | Tutarlılık | C-13 | Rapor |
| C-15 | [ ] | ADR: Additive Modifier / Stat Pipeline (`/architecture-decision`) | Arch. review 2026-08-13 | — | ADR dosyası |
| C-16 | [ ] | ADR: Save/Load Persistence (`/architecture-decision`) | Arch. review 2026-08-13 | — | ADR dosyası |
| C-17 | [ ] | `/architecture-review` yeniden → ADR'leri Accepted yap | Arch. review | C-15, C-16, K-02 | Rapor + ADR durumları |
| C-18 | [ ] | `/create-architecture` | Technical Setup | C-17 | Mimari doküman |

## Tamamlananlar

| Tarih | İş | Commit |
| --- | --- | --- |
| 2026-10-07 | Menü başlık/alt başlık çevirileri, `locale/fallback="en"` | `b0083ee` |
| 2026-10-07 | Oyun adı Steppeborn → ASENA | `dcf5d83` |
| 2026-10-07 | gdUnit4 runner `.gitignore` yüzünden eksikti → geri getirildi, CI sessiz başarı açığı kapandı | `a6233ee` |
| 2026-10-07 | Pixel art geçişi: 640×360, pixel fontlar (Fusion Pixel + Unifont), LocaleFontController | `5266962` |
| 2026-10-07 | Tüm ekranlar 640×360'a yeniden yerleşti, pixel UI teması, RTL düzeltmeleri | `80fbc01` |
| 2026-10-07 | Art Bible (9 bölüm) — `design/art/art-bible.md` | `da43161` |
