# Devam İndeksi — ULUS

> **Tek doğruluk kaynağı.** Kullanıcı "devam" yazdığında iş buradan sürdürülür.
> Görev listesi, durumlar ve tamamlanan işlerin kaydı burada tutulur;
> `production/session-state/active.md` yalnızca oturum notlarıdır.

- **Son güncelleme:** 2026-10-08
- **Son commit:** `b571487` (C-13 GDD çapraz inceleme — FAIL)
- **Proje evresi:** Concept (`production/stage.txt`)
- **Aktif görev:** C-28 (kullanıcı seçimi; kuyruk sırası C-14)

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
- **Kilometre taşı görevleri (M1: C-35…C-42, M2: C-43…C-48) korunur:** kullanıcı
  açıkça onaylamadan `[-]` ertelenemez, birleştirilemez veya kuyruktan
  çıkarılamaz. Her "devam"da 1. adımda "Kilometre Taşları" tablosuna bakılır;
  bir taşın tüm görevleri `[x]` olunca taşın durumu güncellenir ve kullanıcıya
  bildirilir.

Durum işaretleri: `[ ]` bekliyor · `[~]` devam ediyor · `[x]` bitti · `[-]` ertelendi

---

## Kilometre Taşları

> 2026-10-08'de kullanıcı isteğiyle eklendi: mevcut sıra korunur, ama Prolog demosu
> ve vertical slice kuyrukta kalıcı olarak yer alır, unutulmaz.
> Süreler `design/gdd/game-concept.md` → "Kapsam Kademeleri" tahminidir, taahhüt değildir.

| ID | Kilometre taşı | Kapsam | Görevler | Tahmini süre | Durum |
| --- | --- | --- | --- | --- | --- |
| M1 | **Prolog Demo** (konseptteki MVP kademesi) | Prolog: Doğuş uçtan uca oynanır: fetih + altın + ordu üretimi + savaş + temel arındırma + Kök Böri ilk görünüşü + intro/outro; ses placeholder | C-35…C-42 | 6–8 hafta | [ ] |
| M2 | **Vertical Slice** (Prolog + Perde 1) | M1 + Perde 1 (Doğu, Cürcet Kağan, 8 bölge) + ruh lütuf sistemi tam + Erlik katmanı, temsili kalitede sanat; Pre-Production → Production kapısı | C-43…C-48 | 3–4 ay | [ ] |

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
| C-03 | [x] `db53df6` | HUD üst/alt bara ~%70 opak `#1C150D` zemin + 1px kenarlık | §7 | — | Ekran görüntüsü |
| C-04 | [x] `5c8dc51` | Tema paleti → UI paleti (panel `#1C150D`, kenarlık `#8A6D4F`, metin renkleri); `generate_ui_theme_icons.gd` renkleri + ikonları yeniden üret | §4, §7 | — | Ekran görüntüsü, kontrast tablosuyla eşleşme |
| C-05 | [x] `eaccf54` | Seçili bölge köşelerine 2px `◆` işaretleri | §4, §7 | C-01 | Ekran görüntüsü |
| C-06 | [x] `6e3b99e` | Tamga ikonları: oyuncu + 5 kral 7×7 (üretici script) → bölge merkezinde `Sprite2D`, data-driven `tamga_id` | §5, §7 | C-04 | Ekran görüntüsü + testler |
| C-07 | [x] `5a7aa9f` | Erişilebilirlik ayarları: Renk Körlüğü Modu, Hareketi Azalt, Bölge Adlarını Göster/Gizle + 11 dil çeviri key'leri | §7 | C-02, C-06 | Ayar başına ekran görüntüsü + testler |
| C-08 | [x] `aadbab3` | Buton taban genişlikleri (ör. Tur Bitir ≥64px) + dinamik buton `focus_neighbor_*` | §7 | — | Uzun dillerde (de/ru) ekran görüntüsü |
| C-09 | [x] `95d8f33` | Binlik ayırıcı: dil bazlı çeviri key'i + sayı biçimlendirme yardımcısı + birim testi | §7 | — | Testler |
| C-10 | [x] `1eb1b88` | Global palet dosyası `art-source/global_palette_ulus.gpl` + `tools/asset-pipeline/validate_palette.gd` + CI'a bağla | §8 | — | Mevcut asset'ler doğrulayıcıdan geçer (veya ihlaller listelenir) |
| C-11 | [x] `7f0f5d5` | `game-concept.md`'deki kalan sulu boya ifadelerini art bible'a yönlendir (MDA "Duygu", oturum seviyesi, ilhamlar) | Tutarlılık | — | grep "sulu boya" yalnızca tarihsel notta |
| C-12 | [x] `0f64d19` | `design/art-reference/ai-art-prompts.md`'yi pixel art kurallarına göre yeniden yaz (veya /asset-spec ile değiştir) | §9 | — | Art bible kurallarıyla uyumlu prompt seti |
| C-13 | [x] `b571487` | `/review-all-gdds` | Technical Setup gate | — | Rapor dosyası |
| C-14 | [ ] | `/consistency-check` (GDD'ler ↔ art bible ↔ entity registry) | Tutarlılık | C-13 | Rapor |
| C-15 | [ ] | ADR: Additive Modifier / Stat Pipeline (`/architecture-decision`) | Arch. review 2026-08-13 | — | ADR dosyası |
| C-16 | [ ] | ADR: Save/Load Persistence (`/architecture-decision`) | Arch. review 2026-08-13 | — | ADR dosyası |
| C-17 | [ ] | `/architecture-review` yeniden → ADR'leri Accepted yap | Arch. review | C-15, C-16, K-02, C-34 | Rapor + ADR durumları |
| C-18 | [ ] | `/create-architecture` | Technical Setup | C-17 | Mimari doküman |
| C-19 | [ ] | ADR-0005 uygulaması: `game/features/ai/` altında `EnemyAIController` + `ErlikSpreadController` (saf `decide()`), `MapController` intent'leri uygular; `_run_enemy_ai()` taşınır | ADR-0005 (K-02 sırasında keşfedildi) | C-17 | Davranış aynı kalır; mevcut testler yeşil + `decide()` için izole testler |
| C-20 | [x] `5371770` | `tools/ci/run-tests.sh` varsayılan Godot yolu eskimiş (`~/Downloads/Applications`); Godot artık `/Applications/Godot.app` → yaygın konumları sırayla dene | C-01 sırasında keşfedildi (script `GODOT` olmadan çalışmıyor) | — | `GODOT` ayarlamadan `run-tests.sh` testleri çalıştırır |
| C-21 | [ ] | Birincil buton (Tur Bitir, Saldır) ve modal panel (ayarlar, savaş raporu) çerçeveleri: 5×5 koçboynuzu köşe + 2px kilim şevron bandı → üretici script + 9-slice `StyleBoxTexture`, `PrimaryButton` / `ModalPanel` tema varyasyonları; ayarlar ekranı modal panele alınır | Art bible §3, §7 (C-04 sırasında keşfedildi) | C-04 | Ekran görüntüsü + tema testi |
| C-22 | [ ] | Harita zemini (`#222A18`) ve komşuluk çizgileri (%30 saydam gri — palet dışı ton üretir) palete bağlanır: opak çizgi rengi + bölüm zemin tonu (bible §4 "Yön Başına Sıcaklık"), data-driven | Art bible §4 (C-04 sırasında keşfedildi) | — | Ekran görüntüsü + piksel kontrolü |
| C-23 | [ ] | Bölge seçim "tık" sesi (bible: seçimin renk körlüğü yedeği) — ses altyapısı (`features/audio`, SFX bus) henüz yok; önce ses yönetimi tasarımı/ADR gerekir | Art bible §4 (C-05 sırasında keşfedildi) | — | Seçimde ses çalar; ses ayarı (SFX) ile ölçeklenir |
| C-24 | [ ] | **Karar:** `.uid` dosyaları `game/.gitignore` ile yok sayılıyor (repoda 0 adet); Godot 4.4+ bunların commit'lenmesini öneriyor (UID referansları klonlar arasında tutarlı kalsın). Politikayı seç → gerekiyorsa ignore'dan çıkar + mevcutları ekle | C-06 sırasında keşfedildi | — | Karar kaydı + (seçilirse) tüm `.uid`'ler takipte |
| C-25 | [ ] | **Karar + uygulama:** ekran açılışında başlangıç odağı yok (menü, ayarlar, oyun) → klavye/gamepad kullanıcısı gezinmeye başlayamıyor. Fare kullanıcısına sürekli altın odak çerçevesi göstermeden çözüm seç (ör. ilk yön tuşunda odak ver / Godot 4.7 odak görünürlüğü ayarını araştır) | C-08 sırasında keşfedildi | — | Her ekranda ilk ok/Tab tuşu bir butona odaklanır; fareyle açılışta çerçeve yok |
| C-26 | [ ] | Bilgi panelinde `tr("TURN").to_lower()` → Almancada "2 / runde" (isimler büyük harf olmalı); bible programatik büyük/küçük harf dönüşümünü yasaklıyor. `PER_TURN` gibi ayrı çeviri key'i (11 dil) + kodda başka `to_lower()/to_upper()` kalmadığını doğrula | C-09 sırasında keşfedildi | — | grep `to_lower\|to_upper` oyuncuya görünen metinde yok; de ekran görüntüsü |
| C-27 | [ ] | Gerçek CI hattı yok: `.github/workflows/` boş (yalnızca şablonlar). Coding standards "her push/PR'da testler çalışır, kırmızıysa merge yok" diyor → GitHub Actions: headless Godot 4.7 + `tools/ci/run-tests.sh` (testler + palet) | C-10 sırasında keşfedildi | — | Push'ta workflow yeşil; bilerek kırılan testte kırmızı |
| C-28 | [~] (2026-10-08) | **Karar + GDD:** ordu üretimi (maliyet, formül, sahibi) — `resource-system.md` yazılır veya `army-system.md`'ye eklenir; kartopu/bakım (D1, D2) burada değerlendirilir | `design/gdd/gdd-cross-review-2026-10-08.md` B1 | C-13 | GDD'de üretim formülü + ayar aralığı; Prolog kazanılabilirliği hesapla gösterilir |
| C-29 | [ ] | **Karar + GDD:** Erlik modeli (bozulma katmanı mı, sahip türü mü — Prolog canavarı dahil), yayılım/bozulmanın sahibi GDD (spirit / corruption-purification / enemy-layers) ve tur sonundaki yeri → region-map §3.4 + AC4 + TR-map-003 güncellenir; Prolog'da Erlik baskısı (D3) | `design/gdd/gdd-cross-review-2026-10-08.md` B2, B4 | C-13 | Tek sahip GDD; tur sonu sırası tüm GDD/TR/ADR'de aynı |
| C-30 | [ ] | **GDD:** arındırma eylemi (varış dalı mı ayrı eylem mi, aksiyon maliyeti, birliklerin yerleşmesi, sahipli+bozuk hedef) + fetihte bozulmanın akıbeti | `design/gdd/gdd-cross-review-2026-10-08.md` B3, B5 | C-29 | army §3.3 / spirit §3.2 tanımlı, kabul kriterli |
| C-31 | [ ] | **GDD:** lütuf sunma zamanı, erteleme, etkinin başlangıcı, MVP alt kümesi; olmayan sistemlere dayanan lütuflar, Gök Kalkanı yığılması, Ruh ölçekleme yönü, maliyet eğrisi (W9–W11, D5) | `design/gdd/gdd-cross-review-2026-10-08.md` B6 | C-29 | spirit §3.4/§4/§7 güncel, sıfıra bölme yok |
| C-32 | [ ] | **GDD:** tur ortası kazanma davranışı, kazanma/kaybetme önceliği, kazanma kapsamı (siyasi / + Erlik) ve formül metni (W7, D4) | `design/gdd/gdd-cross-review-2026-10-08.md` B7 | C-29 | region-map §3.3/§3.4/§3.6 tutarlı; kod davranışıyla eşleşiyor veya düzeltme görevi açıldı |
| C-33 | [ ] | GDD düzeltmeleri: W1–W6, W8, W12 + bilgi notları (örnek hesap, berabere/hayatta kalanlar, 0 ordu, `draw_favors_defender`, §3.5 "planlı", eşitlik bozma, gelir formülü sahibi, bozulma görseli → art bible, indeks/konsept notları, bağımlılık asimetrisi) | `design/gdd/gdd-cross-review-2026-10-08.md` uyarılar | C-28 | Her uyarı kapandı veya gerekçeyle kaldı |
| C-34 | [ ] | `/review-all-gdds` yeniden → PASS veya CONCERNS | C-13 FAIL | C-28, C-29, C-30, C-31, C-32, C-33 | Yeni rapor; engelleyici yok |
| C-35 | [ ] | **M1 · GDD:** `scene-flow.md` — sahne intro/outro anlatı ekranları, Kök Böri "genesis" sahnesi, Prolog kazanma → Kağan ilanı, bölüm unlock (`/design-system`) | Konsept MVP #5; M1 | C-32 | 8 zorunlu bölüm + indeks satırı; `/design-review` geçer |
| C-36 | [ ] | **M1 · Harita:** Ötüken haritası → Oğuz ata yurdu (6 bölge, dağınık boylar + Erlik canavarı yerleşimi), data-driven `ChapterMapDefinition` + 11 dil bölge adları | Konsept "Sonraki Adımlar"; M1 | C-29, C-34 | Harita verisi + testler + ekran görüntüsü |
| C-37 | [ ] | **M1 · Kod:** ordu üretimi + altın harcama (`resource-system.md` uygulaması) — UI butonu, maliyet/limit, düşman üretimi | C-28; M1 | C-18 | GDD kabul kriterleri birim testlerinde; ekran görüntüsü |
| C-38 | [ ] | **M1 · Kod:** Erlik canavarı + temel arındırma (C-29/C-30 kararlarına göre) | Konsept MVP #4; M1 | C-18, C-19, C-30 | Kabul kriterleri testte; canavar yenilip bölge arınır |
| C-39 | [ ] | **M1 · Kod:** Kök Böri çekirdeği — ruh kazanımı + ilk görünüş (MVP alt kümesi, C-31) | Konsept MVP #4; M1 | C-18, C-31 | Ruh kazanımı testli; HUD'da görünür |
| C-40 | [ ] | **M1 · Kod:** sahne akışı — intro/outro ekranları, Kök Böri sahnesi, kazanma/kaybetme → outro (`features/campaign/`) | C-35; M1 | C-35, C-18 | Yeni kampanya → intro → harita → zafer → outro akışı; 11 dil key'leri |
| C-41 | [ ] | **M1 · UX + Kod:** Prolog öğretici akışı (fetih → kaynak → üretim → savaş → arındırma sırasıyla tanıtım) — `/ux-design` spec + uygulama | Konsept "Prolog — ÖĞRETİCİ"; M1 | C-37, C-38, C-39, C-40 | UX spec dosyası; rehbersiz oyuncu her mekaniği bir kez görür |
| C-42 | [ ] | **M1 · Kilometre taşı kapanışı: Prolog Demo** — uçtan uca oynanış, `/smoke-check`, `/playtest-report`, macOS/Windows demo export'u | M1 | C-36, C-37, C-38, C-39, C-40, C-41 | Başlangıçtan Kağan ilanına çökmeden oynanır (20–35 dk); smoke PASS; playtest raporu; çalışan export |
| C-43 | [ ] | **M2 · Tasarım:** Perde 1 (Doğu — Cürcet Yönü) — 8 bölgelik harita/seviye, Cürcet Kağan AI'ı, çürümüş orman + körmös (`/team-level`) | Konsept "Perde 1"; M2 | C-42 | Seviye dokümanı + gerekli GDD güncellemeleri |
| C-44 | [ ] | **M2 · Tasarım:** ruh lütuf sistemi tam kapsam + Erlik katmanı (enemy-layers / corruption-purification eksik GDD'leri), `/review-all-gdds` | Konsept "Vertical Slice" kademesi; M2 | C-42 | GDD'ler yazılı; çapraz inceleme PASS/CONCERNS |
| C-45 | [ ] | **M2 · UX:** vertical slice ekranlarının UX spec'leri (HUD, savaş raporu, lütuf seçimi, sahne ekranları) — `/ux-design` + `/ux-review` | `/vertical-slice` ön koşulu; M2 | C-44 | Spec'ler APPROVED |
| C-46 | [ ] | **M2 · Sanat:** Prolog + Perde 1 temsili kalite pixel art (harita, birim, tamga, illüstrasyon) — `/asset-spec` + üretim | Art bible; M2 | C-43 | Asset'ler palet doğrulayıcıdan geçer; manifest güncel |
| C-47 | [ ] | **M2 · Kod:** Perde 1 + lütuf sistemi + Erlik katmanı uygulaması — önce `/create-epics` + `/create-stories` ile parçalanır, story'ler kuyruğa C-XX olarak eklenir | M2 | C-43, C-44, C-45 | Tüm story'ler Done; testler yeşil |
| C-48 | [ ] | **M2 · Kilometre taşı kapanışı: Vertical Slice** — `/vertical-slice` + `/gate-check` (Pre-Production → Production) | M2 | C-46, C-47 | PROCEED/PIVOT/KILL kararı yazılı; PIVOT'ta düzeltme görevleri kuyruğa eklenir |

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
| 2026-10-08 | C-03: HUD barları + bilgi paneli `HudBarTop/Bottom`, `HudPanel` (%70 `#1C150D`, 1px `#8A6D4F`); bible §3↔§7 çelişkisi giderildi | `db53df6` |
| 2026-10-08 | C-04: tema → art bible UI paleti (stilbox + metin renkleri, `SecondaryLabel`), ikonlar yeniden üretildi, kontrast tablosu düzeltildi | `5c8dc51` |
| 2026-10-08 | C-05: seçili bölge köşelerine 5×5 altın `◆` (1px koyu kenar), hover'da yok | `eaccf54` |
| 2026-10-08 | C-06: 7 tamga ikonu (üretici), bölge sahibine göre data-driven tamga, seçimde görünür, fetihte değişir | `6e3b99e` |
| 2026-10-08 | C-07: erişilebilirlik ayarları (Renk Körlüğü Modu: tamga + iç kontur, Bölge Adları, Hareketi Azalt bayrağı), 11 dil | `5a7aa9f` |
| 2026-10-08 | C-08: alt bar butonları ≥64px, Ordu Gönder odak zincirine bağlı (Tur Bitir ↕) | `aadbab3` |
| 2026-10-08 | C-09: `THOUSANDS_SEPARATOR` (11 dil) + `NumberFormatter`, HUD/bölge/panel sayıları gruplanıyor | `95d8f33` |
| 2026-10-08 | C-10: `art-source/global_palette_ulus.gpl` (94 renk, tek kaynak) + `validate_palette.gd`, `run-tests.sh`'e bağlı | `1eb1b88` |
| 2026-10-08 | C-11: `game-concept.md` sulu boya ifadeleri → pixel art / art bible referansları | `7f0f5d5` |
| 2026-10-08 | C-12: `ai-art-prompts.md` pixel art'a göre baştan yazıldı (AI = konsept referansı, 10 prompt, ortak stil/negatif blok) | `0f64d19` |
| 2026-10-08 | C-13: `/review-all-gdds` → FAIL (7 engelleyici, 20 uyarı); rapor + indeks "Needs Revision"; çözüm görevleri C-28…C-34 | `b571487` |
| 2026-10-08 | Kilometre taşları M1 Prolog Demo (C-35…C-42) + M2 Vertical Slice (C-43…C-48) kuyruğa eklendi; korunma kuralı | (bu commit) |
