# Devam İndeksi — ULUS

> **Tek doğruluk kaynağı.** Kullanıcı "devam" yazdığında iş buradan sürdürülür.
> Görev listesi, durumlar ve tamamlanan işlerin kaydı burada tutulur;
> `production/session-state/active.md` yalnızca oturum notlarıdır.

- **Son güncelleme:** 2026-10-08
- **Son commit:** `34ac70d` (C-02 harita etiketleri)
- **Proje evresi:** Concept (`production/stage.txt`)
- **Aktif görev:** — (yok; sıradaki: C-03)

---

## Devam Protokolü

Kullanıcı yalnızca **"devam"** yazdığında (büyük/küçük harf, "devam et", "Devam."
fark etmez) şu adımlar **sırayla** uygulanır:

1. **Durumu oku:** bu dosya → `production/session-state/active.md` →
   `git log --oneline -5` → `git status --short`.
   (Git: sistem git'i Xcode lisansına takılıyor — her komutta GitHub Desktop'un
   git'ini PATH'in başına koy:
   `D="$HOME/Applications/GitHub Desktop.app/Contents/Resources/app/git"; export PATH="$D/bin:$D/libexec/git-core:$PATH"`.
   Kimlik doğrulama `gh auth git-credential` ile otomatik.)
2. **Gönderilmemiş commit var mı?** `git status -sb` "ahead" diyorsa önce
   `git push origin main` (GitHub arızasında: https://www.githubstatus.com).
3. **Yarım kalan iş var mı?** Bir görev `[~]` durumundaysa veya çalışma ağacında
   commit'lenmemiş değişiklik varsa → **önce o görevi tamamla.** Baştan başlama:
   dosyalara ve commit'lere bakarak neyin bittiğini tespit et, kalan kısmı yap.
4. **Sıradaki görevi seç:** kuyruktaki **ilk `[ ]`** görev — bağımlılıkları `[x]`
   olmalı. Bağımlılığı bitmemişse önce bağımlılığı yap. Görev atlanmaz.
5. **Duyur ve başla:** kullanıcıya tek satırla "Sıradaki: C-XX — … (plan: …)" yaz;
   görevi `[~] (tarih)` olarak işaretle. "devam" komutu, kuyrukta tanımlı olan
   bu görevi uygulamak için onay sayılır. Görevin içinde **kullanıcıya ait bir
   karar** (tasarım seçimi, kapsam, yeni bağımlılık) çıkarsa sorulur.
6. **Doğrula:** testler (`tools/ci/run-tests.sh`), UI işlerinde ekran görüntüsü,
   görevin "Bitti kriteri".
7. **Kapat:** görevi `[x] <commit>` yap → "Tamamlananlar" tablosuna ekle →
   üstteki "Son commit / Aktif görev" alanlarını güncelle → `active.md`'ye kısa
   özet yaz → **commit at ve push et** (`git push origin main`; kullanıcı
   yetkilendirdi). Commit mesajı **her zaman anlamlı**: Conventional Commits
   başlığı + gövdede *ne değişti ve neden*, nasıl doğrulandı, `Task: C-XX`.
8. **Bir sonraki göreve geçme** — kullanıcının bir sonraki "devam"ını bekle
   (her "devam" = bir görev).

**Kurallar**
- `[x]` olan görev **tekrar yapılmaz.** Sonradan hatalı olduğu anlaşılırsa yeni
  bir düzeltme görevi (`C-XX-fix`) eklenir.
- Çalışırken yeni bir iş keşfedilirse **o an yapılmaz** — kuyruğun sonuna yeni
  ID ile eklenir (kaynağı ve gerekçesiyle).
- Bir görev ertelenecekse `[-] ertelendi: <sebep>` yazılır; sessizce atlanmaz.
- Kullanıcı başka bir iş isterse o yapılır; bitince bu dosyaya "Tamamlananlar"
  olarak işlenir, kuyruk sırası bozulmaz.
- Her commit'ten sonra push edilir; push başarısız olursa sebebiyle birlikte kullanıcıya bildirilir.

Durum işaretleri: `[ ]` bekliyor · `[~]` devam ediyor · `[x]` bitti · `[-]` ertelendi

---

## Kullanıcı Aksiyonu Bekleyenler

| ID | Durum | İş | Not |
| --- | --- | --- | --- |
| K-01 | [x] | **Push:** origin'e gönderilmemiş commit'ler | 2026-10-07 push edildi (`1206f14`); push artık protokolün parçası |
| K-02 | [x] | **Karar:** `ai_turn_execution` registry güncelleme önerisi | 2026-10-07 onaylandı — kayıt (13 Ağustos'ta yazılmıştı) olduğu gibi kaldı |

## Görev Kuyruğu

| ID | Durum | Görev | Kaynak | Bağımlı | Bitti kriteri |
| --- | --- | --- | --- | --- | --- |
| C-01 | [x] `656223d` | Sahiplik renkleri opak mini rampalara: oyuncu `#47A3E8`, düşman `#C45A2A`, nötr `#6B655A`, seçim 1px altın kontur (`region_node.gd`) | Art bible §4 | — | Ekran görüntüsü + testler |
| C-02 | [x] `34ac70d` | Harita etiketleri: krem + 1px `#1C170F` kontur, `text_overrun_behavior` ellipsis | §4, §7 | — | en/ar/de ekran görüntüsü |
| C-03 | [ ] | HUD üst/alt bara ~%70 opak `#1C150D` zemin + 1px kenarlık | §7 | — | Ekran görüntüsü |
| C-04 | [ ] | Tema paleti → UI paleti (panel `#1C150D`, kenarlık `#8A6D4F`, metin renkleri); `generate_ui_theme_icons.gd` renkleri + ikonları yeniden üret | §4, §7 | — | Ekran görüntüsü, kontrast tablosuyla eşleşme |
| C-05 | [ ] | Seçili bölge köşelerine 2px `◆` işaretleri | §4, §7 | C-01 | Ekran görüntüsü |
| C-06 | [ ] | Tamga ikonları: oyuncu + 5 kral 7×7 (üretici script) → bölge merkezinde `Sprite2D`, data-driven `tamga_id` | §5, §7 | C-04 | Ekran görüntüsü + testler |
| C-07 | [ ] | Erişilebilirlik ayarları: Renk Körlüğü Modu, Hareketi Azalt, Bölge Adlarını Göster/Gizle + 11 dil çeviri key'leri | §7 | C-02, C-06 | Ayar başına ekran görüntüsü + testler |
| C-08 | [ ] | Buton taban genişlikleri (ör. Tur Bitir ≥64px) + dinamik buton `focus_neighbor_*` | §7 | — | Uzun dillerde (de/ru) ekran görüntüsü |
| C-09 | [ ] | Binlik ayırıcı: dil bazlı çeviri key'i + sayı biçimlendirme yardımcısı + birim testi | §7 | — | Testler |
| C-10 | [ ] | Global palet dosyası `art-source/global_palette_ulus.gpl` + `tools/asset-pipeline/validate_palette.gd` + CI'a bağla | §8 | — | Mevcut asset'ler doğrulayıcıdan geçer (veya ihlaller listelenir) |
| C-11 | [ ] | `game-concept.md`'deki kalan sulu boya ifadelerini art bible'a yönlendir (MDA "Duygu", oturum seviyesi, ilhamlar) | Tutarlılık | — | grep "sulu boya" yalnızca tarihsel notta |
| C-12 | [ ] | `design/art-reference/ai-art-prompts.md`'yi pixel art kurallarına göre yeniden yaz (veya /asset-spec ile değiştir) | §9 | — | Art bible kurallarıyla uyumlu prompt seti |
| C-13 | [ ] | `/review-all-gdds` | Technical Setup gate | — | Rapor dosyası |
| C-14 | [ ] | `/consistency-check` (GDD'ler ↔ art bible ↔ entity registry) | Tutarlılık | C-13 | Rapor |
| C-15 | [ ] | ADR: Additive Modifier / Stat Pipeline (`/architecture-decision`) | Arch. review 2026-08-13 | — | ADR dosyası |
| C-16 | [ ] | ADR: Save/Load Persistence (`/architecture-decision`) | Arch. review 2026-08-13 | — | ADR dosyası |
| C-17 | [ ] | `/architecture-review` yeniden → ADR'leri Accepted yap | Arch. review | C-15, C-16, K-02 | Rapor + ADR durumları |
| C-18 | [ ] | `/create-architecture` | Technical Setup | C-17 | Mimari doküman |
| C-19 | [ ] | ADR-0005 uygulaması: `game/features/ai/` altında `EnemyAIController` + `ErlikSpreadController` (saf `decide()`), `MapController` intent'leri uygular; `_run_enemy_ai()` taşınır | ADR-0005 (K-02 sırasında keşfedildi) | C-17 | Davranış aynı kalır; mevcut testler yeşil + `decide()` için izole testler |
| C-20 | [x] `5371770` | `tools/ci/run-tests.sh` varsayılan Godot yolu eskimiş (`~/Downloads/Applications`); Godot artık `/Applications/Godot.app` → yaygın konumları sırayla dene | C-01 sırasında keşfedildi (script `GODOT` olmadan çalışmıyor) | — | `GODOT` ayarlamadan `run-tests.sh` testleri çalıştırır |

## Tamamlananlar

| Tarih | İş | Commit |
| --- | --- | --- |
| 2026-10-07 | Menü başlık/alt başlık çevirileri, `locale/fallback="en"` | `b0083ee` |
| 2026-10-07 | Oyun adı Steppeborn → ASENA | `dcf5d83` |
| 2026-10-08 | Oyun adı ASENA → **ULUS: Blood of the Sky Wolf** (başlık tüm dillerde ULUS, alt başlık çevrili) | `79aae73` |
| 2026-10-07 | gdUnit4 runner `.gitignore` yüzünden eksikti → geri getirildi, CI sessiz başarı açığı kapandı | `a6233ee` |
| 2026-10-07 | Pixel art geçişi: 640×360, pixel fontlar (Fusion Pixel + Unifont), LocaleFontController | `5266962` |
| 2026-10-07 | Tüm ekranlar 640×360'a yeniden yerleşti, pixel UI teması, RTL düzeltmeleri | `80fbc01` |
| 2026-10-07 | Art Bible (9 bölüm) — `design/art/art-bible.md` | `da43161` |
| 2026-10-07 | Devam indeksi + "devam" protokolü | `1206f14` |
| 2026-10-07 | Push protokole eklendi, anlamlı commit kuralı | `60f66b2` |
| 2026-10-07 | K-02: `ai_turn_execution` kuralı onaylandı | `9f26595` |
| 2026-10-08 | C-01: opak sahiplik rampaları, 1px koyu ton kenar, altın seçim / hover konturu | `656223d` |
| 2026-10-08 | C-01-fix: hover konturu da bible'daki altın `#EDC76B` (seçimle aynı) | `b276316` |
| 2026-10-08 | C-20: `run-tests.sh` Godot'u otomatik buluyor (/Applications, ~/Applications, ~/Downloads/Applications, PATH) | `5371770` |
| 2026-10-08 | `project.godot` editör normalizasyonu (davranış değişmedi) + eksik kalan oturum notları | `4dfdcc2` |
| 2026-10-08 | C-02: `MapLabel` tema varyasyonu (krem + 1px koyu kontur), uzun adlarda `…` | `34ac70d` |
