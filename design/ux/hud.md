# HUD Tasarımı: ULUS

> **Durum**: Approved (C-45, 2026-10-21)
> **Bağlantılı kararlar**: K1 (Yayılım: Sade), K2 (Kağan vuruş eşiği satırı), K3 (Hedef sayacı), K4 (klavyeyle bölge seçimi M2 kapsamında) — bkz. §13
> **Yazar**: ux-designer
> **Son güncelleme**: 2026-10-21
> **Oyun**: ULUS (tek belge, öğe başına değil)
> **Platform**: PC (Steam) — yalnız klavye/fare. Gamepad, dokunmatik, Steam Deck, konsol YOK (technical-preferences, 2026-10-08)
> **İlgili GDD/ADR**: `resource-system.md` §9–10, `spirit-system.md` §3.4/§3.6/§4.7, `scene-flow.md` §10, `enemy-layers.md` §3.3/§10, `region-map-system.md` §3.6, `design/levels/perde1-dogu-curcet.md` §7, `gdd-cross-review-2026-10-21.md` (D3, S2-a, H5), `design/ux/battle-report.md`, ADR-0009, ADR-0010, ADR-0011
> **Erişilebilirlik katmanı**: Standart (renk körlüğü, Hareketi Azalt, klavye odak zinciri; Büyük Metin ertelendi — art bible §7). Ekran okuyucu / AccessKit **kapsam dışı** (Standart katman); `accessibility_name` kodda kalabilir, kabul ölçütü değildir.
> **Stil referansı**: `design/art/art-bible.md` §7 (HUD paneli, tipografi, UI animasyonu, erişilebilirlik)

> **Okuma notu**: "Mevcut" = kodda var (2026-10-21'de okundu). "M2" = tanımlanan ama kodda olmayan ekleme. "Karar (C-45)" = kullanıcı onaylı karar. "yeni kalıp" = `interaction-patterns.md` henüz yok; kalıp adı + "yeni" etiketiyle işaretlenir (§14).
> **Kapsam sınırı**: Modallar (savaş raporu, lütuf, hedef paneli, sonuç/yenilgi) `ModalQueue` üzerinden gelir ve ayrı UX spec'lerinin konusudur; burada yalnız HUD ile ilişkisi (§5, §8) belgelenir.

---

## 1. HUD Felsefesi

**Bilgiyle ilişki.** ULUS sıra tabanlı bir stratejidir: oyuncu zamanı baskısı altında değil, **karar vermek için** bakar. HUD "stratejist bakışı"nın çerçevesidir (art bible §7): harita odakta, HUD sade. Oyuncunun asıl sorusu her turda aynıdır: *"Ne kadar kaynağım var, hedefe ne kadar yakınım, ne beni zorlayacak?"* HUD yalnız bu üç soruyu cevaplar; neden-sonuç ayrıntısı bağlamsal panelde ve modallarda yaşar.

**Görünürlük ilkesi: BAĞLAMSAL, ama karar-kritik sayılar sabit.** Tur boyunca kararı değiştiren az sayıda değer (altın, gelir, Ruh, tur, hedef, Erlik) kalıcıdır; seçili bölgeye ait ayrıntı seçimle gelir; olay anlatımı (savaş, yayılım sonucu) modalda gelir. Şüphede: **sabit satır eklemek yerine bağlamsal panele koy.**

**Gereklilik kuralı.** *Bir HUD öğesi, oyuncunun bir sonraki hamlesini o bilgi olmadan gözle bulamayacağı ya da yanlış hesaplayacağı durumda yer hak eder* (ör. gelir tahmini: kafadan F2 hesaplamak gerekirdi). "Faydalı olur" yetmez. Yeni öğe öneren kişi §7 bütçesinden hangi satırı etkilediğini ve neyi bağlamsala indirdiğini yazar.

---

## 2. Bilgi Mimarisi (üç katman)

| Bilgi | Her an görünür (üst/alt bar) | Bağlamsal (seçim/koşul) | Modalda / isteğe bağlı | Gerekçe |
|---|---|---|---|---|
| Bölüm adı | X | | | Yer duygusu; `…` ile kısalan ilk öğe (feda edilebilir) |
| Altın + gelir tahmini (+Y) | X | | | Her tur harcama kararı (Ordu Topla) |
| Altın değişimi (↑+X / ↓-X) | | X (1.5 sn) | | Neden-sonuç; renk + metin |
| Ruh | X | | | Lütuf eşiğine ilerleme; sayı küçük, kalıcı |
| Kök Böri düğmesi | | X (sunum bekliyorsa) | | Eylem çağrısı; bekleme yokken gizli |
| Tur sayısı | X | | | Yayılım/saldırı takvimi tura bağlı |
| Hedef (metin) | X | | Hedef paneli (sahne başı, modal) | scene-flow §10 "kalıcı Hedef satırı" |
| Hedef ilerlemesi (boylar, inler) | X | | | Zafer yakınlığı |
| **Düşman bölgesi sayacı `Cürcet bölgeleri x/3` (M2, K3)** | X (`must_defeat_all_enemies` iken) | | | Kazanma koşulunun dördüncü parçası izlenir |
| Erlik'in Gölgesi `p / eşik` | X (eşik > 0) | | | Kayıp koşulu; kalıcı olmalı |
| **Yayılım: N tur (M2, K1)** | X (Gölge hücresinin 2. segmenti) | | | Kalan tur = planlama girdisi (spirit §3.6, N7) |
| Erlik kayıp uyarısı (p = eşik − 1) | | X | | Hedef metninin yerini alır (mevcut) |
| **Odak tehlikede (M2, K1)** | | X (N = 0 **ve** hedef bir odaksa) | | `Yayılım` segmentinin yerini alır (S2-a) |
| Bölge adı/sahip/ordu/gelir | | X (seçili bölge) | | Seçimle gelir |
| Bozulma + Erlik direnci | | X (bozulma ≥ 1) | | Arındırma kararı |
| Ordu Topla (seçici, maliyet, tavan) | | X (oyuncu bölgesi, oyun sürüyor) | | Üretim kararı |
| **Kağan vuruş eşiği (M2, K2)** | | X (düşmana komşu oyuncu bölgesi, `strike_enabled`, her tur) | | Kural bilgisi (D3); niyet önizlemesi DEĞİL (K8) |
| Düşman takviyesi | | X (takviye alan düşman bölgesi) | | Kural bilgisi; liste filtreli (M2) |
| Düşman tamgası | X (haritada, ENEMY'de hep) | | | Renk körlüğü; harita katmanı |
| Hedef seçimi ipucu (M2, A5) | | X (`Ordu Gönder` basılıyken) | | Mod görünürlüğü |
| Öğretici ipucu | | X (bir kez) | | Girdiyi kilitlemez |
| Savaş/yayılım/arındırma raporu | | | X (`ModalQueue`) | Tek seferde bir modal (ADR-0011) |
| Lütuf seçimi, zafer, yenilgi | | | X | Tam dikkat gerektirir |
| Ayarlar, Ana Menü onayı | | | X | |

---

## 3. Yerleşim Bölgeleri (640×360, ×3 = 1080p)

### 3.1 Bölge şeması (mevcut; M2 eklemeleri `*` ile)

```
 x:0                                                  640
 ┌────────────────────────────────────────────────────┐ y:0
 │ ÜST BAR R1: Bölüm adı | Altın (+Y) | Ruh | Tur     │
 │ ÜST BAR R2: Hedef … | İlerleme [*x/3] | Gölge p/e  │ 40 üst sınır (en ~38,
 │                                    [*Yayılım: N tur]│ Arapça ~40)
 ├────────────────────────────────────────────────────┤
 │                                                    │
 │       HARİTA (x ≤ 491)            ┌─────────────┐  │
 │  (bölge etiketleri, tamgalar,     │ BİLGİ PANELİ│  │
 │   hedef işaretleri)               │  136 px     │  │
 │   [İpucu balonu: sol-üst tercih]  │ yukarı büyür│  │
 │                                   └─────────────┘  │ y:329
 ├────────────────────────────────────────────────────┤ 4px boşluk
 │ ALT BAR: [Ana Menü]        [Kök Böri] [Tur Bitir]  │ 27
 └────────────────────────────────────────────────────┘ y:360
 Modal katmanı (CanvasLayer 10): tam ekran %60 karartma, tek modal.
 Modal alt marjı 31 (27 + 4), üst marj 40.
```

**K1 (Karar C-45): Yayılım ayrı hücre değildir.** R2'nin sağ hücresi tek `ShadowLabel` hücresidir ve iki segmentten oluşur: `Erlik'in Gölgesi: p / eşik` + `Yayılım: N tur`. Metin biçimi çevirmen sahipli tek key'lerle (§5.1). Genişlik yetmezse sığdırma sırası: önce Hedef (`…`), sonra İlerleme; Gölge `p / eşik` ve Yayılım segmenti **kısalmaz** (L1).

### 3.2 Bölge tablosu

| Bölge | Konum (px) | İçerik | Maks. eşzamanlı | Not |
|---|---|---|---|---|
| Üst bar R1 | 0–~19, tam genişlik | Bölüm, Altın, Ruh, Tur | 4 | Kalıcı; Bölüm adı genişler/kısalır |
| Üst bar R2 | ~19–38, tam genişlik | Hedef, İlerleme (+ düşman bölgesi sayacı), Gölge (+ Yayılım segmenti) | 3 hücre | Hedef metni `…` ile kısalır; uyarıda İlerleme gizlenir |
| Harita | Üst bar altı – alt bar üstü, x ≤ 491 | Bölgeler | — | HUD haritayı örtmez; panel/balon `PanelPlacement` ile işaretleri kaçınır |
| Bilgi paneli | x 500–636, alt kenar y=329 (alt bar −4px), yukarı büyür | Seçili bölge | 1 panel | Boyut içerikten; genişlik sabit 136; başlık 12 px `HeaderLabel` (Arapça 16) |
| Alt bar | y 333–360 (27 px) | Ana Menü, Kök Böri, Tur Bitir | 3 | Tur Bitir ≥ 64 px, birincil stil |
| İpucu balonu | sol-üst (4, üst bar+4) → sağ-üst → sol-alt | Öğretici | 1 | 216 px metin genişliği; `PanelPlacement.choose` |
| Modal | Merkez / üst / alt yaslı | Raporlar | 1 | Harita girdisi kilitli; iç genişlik tavanı 288 px, dış 304 px; kullanılabilir yükseklik ≈ 360 − 40 − 31 − 8 ≈ 281 px |

**Güvenli bölge**: PC pencere/tam ekran için kenar boşluğu gerekmez (technical-preferences). Tam kat ölçekleme (×3, ×6) `integer` modda; ara çözünürlükte siyah bant (kabul).

---

## 4. HUD Öğeleri

### 4.1 Öğe tablosu (mevcut + M2)

Boyutlar tahmindir; 12 px font (Arapça 16 px) satır ≈ 14 px (Arapça ≈ 20 px). Ölçüm AC'si §12'de.

| Öğe | Veri kaynağı | Güncelleme anı | Konum / bütçe | En uzun dil davranışı | Arapça (RTL) | Renk-dışı ipucu |
|---|---|---|---|---|---|---|
| Bölüm adı (`ChapterLabel`) | `SceneDefinition.title_key`; bitince `VICTORY`/`DEFEAT` | `_render_hud` (her değişiklik sonrası `_refresh_views`) | R1 sol, genişleyen | `text_overrun_behavior=3` (`…`); de/ru sığar (c66) | Sağa hizalı, RTL | Metin |
| Altın (`GoldLabel`) | `HudModel.gold`, `income_forecast`; `ValueFeedback` | Her yenilemede; vurgu 2 kare, fark 1.5 sn | R1 orta, ~130–150 px (`Altın: 25 ↑+5 (+5)`) | ru "Золото: 4 ↑+2 (+2)" sığıyor (c66); sığmazsa Bölüm adı küçülür | `ltr()` ile yalıtılmış `(+2)`, `↑+X` (c69: sıra doğru) | `↑+X` / `↓-X` sembol + işaret (renk yeşil/kırmızı ek) |
| Gelir tahmini `(+Y)` | `ResourceController.forecast_income` (F2) | Yenileme; oyun sürerken | Altın etiketinde | Aynı | `NumberFormatter.ltr` | Parantez + `+` |
| Ruh (`SpiritLabel`) | `HudModel.ruh` | Yenileme | R1, ~60 px | Kısa | RTL, rakam LTR | Metin |
| Tur (`TurnLabel`) | `map_state.current_turn` | Yenileme | R1 sağ, ~50 px | Kısa | RTL | Metin |
| Hedef (`ObjectiveLabel`) | `WinCondition.description_key` | Yenileme | R2 sol, genişleyen | `…` ile kısalır (en/de/ru'da şimdiden kesiliyor: c66) | RTL | Metin; kayıp uyarısında metin tamamen değişir |
| İlerleme (`ProgressLabel`) | `neutral_conquered/required`, `foci_cleansed/total`, **M2:** `enemy_regions_taken/enemy_regions_initial` | Yenileme | R2 orta, ~190 px (en) + sayaç segmenti | de/ru en geniş hâli; sığıyor ama Hedef'i daraltıyor | `fraction()` LRI yalıtımı | Metin |
| Düşman bölgesi sayacı (M2, K3) | `WinCondition.must_defeat_all_enemies`; alınan düşman bölgesi / **başlangıçtaki** düşman bölgesi sayısı | Yenileme | İlerleme satırının son segmenti: `Cürcet bölgeleri 1/3` | Kısa; ilerleme gizlenince birlikte gizlenir | `fraction()` | Metin + oran |
| Erlik'in Gölgesi (`ShadowLabel`, 1. segment) | `WinCondition.erlik_power`, `erlik_loss_threshold` | Yenileme; eşik 0 → gizli | R2 sağ hücre | Kısa; **kısalmaz** | `fraction()` yalıtımı (c69) | Mor `#A86BC4` / uyarıda kırmızı `#E87A7A` **+ Hedef metni uyarı cümlesiyle değişir** |
| Yayılım (`ShadowLabel`, 2. segment; M2, K1) | `HudModel.spread_turns_left` | Yenileme | Gölge hücresinin ikinci segmenti | **Kısalmaz**; sığmazsa Hedef daralır | Rakam `ltr` yalıtımı | Metin (`bu tur sonu`); kırmızı ek |
| Erlik kayıp uyarısı | `HudModel.erlik_warning` (p = eşik − 1) | Yenileme | Hedef satırının yerine, aynı satır | Uzun cümle `…`; İlerleme gizlenir (yer açar) | RTL, cümle okunur (c69) | Cümle metni (renk tek ipucu değil) |
| Kök Böri düğmesi | `HudModel.boon_offer_available` | Yenileme | Alt bar sağ, ≥ 64 px, ikincil | Genişler | Sol/sağ aynalanır | Etiket metni; görünürlük = durum |
| Tur Bitir | `game_result == ONGOING` | Yenileme; `disabled` bitince | Alt bar sağ uç, birincil, ≥ 64 px; **varsayılan sessiz odak** | Genişler (ru "Конец хода" sığıyor) | Alt bar aynalanır (c37) | Birincil çerçeve (koçboynuzu) + odak 1 px altın kenar |
| Ana Menü | — | — | Alt bar sol, ≥ 64 px | Genişler | Aynalanır | Metin |
| Bilgi paneli — başlık/sahip/ordu | `RegionData` | Seçim + her yenileme | 136 px sabit genişlik | Ad 12 px `HeaderLabel` (altın renk = hiyerarşi) | Panel LTR kalır, içerik RTL (kodda belgeli) | Sahip metni |
| Bilgi paneli — Altın `/ tur` + `↓-X` ceza | `IncomeRules.region_income` | Yenileme | 1 satır | `PER_TURN` çeviri biçimi | `ltr()` | `↓-X` sembol + işaret |
| Bilgi paneli — Bozulma, Erlik direnci | `corruption_level`, `SpiritRules` | Yenileme; yalnız seviye ≥ 1 | +2 satır (≈ +28 px) | Etiket birincil, değer mor | `fraction()` | Etiket + sayı |
| Bilgi paneli — Ordu Gönder | `owner == PLAYER` ve `army > 1` | Yenileme | 1 buton, birincil | de/ru sığıyor (c37) | Aynalanır | Etiket |
| Bilgi paneli — Ordu Topla | `ResourceController` (`max_recruit`, `recruit_cap`, `recruit_cost`) | Yenileme | ≈ 5 satır (başlık, seçici, maliyet, tavan, ipucu) | İpucu `AUTOWRAP_WORD_SMART` (2–3 satır) | Seçici sırası RTL'de ters (c37: `-` `+` `Topla`) | Pasif düğme + kırmızı ipucu **metni** |
| Bilgi paneli — Düşman takviyesi | `enemy_reinforcement_per_turn` | Yenileme; ENEMY seçilince | 1 satır `Takviye: +1 / tur` | `PER_TURN` | `ltr("+1")` | Etiket + işaret (kırmızı ek) |
| Bilgi paneli — Kağan vuruş eşiği (M2, K2) | `StrikeThreshold` (saf) | Yenileme (lütuf / topla / gönder sonrası anında) | Ordu Topla'nın altı; +42–56 px | Sarar | Metin yönü locale | Düz metin + sayı |
| Öğretici balonu (`HintBubble`) | `TutorialRules`, `TutorialProgress` | Olay tetikli; modal kapanınca `drained` | 216 px metin + `[Anladım]`; ≈ 80–95 px yükseklik | Sarar | Metin yönü locale | Metin + buton |
| Altın değişim vurgusu | `ValueFeedback` | `observe()` değişimde | Altın etiketi rengi 0.1 sn | — | Aynı | `↑+X`/`↓-X` 1.5 sn (Hareketi Azalt: kalıcı) |

### 4.2 Mevcut davranış notları (belgelenen kararlar ve boşluklar)

| # | Not | Kaynak |
|---|---|---|
| 1 | Üst bar yüksekliği içerikten gelir; modal ve ipucu yerleşimi `_top_bar_height()` kullanır | `game_context.gd` |
| 2 | Altın etiketi tek `Label`; 3 parça (`Altın: X`, fark, gelir) boşlukla birleşir | `_render_gold` |
| 3 | Oyun bitince (WON/LOST) Tur Bitir pasif, gelir tahmini gizli, başlık sonucu gösterir | `_render_hud` |
| 4 | **Kabul edilmiş boşluk:** Hedef metni R2'de en/de/ru'da şimdiden `…` ile kesiliyor (c66); tam cümle Hedef panelinde (sahne başı). Karar: A8 | görsel c66 |
| 5 | **Boşluk (A4 → AC):** Kök Böri düğmesinde etiket dışında ipucu yok; görünürlük durumu veriyor (Karar A7, B5) | kod |
| 6 | **Boşluk → K4 (M2):** Harita bölgeleri için klavye odağı kodda bulunmadı (`features/grid` içinde `focus_mode` yok); klavye zinciri yalnız bar düğmeleri ve bilgi paneli. Çözüm §10.3 kural 5 + C-47 görevi | `grep` |

---

## 5. M2 Eklemeleri

### 5.1 "Yayılım: N tur" sayacı (K1, Karar C-45)

| Alan | Tanım |
|---|---|
| Kaynak | spirit §3.6 (N7, C-53; C-45'te bu tanıma daraltıldı), seviye belgesi §7 R3; `ErlikSpreadController.decide` ve `MapState.last_erlik_spread_turn` |
| Değer | `N = max(0, I_eff − (current_turn − last_erlik_spread_turn))`. `HudModel.spread_turns_left` (yeni alan, yalnız veri); `HudPresenter` kurar (saf; test `hud_presenter`: "geri sayar, yayılım turunda sıfır") |
| Görünürlük | Yalnız `erlik_threshold > 0` (Gölge görünürken). Eşik kapalıysa gizli |
| **Konum (tek tanım)** | Ayrı hücre **değil**: Erlik'in Gölgesi hücresinin **ikinci segmenti**. Biçim: `Erlik'in Gölgesi: p / eşik  Yayılım: N tur`. 3. satır açılmaz |
| Metin | `N ≥ 1`: `Yayılım: N tur`. `N = 0`: `Yayılım: bu tur sonu` (yeni key'ler, öneri adlar `SPREAD_COUNTDOWN` / `SPREAD_THIS_TURN_END`; çevirmen sahipli biçim, `to_upper` yok, ADR-0009). Sığmazsa birim çıkarılmaz: önce Hedef metni daralır |
| Rakam | `NumberFormatter.format_int`; Arapçada `ltr` yalıtımı |
| Stil | Mor `#A86BC4` (Erlik bilgisi); `N = 0` iken kırmızı `#E87A7A` **ve** metin değişir (renk tek ipucu değil) |
| Güncelleme | `_refresh_views()` içinde; tur sonunda yayılım olunca sıfırlanır, arındırma aralığı sıfırlamaz (seviye §11) |
| Gök Kalkanı | `I_eff` uzarsa gösterge uzar, kısalmaz (spirit §3.6 C-31); N yine formülden |
| Hareketi Azalt | Animasyon yok; fark yok |
| Hedef bölge | Hedef bölge adı yalnız §5.2'deki Odak tehlikede durumunda gösterilir. Haritada hedef işareti **cila** (M2 kabul ölçütü değil; saldırıya uğrayan bölge işaretiyle birlikte, seviye §8) |

### 5.2 "Odak tehlikede" (K1, Karar C-45)

| Alan | Tanım |
|---|---|
| Kaynak | spirit §3.6 S2-a; gdd-cross-review S2-a |
| Koşul | **`N = 0` VE** yayılım hedefi (`SpreadDecision.target_id`, "şu an olsa") bir `win_condition.erlik_foci` bölgesidir. İkisinden biri yoksa gösterilmez |
| Neden | Tek hamlede üç ceza (geri alma, odağın yeniden bozulması, odağın düşmana geçmesi) oyuncuya okunabilir olsun; kural değişmez, yalnız sunum |
| Metin | `Odak tehlikede: <bölge adı>` (yeni key `FOCUS_AT_RISK` + bölge adı `%s`) |
| Renk-dışı | Piksel ikon (7×7 uyarı; `⚠` glifi Fusion'da yok, ADR-0009) + metin; kırmızı ek |
| Yer | Aynı Gölge hücresi: `Yayılım: N tur` segmentinin **yerini alır**; `p / eşik` segmenti **hep görünür**. Aynı anda ikisi gösterilmez (R2'ye yeni hücre eklenmez) |
| Harita | Hedef işareti cila (§5.1) |
| Hata | Hedef `null` ise (yayılacak yer yok) `Yayılım` segmenti normal kalır |
| Modal | Bu uyarı modal açmaz (dikkat bütçesi); yayılım sonucu zaten `TURN_SUMMARY_SPREAD` raporundadır. Modaldaki `ERLIK_SHADOW_WARNING` (eşik−1) ayrı bir uyarıdır (battle-report.md §4.3) |

### 5.3 "Kağan bu bölgeyi en az N orduyla vurabilir" (K2, D3, Karar C-45)

| Alan | Tanım |
|---|---|
| Kaynak | enemy-layers §10 / F-E1; gdd-cross-review D3 (W-6, H5). Uygulama bu belgede (cross-review D3 metnine "uygulama: hud.md" notu) |
| Yer | Bilgi paneli, **düşmana komşu oyuncu** bölgesi, Ordu Topla bölümünün altında, kural bilgisi satırı (ikincil metin rengi `#B8A689`; kırmızı değil, bilgi) |
| Zamanlama | `strike_enabled` iken **1. turdan itibaren her tur** (planlama için; `attack_start_turn` kapısı satırda belirtilmez) |
| Değer | `N = max(P_eff + 1, ceil(num · P_eff / den))`; `P_eff = 0` iken `N = 1`; `P_eff = ceil(resolve(&"army_defense", P.army))` (lütuflar dahil). Perde 1 (3/2): `N = max(P_eff+1, ceil(1.5·P_eff))` |
| Hesaplayan | Saf fonksiyon (`StrikeThreshold`, öneri adı); `P_eff`'i `StatResolver` verir, panel yalnız gösterir (ADR-0011: kural tekrarı yok) |
| Metin | Kısa; yeni key `ENEMY_STRIKE_THRESHOLD` (`%s` = N; öneri biçim: `Kağan vuruş eşiği: %s ordu`). "Lütuflar dahil" ve "T5'ten itibaren" açıklaması satıra **eklenmez**; `HINT_ENEMY_KING` ipucunda anlatılır (enemy-layers §10 güncellendi) |
| Panel sığması | 136 px'te sarar (`AUTOWRAP_WORD_SMART`), kısa metinle 1–2 satır (de/ru/ar 2–3). Bütçe ≈ +14–42 px (kısa metin; ilk taslaktaki 42–56 px'lik uzun cümle düştü) |
| Önizleme DEĞİL | K8 korunur: "bu turda vuracak" demez; yalnız eşik. Başlık/ikon "tehdit" çağrışımı vermez (kırmızı `↓` yok) |
| Güncelleme | Lütuf alınınca / ordu toplanınca / ordu gönderince `_refresh_views` ile anında (seçili bölge) |
| Renk-dışı | Düz metin, sayı |

### 5.4 Düşman takviye satırı (M2 liste filtresi)

| Alan | Tanım |
|---|---|
| Mevcut | `ENEMY` bölgesi seçiliyse ve `enemy_reinforcement_per_turn > 0` → `Takviye: +E_r / tur` (`game_context.gd` `_show_region_info`) |
| M2 | Satır **yalnız** takviye listesindeki bölgede (`enemy_reinforcement_region_ids`; boş = tüm düşman bölgeleri). Perde 1: yalnız `curcet_otagi` (başkent); `curcet_oba` ve `kurt_ini_ormani` satırı göstermez (enemy-layers §10, resource §10 W-16) |
| Kod farkı | `_show_region_info` şu an listeyi okumuyor; `region_id ∈ liste` kontrolü eklenir. Liste `MapState`'te (`enemy_reinforcement_region_ids`) zaten alan olarak var, panel okumaz |
| Metin | Mevcut `ENEMY_REINFORCEMENT` + `PER_TURN` (yeni key yok) |
| Başkent geri alınırsa | Takviye yeniden başlar; satır, bölge düşmana geçince yeniden görünür |
| Okunabilirlik | Listede olmayan düşman bölgesinde satırın **yokluğu** bilgi taşır (takviye almaz); ayrı "takviye yok" satırı eklenmez |

### 5.5 Düşman bölgesi sayacı (K3, Karar C-45)

| Alan | Tanım |
|---|---|
| Neden | Perde 1 kazanma koşulu dört parçalıdır (nötr bölgeler, odaklar, düşman bölgeleri, Erlik eşiği altı); ilk üçü izlenir, düşman bölgeleri izlenmiyordu |
| Koşul | `WinCondition.must_defeat_all_enemies == true` |
| Değer | `alınan düşman bölgesi / başlangıçtaki düşman bölgesi sayısı`; payda sahne başında sabitlenir (`MapState`/`HudModel` veri alanı: `enemy_regions_initial`). Perde 1: `Cürcet bölgeleri x/3` |
| Konum | İlerleme satırına (R2 orta) son segment olarak eklenir; yeni hücre değil. Uyarı durumunda İlerleme ile birlikte gizlenir |
| Metin | Yeni key (öneri `PROGRESS_ENEMY_REGIONS`, `%s` = oran; bölüm adı çevirmen/sahne verisi: "Cürcet bölgeleri") |
| Bağ | `scene-flow.md` §10 "Hedef" satırı bu sayaçla güncellenir (başka ajan/görev) |
| Test | H9 |

### 5.6 Hedef seçimi modu (A5, Karar C-45)

`Ordu Gönder` basıldığında `_awaiting_target` modu (yeni kalıp: **Hedef seçim modu**): `Ordu Gönder` düğmesi "basılı" stilde kalır, panel altında tek satır `Hedef bölgeyi seç` (yeni key `PICK_TARGET_HINT`). **Esc = iptal** (mod kapanır, düğme normale döner). Klavyede de çalışır (K4). Hareketi Azalt: fark yok.

---

## 6. Dikkat Bütçesi Stratejisi (H5)

**Sorun.** Cross-review H5: Perde 1 T5–9'da 5 eşzamanlı aktif sistem (eşik 4): ekonomi/üretim, hedef ilerlemesi, Erlik yayılımı, Kağan saldırısı, Ruh/lütuf. Oyuncu `2(E−1) ≥ 3·P_eff` ve F-E2'yi kafadan hesaplıyor, yayılım takvimi bilinmiyor.

**Strateji: "az kalıcı sayı, çok bağlamsal kural, sıfır kendiliğinden modal".**

| Sistem | Her an (HUD) | Bağlamsal | Modal | Gerekçe |
|---|---|---|---|---|
| Ekonomi | Altın (+Y) | Bölge geliri/ceza, Ordu Topla | — | Her tur karar |
| Hedef | Hedef + ilerleme + düşman bölgesi sayacı | — | Hedef paneli (sahne başı) | Zafer yönü; dört parça da izlenir |
| Erlik yayılımı | Gölge `p/eşik` + **Yayılım: N tur** (aynı hücre) | **Odak tehlikede** (N = 0 ve hedef odak; Yayılım segmentinin yerini alır), bozulma/direnç satırları | Yayılım raporu (tur sonu, tek modal) | Takvim kalıcı, ayrıntı bağlamsal |
| Kağan saldırısı | **Hiçbir şey** (K8: niyet yok) | **Vuruş eşiği satırı** (düşmana komşu oyuncu bölgesi seçilince, her tur), takviye satırı (başkent seçilince) | Saldırı raporu (`BATTLE_LOST_DEFENSE`) | Kural bilgisi sunulur; niyet açık değil |
| Ruh/lütuf | Ruh (sayı) | Kök Böri düğmesi (bekleyince) | Lütuf modalı (şafak ≤ 1 / tur, ertelenebilir) | Kendiliğinden modal sınırlı (D6) |

**Kurallar.**

| # | Kural |
|---|---|
| 1 | R1 sabit hücre sayısı 4, R2 sabit hücre sayısı 3 (Hedef, İlerleme, Gölge). Yayılım Gölge hücresinin **ikinci segmentidir**; Odak tehlikede aynı segmenti paylaşır; düşman bölgesi sayacı İlerleme hücresinin segmentidir. Bundan fazla sabit hücre için §7 ihlali onayı gerekir |
| 2 | Aynı anda **en çok 1 kırmızı uyarı** kalıcı HUD'da: öncelik Erlik kayıp uyarısı > Odak tehlikede > (Yayılım `N = 0` kırmızısı). Yüksek önceliklisi diğerinin yerini alır |
| 3 | Kendiliğinden açılan öğe/tur: ≤ 1 modal (lütuf şafak) + ≤ 1 ipucu balonu; ikisi aynı anda açılmaz (`_hint_bubble != null or modal açık` → ertelenir, mevcut) |
| 4 | Kural bilgisi (D3, takviye, direnç) yalnız **seçilen bölgede** görünür; seçmeyen oyuncuya yük bindirmez, seçen her zaman bulur |
| 5 | Yeni kalıcı bilgi önerisi §1 gereklilik kuralını geçmeli; geçmeyen bağlamsal paneli veya modalı kullanır |
| 6 | Playtest (C-47/C-42) ölçütü: "tur başına HUD'a bakış sayısı" ve "Tur Bitir öncesi bölge seçimi" — eşik değeri henüz yok (playtestte belirlenir); bütçe aşılırsa önce Odak tehlikede'deki bölge adı çıkarılır (yalnız ikon + `Odak tehlikede` kalır) |

---

## 7. Görsel Bütçe

| Kısıt | Sınır | Ölçüm | Mevcut tahmin | Durum |
|---|---|---|---|---|
| Üst bar yüksekliği | ≤ 40 px, 2 satır (Arapça dahil; ilk taslaktaki 42 sınırı kaldırıldı) | `_top_bar_height()` | ≈ 38 (en), ≈ 40 (ar; c69) | Doğrulanacak |
| Alt bar yüksekliği | 27 px (modal alt marjı 31 = 27 + 4) | Düğme + dolgu | 27 | Mevcut |
| HUD kapladığı alan (bar + panel dahil) | ≤ %25 ekran | Piksel alanı / 230.400 | Barlar ≈ 67×640 ≈ %19; panel ≈ %9 en kötü | Doğrulanacak |
| Bilgi paneli genişliği | 136 px sabit | Tema | 136 | Mevcut |
| Bilgi paneli en kötü yükseklik (oyuncu, bozuk, tavan, ipucu 3 satır, D3 2–3 satır) | **≤ 285 px** (360 − 27 − 4 − (40 + 4)); düzeltildi: ilk taslaktaki 233 hatalıydı | Dil bazlı ekran görüntüsü | ≈ 170–215 (tahmin, de/ru/ar) | Doğrulanacak |
| Modal kullanılabilir yükseklik | ≈ 281 px (360 − 40 − 31 − 8) | Modal spec'leri | — | Ortak kural |
| Harita alanı örtülmesi | Panel x ≥ 500 (harita x ≤ 491) | Düzen testi | 0 | Mevcut |
| Panel arkaplan opaklığı | %70 (art bible §7); **metin kontrastı 4.5:1 uygulanan zeminde** | `ui_palette_contrast_test` | Palet testli | Mevcut |
| Pixel font boyutları | Yalnız native/tam kat (Fusion 12/24/36, Unifont 16/32); M2'de tüm panel/modal başlıkları 12 px | Tema denetimi | 12 / 16 | Mevcut |
| Eşzamanlı sabit bilgi hücresi (üst bar) | ≤ 7 (R1:4 + R2:3); alt bar düğmeleri (en çok 3) ve bilgi paneli ayrı sayılır | Sayım | 7 | Sınırda: yeni hücre YASAK (§6 kural 1); segmentler hücre sayılmaz |
| Yenileme maliyeti | HUD kısmı `_refresh_views()` ≤ 1.6 ms (kare bütçesinin %10'u) en kötü durumda; kare başına tahsis yok | Profil / debug ölçümü | — | Doğrulanacak (P1) |

---

## 8. Bildirim ve Geri Bildirim Sistemleri

| Bildirim | Tetikleyen | Yer | Süre | Animasyon | Aynı anda | Öncelik | Kuyruk | Kapatılabilir |
|---|---|---|---|---|---|---|---|---|
| Altın değişimi | `ValueFeedback.observe` | Altın etiketi | Vurgu 0.1 sn (2 kare); fark 1.5 sn | Anlık renk (fade/scale yasak) | 1 | Düşük | Yok | Hayır; Hareketi Azalt'ta kalıcı |
| Erlik kayıp uyarısı | `erlik_warning` | R2 Hedef yeri | Koşul sürerken | Yok | 1 | Yüksek | — | Hayır |
| Odak tehlikede (M2) | N=0 ve hedef odak | R2 (Yayılım segmenti) | Koşul sürerken | Yok | 1 | Orta-yüksek | — | Hayır |
| Öğretici ipucu | `TutorialRules` | Köşe balonu | Kapatılana dek | Yok (anlık) | 1 | Orta | Meşgulken kaçar, sonraki tetikte yeniden | Evet (`Anladım`, görüldü sayılır) |
| Savaş/yayılım/arındırma raporu | `MoveOutcome`/`SpreadDecision` | `ModalQueue` | Oyuncu kapatana dek | Düz kesme (dither cila) | 1 | Yüksek | FIFO, harita girdisi kilitli | Evet (Devam; Esc = Devam) |
| Lütuf sunumu | Şafak / HUD düğmesi | `ModalQueue` | — | Düz kesme (kart dither cila) | 1 | Yüksek | Şafak ≤ 1/tur; ertelenebilir | Evet (Ertele; Esc = Ertele; sahne sonu zorunlu: Esc etkisiz) |
| Kayıt hatası | `SAVE_*` | Modal | — | — | 1 | Yüksek | — | Evet |

**Kurallar**: (1) Toast yok; ölçekli/alfa'lı animasyon yok (art bible §7). (2) Modal açıkken ipucu ve kendiliğinden lütuf beklemede. (3) Modal kapanınca `drained` ile bekleyen ipucu yeniden denenir. (4) Aynı tür bildirim birleşmez; tek-seferlik modal zinciri tur sonu raporunu tek modala toplar (ADR-0011 alt. 3). (5) **Girdi koruması (ortak):** TÜM `ModalQueue` modalları (lütuf seçimi, ertelenebilir sunum dahil) ve E5 bölüm seçimi açılışında tek `screen_input_guard_s` (0.4 sn) uygulanır; koruma içinde Esc/Enter düşer. (6) **Açılış animasyonu:** M2 varsayılanı düz kesme; dither cila, kabul ölçütü değil; Hareketi Azalt = dither yok + sabit kare. (7) **Esc kuralı:** bkz. §10.3 kural 7.

---

## 9. HUD Durumları (bağlam)

| Bağlam | Gösterilen | Gizlenen / değişen | Giriş |
|---|---|---|---|
| Harita, oyuncu turu | Tüm kalıcı barlar; seçime bağlı panel | — | Varsayılan |
| Bölge seçili (oyuncu) | + Ordu Gönder/Topla, vuruş eşiği (M2, düşmana komşuysa) | — | `region_selected` |
| Bölge seçili (düşman) | + takviye satırı (listedeyse) | Ordu Topla/Gönder yok | `region_selected` |
| Hedef bekleme (`_awaiting_target`) | `Ordu Gönder` basılı stil + `Hedef bölgeyi seç` satırı (§5.6); sonraki harita tıklaması / `ui_accept` hedef | Esc = iptal | `Ordu Gönder` |
| Modal açık | Barlar görünür, %60 karartma altında; panel kalır | Harita girdisi kilitli, odak modala | `ModalQueue.push` |
| Oyun bitti (WON/LOST) | Başlık `VICTORY`/`DEFEAT` | Tur Bitir pasif, gelir tahmini gizli, Kök Böri gizli | `game_result != ONGOING` |
| Yükleme / bağlam geçişi | `RootContext` yönetir; HUD yok | — | Sahne akışı |

---

## 10. Erişilebilirlik (HUD)

### 10.1 Renk körlüğü (renk tek ipucu olamaz)

| Öğe | Risk | Çözüm (mevcut / M2) |
|---|---|---|
| Altın artış/azalış (yeşil/kırmızı) | Yeşil-kırmızı ayrımı | `↑+X` / `↓-X` ok + işaret (mevcut; `↑ ↓` Fusion'da var, glyph_coverage_test) |
| Bilgi paneli ceza (`↓-1`) | Kırmızı | Ok + `-` işareti (mevcut) |
| Gölge değeri mor → kırmızı | Mor/kırmızı yakın (protanopi) | Uyarıda Hedef satırı **cümleyle** değişir (mevcut); kırmızı ek |
| Odak tehlikede (M2) | Kırmızı | İkon + metin + bölge adı |
| Yayılım `N = 0` (M2) | Kırmızı | Metin `bu tur sonu` |
| Ordu Topla ipucu (kırmızı) | Kırmızı | İpucu metni (`Tavan doldu`, `Altın yetmiyor`) + pasif düğme |
| Düşman sahipliği (harita) | Düşman-nötr (protanopi ΔE 1.09) | **Düşman tamgası her zaman görünür**, nötrde yok, renk körlüğü modundan bağımsız (seviye §7.8) |
| Çürük ağaç / bozulma | Düşük kontrast 1.1:1 | Bölge lekesi + panel `Bozulma: n / m` sayısı |
| Kök Böri düğmesi | Görünür/gizli tek ipucu | Etiket metni (`Kök Böri`); koşul metinsel |

### 10.2 Hareketi Azalt

| Öğe | Hareketsiz davranış |
|---|---|
| Altın vurgusu + fark metni | Anında uygulanır; **bir sonraki değişime dek kalıcı** (mevcut, `ValueFeedback`) |
| Yayılım sayacı / Odak tehlikede | Animasyon yok; fark yok |
| Panel/modal geçişi | Düz kesme (M2 varsayılanı zaten düz kesme; dither cila ve Hareketi Azalt'ta kapalı, sabit kare) |
| Lütuf kartı dither'ı | Cila; Hareketi Azalt'ta düz kesme |
| Harita Erlik lekesi / Kök Böri | Orta kare sabit (art bible §7) |

### 10.3 Klavye (odak) zinciri

| # | Kural |
|---|---|
| 1 | Başlangıç sessiz odağı: **Tur Bitir** (`FocusReveal.focus_quietly`). Odak, fareyle tıklanana dek görünmez (sessiz), klavye gelince 1 px altın kenar |
| 2 | Zincir: `Tur Bitir ↑ Ordu Topla/Gönder ↓ Tur Bitir` (dinamik bağ; panel gizlenince kalkar). `GameContext._update_focus_chain` kurar, panel kardeşlerini bilmez |
| 3 | Modal açılınca odak modalın `get_focus_target()`'ına gizlice taşınır; kapanınca önceki odak geri verilir |
| 4 | Modal klavyeyle kapanır (`ui_accept` / `ui_cancel` — Esc kuralı 7'ye tabi) |
| 5 | **K4 (Karar C-45, M2 kapsamında): klavyeyle bölge seçimi.** Harita bölgeleri odaklanabilir (`focus_mode=ALL`; Tab ve ok tuşları, ok tuşları harita komşuluğuna göre `focus_neighbor`), `ui_accept` = bölgeyi seç (bilgi paneli açılır, odak panelin ilk etkin öğesine geçer; `ui_cancel` ile bölgeye döner). Hedef seçim modunda `ui_accept` = hedef. Yeni kalıp: **Bölge odağı**. Uygulandı **C-75**; RTL: harita LTR olduğundan oklar her dilde ekran geometrisini izler (UD kapandı). AC A-7 |
| 6 | Yeni M2 salt-okunur satırları (D3, Yayılım, Odak tehlikede, düşman bölgesi sayacı) odaklanmaz (odak zincirini uzatmaz) |
| 7 | **Esc kuralı (ortak, tüm modallar):** tek güvenli çıkışı olan veya ertelenebilir modalda Esc = o eylem (rapor/zafer kartı = Devam; ertelenebilir lütuf = Ertele; E1 anlatı = Atla; E5 = Ana Menü). Zorunlu içeriği atlatacak modalda (zorunlu lütuf, E2 hedef paneli, E4 yenilgi) Esc **etkisizdir**. HUD hedef seçimi modunda Esc = iptal. Girdi koruması süresince (0.4 sn) Esc/Enter düşer |

### 10.4 Metin ve ölçek

| Konu | Karar |
|---|---|
| Büyük Metin Modu | **Ertelendi (post-launch)**; 12/16 px tek boyut (art bible §7) |
| Hiyerarşi | Boyutla değil renkle: başlık `#EDC76B`, ikincil `#B8A689`, Erlik bilgisi `#A86BC4`, kayıp `#E87A7A`, kazanç `#87B85C`. Tüm panel/modal başlıkları 12 px `HeaderLabel` (Arapça 16); 24 px yalnız tam ekran başlık kartı (cila) |
| Kontrast | HUD metni ≥ 4.5:1, %70 opak panel üstünde; renk çiftleri `ui_palette_contrast_test`te |
| Uzun çeviri | `…` ile kısalır (UI); anlatı metni kısalmaz (içerik hatası) |
| Altyazı | Yok (diyalog sesi yok; anlatı metni ekranda) |
| Yanıp sönen içerik | Yok; HUD'da flaş yok (2 karelik renk vurgusu Hareketi Azalt'ta kalıcıya döner) |
| Ekran okuyucu | Kapsam dışı (Standart katman); AC değil |

### 10.5 Yerelleştirme / RTL (ADR-0009)

| Kural | Uygulama |
|---|---|
| İşaretli ve oranlı değerler | `NumberFormatter.ltr()` / `fraction()` (LRI…PDI) |
| Sözcük sırası ve birim | Çevirmen sahipli biçim key'i (`PER_TURN`); `to_upper/to_lower/capitalize` yasak |
| Glif | `−`, `⚠`, `✕`, `✓` metinde yasak; eksi ASCII `-`; durum sembolleri piksel ikon. `↑ ↓ ◆` Fusion'da var (`glyph_coverage_test`). **C-76 (2026-10-25): `×` ve `→` her native fontta var** (Fusion 12 latin/ja/ko/zh + Unifont 16; `glyph_coverage_test` + 12 px görsel kontrol) → metinde kullanılabilir; `×N/MAX` gibi sayı içeren biçimler Arapçada yön sırası bozulmasın diye kodda LTR yalıtılır (`NumberFormatter.ltr`) |
| Panel yönü | Bilgi paneli LTR (harita aynalanmaz), içerik locale yönünde; üst bar ve alt bar locale yönünde |
| Yeni key'ler | Yalnız `en` önce, sonra diğer 10 dil; Fusion/Unifont kapsama testi geçmeli. M2 key'leri: `SPREAD_COUNTDOWN`, `SPREAD_THIS_TURN_END`, `FOCUS_AT_RISK`, `ENEMY_STRIKE_THRESHOLD`, `PROGRESS_ENEMY_REGIONS`, `PICK_TARGET_HINT` (adlar öneridir) |

---

## 11. Ayar Düğmeleri (Tuning Knobs)

| Parametre | Değer | Aralık | Not |
|---|---|---|---|
| `ValueFeedback.FLASH_FRAMES` | 2 kare (0.1 sn) | 1–4 | Art bible §7 |
| `ValueFeedback.DELTA_HOLD_SEC` | 1.5 sn | 1–3 | Hareketi Azalt'ta kalıcı |
| `ROW_SEPARATION` / panel genişliği | 4 / 136 px | — | Tam kat |
| İpucu metin genişliği | 216 px | 180–240 | `HintBubble.TEXT_WIDTH` |
| Panel/alt bar boşluğu | 4 px | — | Sabit |
| Odak tehlikede eşiği | `N = 0` (Karar C-45) | — | Sabit (K1) |
| `screen_input_guard_s` | 0.4 sn | 0.2–0.6 | Tüm modallar + E5 (`SceneFlowConfig`) |
| Perde başına vuruş oranı | 3/2 | `strike_ratio_num/den` | Veri odaklı (enemy-layers) |
| `attack_start_turn` | 5 | 3–8 | Veri odaklı |
| Kendiliğinden modal/tur | ≤ 1 (lütuf şafak) | — | spirit §3.4 |

---

## 12. Kabul Kriterleri (test edilebilir)

**Veri / saf mantık (otomatik, `tests/unit/ui/`)**

| # | Kriter | Tür |
|---|---|---|
| H1 *(✅ C-87 model; H1–H4, H8–H10 `tests/unit/ui/hud_presenter_m2_test.gd`; görünüm C-88)* | `HudPresenter.build`: `spread_turns_left = max(0, I_eff − (turn − last_spread))`; yayılım turunda 0; arındırma sayacı sıfırlamaz; Gök Kalkanı ile `I_eff` uzayınca N uzar | Otomatik |
| H2 | `erlik_threshold = 0` iken yayılım sayacı ve Gölge gizli | Otomatik |
| H3 | `spread_target ∈ erlik_foci` **ve** `N = 0` ⇒ `focus_at_risk = true`; `N ≥ 1` iken `false`; hedef `null` ise `false`; hedef odak değilse `false` | Otomatik |
| H4 | `StrikeThreshold.min_force(P_eff, num, den)`: `(P_eff=0 → 1)`, `(2 → 3)`, `(3 → 5)` (3/2); `(5 → 8)`; `A > P_eff` ve `2A ≥ 3·P_eff` birlikte sağlanır; lütuf modifikatörü `P_eff`'i artırınca N artar; aynı fonksiyon AI'nın kullandığı F-E1 ile tutarlı (çapraz test) | Otomatik |
| H5 | D3 satırı: yalnız düşmana komşu PLAYER bölgesinde, `strike_enabled` iken, **1. turdan itibaren her tur**; ENEMY/NEUTRAL bölgede yok; oyun bitince yok | Otomatik / görünüm |
| H6 | Takviye satırı yalnız `enemy_reinforcement_region_ids` içindeki bölgede; liste boşsa tüm ENEMY bölgelerde; Perde 1'de `curcet_oba`/`kurt_ini_ormani` satırsız | Otomatik |
| H7 | `ValueFeedback`: ilk gözlem geri bildirim üretmez; Hareketi Azalt'ta bayraklar bir sonraki değişime dek kalır (mevcut test) | Otomatik |
| H8 | Aynı anda kalıcı HUD'da en çok 1 kırmızı uyarı; öncelik Erlik kayıp > Odak tehlikede > Yayılım `N=0` | Otomatik |
| H9 | Düşman bölgesi sayacı: yalnız `must_defeat_all_enemies` iken görünür; payda sahne başındaki düşman bölgesi sayısıdır ve düşman bölgesi alınınca/geri kaybedilince pay değişir, payda değişmez | Otomatik |
| H10 | `N = 0` ve hedef odaksa Gölge hücresinde `p / eşik` segmenti görünür ve `Yayılım` segmenti `Odak tehlikede` ile **yer değiştirir** (ikisi birden yok) | Otomatik / görünüm |

**Yerleşim (ekran görüntüsü, `production/qa/evidence/`)**

| # | Kriter |
|---|---|
| L1 *(C-88: `_fit_objective_row` — Hedef sonra İlerleme `…`; en/de/ru/ar en kötü durum ve Prolog 6 dil 38 px; de/ar/fr/es/pt `SPREAD_COUNTDOWN` kısa biçim, Prolog'da Arapça in sayısı kaybolmasın diye)* | 11 dilin tümünde (özellikle de, ru, ar) üst bar 2 satırda ve ≤ 40 px kalır; taşma yok; yalnız Bölüm adı ve Hedef `…` ile kısalır; Altın/Ruh/Tur/Gölge `p / eşik`/Yayılım **kısalmaz** |
| L2 | Bilgi paneli en kötü durumda (oyuncu, bozuk, tavan, D3 satırı) ≤ **285 px** (360 − 27 − 4 − (40 + 4)); üst barla çakışmaz; de/ru/ar kontrol edilir |
| L3 | Yayılım segmenti ve Odak tehlikede aynı segmentte; ikisi birden görünmez |
| L4 | Arapçada `Yayılım: N`, `p / eşik`, `(+Y)` rakam ve işaret sırası doğru (c69 örneği); native okur onayı (ADR-0009) |
| L5 | Panel/ipucu balonu hedef işaretlerini örtmez (`PanelPlacement.choose`); Perde 1'de sol-üst başlangıç yok |
| L6 | Yeni key'ler `glyph_coverage_test`i geçer (`−`, `⚠`, `✕`, `✓` yok); `×` ve `→` kullanılabilir (C-76; sayılı biçim LTR yalıtılır) |
| L7 | Modal iç genişliği ≤ 288 px, dış ≤ 304 px; modal ≈ 281 px kullanılabilir yüksekliğe sığar (üst 40 / alt 31 marj) |

**Erişilebilirlik**

| # | Kriter |
|---|---|
| A-1 | Her HUD durumu renksiz (gri tonlamalı) ekran görüntüsünde aynı bilgiyi verir (altın farkı, Erlik uyarısı, Odak tehlikede, Ordu Topla ipucu) |
| A-2 | Protanopi/deuteranopi simülasyonunda düşman bölgesi tamgayla ayırt edilir (kontrast ≥ 3:1, test: `unit/ui`) |
| A-3 | Hareketi Azalt açıkken HUD'da zamanlayıcıyla kaybolan hiçbir öğe yok (Altın farkı kalıcı) |
| A-4 | Klavye yalnız: Tur Bitir ↔ Ordu Gönder/Topla zinciri çalışır; modal açılınca odak modalda, kapanınca geri döner; **ortak Esc kuralı (§10.3 kural 7) her modal türünde doğrulanır**: rapor/zafer kartı Esc = Devam, ertelenebilir lütuf Esc = Ertele, zorunlu lütuf / E2 / E4'te Esc etkisiz, hedef seçim modunda Esc iptal; girdi koruması süresince Esc/Enter düşer |
| A-5 | HUD'da yanıp sönme yok (>3 Hz); renk vurgusu 2 kare ve Hareketi Azalt'ta kalıcı |
| A-6 | Tüm kontrast çiftleri `ui_palette_contrast_test` ile ≥ 4.5:1 (metin) / ≥ 3:1 (grafik) |
| A-7 | **K4:** Yalnız klavyeyle bir bölge seçilebilir (Tab/ok ile odak, `ui_accept` seçer); bilgi paneline (D3 satırı, Ordu Topla) ve hedef seçim moduna klavyeyle erişilir; fare hiç kullanılmadan bir tur oynanabilir. Uygulama: **C-75** (`RegionFocusTarget`, `RegionFocusRules`, Tab: Tur Bitir → bölgeler okuma sırası; kanıt `production/qa/evidence/c75-keyboard-turn.md`) |

**Davranış**

| # | Kriter |
|---|---|
| B1 | Modal açıkken harita tıklaması bölge seçmez, panel kalır, kapanınca odak geri verilir |
| B2 | Aynı anda ≤ 1 modal ve ≤ 1 ipucu balonu; modal açıkken ipucu ertelenir, `drained` sonrası denenir |
| B3 | Oyun bitince Tur Bitir pasif; gelir tahmini ve Kök Böri gizli |
| B4 | Lütuf alınınca açık bölgenin D3 sayısı ve Gölge/gelir aynı yenilemede güncellenir |
| B5 | **A7:** Kök Böri düğmesi yalnız sunum beklerken görünür; beklemiyorsa gizli; etiket `Kök Böri` (ek ipucu yok); oyun bitince gizli |
| B6 | `Ordu Gönder` sonrası hedef seçim modu: düğme basılı stil, `Hedef bölgeyi seç` satırı görünür, Esc modu iptal eder |

**Performans**

| # | Kriter |
|---|---|
| P1 | En kötü durumda (tüm M2 satırları görünür, de/ru/ar) HUD yenilemesi (`_refresh_views` HUD kısmı) ≤ 1.6 ms; kare başına yeni nesne tahsisi yok; 60 FPS korunur (debug profil ölçümü) |

---

## 13. Kararlar (C-45) — eski Açık Sorular

| # | Konu | Karar (C-45) |
|---|---|---|
| K1 / A1–A3 | Yayılım göstergesi | **Sade.** HUD her an `Yayılım: N tur` (N = 0 → "bu tur sonu"); sayaç Gölge hücresinin **ikinci segmenti** (ayrı hücre değil). Yalnız N = 0 **ve** hedef bir `erlik_foci` ise segment `Odak tehlikede: <bölge>` (ikon + metin) ile yer değiştirir; `p / eşik` hep görünür. Haritada hedef işareti cila. spirit §3.6 bu tanıma daraltıldı |
| K2 / A4 | Kağan vuruş eşiği satırı | Düşmana komşu oyuncu bölgesinde 1. turdan itibaren her tur (`strike_enabled`); kısa metin, yeni key `ENEMY_STRIKE_THRESHOLD`; `N = max(P_eff+1, ceil(num·P_eff/den))`, `P_eff=0 → 1`. "Lütuflar dahil / T5'ten itibaren" açıklaması `HINT_ENEMY_KING` ipucunda. enemy-layers §10 güncellendi; cross-review D3 metnine "uygulama: hud.md" notu eklenir (başka görev) |
| K3 | Hedef sayacı | Perde 1 ilerleme satırına `Cürcet bölgeleri x/3` (`must_defeat_all_enemies` iken). scene-flow §10 "Hedef" satırı buna bağlanır (başka görev) |
| K4 / A6 | Klavyeyle bölge seçimi | **M2 kapsamında**: bölgeler odaklanabilir (Tab/ok), `ui_accept` seçer. AC A-7 + **C-47 görevi** |
| A5 | Hedef seçimi ipucu | M2'de: basılı düğme stili + `Hedef bölgeyi seç` satırı, Esc iptal (§5.6) |
| A7 | Kök Böri düğmesi ipucu | Değişiklik yok; görünürlük durumu verir; AC B5 |
| A8 | Hedef satırı kısalıyor | Hedef panelindeki tam cümle yeterli; R2'de kısaltma kabul. `WIN_CONDITION_*` metinleri ≤ 40 karakter hedefi (çevirmen notu) |
| Ortak | Esc, girdi koruması, modal genişliği, başlık, animasyon, çubuk ölçüleri, AccessKit, glifler | §3.2, §7, §8, §10.3 (kural 7), §10.4–10.5 |

**Çözülmemiş / bağımlı:** (1) scene-flow §10 "Hedef" satırı ve cross-review D3 notu başka görevlerde güncellenecek. (2) M2 key adları öneridir; `translations.csv` kaydında kesinleşir. (3) ~~`×` / `→` glif testi~~ C-76'da kapandı.

---

## 14. Yeni Kalıp Bayrakları (interaction-patterns.md yok)

| Kalıp | Durum |
|---|---|
| Gölge hücresinde segment değişimi (Yayılım ↔ Odak tehlikede) | yeni |
| Salt okunur kural bilgisi satırı (D3) | yeni |
| Hedef seçim modu (basılı düğme + yönerge satırı + Esc iptal) | yeni |
| Bölge odağı (Tab/ok ile harita bölgeleri) | yeni |
| Modal girdi koruması (`screen_input_guard_s`) | mevcut (ortak kural olarak genişletildi) |
