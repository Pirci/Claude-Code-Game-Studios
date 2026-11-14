# Devam İndeksi — TURAN: Kızılelma

> **Tek doğruluk kaynağı.** Kullanıcı "devam" yazdığında iş buradan sürdürülür.
> Yalnız **açık** işler burada tutulur; kapananlar `production/continuation-archive.md`'de;
> `production/session-state/active.md` yalnızca oturum notlarıdır.

- **Son güncelleme:** 2026-11-14
- **Son commit:** `3f1d98f` (C-93: E5 bölüm seçimi M2)
- **Proje evresi:** Concept (`production/stage.txt`)
- **Aktif görev:** C-42 — kullanıcının playtest raporu bekleniyor; sıradaki C-94 (Perde 1 denge replay'i)

---

## Devam Protokolü

Kullanıcı yalnızca **"devam"** yazdığında (büyük/küçük harf, "devam et", "Devam."
fark etmez) şu adımlar **sırayla** uygulanır:

1. **Durumu oku (yalnız bunlar):** bu dosya → `production/session-state/active.md` →
   `git log --oneline -5` → `git status --short`. Arşivler
   (`continuation-archive.md`, `session-state/archive.md`) **okunmaz** — geçmiş bir
   karar gerekirse `grep` ile tek satır aranır.
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
   (Kuyrukta **bulunmayan** bağımlılık ID'si = kapanmış, arşivdedir.)
5. **Duyur ve başla:** kullanıcıya tek satırla "Sıradaki: C-XX — … (plan: …)" yaz;
   görevi `[~] (tarih)` olarak işaretle. "devam" komutu, kuyrukta tanımlı olan
   bu görevi uygulamak için onay sayılır. Görevin içinde **kullanıcıya ait bir
   karar** (tasarım seçimi, kapsam, yeni bağımlılık) çıkarsa sorulur.
6. **Doğrula:** testler (`QUIET=1 tools/ci/run-tests.sh [test_yolu]` — yalnız özet +
   başarısızlar; çalışırken ilgili test yolu, kapanışta bir kez tam paket), UI işlerinde ekran görüntüsü,
   görevin "Bitti kriteri".
7. **Kapat:** görev satırını kuyruktan **kes**, `[x] <commit>` olarak
   `continuation-archive.md`'nin sonuna ekle (okumadan `cat >>`) → üstteki
   "Son commit / Aktif görev" alanlarını güncelle → `active.md`'ye en fazla 4
   satırlık özet yaz (4'ten eski özet `session-state/archive.md`'ye taşınır) → **commit at ve push et** (`git push origin main`; kullanıcı
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
- Kullanıcı başka bir iş isterse o yapılır; bitince arşive ("Tamamlananlar")
  olarak işlenir, kuyruk sırası bozulmaz.
- Her commit'ten sonra push edilir; push başarısız olursa sebebiyle birlikte kullanıcıya bildirilir.
- **Temel amaç (kullanıcı, 2026-10-19): Demo (M1) ve Vertical Slice (M2).** Sıra:
  C-42 kapanışı → C-66 → C-43…C-48. Diğer işler (C-67, C-68, K-03, ses cihaz
  kontrolü) yalnız playtest gerektirirse ya da M2 cilasında öne alınır. Kullanıcıya
  seçenek listesi değil, tek öneri sunulur.
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
| K-03 | [ ] | **İnceleme:** C-54 anlatı metinleri + C-39 lütuf kartları + *C-91 Perde 1 metinleri* (`CHAPTER_2_*`, `HINT_ENEMY_KING/CAPITAL`, `REGION_*` ×8, `OBJECTIVE_FOCI_CH2`, `CAMPAIGN_END_DEMO_1`; Jurchen/女真/여진, ar الجورتشن, Kanglı/康里, Urum; kısaltılmış bölge adları es/pt/ru/ar) (19 key; tr yüzde `%%%s` sırası, "+1 tur" tekil birim yalnız 1 için doğru) — ana dil incelemesi (öncelik zh/ja/ko/ar, sonra ru/pt/fr/es/de) + Türkçe metin onayı ("Ben sizlere oldum Kağan" destan alıntısı bilinçli) | `design/narrative/narrative-voice.md` §8; kanon düzeyi "Provisional" |

## Görev Kuyruğu

| ID | Durum | Görev | Kaynak | Bağımlı | Bitti kriteri |
| --- | --- | --- | --- | --- | --- |
| C-68 | [ ] | **Art:** Prolog anlatı illüstrasyonları (5 adet, 640×360, ≤ 32 renk, alfa 0/255): `ill_prolog_intro`, `ill_prolog_tribes`, `ill_prolog_genesis`, `ill_prolog_beast_purified`, `ill_prolog_kagan` (`game/assets/art/illustrations/`); gelince içerik testine L7 (dosya, boyut, palet) eklenir | C-40 sırasında keşfedildi (anlatı ekranı şu an düz indigo zemine düşüyor) | C-40 | 5 dosya palet doğrulayıcıdan geçer; L7 testi yeşil; en/de/ar ekran görüntüsü |
| C-42 | [~] | **M1 · Kilometre taşı kapanışı: Prolog Demo** — uçtan uca oynanış, `/smoke-check`, `/playtest-report`, macOS/Windows demo export'u. *İlerleme (2026-10-19):* kararlar — export macOS + Windows, playtest'i kullanıcı oynar; UI-düğmeli uçtan uca test `prolog_playthrough_test.gd`, `export_presets.cfg` (artık takipte) + uygulama ikonu, smoke PASS (`production/qa/smoke-2026-10-19.md`, `99d686e`), export'ta BOM hatası düzeltildi (kayıt/ayar okunamıyordu), protokol + rapor şablonu `production/qa/playtest-c42-protocol.md`. **Bekleyen:** kullanıcının playtest raporu → `/playtest-report analyze` → kapanış | M1 | C-36, C-37, C-38, C-39, C-40, C-41, C-63 | Başlangıçtan Kağan ilanına çökmeden oynanır (20–35 dk); smoke PASS; playtest raporu; çalışan export |
| C-46 | [~] (2026-10-21) | **M2 · Sanat:** Prolog + Perde 1 temsili kalite pixel art (harita, birim, tamga, illüstrasyon) — `/asset-spec` + üretim *İlerleme (2026-10-21): Perde 1 küçük varlıkları bitti — `generate_env_forest.gd` (2 sağlıklı + 2 çürük ağaç, köprü, Cürcet otağı, orman körmösü 2 kare), test + palet temiz. İlahi panel + lütuf ikonları bitti (C-67 kapandı). Kalan: illüstrasyonlar (Prolog 5 + Perde 1 5; kullanıcı kararı: Retro Diffusion MCP / yerel Aseprite bağlanınca), Kök Böri figürü + kart belirme dither'i, birim sprite'ları (harita şu an sayı etiketi kullanıyor — gerek olup olmadığı C-47 ile birlikte)* | Art bible; M2 | C-43 | Asset'ler palet doğrulayıcıdan geçer; manifest güncel |
| C-47 | [~] (2026-10-22) | **M2 · Kod:** Perde 1 + lütuf sistemi + Erlik katmanı uygulaması — önce `/create-epics` + `/create-stories` ile parçalanır, story'ler kuyruğa C-XX olarak eklenir *(C-43: Perde 1 için 13 sıralı uygulama adımı + kabul kriterleri `design/levels/perde1-dogu-curcet.md` §13'te; açık ölçümler: nehir üst sınırı `_top_bar_height()+4`, arındırma P ≥ 13 doğrulaması, denge değerleri gerçek controller replay ile; Perde 1 `.tres` adı `chapter_2_map.tres` kalıbıyla; `DEFEAT_REASON_ERLIK` metni 11 dilde sahneden bağımsız yazılacak; ses yönü `audio-director` ile)* | M2 | C-43, C-44, C-45 | Tüm story'ler Done; testler yeşil *(C-44: `enemy-layers.md` AC21 güney ≤ T16 BLOCKING + AC22 ölçümleri (felç oranı, Ruh çiftçiliği, GK1/Bereket1 girişleri, N4/N5/N6/N8/N9); `decide(map_state, acted, defense_modifiers)` + profil `bind_config`; Demir Post ≤ 3; kampanya tohumu (kayıt alanı — ADR-0007 eki); `SceneDefinition.boon_pool_ids`)* *(C-45: `design/ux/` spec'leri — savaş/arındırma raporu + tur özeti modalları kodda YOK, yazılacak (`battle-report.md`; ADR-0010 eki: `combat_occurred(outcome)`, MoveOutcome önceki sahip + reason, yayılım öncesi seviye); klavyeyle bölge seçimi (Tab/ok, `hud.md` A-7); tüm modallarda giriş koruması (lütuf sunumu eksik); HUD yayılım sayacı / Odak tehlikede / Cürcet x/3 / vuruş eşiği satırı; `DEFEAT_REASON_ERLIK` sahneden bağımsız metin 11 dil; × ve → glif testi)* *(C-47 kırılımı onaylı 2026-10-22: 6 epic (`production/epics/index.md`), 30 story C-70…C-99 kuyrukta (C-48'den önce); C-47 şemsiye — hepsi [x] olunca kapanır. Kararlar: AC21 ayar sırası saldırı başlangıcı → takviye → garnizon; sanat bloklamaz (yer tutucu); başlangıç C-70)* |
| C-94 | [ ] | **M2 · E6 (I):** **Perde 1 denge replay'i** (gerçek controller, C-64 kalıbı) — N-fast, S-purify, Mixed, no-purify, pasif, 3 boş tur; ilk AI vuruşu turu | C-47 kırılımı (`production/epics/m2-breakdown.md`) | C-82, C-83, C-89 | seviye §13 #10, kabul #2–#4; enemy-layers AC15 (fark çıkarsa replay esas, belge güncellenir); pasif T15 Erlik kaybı; 3 boş tur T15 öncesi zafer yok; kanıt: `tests/integration/balance/perde1_balance_test.gd` |
| C-95 | [ ] | **M2 · E6 (I):** **AC21 kapısı: S-purify ≤ T16 (BLOCKING)** — replay sonucu; geçmezse seviye verisi ayarı (bkz. Karar 1), tablo yeniden üretilir, Kök Böri'nin sözü değişmez | C-47 kırılımı (`production/epics/m2-breakdown.md`) | C-94 | enemy-layers AC21; seviye kabul #11; cross-review D1; diğer senaryolar hedef aralığında kalır (T10–18); kanıt: `perde1_balance_test.gd` içinde `test_s_purify_wins_by_turn_16` + `design/balance/perde1-replay-<tarih>.md` |
| C-96 | [ ] | **M2 · E6 (I):** **AC22 ölçümleri + kabul/erteleme kaydı** — T5 sonrası AI adayı tur oranı (H2), felç + yeniden arındırma Ruh/tur (H3), GK1 / Bereket1 giriş varyantları (H4: pasif + GK1 > T18 → eşik 9 → 8), N4/N5/N6/N8/N9 | C-47 kırılımı (`production/epics/m2-breakdown.md`) | C-95, C-80 | enemy-layers AC22; seviye kabul #12; H2 düşükse başkent F-E2 muafiyeti **kullanıcıya sorulur**; H3 aşılırsa ×0.5 yedeği açılır (spirit §3.7); spirit §5 işaretçileri güncellenir; kanıt: `tests/integration/balance/perde1_measurements_test.gd` + rapor `design/balance/perde1-replay-<tarih>.md` |
| C-97 | [ ] | **M2 · E6 (I):** **Perde 1 uçtan uca oynanış** — UI düğmeleriyle Prolog zaferi → E5 → intro → E2 → zafer → outro → `CAMPAIGN_END` → menü; kayıt/yükleme sonrası dekor + sahiplik eşit; Yeniden Dene tohumu korur | C-47 kırılımı (`production/epics/m2-breakdown.md`) | C-90, C-91, C-93, C-73 | seviye §13 #11, kabul #7; scene-flow AC (S2/S3, Devam Et `map = null` → E5, AC-E5-9); spirit AC25 akış düzeyinde; kanıt: `tests/integration/campaign/perde1_playthrough_test.gd` |
| C-98 | [ ] | **M2 · E6 (V):** **Görsel kanıt + performans** — nehir üst sınırı `_top_bar_height()+4` ölçümü, Perde 1 haritası (ağaç yoğunluğu, çürük ağaçlar), HUD L1–L7 / A-1 gri tonlama, raporlar 11 dil (en/de/ru/ar asgari), HUD P1 ≤ 1.6 ms | C-47 kırılımı (`production/epics/m2-breakdown.md`) | C-97, C-88, C-72 | seviye kabul #8; §7.3 açık ölçüm; hud L1–L7, A-1, P1; battle-report "Yerleşim ve yerelleştirme"; kanıt: `production/qa/evidence/c98-perde1-*.png` + `production/qa/evidence/c98-perf.md` |
| C-99 | [ ] | **M2 · E6 (D):** **Belge kapanışı** — seviye §12 tablosu (region-map, resource, spirit, scene-flow, art bible, narrative-voice, entities.yaml), `tr-registry.yaml` enemy-layers TR-ID'leri + yeni ADR ekleri, `architecture.md` §4 `end_turn` notu, seviye §5 simülasyon tablosu → replay değerleri | C-47 kırılımı (`production/epics/m2-breakdown.md`) | C-96, C-97 | seviye §13 #13; enemy-layers §6 karşı güncellemeler kapalı; `/architecture-review` için TR kapsamı güncel; kanıt: Belge diff'i; `tr-registry.yaml` TR-enemy-* ✅ |
| C-100 | [ ] | **Demo (M1) erişilebilirlik:** Prolog komşuluk çizgisi `#436129` zemin `#1A2614`'e 2,24:1 (< 3:1, WCAG 1.4.11 grafik nesne) — bölge bağlantıları zor seçiliyor. Öneri: Bozkır Yeşili rampasında zemine ≥ 3:1 veren ton (art-director onayı), `chapter_1_map.tres` tek satır; `map_readability_contrast_test` istisnası silinir | C-86 kontrast denetimi | C-86 | Prolog çizgi/zemin ≥ 3:1, istisna listesi boş; Prolog ekran görüntüsü (en) |
| C-101 | [ ] | **M2 · UI:** Perde 1 üst çubuk ilerleme satırı (`Objective tribes · foci · enemy lands`) ru/ar/de'de 640 px'e sığmıyor, sonu `…` ile kırpılıyor (C-88 `_fit_objective_row`) — kısa biçim key'leri ya da ikon+kesir | C-91 bulgusu (`production/qa/evidence/c91-perde1-map-ru.png`, `c91-perde1-map-ar.png`) | C-91 | 11 dilde üst çubuk kırpmasız (ölçüm testi `Font.get_string_size`); ekran görüntüsü ru/ar/de |
| C-102 | [ ] | **M2 · UI (karar gerekli):** **Hamle önizlemesi yok** — `MapController.preview_move()` var ama hiçbir görünüm çağırmıyor; `PURIFY_PREVIEW_OK/FAIL`, `PURIFY_CONFIRM_AGAIN` (başarısız arındırmada ikinci tık onayı, ADR-0011 §6), `CHAPTER_1/2_HUNT_HEADING/READY/NOT_READY` metinleri yazılı ama gösterilmiyor (Prolog dahil). Hedef modunda hedef bölge üzerine gelince/odaklanınca önizleme satırı + başarısız arındırmada ikinci seçim | C-92 bulgusu | C-92 | ux/battle-report.md §216 "önizleme / ikinci tık"; narrative-voice AC-V3 (`HUNT_READY` Kök Böri anı); ekran görüntüsü + entegrasyon testi |
| C-103 | [ ] | **Tür pivotu (karar gerekli):** oyun artık strateji + kartla şehir kurma + kule savunması + sıra tabanlı karışımı (kullanıcı, 2026-11-14). `game-concept.md` Temel Döngü / Mekanikler / Sütunlar / MVP yeniden yazılır (`/brainstorm` veya `/quick-design` ile: kart destesi, şehir ızgarası, dalga yapısı, mevcut bölge haritasının rolü), ardından `systems-index.md` ve etkilenen GDD/ADR listesi (`/propagate-design-change`). **M2 görevleri (C-94…C-48) eski tasarıma göredir — bu görev kapanmadan sürdürülüp sürdürülmeyeceği kullanıcıya sorulur** | Kullanıcı isteği 2026-11-14 | — | Konsept belgesinde "Tür Revizyonu" notu kalkar; yeni sistem listesi + hangi mevcut sistemin kalıp hangisinin değiştiği yazılı; kuyruk yeni türe göre yeniden sıralanmış |
| C-104 | [ ] | **Ajan sistemi · tür uyarlaması:** C-103 kapanınca tasarımcı/programcı ajan tanımlarına yeni türün alanlarını ekle (kart destesi/el, şehir ızgarası, dalga + kule dengesi), `directory-structure.md`'ye yeni feature klasörlerini yaz; kullanılmayan ajan/skill'leri (ör. live-ops, analytics) yeniden değerlendir | Token optimizasyonu 2026-11-14 | C-103 | Ajan tanımları yeni sistem listesini anıyor; feature klasörleri belgede |
| C-48 | [ ] | **M2 · Kilometre taşı kapanışı: Vertical Slice** — `/vertical-slice` + `/gate-check` (Pre-Production → Production) | M2 | C-46, C-47 | PROCEED/PIVOT/KILL kararı yazılı; PIVOT'ta düzeltme görevleri kuyruğa eklenir |
