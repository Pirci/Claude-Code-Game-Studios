# Devam İndeksi — ULUS

> **Tek doğruluk kaynağı.** Kullanıcı "devam" yazdığında iş buradan sürdürülür.
> Görev listesi, durumlar ve tamamlanan işlerin kaydı burada tutulur;
> `production/session-state/active.md` yalnızca oturum notlarıdır.

- **Son güncelleme:** 2026-10-19
- **Son commit:** `9883e76` (C-26: PER_TURN çeviri key'i)
- **Proje evresi:** Concept (`production/stage.txt`)
- **Aktif görev:** — (yok; sıradaki: C-27)

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

## Otonom Kararlar (gece modu — kullanıcı incelemesi bekliyor)

> 2026-10-18 gecesi kullanıcı talimatı: "sabaha kadar devam, önerileni kabul et".
> Kullanıcıya ait kararlar bu modda **önerilen seçenekle** verildi; her biri
> aşağıda listelenir. Beğenilmeyen karar için düzeltme görevi (`C-XX-fix`) açılır.

| Görev | Karar | Reddedilen alternatifler | Geri alma maliyeti |
| --- | --- | --- | --- |
| C-25 | Her ekranda birincil kontrol **gizli** odak alır (`grab_focus(true)`: Yeni Sefer, Dil seçimi, Tur Bitir; ayarlardan dönünce Ayarlar); ilk yön/Tab/onay tuşu odağı **taşımadan ve basmadan** görünür yapar (`FocusReveal`, RootContext `_input`); `gui/common/show_focus_state_on_pointer_event` varsayılanda (Text Input Controls) | Açılışta görünür odak (fare kullanıcısına sürekli çerçeve); odak yok + ilk tuşta ver (ekstra durum takibi); ilk Enter'ın doğrudan basması | Düşük — tek yardımcı sınıf + 4 satır çağrı |
| C-24 | `.uid` dosyaları commit edilir (Godot 4.4+ önerisi); 272 dosya (45 oyun + 227 gdUnit4) bu container'daki Godot 4.7.1 ile üretildi | Yok sayılmaya devam | Düşük — `.gitignore` satırı; ⚠️ kullanıcı Mac'te pull ederken git yerel `.uid`'lerden şikâyet ederse: yerel `*.uid`'leri silip tekrar pull |
| C-23 | Ses mimarisi ADR-0008: RootContext'in kalıcı `AudioController`'ı (bind_services ile enjekte), `Master → Music/SFX` bus düzeni, `SfxLibrary` (typed dictionary); yer tutucu "tık" sentezlendi (deterministik); ses yalnızca seçimde (seçim kaldırmada yok) | Autoload ses; bağlam başına oyuncular; sinyal hub'ı; hazır ücretsiz SFX indirme (lisans takibi) | Düşük — ADR + küçük modül |
| C-22 | Prolog zemini `#1A2614` (Bozkır Yeşili 2), çizgi `#436129` (Bozkır Yeşili 4); kural "çizgi = zemin rampasında iki ton açık" | Gri çizgi (Keçe Grisi 3); mevcut `#222A18` (palet dışı) | Düşük — bölüm verisinde iki renk |
| C-21 | Koçboynuzu 5×5 biçimi: köşegen gövde + iki kıvrık kol (köşegen simetrik); Yeni Sefer butonu da birincil (bible "ana menü: birincil buton süslü") | Halka biçimli köşe; yalnızca Tur Bitir/Saldır | Düşük — üretici script'te tek sabit |
| C-18 | `architecture.md` v1.0: 5 katman, modül sahiplik tabloları, 6 veri akışı, API sınırları, 5 ilke, 8 açık soru; TD öz-inceleme CONCERNS (koşullu onay); LP-FEASIBILITY lean modda atlandı | Bölüm bölüm kullanıcı onayı (gece modu: önerilen kabul) | Düşük — doküman |
| C-17 | Mimari inceleme CONCERNS → düzeltmeler uygulandı ve 7 ADR **Accepted**. D1: context sahneleri geçişte `load()` (preload yasağına uyum); D2: yığın sınırının tek sahibi `ModifierSource.max_stacks` + `can_add()`; D3: `SpiritController` (`features/bozkurt/`) bozulma/Ruh/lütufların tek yazıcısı; D4: `SaveController`'ın sahibi RootContext, `MenuContext.continue_requested`; düşman AI kopya yerine karar→uygula döngüsü | D1-B teknik tercihlere istisna; D2-B BoonDefinition sahibi; D3-B çapraz-feature yazımlar; D4-B MenuContext SaveController sahibi; ADR'leri taze oturuma kadar Proposed bırakmak | Orta — ADR'ler Accepted; geri alma = değişiklik notu + yeniden inceleme |
| C-53 | W-C: aynı tur ikinci lütuf seçimi HUD'dan serbest, otomatik modal tur başı en fazla 1 (seçenek c); W-F: "seçimi sakla, etkiyi türet" — `boons` tek doğruluk kaynağı, modifikatörler yüklemede yeniden kurulur, `ModifierSource.max_stacks`; W-D: `turn_ended` kontrolden sonra ve yalnızca ONGOING iken, zafer kalıcılığı scene-flow'da; W-E: `SpreadDecision`; arındırma `draw_favors_defender`'dan bağımsız; başarısız arındırma hamle önizlemesiyle ikinci onay ister (N7) | W-C (a) geçici bayrak / (b) HUD yalnız gösterileni açar; W-F modifikatörleri kaydet + `n`'i stack'lerden say; arındırmayı knob'a bağlı bırak; önizlemesiz | Orta — ADR-0006/0007 kalıcılık modeli değişti (henüz kod yok, Proposed) |
| C-34 | Rapor yazıldı (CONCERNS, 0 engelleyici); GDD'ler "Needs Revision" yapılmadı (uyarılar engelleyici değil) → indekste Designed; uyarılar C-53'e, tasarım uyarıları C-49 / C-44 / C-54'e; C-17'ye C-53 bağımlılığı, C-39'a C-55 bağımlılığı eklendi | Raporu yazmama; işaretli GDD'leri "Needs Revision" yapma; uyarıları C-17 içinde çözme | Düşük — kuyruk düzeni |
| C-33 | Kaybedenin hayatta kalanları dağılır (W2); savaştan sonra 0 birlikli bölge sahipsiz olur (W3); `draw_favors_defender` belgelendi (W4); hareket kuralları sahip-bağımsız (`mover`, W5); eşitlik bozma her yerde `region_id` alfabetik, düşman bölgeleri `region_id` sırasıyla (W6) | W2: hayatta kalanlar kaynağa döner; W3: kazanan en az 1 birlik tutar (taban); W4: knob'u kaldır; W6: "ilk bulunan" | Düşük — GDD; kod C-52 |
| C-32 | Tur ortası zafer oyunu anında bitirir (`game_result` kilidi; seçenek A); kontrol sırası kaybetme → kazanma; kazanma = siyasi + nötr genişleme (başlangıçta nötr, odak hariç) + `erlik_foci` arındırılmış; odak dışı bozulma engellemez | B: bayrak + atla; C: yalnızca tur sonu kontrol; kazanma için tüm bozulmanın temizlenmesi; eski `−1` sayımı | Düşük — GDD; kod C-51 |
| C-31 | Lütuf sunumu tur başında (en fazla 1) veya sahne zaferinde (zorunlu); erteleme aynı 3 lütfu korur; etki seçildiği an; Bereket/Kurt Gücü/Demir Post düz +1; Gök Kalkanı +1 tur, 3 yığın sınırı, sayaçlı yayılım; Sürü/Yiğit Ruhu kilitli; M1 havuzu Arınma Ustalığı + Bereket + Gök Kalkanı; doğrusal maliyet eğrisi korunur (hedef finalde 6–8 lütuf) | Anında modal (tur ortası); yalnızca sahne sonu; yüzde bonuslar; Gök Kalkanı bölme formülü + üst sınır; üstel maliyet eğrisi | Düşük — yalnızca GDD/ADR örneği (kod C-39 / M2) |
| C-30 | Arındırma = ordu varışının 2. dalı (ayrı eylem değil); fetih bozulmayı korur (B5-A); başarısız arındırmada gelen kuvvetin tamamı kaybolur; düşman AI bozulmayı yok sayar | Ayrı "Arındır" eylemi; fetih otomatik arındırır (B5-B); bozuk bölgeye saldırmadan önce arındırma şartı (B5-C); başarısızlıkta Dal 3 kalanı geri döner | Düşük — yalnızca GDD (kod C-38'de) |

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
| C-14 | [x] `5ba890b` | `/consistency-check` (GDD'ler ↔ art bible ↔ entity registry) | Tutarlılık | C-13 | Rapor |
| C-15 | [x] `62de438` | ADR: Additive Modifier / Stat Pipeline (`/architecture-decision`) | Arch. review 2026-08-13 | — | ADR dosyası |
| C-16 | [x] `bf4f2ff` | ADR: Save/Load Persistence (`/architecture-decision`) | Arch. review 2026-08-13 | — | ADR dosyası |
| C-17 | [x] `815e07c` | `/architecture-review` yeniden → ADR'leri Accepted yap | Arch. review | C-15, C-16, K-02, C-34, C-53 | Rapor + ADR durumları |
| C-18 | [x] `bf6932f` | `/create-architecture` | Technical Setup | C-17 | Mimari doküman |
| C-19 | [x] `278760f` | ADR-0005 uygulaması: `game/features/ai/` altında `EnemyAIController` + `ErlikSpreadController` (saf `decide()`), `MapController` intent'leri uygular; `_run_enemy_ai()` taşınır | ADR-0005 (K-02 sırasında keşfedildi) | C-17 | Davranış aynı kalır; mevcut testler yeşil + `decide()` için izole testler |
| C-20 | [x] `5371770` | `tools/ci/run-tests.sh` varsayılan Godot yolu eskimiş (`~/Downloads/Applications`); Godot artık `/Applications/Godot.app` → yaygın konumları sırayla dene | C-01 sırasında keşfedildi (script `GODOT` olmadan çalışmıyor) | — | `GODOT` ayarlamadan `run-tests.sh` testleri çalıştırır |
| C-21 | [x] `21a9735` | Birincil buton (Tur Bitir, Saldır) ve modal panel (ayarlar, savaş raporu) çerçeveleri: 5×5 koçboynuzu köşe + 2px kilim şevron bandı → üretici script + 9-slice `StyleBoxTexture`, `PrimaryButton` / `ModalPanel` tema varyasyonları; ayarlar ekranı modal panele alınır | Art bible §3, §7 (C-04 sırasında keşfedildi) | C-04 | Ekran görüntüsü + tema testi |
| C-22 | [x] `ffbf2b5` | Harita zemini (`#222A18`) ve komşuluk çizgileri (%30 saydam gri — palet dışı ton üretir) palete bağlanır: opak çizgi rengi + bölüm zemin tonu (bible §4 "Yön Başına Sıcaklık"), data-driven | Art bible §4 (C-04 sırasında keşfedildi) | — | Ekran görüntüsü + piksel kontrolü |
| C-23 | [x] `85eeea3` | Bölge seçim "tık" sesi (bible: seçimin renk körlüğü yedeği) — ses altyapısı (`features/audio`, SFX bus) henüz yok; önce ses yönetimi tasarımı/ADR gerekir | Art bible §4 (C-05 sırasında keşfedildi) | — | Seçimde ses çalar; ses ayarı (SFX) ile ölçeklenir |
| C-24 | [x] `061ada8` | **Karar:** `.uid` dosyaları `game/.gitignore` ile yok sayılıyor (repoda 0 adet); Godot 4.4+ bunların commit'lenmesini öneriyor (UID referansları klonlar arasında tutarlı kalsın). Politikayı seç → gerekiyorsa ignore'dan çıkar + mevcutları ekle | C-06 sırasında keşfedildi | — | Karar kaydı + (seçilirse) tüm `.uid`'ler takipte |
| C-25 | [x] `2e016f3` | **Karar + uygulama:** ekran açılışında başlangıç odağı yok (menü, ayarlar, oyun) → klavye kullanıcısı gezinmeye başlayamıyor. Fare kullanıcısına sürekli altın odak çerçevesi göstermeden çözüm seç (ör. ilk yön tuşunda odak ver / Godot 4.7 odak görünürlüğü ayarını araştır) | C-08 sırasında keşfedildi | — | Her ekranda ilk ok/Tab tuşu bir butona odaklanır; fareyle açılışta çerçeve yok |
| C-26 | [x] `9883e76` | Bilgi panelinde `tr("TURN").to_lower()` → Almancada "2 / runde" (isimler büyük harf olmalı); bible programatik büyük/küçük harf dönüşümünü yasaklıyor. `PER_TURN` gibi ayrı çeviri key'i (11 dil) + kodda başka `to_lower()/to_upper()` kalmadığını doğrula | C-09 sırasında keşfedildi | — | grep `to_lower\|to_upper` oyuncuya görünen metinde yok; de ekran görüntüsü |
| C-27 | [ ] | Gerçek CI hattı yok: `.github/workflows/` boş (yalnızca şablonlar). Coding standards "her push/PR'da testler çalışır, kırmızıysa merge yok" diyor → GitHub Actions: headless Godot 4.7 + `tools/ci/run-tests.sh` (testler + palet) | C-10 sırasında keşfedildi | — | Push'ta workflow yeşil; bilerek kırılan testte kırmızı |
| C-28 | [x] `1468973` | **Karar + GDD:** ordu üretimi (maliyet, formül, sahibi) — `resource-system.md` yazılır veya `army-system.md`'ye eklenir; kartopu/bakım (D1, D2) burada değerlendirilir | `design/gdd/gdd-cross-review-2026-10-08.md` B1 | C-13 | GDD'de üretim formülü + ayar aralığı; Prolog kazanılabilirliği hesapla gösterilir |
| C-29 | [x] `e0eae22` | **Karar + GDD:** Erlik modeli (bozulma katmanı mı, sahip türü mü — Prolog canavarı dahil), yayılım/bozulmanın sahibi GDD (spirit / corruption-purification / enemy-layers) ve tur sonundaki yeri → region-map §3.4 + AC4 + TR-map-003 güncellenir; Prolog'da Erlik baskısı (D3) | `design/gdd/gdd-cross-review-2026-10-08.md` B2, B4 | C-13 | Tek sahip GDD; tur sonu sırası tüm GDD/TR/ADR'de aynı |
| C-30 | [x] `f8e3737` | **GDD:** arındırma eylemi (varış dalı mı ayrı eylem mi, aksiyon maliyeti, birliklerin yerleşmesi, sahipli+bozuk hedef) + fetihte bozulmanın akıbeti | `design/gdd/gdd-cross-review-2026-10-08.md` B3, B5 | C-29 | army §3.3 / spirit §3.2 tanımlı, kabul kriterli |
| C-31 | [x] `ae8abdd` | **GDD:** lütuf sunma zamanı, erteleme, etkinin başlangıcı, MVP alt kümesi; olmayan sistemlere dayanan lütuflar, Gök Kalkanı yığılması, Ruh ölçekleme yönü, maliyet eğrisi (W9–W11, D5) | `design/gdd/gdd-cross-review-2026-10-08.md` B6 | C-29 | spirit §3.4/§4/§7 güncel, sıfıra bölme yok |
| C-32 | [x] `b48e788` | **GDD:** tur ortası kazanma davranışı, kazanma/kaybetme önceliği, kazanma kapsamı (siyasi / + Erlik) ve formül metni (W7, D4) | `design/gdd/gdd-cross-review-2026-10-08.md` B7 | C-29 | region-map §3.3/§3.4/§3.6 tutarlı; kod davranışıyla eşleşiyor veya düzeltme görevi açıldı |
| C-33 | [x] `1390df2` | GDD düzeltmeleri: W1–W6 + bilgi notları (örnek hesap, berabere/hayatta kalanlar, 0 ordu, `draw_favors_defender`, §3.5 "planlı", eşitlik bozma, indeks/konsept notları, bağımlılık asimetrisi). W8 (gelir sahibi C-28, seviye 3 → K1) ve W12 (bozulma görseli → K2) kapandı | `design/gdd/gdd-cross-review-2026-10-08.md` uyarılar | C-28 | Her uyarı kapandı veya gerekçeyle kaldı |
| C-34 | [x] `f661227` | `/review-all-gdds` yeniden → PASS veya CONCERNS | C-13 FAIL | C-28, C-29, C-30, C-31, C-32, C-33 | Yeni rapor; engelleyici yok |
| C-49 | [ ] | **Prolog Erlik modeli etki takibi:** Canavarın İni nötr + bozulma 3 olunca Prolog'da `ENEMY` bölgesi kalmıyor → düşman AI/takviye (F6) boşta, `game_lost` tetiklenemez; resource-system §4 Prolog kazanılabilirlik hesabı (canavar eşiği 12 direnç vs eski A≥7) ve `ERLIK_SPREAD_INTERVAL=3` `/balance-check` ile yeniden doğrulanır; Prolog'da siyasi düşman/kayıp koşulu var mı kararı (kullanıcı); **C-34 raporu ekleri:** N1 (Prolog'da Ruh/lütuf getirisi yok — öğretici L1/L2 bozuk bölge?), N2 (kayıp koşulu / tur sınırı), N3 (ilk arındırma en zoru, ölü turlar), N4 (yayılım yönlendirme/olgunlaştırma), N9 (fetih Erlik'i büyütmüyor), S1-e (in garnizonu 0 + veri AC'si) | C-29 sırasında keşfedildi | C-29, C-32 | Karar kaydı + güncel Prolog sayıları GDD'de + balance raporu |
| C-50 | [ ] | **Art bible + UI spec:** bozulma seviyesi görseli (seviye 1–3: Erlik Moru + Kömürü dither yoğunluğu / leke boyutu, sahiplik rengini gizlemeden) art bible §4'e; bölge bilgi panelinde bozulma seviyesi + Erlik direnci satırının yerleşimi | C-30 sırasında keşfedildi (spirit §3.1/§3.2, AC10/AC14) | C-30 | Art bible'da seviye görsel kuralı (palet doğrulayıcıyla uyumlu); bilgi paneli satırı tanımlı |
| C-51 | [ ] | **Kod düzeltmesi (C-32):** `MapState.game_result` kilidi (tur ortası zaferde `attempt_move`/`end_turn`/üretim reddedilir, `game_won`/`game_lost` bir kez), kontrol sırası kaybetme → kazanma, `WinCondition`: `conquered_neutral_count` (`initial_owner`, odak hariç) + `erlik_foci` alanı (bozulma C-38 ile etkinleşir) + testler; `turn_ended` 5. adımdan sonra ve yalnızca `ONGOING` iken + 1. adımdan sonra erken kayıp çıkışı (region-map §3.4, AC8, AC12 — C-53) | C-32 sırasında keşfedildi: `map_controller.gd` iki noktada kontrol ediyor, kazanma önce; `win_condition.gd` `oyuncu_bölge − 1` sayıyor | C-32 | region-map AC7, AC8, AC10 testleri yeşil (AC11 C-38'de) |
| C-52 | [ ] | **Kod düzeltmesi (C-33):** savaştan sonra 0 birlik kalan bölge `NEUTRAL` olur (oyuncu ve düşman AI yolu; W3), `draw_favors_defender = false` testli; düşman AI eşitlik bozma `region_id` alfabetik + düşman bölgeleri `region_id` sırasıyla (W6) + testler | C-33 sırasında keşfedildi: `apply_combat_result` ve `_run_enemy_ai` 0 ordulu sahipli bölge bırakıyor; AI "ilk bulunan"ı seçiyor | C-33 | army AC13, combat AC9, region-map AC6 testleri yeşil |
| C-53 | [x] `62f8b96` | **GDD + ADR düzeltmeleri (C-34 CONCERNS):** W-A resource §4/F5–F6 örnekleri/AC15 "C-49'a dek eskimiş" işareti; W-C aynı tur ikinci lütuf seçimi kuralı; W-D `turn_ended` + otomatik kayıt sırası (region-map §3.4, ADR-0007); W-E ADR-0005 `ErlikSpreadController` arayüzü (etkin aralık girdisi, "yayılım turu" çıktısı); W-F ADR-0006 Gök Kalkanı/katalog alanları + `n` ↔ stacks tek kaynak; W-G `RegionData`/`ChapterMapDefinition` alan sahipliği; W-H konsept kademe tablosu + C-39 kriteri ↔ spirit §3.8; W-I spirit AC10; S1-a/S1-c (zafer sinyalinden önce tüm durum işlenir, kilitte lütuf seçimi serbest); N7 hamle önizlemesi + yayılım göstergesi gereksinimi; N11c yerinde üretim notu; bilgi notlarındaki eskimiş atıflar/ifadeler/aralıklar | `design/gdd/gdd-cross-review-2026-10-19.md` | C-34 | Raporun her uyarı/bilgi maddesi kapandı veya gerekçeyle kaldı; C-17 için ADR'ler güncel |
| C-54 | [ ] | **Anlatı sesi (D7/N10):** savaş ve arındırma raporu metinleri, Kök Böri'nin hedef işaretlemesi ve canavar anının ritüel çerçevesi — narrative-director + writer; 11 dil key'leri | `design/gdd/gdd-cross-review-2026-10-19.md` N10 | C-35 | Metin rehberi + key listesi; rapor ekranlarında "kuru hesap" dili yok |
| C-55 | [ ] | **ADR-0006 uygulaması:** `game/features/modifiers/` — `StatModifier`, `StatResolver`, `ModifierSource`, `ModifierController` + birim testleri (ADR doğrulama listesi) | C-34 raporu bilgi notu (kuyrukta uygulama görevi yoktu; M1 lütuf havuzu buna dayanır) | C-17 | ADR-0006 doğrulama testleri yeşil |
| C-56 | [ ] | **ADR-0007 uygulaması:** `SaveSerializer` / `SaveStore` / `SaveController`, tur sonu otomatik kayıt, `.bak` rotasyonu + testler | C-34 raporu bilgi notu | C-17, C-51 | ADR-0007 doğrulama testleri yeşil; bozuk kayıt yedekten yüklenir |
| C-57 | [ ] | **Kod (ADR-0001 değişikliği):** `RootContext` context sahnelerini geçiş anında `load()` ile yükler (`const preload` kalkar), `_switch_to()` `remove_child(old)` → `queue_free()`; `GameContext` bölüm haritasını `chapter_id` ile `load()` eder (`chapter_1_map.tres` preload'u kalkar) | `docs/architecture/architecture-review-2026-10-19.md` B4 | C-17 | Testler yeşil; grep: `root_context` / `game_context`'te büyük sahne `preload` yok; menü ↔ oyun geçişi çalışır (ekran görüntüsü) |
| C-58 | [ ] | **Motor referansı 4.7 tazeleme:** `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md`, `modules/*` 4.6'da doğrulanmış → 4.6→4.7 farkları (resmi release notes / migration guide) işlenir, `VERSION.md` 4.7 satırı doldurulur | C-17 godot-specialist bulgusu | — | Her dosyada "Last verified: 4.7"; VERSION.md 4.7 satırı kaynaklı |
| C-59 | [ ] | **ADR: Move Resolution — saf Outcome + Apply** (`/architecture-decision`): varış dallarını (savaş / arındırma / barışçıl) ve gelir tahminini (F2) önizleme ile uygulamanın paylaştığı saf fonksiyonlara ayırır; `SpiritController` çağrı noktası | TR-army-003, TR-resource-006 (C-17 raporu, öncelik 1) | C-17 | ADR Accepted; TR-army-003 ✅ |
| C-60 | [ ] | **ADR: Presentation Layer & Reports** (`/architecture-decision`): HUD, bilgi paneli, savaş raporu, hamle önizlemesi, yayılım göstergesi, lütuf modalı için görünüm sözleşmesi (yenileme, sinyaller) | TR-combat-003, TR-map-004, TR-spirit-010 (C-17 raporu, öncelik 2) | C-17 | ADR Accepted; TR-combat-003 ✅ |
| C-61 | [ ] | **ADR: Localization & Pixel-Font Pipeline** (as-built `LocaleFontController`, 11 dil, RTL, font boyut kuralları) | TR-concept-006 (C-17 raporu) | C-17 | ADR Accepted; TR-concept-006 ✅ |
| C-62 | [ ] | **ADR: Scene flow & chapter loading** — sahne sonu sırası (zafer → zorunlu lütuflar → kayıt → outro), `chapter_id` ile içerik yükleme yolu, Continue | TR-concept-007, TR-map-002 (C-17 raporu) | C-35 | ADR Accepted; TR-concept-007 ✅ |
| C-35 | [ ] | **M1 · GDD:** `scene-flow.md` — sahne intro/outro anlatı ekranları, Kök Böri "genesis" sahnesi, Prolog kazanma → Kağan ilanı, bölüm unlock (`/design-system`) | Konsept MVP #5; M1 | C-32 | 8 zorunlu bölüm + indeks satırı; `/design-review` geçer |
| C-36 | [ ] | **M1 · Harita:** Ötüken haritası → Oğuz ata yurdu (6 bölge, dağınık boylar + Erlik canavarı yerleşimi), data-driven `ChapterMapDefinition` + 11 dil bölge adları; art bible §5 canavar tamgası (`erlik_beast`) kaldırılır, in garnizonu 0 için veri kabul kriteri (C-53 / S1-e) | Konsept "Sonraki Adımlar"; M1 | C-29, C-34, C-49 | Harita verisi + testler + ekran görüntüsü |
| C-37 | [ ] | **M1 · Kod:** ordu üretimi + altın harcama (`resource-system.md` uygulaması) — UI butonu, maliyet/limit, düşman üretimi | C-28; M1 | C-18 | GDD kabul kriterleri birim testlerinde; ekran görüntüsü |
| C-38 | [ ] | **M1 · Kod:** Erlik canavarı + temel arındırma (C-29/C-30 kararlarına göre) | Konsept MVP #4; M1 | C-18, C-19, C-30, C-50, C-59 | Kabul kriterleri testte; canavar yenilip bölge arınır |
| C-39 | [ ] | **M1 · Kod:** Kök Böri çekirdeği — ruh kazanımı + ilk görünüş (MVP alt kümesi, C-31) | Konsept MVP #4; M1 | C-18, C-31, C-55 | Ruh kazanımı + M1 sunum akışı (tur başı / sahne sonu / erteleme / aynı tur HUD seçimi) + 3 lütfun etkisi testli; HUD'da Ruh ve Kök Böri düğmesi görünür (spirit §3.8, C-53) |
| C-40 | [ ] | **M1 · Kod:** sahne akışı — intro/outro ekranları, Kök Böri sahnesi, kazanma/kaybetme → outro (`features/campaign/`) | C-35; M1 | C-35, C-18, C-62 | Yeni kampanya → intro → harita → zafer → outro akışı; 11 dil key'leri |
| C-41 | [ ] | **M1 · UX + Kod:** Prolog öğretici akışı (fetih → kaynak → üretim → savaş → arındırma sırasıyla tanıtım) — `/ux-design` spec + uygulama | Konsept "Prolog — ÖĞRETİCİ"; M1 | C-37, C-38, C-39, C-40, C-59, C-60 | UX spec dosyası; rehbersiz oyuncu her mekaniği bir kez görür |
| C-42 | [ ] | **M1 · Kilometre taşı kapanışı: Prolog Demo** — uçtan uca oynanış, `/smoke-check`, `/playtest-report`, macOS/Windows demo export'u | M1 | C-36, C-37, C-38, C-39, C-40, C-41 | Başlangıçtan Kağan ilanına çökmeden oynanır (20–35 dk); smoke PASS; playtest raporu; çalışan export |
| C-43 | [ ] | **M2 · Tasarım:** Perde 1 (Doğu — Cürcet Yönü) — 8 bölgelik harita/seviye, Cürcet Kağan AI'ı, çürümüş orman + körmös (`/team-level`) | Konsept "Perde 1"; M2 | C-42 | Seviye dokümanı + gerekli GDD güncellemeleri |
| C-44 | [ ] | **M2 · Tasarım:** ruh lütuf sistemi tam kapsam + Erlik katmanı (enemy-layers / corruption-purification eksik GDD'leri), `/review-all-gdds` | Konsept "Vertical Slice" kademesi; M2 | C-42 | GDD'ler yazılı; çapraz inceleme PASS/CONCERNS; lütuf arzı/maliyet eğrisi `/balance-check` (D5, C-53) |
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
| 2026-10-08 | Kilometre taşları M1 Prolog Demo (C-35…C-42) + M2 Vertical Slice (C-43…C-48) kuyruğa eklendi; korunma kuralı | `b7e5af5` |
| 2026-10-08 | C-28: `resource-system.md` (altın + ordu üretimi, F1–F7, simülasyonla doğrulanmış Prolog değerleri, 24 AC); karşı GDD güncellemeleri, registry ilk kayıtlar | `1468973` |
| 2026-10-08 | C-14: `/consistency-check` → 2 çakışma (K2 düzeltildi, K1 açık → C-33/C-31); registry +3 sabit; rapor `docs/consistency-report-2026-10-08.md` | `5ba890b` |
| 2026-10-08 | K1 (C-14 çakışması): bozulma üretimi seviye tablosu `[1.0, 0.75, 0.5, 0.0]` — kullanıcı kararı; W8/W12 kapandı | `18df1d4` |
| 2026-10-18 | C-15: ADR-0006 Additive Modifier / Stat Pipeline (kaynak anahtarlı `StatModifier`, saf `StatResolver`, `exclusive_group`); registry +3 durus; TR-spirit-006 kapandı | `62de438` |
| 2026-10-18 | C-16: ADR-0007 Save/Load Persistence (versiyonlu JSON, saf SaveSerializer, atomik .bak rotasyonu, tur sonu otomatik kayıt); ADR-0004 göç planı kısmen supersede; registry +3 durus; TR-concept-002 kapandı; resource-system açık soru #6 çözüldü | `bf4f2ff` |
| 2026-10-18 | C-29: Erlik modeli = bozulma katmanı (canavar = bozuk nötr bölge, ERLIK sahip türü yok); sahip spirit-system; `end_turn`: AI → Erlik yayılımı → gelir → tur+1 → kontrol; Prolog: Canavarın İni seviye 3 + aralık 3; B2/B4/D3 kapandı; yeni görev C-49 | `e0eae22` |
| 2026-10-18 | C-30: arındırma = ordu varışının 2. dalı (yabancı garnizon yok + bozuk → `CombatResolver(P, corruption_strength)`, 1 aksiyon, başarısızlıkta kuvvet kaybolur, düşman arındıramaz); fetih bozulmayı korur (B5-A); B3/B5 kapandı; registry +2; yeni görev C-50 *(gece modu: önerilen seçenek)* | `f8e3737` |
| 2026-10-18 | C-31: lütuf sunumu tur başı / sahne zaferi, erteleme, etki seçildiği an, türetilmiş durum (TR-spirit-008); katalog `stat_id` + `requires` + yığılma sınırı; Bereket/Kurt Gücü/Demir Post düz +1, savaş "Etkin güç" (M2); Gök Kalkanı `I + min(k,3)`; MVP alt kümesi §3.8; B6/W9/W10/W11/D5 kapandı; resource açık soru #1 çözüldü *(gece modu: önerilen seçenek)* | `ae8abdd` |
| 2026-10-18 | C-32: tur ortası zafer oyunu anında bitirir (`MapState.game_result` kilidi), tur sonu kontrolü kaybetme → kazanma, kazanma kapsamı siyasi + genişleme + `erlik_foci` (D4), `conquered_neutral_count` (W7); B7/W7/D4 kapandı; TR-map-006 revised; kod düzeltmesi C-51 açıldı *(gece modu: önerilen seçenek)* | `b48e788` |
| 2026-10-18 | C-33: GDD düzeltmeleri — W1 örnek (army=2), W2 dağılma, W3 boş kalan bölge nötr, W4 knob, W5 sahip-bağımsız kurallar + §3.5 planlı, W6 alfabetik eşitlik bozma; bilgi notları (indeks bağımlılık sütunu + eksik sistemler, konsept tarih/adımlar, MapState alanları, AC9 renk körlüğü, `scene_id = chapter_id`, yayılım aday kümesi + sayaç); kod düzeltmesi C-52 *(gece modu: önerilen seçenek)* | `1390df2` |
| 2026-10-19 | C-34: `/review-all-gdds` yeniden → **CONCERNS** (0 engelleyici; 9 tutarlılık + 12 tasarım uyarısı); rapor `gdd-cross-review-2026-10-19.md`; indeks Designed; yeni görevler C-53 (düzeltmeler, C-17'yi bloklar), C-54 (anlatı sesi), C-55/C-56 (ADR-0006/0007 uygulaması); C-49 kapsamı genişledi *(gece modu: önerilen seçenek)* | `f661227` |
| 2026-10-19 | C-53: çapraz inceleme düzeltmeleri — resource §4/AC15 "eskimiş" işaretleri + aralıklar; spirit aynı tur lütuf kuralı, `P_eff`, işleme sırası (S1-a), hamle önizlemesi + yayılım göstergesi gereksinimleri (N7), `boons` tek kaynak; region-map veri modeli sahipliği (W-G), `turn_ended`/erken çıkış (W-D, S2-b), kilitte lütuf seçimi (S1-c); army 'barışçıl' nitelemeleri + yerinde üretim (N11c); combat arındırma ↔ knob ayrımı; konsept kademe tablosu (W-H); ADR-0005/0006/0007 değişiklik notları; registry +4 sabit, TR-spirit-005 revised; C-39/C-44/C-51/C-36 kriterleri güncellendi *(gece modu: önerilen seçenek)* | `62f8b96` |
| 2026-10-19 | C-17: `/architecture-review` → CONCERNS (36 TR: 23 ✅ / 9 ⚠️ / 4 ❌); bağımsız technical-director + godot-specialist (4.7.1 deneyleri); 4 metin çakışması (B1–B4) + W1–W11 düzeltildi; 7 ADR **Accepted**; TR registry v3 (+11 TR, `resource` slug'ı, 15 revizyon); mimari registry (`spirit_state`, Continue, AI imzası); yeni görevler C-57…C-62 *(gece modu: önerilen seçenekler D1–D4)* | `815e07c` |
| 2026-10-19 | C-18: `docs/architecture/architecture.md` v1.0 — katman haritası, modül sahipliği, veri akışları (hamle, tur sonu, kayıt/yükleme, başlatma, zafer), API sınırları, ADR denetimi, gerekli ADR'ler (C-59…C-62), ilkeler, açık sorular QQ-01…08; TD öz-inceleme CONCERNS *(gece modu)* | `bf6932f` |
| 2026-10-19 | C-19: ADR-0005 uygulaması — `EnemyAIController.decide(map, acted)` + `ErlikSpreadController.decide(map, interval) -> SpreadDecision` (saf), `MapController` karar → uygula döngüsü (ele geçirilen bölge aynı tur hareket etmez), `ArmyController` `mover` parametresi; `RegionData.corruption_level`, `MapState.erlik_spread_interval/last_erlik_spread_turn` alanları; 104/104 test (24 yeni) | `278760f` |
| 2026-10-19 | C-21: koçboynuzu köşe + kilim şevron bandı 9-slice çerçeveleri (`generate_ui_frames.gd`, 5 PNG), `PrimaryButton` / `ModalPanel` tema varyasyonları; Tur Bitir, Ordu Gönder, Yeni Sefer birincil; ayarlar ekranı modal panelde; 112/112 test (8 yeni), palet 0 ihlal; en/de ekran görüntüleri (Xvfb) *(gece modu)* | `21a9735` |
| 2026-10-19 | C-22: harita zemini ve komşuluk çizgisi palete bağlandı ve data-driven (`ChapterMapDefinition.ground_color` / `adjacency_line_color`, opak); Prolog `#1A2614` / `#436129`; render piksel kontrolü: harita alanında palet dışı renk 0; 116/116 test *(gece modu)* | `ffbf2b5` |
| 2026-10-19 | C-23: bölge seçim "tık"ı + ses altyapısı — ADR-0008 (Accepted), `default_bus_layout.tres` (Music/SFX → Master; ayar kaydırıcıları artık çalışıyor), `AudioController` (havuz 4, SFX bus), `SfxLibrary` + `sfx_ui_region_select.wav` (sentez yer tutucu); 123/123 test (7 yeni); Xvfb çalıştırması hatasız *(gece modu)* | `85eeea3` |
| 2026-10-19 | C-24: `.uid` politikası — commit edilir (`game/.gitignore`'dan `*.uid` kaldırıldı, 272 `.uid` eklendi, yetim yok); teknik tercihlere "Version Control Notes" *(gece modu: önerilen seçenek)* | `061ada8` |
| 2026-10-19 | C-25: sessiz başlangıç klavye odağı — `FocusReveal` (`game/ui/focus_reveal.gd`), menü/ayarlar/oyun ekranlarında gizli odak, ilk gezinme tuşu görünür yapar (taşımaz, Enter basmaz); 131/131 test (8 yeni); Xvfb: açılışta çerçeve yok, ilk ↓ çerçeveyi Yeni Sefer'de gösterir, ikinci ↓ Ayarlar'a geçer *(gece modu: önerilen seçenek)* | `2e016f3` |
| 2026-10-19 | C-26: bölge panelinde `/ tur` birimi ayrı çeviri key'i `PER_TURN` (`%s / …`, 11 dil; Almanca "Runde" büyük harf), `to_lower()` kaldırıldı; oyun kodunda `to_lower/to_upper/capitalize` yok; 134/134 test (3 yeni); de/ar ekran görüntüleri (Xvfb) | `9883e76` |
