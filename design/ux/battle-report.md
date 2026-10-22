# UX Spec: Savaş / Arındırma Raporu ve Tur Özeti (C-45)

> **Durum**: Approved (C-45, 2026-10-21)
> **Bağlantılı kararlar**: K1 (Yayılım: Sade — "Odak tehlikede" yalnız HUD), K2 (Kağan vuruş eşiği — panel satırı, rapor değil), ortak kurallar (modal genişliği 288/304, girdi koruması, Esc kuralı, 12 px başlık, düz kesme açılış, çubuk ölçüleri 40/27/31) — bkz. §10 ve `design/ux/hud.md` §13
> **Yazar**: ux-designer. **Son güncelleme**: 2026-10-21. **Platform**: PC, klavye + fare (gamepad/dokunmatik yok).
> **Erişilebilirlik katmanı**: Standart (klavye tam, renk tek başına anlam taşımaz, Hareketi Azalt, 11 dil). Ekran okuyucu / AccessKit kapsam dışı.
> **Şablon**: `.claude/docs/templates/ux-spec.md` (kısaltılmış; boş kalan bölümler bilinçli atlandı).

**İlgili:** ADR-0011 (karar 4-5, 7), ADR-0010 (`MoveOutcome`; G1–G4 için ek gerekir), ADR-0009 (metin/font), `combat-system.md` §3-5 + "Etkin güç" (M2),
`spirit-system.md` §3.2/§3.6, `enemy-layers.md` §3.4 (R1 = hep `BATTLE_LOST_DEFENSE`), `narrative-voice.md` §5.2/§5.5/§8,
`perde1-dogu-curcet.md` §2, `gdd-cross-review-2026-10-21.md` S1-c, art bible §7, `design/ux/hud.md`.
**Kardeş spec'ler:** `design/ux/prolog-tutorial.md` (ipucu balonu), `design/ux/hud.md`, scene-flow §3.6 (zafer kartı, aynı modal kalıbı).

> **Mevcut durum (kod, 2026-10-21):** `ModalQueue` (`ui/modal_queue.gd`), `VictoryCard`/`BoonOfferModal` (modal kalıbı), `MoveOutcome`
> (`features/army/move_outcome.gd`) ve 11 dillik metin anahtarları (`translations.csv` satır 50-70, 91-94) **VAR**.
> `BattleReport`, `PurificationReport`, `TurnSummaryReport` sahneleri **YOK**; `GameContext._on_combat_occurred` /
> `_on_purification_resolved` / `_on_turn_ended` yalnız `_refresh_views()` çağırıyor (rapor göstermiyor). Bu spec
> **M2'de eklenecek** görünümleri tanımlar. Kanıt görseli: yok (rapor henüz çizilmedi); modal kalıp referansı
> `production/qa/evidence/c39-boon-offer-en-de-ru-ar-zh-tr.png`.

---

## 1. Amaç ve oyuncu ihtiyacı

| Soru | Cevap |
| --- | --- |
| Oyuncu ihtiyacı | Hamlesinin ne olduğunu ("neden kazandım/kaybettim, kaç yiğit düştü") ve **gece olanları** (hamlem dışında ne değişti) tek bakışta, kuru hesap olmadan anlamak |
| Oyuncu hedefi | Raporu <= 2 sn'de okuyup Enter ile devam etmek; sayıdan öğrenip sonraki hamleyi ayarlamak (özellikle başarısız arındırmada `S`) |
| Oyun hedefi | Sonucu `MoveOutcome` / yayılım verisinden **olduğu gibi** göstermek; yeniden hesap yok (ADR-0011 K4, AC-V2) |
| Duygu | Destan anlatımı: kısa ozan dizesi + sayı satırları; kayıpta ağırbaşlı, arındırmada tören |
| Bağlam | Oyuncu az önce tıkladı (orta-yüksek gerilim, bilişsel yük: harita + ordu sayıları). Tur özetinde "Tur Bitir"e basmış, sonucu merak ediyor |
| Korkuları | Ne olduğunu kaçırmak; çift tıkla raporu bilmeden geçmek; AI hamlesini hiç görmemek (K8: niyet önceden gösterilmez, rapor tek bilgi kaynağı) |

## 2. Navigasyon ve akış

```
GameContext (harita)
  └── ModalQueue (overlay CanvasLayer 10, tek modal, FIFO)
        ├── BattleReport        (oyuncu hamlesi, COMBAT)
        ├── PurificationReport  (oyuncu hamlesi, PURIFICATION)
        ├── TurnSummaryReport   (tur sonu, düşman + yayılım)
        └── BoonOfferModal      (şafak, <= 1 otomatik)  [C-39, mevcut]
```

**Modal davranışı:** modal; tam ekran arka plan harita girdisini keser (`MOUSE_FILTER_STOP`), tek modal. Kapatma: [Devam] / Enter / Space / **Esc = Devam**
(sonucu geri alınamaz, iptal yok — `VictoryCard` emsali; ortak Esc kuralı: tek güvenli çıkışı olan modalda Esc = o eylem). Dışarı tık kapatmaz.

| Giriş | Tetik | Veri | Not |
| --- | --- | --- | --- |
| Oyuncu savaşı | `MapController.combat_occurred`, `mover == PLAYER` | `MoveOutcome` (branch COMBAT) | Hamleden hemen sonra; durum zaten yazılmış ve harita yenilenmiş. **Bağımlılık:** sinyal bugün `CombatResult` taşır (G1) |
| Oyuncu arındırması | `purification_resolved`, `mover == PLAYER` | `MoveOutcome` (branch PURIFICATION) | Aynı |
| Tur özeti | `turn_ended` (oyun sürüyorsa) | tur boyunca toplanan düşman `MoveOutcome` listesi + yayılım olayı | **Şafak lütfundan önce** itilir |
| Barışçıl hamle | `army_moved` | — | **Rapor yok** (ADR-0011: yalnız savaş/arındırma) |
| Düşman barışçıl / nötr hedefe hamle | `army_moved` / oyuncuyu ilgilendirmeyen savaş | — | Özette **gösterilmez** (K8, ilgisiz) |

| Çıkış | Hedef | Veri | Not |
| --- | --- | --- | --- |
| [Devam] / Enter / Space / Esc | Kuyruktaki sonraki modal; boşsa önceki odak geri verilir (`FocusReveal.focus_quietly`) | `closed` sinyali | Modal `queue_free`; harita girdisi serbest |
| Oyun biterse (`game_won`/`game_lost`) | Sahne akışı (zafer kartı/yenilgi ekranı) | — | Karar Q3: aşağıda |

**Kuyruk sırası (ADR-0011 K5):** oyuncu raporu (hemen) → tur sonunda `TurnSummaryReport` → şafak lütfu (<= 1). Zafer: son hamle raporu
-> (`VICTORY_BEAT`) -> zorunlu lütuf dizisi -> epilog (scene-flow). Kayıt (`save_campaign`) `turn_ended`'da modaldan **önce** yazılır; modal kayıt durumunu etkilemez.

**Yenilgi sırası (Karar Q3, C-45):** oyuncunun son bölgesi düşerse (`NO_REGIONS`) sıra **son hamle raporu → yenilgi ekranı**'dır; `TurnSummaryReport` **atlanır** (yenilgi ekranı `DEFEAT_REASON_*` ile anlatır). Oyuncunun son bölgesi **düşman hamlesiyle** düşerse (tur sonu): özet açılmaz, düşmanın o hamlesi yenilgi ekranının nedenidir.

**`outcome == null` durumu (savunma):** sinyal `outcome` olmadan gelirse veya `MoveOutcome` `null` ise (ör. sürüm geçişi, eksik G1 uygulaması) görünüm **modal açmaz**, hata `push_warning` ile günlüğe yazılır ve `_refresh_views()` yine çalışır; oyun akışı kilitlenmez. Birim testi: `show_*(null)` → modal yok, kuyruk boş.

## 3. Düzen (640 x 360, tam piksel)

Ortak çerçeve: `ModalPanel` varyasyonu (opak `#1C150D`, 1px `#8A6D4F` + 2px kilim bandı, 5x5 koçboynuzu; art bible §7). Arka plan karartması
`ModalQueue.BACKDROP_COLOR` (mevcut, sabit alfa, fade yok). **İç genişlik tavanı 288 px, dış 304 px** (ortak modal kuralı). Üst çubuk 40 px (2 satır), alt çubuk 27 px; modal alt marjı **31** (27 + 4), üst marj 40.
Kullanılabilir modal yüksekliği ≈ 360 − 40 − 31 − 8 ≈ **281 px**.

```
 x=168                                         x=472        (BattleReport, ~304 x 120-150, y ortalı = ~105..255)
   ╔══════════════════════════════════════╗
   ║        Meydandan Haber  (HeaderLabel) ║  1. başlık  (ortalı, 12 px)
   ║        Doğu Obası  (SecondaryLabel)   ║  2. hedef bölge adı (Q1)
   ║  Akıncılarımız safı yardı. Toprak ... ║  3. ozan dizesi (<= 2 satır, ortalı)
   ║  ↓ Düşen yiğitlerimiz: 3  (kırmızı)   ║  4. sayı satırları (1-3 adet)
   ║    Karşı saftan düşen: 5              ║
   ║  ↑ Ayakta kalan yiğitlerimiz: 4 (yeşil)║
   ║              [ Devam ]  ●             ║  5. birincil düğme (PrimaryButton, >= 64px), odak
   ╚══════════════════════════════════════╝
```

| Bölge | İçerik | Boyut (en) | Taşma |
| --- | --- | --- | --- |
| Başlık | 12 px `HeaderLabel` (Arapça 16 px); 24 px yalnız tam ekran başlık kartında (cila) | 1 satır, <= 24 krk | Kısaltma yok; en uzun dil sığar (aşağıda) |
| Hedef adı | `SecondaryLabel`, `tr(region.name_key)` | 1 satır | `…` ile kısalt (bölge adı kuralı, art bible) |
| Ozan dizesi | `Label`, `AUTOWRAP_WORD_SMART`, genişlik 288 | <= 2 satır (Arapça 2-3) | Kaydırma yok, panel dikey büyür |
| Sayı satırları | ikon 9x9 / `↑ ↓` metin glifi + `Label`, sola dayalı (RTL'de sağa) | 1-3 satır | Tek satır, sayı **iki noktadan sonra** (çeviri biçimi) |
| Düğme | `[Devam]`, `CONTINUE` anahtarı | >= 64px | Genişler |

**Yerleşim (Karar Q2):** varsayılan merkez; hedef bölgeyi örtüyorsa `PanelPlacement.choose` ile alt/üst kenara (ObjectivePanel emsali). Alt kenarda alt marj 31, üst kenarda 40 korunur.

**Açılış:** M2 varsayılanı düz kesme; 4 kare dither cila (kabul ölçütü değil); Hareketi Azalt = dither yok + sabit kare.

**TurnSummaryReport** (aynı çerçeve, iç genişlik 288, en çok 3 olay bloğu görünür; en kötü yükseklik ≈ 3 blok × ~50 + başlık/düğme ≈ 200 px < 281):

```
   ╔══════════════════════════════════════╗
   ║        Gece Çökerken  (HeaderLabel)   ║
   ║  [↓] Düşman toprağı aldı. Yiğitlerimiz║  blok A: saldırı (varsa)  — ozan dizesi
   ║      düştü.                           ║
   ║      Doğu Obası · Düşen yiğitlerimiz: 4║    + bölge adı + OUR_FALLEN
   ║  [Erlik] Erlik'in lekesi yayıldı: ... ║  blok B: yayılım (varsa)
   ║  [!] Bir yayılım daha olursa bozkır.. ║  blok C: Erlik'in Gölgesi uyarısı (varsa, Q4)
   ║              [ Devam ]  ●             ║
   ╚══════════════════════════════════════╝
```

## 4. İçerik tabloları

Anahtarlar `narrative-voice.md` §8; hepsi CSV'de mevcut (CH2 anahtarları hariç). "En uzun dil" = CSV'den el sayımı (en/tr/de/fr/es/ru/pt/zh/ja/ko/ar), `%s` sayı/ad ile dolar.
Font: Fusion 12 (Arapça Unifont 16, tek gövde boyutu, hiyerarşi renkle). Metinde `-` ASCII. **Glifler:** `↑ ↓` Fusion'da var (`glyph_coverage_test`) ve metin glifi olarak kullanılır; `✓ ⚠ ✕` glifi yok → **piksel ikon**; `×` ve `→` için glif testi görevi yazılır (C-47), doğrulanana kadar kullanılmaz.

### 4.1 BattleReport (oyuncu hamlesi, `Branch.COMBAT`)

Seçim sırası: **BOTH_FELL** (`attacker_remaining == 0 && defender_remaining == 0`) -> `WON_ATTACK` (`attacker_won`) -> `LOST_ATTACK` (beraberlik dahil).

| Alan | Veri kaynağı | Anahtar | Bütçe / en uzun dil | Arapça notu |
| --- | --- | --- | --- | --- |
| Başlık | sabit | `BATTLE_REPORT_HEADING` | 24 / de 22 ("Kunde vom Schlachtfeld") | Unifont 16, tek satır sığar |
| Hedef adı | `to_id` -> `RegionData.name_key` | (mevcut bölge anahtarı) | <= 12 en | Bölge adı Arapça font |
| Dize: zafer | `combat.attacker_won` | `BATTLE_WON_ATTACK` | 64 / es 59 | 2 satır |
| Dize: yenilgi | `!attacker_won` | `BATTLE_LOST_ATTACK` | 64 / tr 51 | 2 satır |
| Dize: ikisi de düştü | iki kalan 0 | `BATTLE_BOTH_FELL` | 64 / es 47 | 2 satır |
| Düşen yiğitlerimiz | `combat.attacker_losses` | `REPORT_OUR_FALLEN` | 28 / tr 22+n | Sayı `NumberFormatter.format_int` + LRI/PDI yalıtımı |
| Karşı saftan düşen | `combat.defender_losses` | `REPORT_THEIR_FALLEN` | 28 / tr 22+n | Aynı |
| Ayakta kalan (zafer) | `combat.attacker_remaining` (= `target_army_after`) | `REPORT_OUR_STANDING` | 28 / tr 27+n (bütçe aşımı kabul: satır 288px'e sığar) | Aynı |
| Karşı safta kalan (yenilgi) | `combat.defender_remaining` | `REPORT_THEIR_STANDING` | 28 / es 24+n | Aynı |
| Bozkıra dağılan | `outcome.dispersed`, **yalnız > 0** | `REPORT_SCATTERED` | 28 / fr 27+n | Aynı |
| Düğme | sabit | `CONTINUE` | 16 / ru, de 10 | Düğme 64px+ |

Durum matrisi (satır görünürlüğü):

| Durum | Dize | Düşen biz | Düşen onlar | Ayakta biz | Ayakta onlar | Dağılan |
| --- | --- | --- | --- | --- | --- | --- |
| Zafer (A_eff > D_eff) | WON_ATTACK | var | var (= D) | var | — | — |
| Yenilgi (D_eff > A_eff) | LOST_ATTACK | var (= A) | var | — | var | yok (0) |
| Beraberlik (A_eff == D_eff, savunan kazanır) | LOST_ATTACK | var | var | — | var | **var** (`attacker_remaining`, kaybedenin hayatta kalanı) |
| Beraberlikte iki taraf da 0 (örn. A=D=1) | BOTH_FELL | var | var | — | — | — |

Sayılar `MoveOutcome` / `CombatResult` ile birebir (M2 etkin güçte kayıp formülü `ceil(karşı etkin güç * oran)` zaten `CombatResult`'a yazılır; görünüm yeniden hesaplamaz).
Renk: kayıp satırı `↓` metin glifi + açık kırmızı `#E87A7A`; kazanç/kalan `↑` + yeşil; hepsi **glif + rakam + metin** (renk tek başına anlam taşımaz).

### 4.2 PurificationReport (oyuncu hamlesi, `Branch.PURIFICATION`)

| Alan | Veri kaynağı | Anahtar | Bütçe / en uzun dil | Arapça notu |
| --- | --- | --- | --- | --- |
| Başlık | sabit | `PURIFY_REPORT_HEADING` | 24 / fr, es 15 | Tek satır |
| Başlık (odak ritüeli) | hedef sahnenin Erlik odağı **ve** `SceneDefinition` ritüel anahtarları dolu | Prolog `CHAPTER_1_SLAIN_HEADING` / Perde 1 `CHAPTER_2_CLEANSED_HEADING` | 24 / de 25 (aşım kabul, 1 satır sığar) | — |
| Dize: başarı | `outcome.purified` | `PURIFY_SUCCESS` (ritüelde `*_SLAIN_LINE` / `CHAPTER_2_CLEANSED_LINE`) | 64 / es 57 (ritüel: fr 63) | 2 satır |
| Dize: başarısızlık | `!purified` | `PURIFY_FAILED` (ritüelde `CHAPTER_1_HUNT_FAILED` / `CHAPTER_2_HUNT_FAILED`) | 64 / de 53 | 2 satır |
| Kazanılan Ruh | `outcome.ruh_gain` (başarı) | `PURIFY_SPIRIT_GAINED` | 28 / de 18+n | Ruh ikonu (9x9 kurt başı, `#47A3E8`) + `+N`, yeşil `↑` |
| Düşen yiğitlerimiz (başarı) | `combat.attacker_losses` | `REPORT_OUR_FALLEN` | 28 / tr 22+n | — |
| Yerleşen (başarı) | `combat.attacker_remaining` | `PURIFY_SETTLED` | 28 / fr 25+n | — |
| Karanlığa giden (başarısızlık) | `outcome.moving` (tamamı) | `PURIFY_LOST` | 28 / fr 27+n | `↓` kırmızı |
| Öğrenme satırı (başarısızlık) | `outcome.corruption_strength` (`S`) | `PURIFY_FAILED_HINT` | 48 / **ru 56 (aşım, 2 satır)** | `S` sayısı LRI/PDI |
| Düğme | sabit | `CONTINUE` | — | — |

| Durum | Dize | Satırlar |
| --- | --- | --- |
| Başarılı arındırma | `PURIFY_SUCCESS` | Ruh kazanıldı, düşen, yerleşen (düşen 0 olamaz: `ceil` en az 1) |
| Başarısız arındırma (`P_eff <= S`, eşitlik dahil) | `PURIFY_FAILED` | Karanlığa giden, `PURIFY_FAILED_HINT`; Ruh satırı **yok**, sahip/ordu/bozulma değişmedi (hint dışında bunu raporda **tekrar söyleme**) |
| Canavar / odak ritüeli | Prolog `CHAPTER_1_*`, Perde 1 `CHAPTER_2_*` | Aynı satırlar, yalnız başlık + dize anahtar çifti `SceneDefinition`'dan; boşsa `PURIFY_*` |

Not: `CHAPTER_2_HUNT_*`/`CLEANSED_*` anahtarları **CSV'de henüz yok** (seviye belgesi §2 listeler); eklenmeleri C-43 kapsamında, bu spec yalnız bağlar.
Perde 1 dil kuralı: arındırma **"şifa"** olarak anlatılır, "av" değil (`narrative-voice.md` §6.8); rapor görünümü bunu bilmez, anahtar metni taşır.

### 4.3 TurnSummaryReport (`show_turn`)

Başlık `TURN_SUMMARY_HEADING` (24 / fr 22 "À la tombée de la nuit"). Sıra: **saldırı blokları** (olay sırasıyla) -> **yayılım** -> **Erlik'in Gölgesi uyarısı**.
Hiçbir olay yoksa **modal hiç açılmaz** (Q5); `TURN_SUMMARY_QUIET` yalnız o karar "göster" olursa kullanılır.

| Blok | Gösterim koşulu | Veri | Anahtar | Bütçe / en uzun dil |
| --- | --- | --- | --- | --- |
| Saldırı: toprak alındı | düşman hamlesi, hedef = oyuncu bölgesi, `combat.attacker_won` | `MoveOutcome` (`mover == ENEMY`) | `BATTLE_LOST_DEFENSE` (**R1 vuruşu her zaman bu**, `enemy-layers.md` §3.4) | 64 / es 54 |
| + hedef adı | aynı | `to_id` -> `name_key` | (bölge anahtarı) | <= 12 en |
| + kaybımız | aynı | `combat.defender_losses` (oyuncu = savunan) | `REPORT_OUR_FALLEN` | 28 / tr 22+n |
| + düşman kalan | aynı | `combat.attacker_remaining` | `REPORT_THEIR_STANDING` | 28 / es 24+n |
| Saldırı: dayandık | düşman hamlesi, `!attacker_won` | aynı | `BATTLE_HELD_DEFENSE` | 64 / tr, fr 45 — **Perde 1'de üretilmez** (AI yalnız `A > P_eff` iken vurur); anahtar ve dal korunur, test fixture'ıyla doğrulanır |
| Her iki taraf düştü | iki kalan 0 | aynı | `BATTLE_BOTH_FELL` | 64 / es 47 |
| Yayılım: yeni leke | yayılım hedefi 0 -> 1 | hedef adı | `TURN_SUMMARY_SPREAD` | 48 / fr 33+ad (<= 45) |
| Yayılım: derinleşme | hedef >= 1 -> +1 | hedef adı | `TURN_SUMMARY_DEEPENED` | 48 / es 38+ad (**<= 50, aşım, 2 satır**) |
| **Erlik'in Gölgesi uyarısı (eşik−1)** | tur sonu sonrası `erlik_power == eşik - 1` **ve** o gece yayılım olduysa | HUD modeli (`ERLIK_SHADOW_VALUE` ile aynı kaynak) | `ERLIK_SHADOW_WARNING` | 48 / ru ~50 |
| Gelir / takviye | **gösterilmez** (Q6) | — | — | — |

**"Odak tehlikede" bu modalda YOKTUR.** Odak tehlikede (K1) yalnız HUD'da, Gölge hücresinin ikinci segmentinde yaşar ve **hiçbir modal açmaz** (`design/ux/hud.md` §5.2). Bu spec'teki blok C yalnız `ERLIK_SHADOW_WARNING`'dir (kayıp eşiğine bir kala). Aynı HUD uyarısı ile modal uyarısı çakışırsa: modal anlatıdır, HUD kalıcı durumdur; ikisi birbirinin yerine geçmez.

Durum matrisi:

| Durum | Bloklar |
| --- | --- |
| Yalnız saldırı | başlık + A (+ Devam) |
| Yalnız yayılım | başlık + B |
| Saldırı + yayılım (aynı zayıf hat, cross-review S1-b) | A + B; sıra gerçek işlem sırası (AI -> yayılım) |
| Yayılım + Gölge uyarısı | B + C (C ikon `!` 7x7 kırmızı piksel ikon + metin) |
| 2+ saldırı | Her biri ayrı blok; en çok 3 görünür, fazlası `Devam` ile aynı modalda sığmazsa panel içi dikey kaydırma yok — Q7 |
| Oyuncunun son bölgesi düştü | Özet **açılmaz** (Q3); yenilgi ekranı |

## 5. Etkileşim

| Girdi | Bağlam | Eylem | Not |
| --- | --- | --- | --- |
| Enter / Space | [Devam] odakta (açılışta varsayılan) | Kapat, sıradakine geç | `ui_accept` |
| Esc | Modal açık | **= Devam** (kapat) | Ortak Esc kuralı: tek güvenli çıkışlı modal; `ui_cancel` |
| Tab / Shift+Tab | Tek odaklanabilir öğe | Odak [Devam]'da kalır (focus trap) | Dinamik oluşturulan bloklar odaklanmaz |
| Fare tık | [Devam] | Kapat | Hover = renk değişimi |
| Fare tık | Modal dışı / harita | **Yok sayılır** (arka plan keser) | Harita seçimi sızmaz |
| Girdi koruması | Açılıştan sonra tek `screen_input_guard_s` (0.4 sn, `SceneFlowConfig`) — **TÜM ModalQueue modalları ve E5 için ortak kural** | [Devam] pasif; Esc/Enter düşer | Çift tık raporu görmeden geçmesin (`InputGuard.arm`) |

**Odak:** `ModalQueue` odağı `get_focus_target()` ile [Devam]'a gizlice verir (`FocusReveal.focus_quietly`; klavye tuşuna ilk basışta altın kenar
görünür). Kuyruk boşalınca önceki odak geri verilir. Fare kullanıcısında odak çerçevesi görünmez (C-25 kuralı).
**Hamle önizlemesi / ikinci tık** (başarısız arındırma, `PURIFY_CONFIRM_AGAIN`) bu modalın dışında, rapordan **önce** yaşanır; rapor yalnız uygulanmış sonucu gösterir.

## 6. Hareketi Azalt ve geri bildirim

| Öğe | Varsayılan | Hareketi Azalt |
| --- | --- | --- |
| Modal açılışı | M2: düz kesme. Cila (kabul ölçütü değil): 4 kare dither (art bible §7) | Dither yok + sabit kare |
| Haritada arındırma parlaması / yayılım lekesi | Kozmetik, girdiyi **kilitlemez**; durum modaldan önce yazılmış | Durur / anında tamamlanır |
| Sayı vurgusu | Yok (modal içi animasyon yok) | — |
| Ses | Mevcut SFX seti (`region_select`, `recruit`, `income`) rapor için ses **içermez**; yeni SFX gerekirse `SfxLibrary` verisiyle (Q8) | — |
| Alfa fade, kesirli ölçek | **Yasak** (art bible §7) | — |

## 7. Erişilebilirlik ve yerelleştirme

| Madde | Karar |
| --- | --- |
| Klavye | Tüm eylemler klavyeyle (Enter/Esc/Tab); fare gerekmez |
| Renk | Kayıp/kazanç = glif/ikon + `+/-` rakam + metin; kırmızı/yeşil yedekli (renk körlüğü) |
| Kontrast | Modal zemin `#1C150D` opak; gövde krem, başlık `#EDC76B`, ikincil `#B8A689`; test: palet doğrulayıcı + render ölçümü (TBD) |
| Glif | `↑ ↓` metin glifi (Fusion'da var); `✓ ⚠ ✕` piksel ikon; `×` `→` kullanılmaz (glif testi görevi); `- ` ASCII; `glyph_coverage_test` her çeviri için |
| Sayı biçimi | `NumberFormatter.format_int` (binlik ayırıcı dile göre); Arapça'da sayı/kesir LRI...PDI ile soldan sağa yalıtılır (C-69) |
| RTL (ar) | Ozan dizesi ve satırlar sağa dayalı, ikon/glif satırın sağında; panel simetrik; düğme ortada; harita LTR kalır |
| Büyük/küçük harf | Çeviride; kodda `to_upper()` yok |
| Genişleme | Dizeler 288px'te en çok 2 satır (Arapça 2-3, Unifont 16); bütçe aşan 3 anahtar: `PURIFY_FAILED_HINT` ru 56, `TURN_SUMMARY_DEEPENED` es 38+ad, `REPORT_OUR_STANDING` tr 27+n — hepsi satıra sarılır / sığar, kısaltma yok |
| Okuma sırası | Odak sırası: [Devam]; okuma sırası: başlık, hedef, dize, sayılar. Ekran okuyucu / AccessKit **kapsam dışı** (Standart katman); `accessibility_name` kodda kalabilir, kabul ölçütü değil |
| BiDi riski | Bölge adı + sayı aynı satırda (`Doğu Obası · ...`): ayrı `Label`'lar, tek `Label`'da karıştırılmaz |

## 8. Veri boşlukları (kodda henüz yok) — tasarım gerektirir

> **Bağımlılık karşılandı (C-70, 2026-10-22): ADR-0010 eki "report data contract" G1–G4'ü tanımlar** (`combat_occurred(outcome)`, `target_owner_before`, `reason`, `SpreadDecision.level_before` + `corruption_spread(decision)`, gece tamponu). Kod: C-71.
> ~~**Bağımlılık (C-45): G1–G4 için ADR-0010 eki gerekir (C-47 görevi).**~~ Bu spec'in M2 uygulaması ek yazılıp kabul edilene kadar başlamaz; ek `MoveOutcome` / sinyal imzalarını (`combat_occurred(outcome)`, `target_owner_before`, `reason`, `SpreadDecision.level_before`, tur tamponu) tek yerde tanımlar.

| # | Boşluk | Etki | Öneri |
| --- | --- | --- | --- |
| G1 | `combat_occurred` sinyali `CombatResult` taşır, `MoveOutcome` değil | Rapor `dispersed`, bölge adı, `mover` bilemez | İmzayı `(outcome: MoveOutcome)` yap (`purification_resolved` ile simetrik) — **ADR-0010 eki** |
| G2 | `MoveOutcome`'da hedefin **önceki** sahibi ve `reason` (`&"strike"`) yok | "Düşman -> oyuncu" savaşı ayırt edilemez; enemy-layers §3.4 sözleşmesi karşılanamaz | `target_owner_before` + `reason: StringName` alanları (veri, mantık değil) — **ADR-0010 eki** |
| G3 | `SpreadDecision` yalnız `is_spread_turn`/`target_id`; hedefin önceki seviyesi yok | `SPREAD` / `DEEPENED` ayrımı yapılamaz | `GameContext` yayılım öncesi seviyeyi okur **ya da** `SpreadDecision.level_before` — **ADR-0010 eki** |
| G4 | Düşman hamleleri tur boyunca ayrı sinyallerle gelir | Özet için tamponlama gerek | `GameContext` `end_turn` öncesi tamponu sıfırlar, `turn_ended`'da `show_turn(outcomes, spread)` çağırır (ADR-0011 imzası) — **ADR-0010 eki** |
| G5 | `CHAPTER_2_*` anahtarları CSV'de yok | Perde 1 ritüel raporu düz `PURIFY_*` düşer | C-43 anahtarları ekler; fallback `PURIFY_*` (§4.2) |

## 9. Kabul ölçütleri

**Veri ve akış**
- [ ] Rapordaki her sayı `MoveOutcome` alanına eşit (AC-V2, ADR-0011 doğrulaması); görünüm yeniden hesaplamaz. *(Birim testi: fixture outcome -> etiket metni)*
- [ ] Dize seçimi: BOTH_FELL -> WON/LOST_ATTACK -> LOST_DEFENSE/HELD; Perde 1 R1 vuruşu `BATTLE_LOST_DEFENSE`, `HELD` üretilmez. *(Birim; cross-review S1-c)*
- [ ] Beraberlikte `REPORT_SCATTERED` `dispersed > 0` ile görünür, 0 iken görünmez.
- [ ] Başarısız arındırmada Ruh satırı yok; `PURIFY_FAILED_HINT` `S` değerini gösterir.
- [ ] 2 düşman hamlesi + yayılımlı turda **tek** `TurnSummaryReport`, ardından en çok **bir** otomatik lütuf (ADR-0011 doğrulaması); şafakta özet lütuftan önce gelir.
- [ ] Modal açıkken harita tıklaması bölge seçmez; kapanınca önceki klavye odağı geri gelir.
- [ ] **Son bölge düşünce (`NO_REGIONS`):** oyuncunun hamlesiyle ise sıra son hamle raporu → yenilgi ekranı; düşman hamlesiyle ise özet açılmaz, doğrudan yenilgi ekranı. `TurnSummaryReport` ve çift modal oluşmaz; sahne akışı gecikmez. *(Entegrasyon testi)*
- [ ] `outcome == null` ile çağrıda modal açılmaz, uyarı günlüğe yazılır, kuyruk ve oyun akışı bozulmaz. *(Birim)*
- [ ] "Odak tehlikede" hiçbir rapor/özet modalında görünmez (yalnız HUD); `ERLIK_SHADOW_WARNING` yalnız yayılım olan gece ve `erlik_power == eşik − 1` iken görünür.
- [ ] G1–G4 ADR-0010 ekinde tanımlıdır ve uygulanmıştır (önkoşul).

**Girdi**
- [ ] Yalnız klavyeyle: Enter/Space/Esc raporu kapatır; Tab odağı modaldan çıkarmaz.
- [ ] Tek `screen_input_guard_s` (0.4 sn) süresince [Devam] pasif, Esc/Enter düşer; sonra çalışır (tüm ModalQueue modallarıyla aynı kural).

**Yerleşim ve yerelleştirme**
- [ ] 640x360'ta panel iç genişliği ≤ 288, dış ≤ 304 px; üst (40) / alt (31) marjı örtmez; ≈ 281 px yüksekliğe sığar; 11 dilde taşma/üst üste binme yok (ekran görüntüsü: en, de, ru, ar minimum; fr, es en uzun dizeler).
- [ ] Arapça: sayılar yönü doğru ("9 / 4" tersine dönmez), satırlar sağa dayalı, 16px Unifont.
- [ ] Alfa fade / kesirli ölçek yok; Hareketi Azalt açıkken modal anında, dither'sız açılır.
- [ ] `glyph_coverage_test` yeni anahtarlar için geçer; `↑ ↓` dışında yeni sembol glifi yok; AC-V1 yasak sözcük denetimi geçer.

## 10. Kararlar (C-45) — eski Açık Sorular

| # | Soru | Karar (C-45) | Sahip |
| --- | --- | --- | --- |
| Q1 | Rapor hangi bölgeye olduğunu söylemeli mi (anahtar yok) | **Evet**: hedef bölge adı `SecondaryLabel` (mevcut `name_key`, yeni anahtar yok) | ux-designer + kullanıcı |
| Q2 | Merkezdeki modal hedef bölgeyi örtebilir | `PanelPlacement.choose` ile alt/üst kenar, hedef bölge örtülmesin | ux-designer |
| Q3 | Savaş sonrası aynı tur kaybedilirse (`NO_REGIONS`: son bölge düştü) özet gösterilsin mi | **Hayır.** Sıra: son hamle raporu → yenilgi ekranı; özet atlanır (AC §9) | game-designer |
| Q4 | Özette Gölge uyarısı | **Evet**, yalnız yayılım olan gece, `ERLIK_SHADOW_WARNING` (eşik−1) olarak yeniden adlandırıldı; "Odak tehlikede" modalda **değil** yalnız HUD'da (K1) | narrative-director |
| Q5 | Olaysız gecede özet gösterilsin mi (`TURN_SUMMARY_QUIET`) | **Hayır**: modal açılmaz (dikkat bütçesi, cross-review D6); anahtar yedekte | kullanıcı |
| Q6 | Gelir / düşman takviyesi özette gösterilsin mi | **Hayır**: dikkat bütçesi gerekçesiyle; gelir HUD `+N` vurgusu ve `income` SFX ile (C-66), takviye bilgisi bilgi panelinde (kural bilgisi, `hud.md` §5.4) zaten var | game-designer |
| Q7 | `enemy_actions_per_turn` > 3 olursa taşma | Perde 1 = 1; en çok 3 blok garanti, bölüm verisi 3'ü aşarsa son blok "+N daha" yerine ayrı spec | game-designer |
| Q8 | Rapor için SFX | Yok (M2); kayıp/zafer tonu C-41 ses görevinde | audio-director |
| Q9 | Özet açılırken `HINT_SPREAD` balonu aynı anda çıkabilir | Balon, modal kuyruğu boşalana dek ertelenir (`_offer_hint` kuyruk kontrolü `drained` sonrası yeniden dener) | godot-specialist |
| Q10 | Başlık 24px mi 12px mı | **12 px `HeaderLabel`** (Arapça 16); 24 px yalnız tam ekran başlık kartı (cila). Ortak kural; art-bible §7 güncellenir | art-director |

**Çözülmemiş / bağımlı:** G1–G4 (ADR-0010 eki, C-47); `CHAPTER_2_*` anahtarları (C-43); `×` / `→` glif testi görevi (C-47).

## 11. Yeni Kalıp Bayrakları (interaction-patterns.md yok)

| Kalıp | Durum |
| --- | --- |
| Tek-düğmeli sonuç modalı (Devam, Esc = Devam) | mevcut (`VictoryCard`) |
| Olay-bloklu tur özeti (en çok 3 blok) | yeni |
| Modal girdi koruması (`screen_input_guard_s`) tüm modallar | mevcut (ortak kural olarak genişletildi) |
