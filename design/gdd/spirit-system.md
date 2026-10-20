# Sistem GDD: Kök Böri / Ruh Sistemi

*Oyun: ULUS: Blood of the Sky Wolf*
*Oluşturulma: 2026-07-14*
*Durum: Designed (M1 kodu: arındırma/bozulma C-38, değiştirici hattı C-55, Erlik kaybı C-63, Kök Böri lütuf çekirdeği C-39 — `BoonCatalog`/`BoonRules`/`SpiritController.pick_boon`, şafak + HUD + zafer sunumu; sahne geçişi AC6 C-40; çapraz inceleme 2026-10-19 CONCERNS → C-53; Prolog dengesi C-49)*
*Katman: Feature (imza sistem)*

---

## 1. Overview

Kök Böri / Ruh Sistemi, oyunun imza mekaniğidir. Oyuncu, Erlik'in bozduğu
bölgeleri **arındırarak** *Ruh* kaynağı kazanır ve bu Ruh'u gök kurt Kök
Böri'nin sunduğu **ilahi lütuflara** (roguelite tarzı 3 seçenekten 1) harcar.
Lütuflar kalıcı, birikimli pasif bonuslardır ve sahneler arasında taşınır —
finalde tümü aktiftir. Sistem, anlatısal çapayı (Kök Böri rehberliği) doğrudan
oyuncunun güç eğrisine bağlar: dünyayı Erlik'ten temizledikçe güçlenirsin.

---

## 2. Player Fantasy

Oyuncu, Ülgen'in yeryüzündeki eli olarak, gök kurdun kutsamasıyla giderek
güçlenen bir kahraman hisseder. Her arındırılan bölge hem görsel bir zafer
(mor-siyah çürüme → yeşil bozkır) hem de somut bir güç kazanımıdır. Lütuf
seçimi anları "kaderimi ben seçiyorum" hissi verir — her sahne kişisel bir
build inşa etme fırsatıdır. Erlik yayıldıkça "toprağım çürüyor, harekete
geçmeliyim" baskısı hisseder; arındırdıkça "kutsandım" tatmini yaşar.

---

## 3. Detailed Rules

### 3.1 Erlik Bozgunu (Corruption)
- Her bölge bir `corruption_level` değerine sahiptir: `0` (temiz) – `3` (ağır).
- Bozulmuş bölge (`corruption_level ≥ 1`):
  - Görsel: art bible §4 "Sahiplik Renkleri" → Erlik bozgunu katmanı (yalnızca
    Erlik Moru + Erlik Kömürü, dithering'li leke; sahiplik rengini gizlemez,
    üstüne biner). Yeşil arındırılmış toprağın rengidir. Seviye bilgi panelinde
    sayıyla gösterilir (§3.2, C-30); haritadaki seviye görseli art bible §4 "Bozulma
    Seviyeleri"nde (C-50): dither yoğunluğu %25 / %50 / %75, 2px temiz sahiplik bandı.
  - Ceza: o bölgenin `gold_per_turn` ve `herd_per_turn` üretimi seviyeye göre
    çarpanla düşer: seviye 1 → ×0.75, seviye 2 → ×0.5, **seviye 3 → ×0 (üretim
    durur)** (`CORRUPTION_PRODUCTION_MULTIPLIERS`, §4.3).
  - Bir "arınma direnci" (`corruption_strength`) taşır (bkz. Formüller)

### 3.2 Arındırma (Purification) — C-30 kararı (2026-10-18)
- **Eylem:** Arındırma ayrı bir eylem değildir; **ordu varışının 2. dalıdır**
  (`army-system.md` §3.3). Oyuncu, sahip olduğu komşu bir bölgeden bozulmuş bölgeye
  normal hareketle ordu gönderir (`can_move` kuralları aynen geçerli). Hamle **1
  aksiyon** harcar — başarısız olsa da.
- **Ne zaman arındırma olur:** hedefte yabancı garnizon yoksa (hedef oyuncunun ya
  da `army_count == 0`) **ve** `corruption_level ≥ 1` ise. Yabancı garnizon varsa
  hamle **savaştır** (1. dal) ve bozulmaya o hamlede dokunulmaz.
- **Çözüm:** `CombatResolver.resolve(P_eff, corruption_strength)`; `P` = gelen kuvvet
  (`kaynak.army_count − 1`), `P_eff` = Kurt Gücü dahil etkin güç (§4.1; M1'de `P_eff = P`).
  Hedefte zaten duran oyuncu garnizonu katılmaz. Başarı **yalnızca** `P_eff > S` ile
  belirlenir ve kayıp her zaman Dal 1 formülüdür — `draw_favors_defender` knob'u
  arındırmayı etkilemez (C-53).
- **Başarı** (`P_eff > corruption_strength`): `corruption_level = 0`, üretim geri döner,
  oyuncu `ruh_gain` (§4.2, arındırma *öncesi* seviyeyle) kadar Ruh kazanır. Hayatta
  kalanlar (`P − ceil(S × attacker_win_loss_ratio)`) bölgeye yerleşir: bölge
  oyuncunun değilse `owner = PLAYER` olur; oyuncununsa garnizona eklenir.
- **Başarısızlık** (`P_eff ≤ corruption_strength`, eşitlik dahil): gelen kuvvetin
  **tamamı kaybolur** ("Erlik yuttu"); bölgenin sahibi, ordusu ve bozulması
  değişmez; Ruh kazanılmaz. (Savaşta kaybedenin hayatta kalanlarının dağılması
  kuralının uç hali — savaş §3/§7; burada Dal 3'ün kalanı da kaybolur.)
- **İşleme sırası (C-53, S1-a):** Hamlenin tüm sonuçları — sahiplik, ordu, bozulma,
  Ruh ve aksiyon — işlendikten **sonra** kazanma kontrol edilir ve `game_won`
  yayılır (`region-map-system.md` §3.3). Böylece canavarı yenen son hamlede Ruh,
  sahne sonu sunumunu türetmeden önce hazineye girmiş olur.
- Bir bölge tek arındırmada tamamen temizlenir (kısmi arındırma yok — MVP sadeliği).
- **Fetih arındırmaz (B5):** Bozulmuş bir bölgeyi savaşla ele geçirmek
  `corruption_level`'ı değiştirmez ve Ruh vermez. Oyuncu bölgeyi bozulmasıyla
  (düşük üretimle) devralır; arındırmak için sonraki bir hamlede bölgeye kuvvet
  gönderir. Gerekçe: Ruh'un tek musluğu arındırmadır (§3.3) ve Erlik katmanı
  sahiplikten bağımsızdır (§3.7) — fetih siyasi, arındırma kozmik katmandır.
- **Yalnızca oyuncu arındırır:** Düşman AI bozulmayı yok sayar (hedef seçiminde ve
  varışta). Düşman bozuk bölgeye girebilir veya onu alabilir; bozulma kalır, kimse
  Ruh kazanmaz.
- **Görünürlük:** Bölge bilgi paneli bozulmuş bölgede seviyeyi ve
  `corruption_strength`'i gösterir; çözüm deterministik olduğundan sonuç hamleden
  önce hesaplanabilir (Epik Ama Erişilebilir).
- **Hamle önizlemesi (gereksinim, C-53 / N7):** Oyuncu kaynak seçiliyken bir hedefin
  üzerine geldiğinde hamlenin **deterministik sonucu** gösterilir: dal (savaş /
  arındırma / barışçıl), kayıp, kalan ve — arındırmada — başarı/başarısızlık ile Ruh.
  Başarısız olacak bir arındırma (kuvvetin tamamı kaybolur) onaysız yapılamaz:
  önizleme uyarı verir, ikinci tık onaylar. Spec: UX görevleri (C-41 / C-45).
- **Prolog canavarı (C-49 kararı):** Canavarın İni (seviye 3, **garnizon 0**) `S = 12` →
  en az 13'lük kuvvet (kaynakta ≥ 14 ordu) gerekir; başarı 30 Ruh verir = ilk lütuf eşiği
  (`BASE_BOON_COST`). Garnizon 0 bilinçlidir — canavar bozulma direncinin kendisidir;
  garnizonlu in son hamleyi savaşa çevirirdi (arındırma ve zafer o hamlede olmaz, iki
  yığın + iki aksiyon gerekir — S1-e). Veri kabul kriteri: `region-map-system.md` AC14.
  Lütuf sunum zamanı §3.4.
- **Öğretici bozulma (C-49, çapraz inceleme N1/N3):** Doğu Obası (inin ve Otağ'ın komşusu)
  **seviye 1, garnizon 0** başlar: ilk arındırma `P ≥ 5` (Otağ'da 2 üretip 6'yla), +10 Ruh,
  bölge oyuncunun olur ve nötr fetih sayılır. Arındırılmazsa en az ordulu aday olduğu için
  T3'te seviye 2, T6'da seviye 3 olur (eşik 5 → 9 → 13, ödül 10 → 20 → 30) — Erlik'in
  derinleşmesini canavardan önce gösterir. Prolog sayıları: `resource-system.md` §4,
  [balance raporu](../balance/prolog-balance-2026-10-19.md).

### 3.3 Ruh Kaynağı
- Ruh, `GameState` içinde tutulan kalıcı bir kaynaktır (altın/sürüden ayrı).
- Sadece arındırmadan kazanılır (tek musluk). Harcama tek yer: lütuf.

### 3.4 Kök Böri Lütufları (Boons) — C-31 kararı (2026-10-18)
- **Sunum koşulu (türetilmiş durum):** sunum bekler ⇔ `ruh ≥ boon_cost(n)` **ve**
  uygun havuz (§3.5) boş değil; `n = GameState.boons.size()` (kampanya boyunca
  alınan lütuf sayısı). Ayrı bir "bekleyen sunum" alanı tutulmaz — kayıt
  (ADR-0007) yalnızca `ruh` ve `boons`'u saklar, durum yüklemede yeniden türetilir.
- **Zamanlama (çapraz inceleme B6):** Kök Böri sunumu yalnızca iki anda açar:
  1. **Oyuncu turunun başında ("şafak"):** `end_turn` 5. adımı (kontrol) bitmiş ve
     oyun sürüyorsa, sunum bekliyorsa modal açılır. Tur başı başına **en fazla 1**
     sunum.
  2. **Sahne zaferle bittiğinde** (outro'dan önce — `scene-flow.md`, C-35): bekleyen
     sunumlar **sırayla** gösterilir ve **seçim zorunludur**; koşul sağlandığı sürece
     (Ruh bir sonraki eşiğin altına inene ya da havuz boşalana kadar) devam eder; dizi,
     patolojik Ruh değerlerine (hata ayarı, debug) karşı en çok `VICTORY_PICK_CAP` (8)
     seçimle sınırlıdır, kalan sunum türetilmiş olarak bekler (`scene-flow.md` F2).
  Arındırma hamlesinin hemen ardından tur ortasında kendiliğinden açılmaz — hamle
  akışı kesilmez (dikkat bütçesi, çapraz inceleme D6).
- **Erteleme:** Oyuncu tur başı modalını "Ertele" ile kapatabilir. Sunum §4.5
  girdileri (`chapter_id`, `n`, uygun havuz) değişmediği sürece aynı 3 lütufla bekler;
  oyuncu kendi turunda HUD'daki Kök Böri düğmesinden istediği an açıp seçebilir;
  seçilmezse her yeni tur başında yeniden gösterilir. Sunum **açıldığı anda yeniden
  hesaplanır** — uygun havuz değişmişse (M2'de bir `requires` kilidi açılırsa) 3'lü de
  değişebilir. Sahne sonundaki sunum ertelenemez. Kaybedilen sahnede sunum gösterilmez
  (Ruh harcanmaz; yenilgi akışı `scene-flow.md` §3.7: "Sahneyi Yeniden Dene" sahne girişi
  durumuna döner — önceki sahnelerden taşınan Ruh/lütuflar korunur, kaybedilen denemede
  kazanılan Ruh ve seçilen lütuflar geri alınır; kasıtlı yenilgiyle Ruh çiftçiliğini önler).
- **Seçim:** uygun havuzdan **3 lütuf** gösterilir, oyuncu **1** seçer; maliyeti
  Ruh'tan düşülür, seçilmeyen 2'si kaybolur. Seçimden sonra koşul hâlâ sağlanıyorsa:
  **otomatik modal** bir sonraki tur başında açılır (sahne sonundaysa hemen), ama
  **HUD düğmesi** bekleyen sunumu hemen gösterir — oyuncu aynı tur içinde art arda
  seçebilir. "Tur başı en fazla 1" kuralı yalnızca kendiliğinden açılan modalı sınırlar
  (dikkat bütçesi); güç sınırı Ruh ve artan maliyettir (C-53, W-C). Ek durum alanı
  tutulmaz.
- **Etkinin başlangıcı:** seçildiği an. Lütuf `ModifierController.add_source()` ile
  `GameState.modifiers`'a işlenir (ADR-0006); o andan sonraki her hesap — aynı turun
  kalan hamleleri ve sonraki `end_turn` ekonomisi — etkiyi görür. Geriye dönük etki
  yoktur (ör. Bereket, seçildiği turun sonundaki gelire yansır).
- Lütuflar `GameState.boons` listesinde (seçim sırasıyla `boon_id`'ler) birikir,
  sahneler arası taşınır. **Tek doğruluk kaynağı `boons`'tur** (C-53, W-F): `n` buradan
  sayılır ve kayıtta yalnızca `ruh` + `boons` saklanır; lütufların `StatModifier`
  kayıtları yüklemede `boons`'tan yeniden kurulur (ADR-0006/0007 "seçimi sakla, etkiyi
  türet").
- Lütuf etkileri pasif ve toplamsaldır: aynı lütuf yeniden alınınca kaydın `stacks`
  değeri artar (ADR-0006 tekillik değişmezi). Yığılma sınırı olan lütuf sınıra
  ulaşınca uygun havuzdan çıkar.
- 3'lü sunum **deterministik** seçilir (bkz. Formüller — test edilebilirlik için).

### 3.5 Lütuf Kataloğu (Başlangıç Havuzu) — C-31 revizyonu
Etkiler ADR-0006 modifikatör hattından geçer (`stat_id`, `FLAT`/`PERCENT`, yığın
başına değer). Tablodaki sayılar §4/§7 knob'larının varsayılanlarıdır — değerin sahibi
knob'dur, katalog onu gösterir (C-53). Katalog içeriği spirit feature'ının
`BoonDefinition` kaynağıdır (`boon_id`, ad key'i, `requires`, `ModifierSource`);
yığılma sınırının **tek sahibi** `ModifierSource.max_stacks`'tir (Gök Kalkanı `.tres`'i
`GOK_KALKANI_MAX_STACKS` değerini taşır) ve uygunluk `ModifierController.can_add()` ile
sorulur (ADR-0006, mimari inceleme 2026-10-19 D2). **Uygun havuz** = katalog − gerektirdiği sistemi etkin olmayanlar −
yığılma sınırına ulaşmışlar, `boon_id`'ye göre sıralı.

| Lütuf (`boon_id`) | Etki (yığın başına) | Stat / tür | Gerektirir | Yığılma sınırı | İlk kademe |
| ---- | ---- | ---- | ---- | ---- | ---- |
| Arınma Ustalığı (`arinma_ustaligi`) | Arındırma başına Ruh +%20 | `ruh_gain` / PERCENT +0.20 | — | — | M1 |
| Bereket (`bereket`) | Tur geliri +1 altın | `gold_income` / FLAT +1 (→ resource `B_add`) | — | — | M1 |
| Demir Post (`demir_post`) | Savunan oyuncu bölgesine +1 etkin güç | `army_defense` / FLAT +1 | Savaş etkin gücü (`combat-system.md` §4 "Etkin güç") | — | M2 |
| Gök Kalkanı (`gok_kalkani`) | Erlik yayılım aralığı +`GOK_KALKANI_INTERVAL_BONUS` (1) tur | `erlik_spread_interval` / FLAT +`GOK_KALKANI_INTERVAL_BONUS` | — | `GOK_KALKANI_MAX_STACKS` (3) | M1 |
| Kurt Gücü (`kurt_gucu`) | Oyuncunun saldıran ve arındıran kuvvetine +1 etkin güç | `army_attack` / FLAT +1 | Savaş etkin gücü (`combat-system.md` §4 "Etkin güç") | — | M2 |
| Sürü Kutsaması (`suru_kutsamasi`) | Sürü geliri +%10 | `herd_income` / PERCENT +0.10 | Sürü etkin (`resource-system.md` §3.1) | — | kilitli |
| Yiğit Ruhu (`yigit_ruhu`) | Kahraman birim gücü +%10 | `hero_strength` / PERCENT +0.10 | Kahraman birimleri (`hero-units.md`) | — | kilitli |

> **Neden düz değerler (W9):** Prolog'da ordular 2–14, gelir 2–10 arasındadır;
> %5–%10'luk bonuslar yuvarlamada kaybolur (ör. `floor(5 × 1.1) = 5`). Askeri ve
> ekonomi lütufları bu yüzden **+1** düz etkidir: her yığın görünür ve hesaplanabilir.
> Geç oyunda göreli etkisi azalır — doğal bir yumuşak tavan. Sürü ve kahraman
> lütufları bağlı sistemler tasarlanınca yeniden değerlendirilir (aynı yuvarlama riski).

### 3.6 Erlik Yayılımı (AI Katmanı)
- Her `I_eff` turda bir, Erlik yayılır (bkz. Formüller §4.6; `I_eff` = sahnenin
  `ERLIK_SPREAD_INTERVAL` değeri + Gök Kalkanı).
- Yayılım deterministiktir: kurallı hedef seçimi (rastgele değil).
- **Yayılım göstergesi (gereksinim, C-53 / N7):** HUD bir sonraki yayılıma kalan tur
  sayısını ve — hedef deterministik olduğundan — o anki duruma göre bir sonraki hedef
  bölgeyi gösterir (hedef tur sonundaki AI hamleleriyle değişebilir; gösterge "şu an
  olsa" bilgisidir). Spec: C-41 / C-45.
- **Tur sonundaki yeri (C-29):** `end_turn` sırasının **2. adımı** — düşman AI'dan
  sonra, ekonomi adımından önce (`region-map-system.md` §3.4). Yayılan bozulma o
  turun gelirine hemen yansır. Yayılım turu: son yayılımdan bu yana geçen tur sayısı
  `I_eff`'e ulaştığında (`current_turn − last_erlik_spread_turn ≥ I_eff`;
  `MapState.last_erlik_spread_turn` sahne başında 0). Aralık sabitken bu
  `current_turn % interval == 0` ile aynıdır — ilk yayılım `interval`. turun sonu —
  ama aralık sahne ortasında Gök Kalkanı ile uzarsa bir sonraki yayılım kısalmaz
  (C-31).
- **Sahip:** Yayılım, bozulma ve arındırma bu GDD'ye aittir; ayrı bir
  `corruption-purification.md` MVP için yazılmaz (bkz. §3.7).

### 3.7 Erlik Modeli ve Sahiplik (C-29 kararı, 2026-10-18)
- **Tek model — bozulma katmanı:** Erlik, bölge *sahipliğinden bağımsız* bir
  `corruption_level` (0–3) katmanıdır. Sahip türleri yalnızca `NEUTRAL / PLAYER /
  ENEMY`'dir; **`ERLIK` sahip türü yoktur.** `ENEMY` yalnızca siyasi krallar içindir
  (Art Bible: pas turuncusu = düşman kral; mor = yalnızca Erlik).
- **Erlik canavarı = bozulmuş bölge.** Prolog'daki "Canavarın İni", `owner = NEUTRAL`
  ve başlangıçta `corruption_level = 3` olan bir bölgedir; **fetihle değil
  arındırmayla** yenilir (§3.2) ve ilk Ruh'u verir. Canavar siyasi bir aktör değildir:
  düşman AI'ya katılmaz, kendiliğinden hareket etmez.
- **Prolog baskısı (D3 → C-49):** Canavarın İni seviye 3'te, Doğu Obası seviye 1'de başlar
  (§3.2); `ERLIK_SPREAD_INTERVAL` Prolog sahnesinde **3** tura iner (sahne override, bkz.
  Edge Cases "Final sahnesi" ile aynı mekanizma). C-49 doğrulaması: 3 korunur — 2'de
  hiç arındırmayan oyuncu T10'da kaybeder ve öğretici bölge T2'de olgunlaşır (sert); 4'te
  ihmal kaybı T20'ye kayar (10–18 turluk sahne penceresinin dışında, zombi oyun geri döner).
- **Erlik'in Gölgesi ve Erlik kaybı (C-49, çapraz inceleme N2 / W-B):** Erlik'in haritadaki
  toplam gücü `erlik_power = Σ corruption_level` (§4.7). Bölümün
  `WinCondition.erlik_loss_threshold`'u (> 0 ise) bu değere ulaşınca sahne **kaybedilir**
  (`region-map-system.md` §3.6; **Prolog eşiği 9**, başlangıç 4). Her yayılım +1, her
  başarılı arındırma −(arındırılan seviye): ihmal Erlik'i büyütür, arındırma geri iter
  (Sütun 3: "biri ihmal edilirse diğeri güçlenir"). Bozulma yalnızca tur sonu 2. adımda
  arttığından Erlik kaybı yalnızca `end_turn` 5. adımında oluşur. HUD değeri `erlik_power /
  eşik` olarak ve eşiğe 1 kala uyarıyla gösterir (gereksinim; spec C-41 / C-45).
- **Prolog'da siyasi düşman yok (C-49):** siyasi katman nötr boy garnizonlarıdır (konsept
  "dağınık boylar"); düşman AI ve takviye (`resource-system.md` F6) Prolog'da bilinçli
  olarak boştadır; Perde 1'de çalışır (C-43, aşağıdaki not). Prolog'un kayıp yolu Erlik'tir.
- **Perde 1'de Cürcet AI (C-43, 2026-10-20 — [`perde1-dogu-curcet.md`](../levels/perde1-dogu-curcet.md) §4.2/§4.4):**
  Düşman AI bozulmayı yok sayar ve nötr bölgelere (odak `curuk_koru` dahil) girmez; Erlik ile siyasi
  katman ayrıdır (Kağan ile Erlik arasında iş birliği yok). Perde 1 odağı `erlik_foci = [curuk_koru]`
  (başkent odak değil, başlangıç `erlik_power` 4, `ERLIK_SPREAD_INTERVAL` 3 — arındırma aralığı
  sıfırlamaz, `erlik_loss_threshold` 9); `curuk_koru` arındırması P ≥ 13 ister (+30 Ruh, erlik −3).
  Körmös ayrı birim değil, bozulma direncidir.
- **Zafer kapsamı (D4) — ✅ C-32:** zafer = siyasi koşul + nötr genişleme + bölümün
  `erlik_foci` listesindeki odakların arındırılması (`region-map-system.md` §3.6);
  odak dışı bozulma zaferi engellemez. Prolog: 3 nötr (odak hariç) + Canavarın İni.
- **Arındırmanın yeri ve fetihte bozulma (B3/B5):** ✅ C-30 — §3.2 (varışın 2. dalı;
  fetih bozulmayı korur). Lütuf zamanlaması: ✅ C-31 — §3.4.

> **C-49 çözümü (2026-10-19):** Canavar nötr olduğundan Prolog'da `ENEMY` bölgesi kalmaz;
> bu bilinçli olarak korunur (yukarıda). `game_lost` artık Erlik eşiğiyle tetiklenebilir;
> Prolog denge hesabı C-29 sonrası modelle yeniden yapıldı (`resource-system.md` §4).
> Çapraz inceleme N4 (yayılım yönlendirme / olgunlaştırma) ve N9 (fetih Erlik'i büyütmüyor)
> Prolog için kural değişikliği olmadan kapatıldı, kampanya ölçeğindeki karar C-44'e
> devredildi (§5 "Ruh çiftçiliği", "Yayılımı yönlendirme").

### 3.8 MVP Alt Kümesi (C-31)
- **M1 — Prolog Demo** (C-38, C-39): `corruption_level`, arındırma (§3.2), Ruh kazanımı
  + HUD göstergesi, Kök Böri sunum akışı (tur başı / sahne sonu / erteleme) ve
  **M1 uygun havuzu = Arınma Ustalığı, Bereket, Gök Kalkanı** (gerektirdiği sistem
  M1'de olmayan lütuflar havuza girmez). Etkiler ADR-0006 hattıyla uygulanır. C-49 ile M1'e
  eklenenler: Erlik'in Gölgesi (`erlik_power`, §4.7) + Erlik kaybı (§3.7, kod C-63) + HUD
  göstergesi, Doğu Obası öğretici bozulması (veri C-36). Erlik'le ilgilenen oyuncu ilk
  lütfu sahne ortasında (~T7) alabilir; üç M1 lütfunun etkisi sahne içinde görünür
  (Bereket gelirde, Gök Kalkanı yayılım sayacında / Erlik'in Gölgesi hızında, Arınma
  Ustalığı canavarın Ruh'unda 30 → 36).
- **M2 — Vertical Slice** (C-44, C-47): savaş etkin gücü (`combat-system.md` §4 "Etkin güç") ile
  Kurt Gücü + Demir Post, sahneler arası taşıma (AC6), lütuf dengesi (C-44 kapsamında
  `/balance-check` — C-53 ile C-44 bitti kriterine eklendi).
- **Kilitli:** Sürü Kutsaması (sürü etkinleşince), Yiğit Ruhu (kahraman birimleri
  GDD'siyle).

---

## 4. Formulas

Değişkenler ve varsayılan (tuning) değerleri:

| Değişken | Anlam | Varsayılan | Aralık |
| ---- | ---- | ---- | ---- |
| `RUH_PER_LEVEL` | Seviye başına Ruh kazanımı | 10 | 5–20 |
| `CORR_STR_PER_LEVEL` | Seviye başına arınma direnci | 4 | 2–8 |
| `CORRUPTION_PRODUCTION_MULTIPLIERS` | Seviye başına üretim çarpanı (seviye 0–3) | [1.0, 0.75, 0.5, 0.0] | azalan; son eleman 0–0.25 |
| `BASE_BOON_COST` | İlk lütuf maliyeti | 30 | 10–60 |
| `BOON_COST_STEP` | Lütuf başına maliyet artışı | 20 | 5–40 |
| `ERLIK_SPREAD_INTERVAL` | Yayılma periyodu (tur; sahne override'ı — Prolog 3) | 4 | 2–8 |
| `GOK_KALKANI_INTERVAL_BONUS` | Gök Kalkanı yığını başına aralık artışı (tur) | 1 | 1–2 |
| `GOK_KALKANI_MAX_STACKS` | Gök Kalkanı yığılma sınırı | 3 | 1–5 |
| `erlik_loss_threshold` | Erlik kaybı eşiği (§4.7); bölüm verisi `WinCondition`, sahibi `region-map-system.md` §3.6 | 0 (kapalı); Prolog 9 | 0 veya başlangıç `erlik_power` + 3 … 3 × bölge sayısı |

### 4.1 Arınma direnci
```
corruption_strength = corruption_level × CORR_STR_PER_LEVEL
```
Örnek: seviye 2 bölge → `2 × 4 = 8` direnç.
Arındırma eşiği `P ≥ corruption_strength + 1`: seviye 1/2/3 → en az 5/9/13 kuvvet;
başarı kaybı `ceil(S × 0.5)` = 2/4/6 (`army-system.md` §4 tablosu).

**Kurt Gücü ve arındırma:** arındırma gücü etkin güçtür —
`P_eff = ceil(resolve(&"army_attack", P))` (`combat-system.md` §4 "Etkin güç"); başarı
`P_eff > corruption_strength`, başarıda kalan `P − ceil(S × 0.5)` (kayıp gerçek
birlikten düşer). M1'de Kurt Gücü olmadığından `P_eff = P`.

### 4.2 Ruh kazanımı
```
ruh_gain = round( corruption_level × RUH_PER_LEVEL × (1 + arinma_ustaligi_bonusu) )
```
`arinma_ustaligi_bonusu` = alınan "Arınma Ustalığı" lütufu sayısı × 0.20.
Örnek: seviye 2, 1 Arınma Ustalığı lütfu → `round(2 × 10 × 1.20) = 24` Ruh.
(ADR-0006 karşılığı: `ruh_gain = round(resolve(&"ruh_gain", L × RUH_PER_LEVEL))`.)

**Ölçekleme yönü (W11, C-31):** Ruh kazanımı bozulma seviyesiyle **artar** — zor
arındırma (seviye başına +4 direnç, daha çok ordu ve kayıp) büyük ödül verir.
Konseptteki "Erlik güçlendikçe ruh kazanımı zorlaşır" ifadesi bu anlamda düzeltildi:
Erlik güçlendikçe *arındırma* zorlaşır (direnç), ödülü büyür; bozuk bölge **sayısıyla**
ölçeklenen ek bir ceza yoktur (risk/ödül tek eksende kalır — Epik Ama Erişilebilir).

### 4.3 Üretim cezası
Bu sistem yalnızca **bozulma çarpanını** sağlar; gelir formülünün sahibi
`resource-system.md`'dir (F1: `floor(G_base × M_c)`).
```
M_c = CORRUPTION_PRODUCTION_MULTIPLIERS[corruption_level]   # [1.0, 0.75, 0.5, 0.0]
```
Örnek: base 3 altın, seviye 2 → `M_c = 0.5` → F1: `floor(3 × 0.5) = 1` altın.
Seviye 3'te `M_c = 0` → bölge gelirine bakılmaksızın üretim durur.

### 4.4 Lütuf maliyeti (n = daha önce alınan lütuf sayısı)
```
boon_cost(n) = BASE_BOON_COST + n × BOON_COST_STEP
```
Örnek: 0→30, 1→50, 2→70, 3→90.
Birikimli maliyet: `k` lütuf için `30k + 10k(k−1)` → 1: 30, 3: 150, 5: 350, 7: 630, 8: 800.

**Eğri hedefi (D5, C-31):** doğrusal eğri korunur. Hedef sahne başına ~1 lütuf
(Prolog'da tipik 1 — C-49: hızlı oyuncuda zaferde canavarın 30 Ruh'uyla, Erlik'le ilgilenen
oyuncuda sahne ortasında ~T7; teorik tavan 2 lütuf = 80 Ruh, ancak ≥ 13 turluk titiz oyunla),
finalde **6–8 lütuf** — 6 sahnede toplam
~600–800 Ruh arzı. Çapraz incelemedeki "18 lütuf = 3 600 Ruh" hedefi geçersizdir;
katalogda 5 uygun lütuf olduğundan 6–8 yığın, "finalde tümü aktif" vaadini karşılar.
Arz tahmini Perde 1 verisiyle M2'de doğrulanır (C-44 `/balance-check`).

**Perde 1 Ruh arzı (C-43, 2026-10-20 — [`perde1-dogu-curcet.md`](../levels/perde1-dogu-curcet.md) §6):**
`curuk_koru` L3 arındırması **+30** (zorunlu; ilk lütuf garanti), `kurt_ini_ormani` L1 arındırması **+10**
(isteğe bağlı), yayılımla oluşan L1 arındırma **+10** (duruma bağlı); Perde 1 toplamı **~40–60** (ilgili
oyuncu). Perde 1'in Ruh çıktısı ve zorunlu lütuf seçimi C-44 kararına bağlıdır.

### 4.5 Deterministik 3'lü sunum
```
pool     = uygun havuz (§3.5), boon_id'ye göre sıralı
seed     = (scene_id × 31 + boon_index × 7) mod pool_size   # scene_id = MapState.chapter_id (Prolog 1)
offer[k] = pool[ (seed + k) mod pool_size ]  , k ∈ {0,1,2}
```
`boon_index` = `n` = o ana kadar **seçilen** lütuf sayısı (C-31: ertelenen sunum
aynı kalsın diye "yapılan sunum" değil "seçilen lütuf" sayılır). `pool_size ≥ 3`
iken üç slot farklıdır; `pool_size < 3` ise slotlar tekrar eder (§5).
Bu, rastgelelik olmadan tekrarlanabilir sunum üretir (test determinizmi). İleride
oyuncu-görünmez bir seed `GameState`'e eklenerek çeşitlilik artırılabilir.
Örnek (M1 havuzu `[arinma_ustaligi, bereket, gok_kalkani]`, Prolog `chapter_id = 1`,
`n = 0`): seed = 31 mod 3 = 1 → sunum: Bereket, Gök Kalkanı, Arınma Ustalığı.

### 4.6 Erlik yayılımı
Her yayılım turunda (aşağıdaki `I_eff`), tek bir bölge 1 seviye bozulur:
```
adaylar = { r : r.corruption_level < 3  ∧  ∃ n ∈ adj(r) : n.corruption_level ≥ 1 }
hedef   = argmin(army_count) over adaylar; eşitlikte region_id alfabetik ilk
hedef.corruption_level += 1
```
Adaylar sahipten bağımsızdır (oyuncu, nötr, düşman) ve zaten bozuk bölgeleri de
içerebilir (bozuk bir komşusu olan seviye 1–2 bölge derinleşir). Seviye 3 bölgeler
aday değildir. Örnek: yalnızca Canavarın İni (3) bozuksa adaylar inin komşularıdır;
en az ordulu komşu 1. seviyeye iner.
Efektif aralık (C-31 — eski bölme formülü 5 yığında sıfıra bölüyordu, W10):
```
I_eff = ERLIK_SPREAD_INTERVAL(sahne) + min(k, GOK_KALKANI_MAX_STACKS) × GOK_KALKANI_INTERVAL_BONUS
yayılım ⇔ current_turn − last_erlik_spread_turn ≥ I_eff
yayılım turunda (hedef bulunsun bulunmasın): last_erlik_spread_turn = current_turn
```
`k` = Gök Kalkanı yığını. Örnek: Prolog aralığı 3; 1 kalkan → 4, 3 kalkan → 6.
Uygulamada `k` zaten `max_stacks` ile yazım anında sınırlıdır (ADR-0006); `min` güvenlik
ifadesidir, tüketici `stacks`'i doğrudan okumaz — `I_eff = resolve(&"erlik_spread_interval",
taban)`.
Yığılma sınırına (3) ulaşınca Gök Kalkanı uygun havuzdan çıkar.

### 4.7 Erlik'in Gölgesi ve Erlik kaybı (C-49)
```
erlik_power = Σ_{r ∈ regions} r.corruption_level              # 0 … 3 × bölge sayısı (Prolog 0–18)
erlik_lost  = erlik_loss_threshold > 0  ∧  erlik_power ≥ erlik_loss_threshold
```
| Değişken | Tip | Aralık | Kaynak |
| ---- | ---- | ---- | ---- |
| `corruption_level` | int | 0–3 | Bölge durumu (§3.1) |
| `erlik_power` | int | 0–18 (Prolog) | Türetilir, saklanmaz (kayıttaki `corruption_level`'lardan yeniden hesaplanır) |
| `erlik_loss_threshold` | int | 0 (kapalı) veya ≥ başlangıç + 3 | `WinCondition` (bölüm verisi) — Prolog 9 |

Değişim kuralı: her yayılım (aday bulunduysa) **+1**; her başarılı arındırma
**−L** (arındırma öncesi seviye); fetih ve üretim değiştirmez. Değerlendirme yalnızca
`end_turn` 5. adımında (`region-map-system.md` §3.4/§3.6).

**Örnek (Prolog):** başlangıç 3 (in) + 1 (Doğu Obası) = 4. Hiç arındırmayan oyuncu
T3 / T6 / T9 / T12 / T15 yayılımlarıyla 5 / 6 / 7 / 8 / 9 → **15. turun sonunda kayıp**.
Arındırmasız kayıp, son yayılımdan itibaren `(eşik − erlik_power) × I_eff` tur sonradır
(her yayılımda aday varsa); seviye `L` bir bölgeyi arındırmak
kaybı `L × I_eff` tur erteler (Doğu Obası L1 → +3 tur; Gök Kalkanı 1 yığınla `I_eff = 4` →
aynı yol T20). Uyarı eşiği: `erlik_power = eşik − 1` (Prolog 8 — ihmal eden oyuncuda T12).

---

## 5. Edge Cases

- **Ruh eşiği aşırı birikimi**: Oyuncu bir sunumu ertelerse ve Ruh birikirse, tek
  seferde birden çok sunum tetiklenmez — tur başında en fazla 1 sunum; seçimden sonra
  bir sonraki eşik kontrol edilir ve sunum bir sonraki tur başında gelir. Yalnızca
  sahne sonunda bekleyen sunumlar arka arkaya gösterilir.
- **Yeterli Ruh yokken sunum**: Sunum yalnızca `toplam_ruh ≥ boon_cost(n)` iken
  yapılır. Seçim anında maliyet düşülür; kalan Ruh birikmeye devam eder.
- **Havuz tükenmesi**: Uygun havuzda 3'ten az lütuf varsa sunum mevcut olanları
  tekrar eder (aynı lütuf iki slotta görünebilir) — 3 slot her zaman dolu. Uygun
  havuz **boşsa** sunum yapılmaz, Ruh birikir; bir sistem etkinleşip havuz dolunca
  sunum koşulu yeniden sağlanır.
- **Lütuf tur ortasında seçilirse** (HUD düğmesi): etki hemen başlar; ör. Kurt Gücü
  seçildikten sonraki hamle +1 etkin güçle çözülür, Bereket o turun sonundaki gelire
  eklenir.
- **Sunum bekliyorken sahne kaybedilirse**: sunum gösterilmez; Ruh korunur.
- **Arındırma sahneyi kazandırırsa** (ör. Prolog'un son hamlesi Canavarın İni): sunum
  tur başını beklemez, sahne sonu sunumu olarak outro'dan önce gösterilir — Kök
  Böri'nin **ilk lütuf sunumu** bu ana denk gelebilir (Kök Böri'nin "genesis" görünüşü
  ise sahne açılışındadır — `scene-flow.md`, C-35).
- **Gök Kalkanı yığılma sınırı**: 3 yığından sonra sunulmaz; sınır knob'u düşürülürse
  fazla seçimler `boons`'ta kalır (maliyet sayımı `n` değişmez) ama bir sonraki
  yüklemede `rebuild()` en fazla sınır kadar yığın kurar.
- **Arındırma başarısız olursa** (`P ≤ S`): gelen kuvvet tamamen kaybolur; bölge
  bozuk kalır; Ruh verilmez; kısmi ilerleme kaydedilmez; aksiyon harcanmış olur.
- **Eşitlik** (`P == S`): başarısızlıktır — kural `başarı ⇔ P_eff > S`'dir ve
  `draw_favors_defender`'dan bağımsızdır (§3.2, savaş §5).
- **Bozulmuş + yabancı garnizonlu bölge**: önce savaş (fetih), bozulma kalır;
  arındırma ayrı, sonraki bir hamledir (§3.2).
- **Ruh çiftçiliği riski**: Arındırılmış bölge yayılımla yeniden bozulabilir; tekrar
  arındırılınca yine Ruh verir — Erlik'i geri püskürtmek bilinçli olarak
  ödüllendirilir. Risk: oyuncu kaynak bölgeyi (seviye 3) bilerek bırakıp komşusunu
  her yayılımda tekrar arındırabilir (≈ her interval'de 10 Ruh; bedeli 2 ordu +
  1 aksiyon). Artan lütuf maliyeti (§4.4) ve sahne zaman baskısı bunu sınırlar.
  **C-49 değerlendirmesi:** Prolog'da zaferi geciktirip her yayılımı arındıran oyuncu
  ≈ 10 Ruh / 3 tur kazanır ve Erlik'in Gölgesi düşük kaldığı için kaybetmez → sınırsız
  bekleme ile ek lütuf mümkündür. **M1'de sonuçsuzdur** (demoda lütufların taşınacağı
  sonraki sahne yok; 2. lütuf için ~12 ek tur). Lütuflar Perde 1'e taşındığı anda (M2)
  sınırlanmalıdır → **C-44** karar verir (seçenekler: "tekrar arındırma çarpanı" knob'u +
  sahne içi bölge başına arındırma sayacı, sahne Ruh tavanı, sahne tur sınırı).
- **Yayılımı yönlendirme (N4, C-49):** en az ordulu aday kuralı yüzünden oyuncu değersiz,
  garnizonu 1 bir bölgeyi "paratoner" yapabilir. Erlik'in Gölgesi her yayılımda yine +1
  olduğundan bu ihmalin bedelini kaldırmaz; hangi bölgenin acı çekeceğini seçmek
  deterministik ve göstergede görünür olduğu için **sağlıklı ustalık** sayılır. Prolog'da
  Doğu Obası (garnizon 0) bu rolü kendiliğinden üstlenir: o boşken Otağ aday olsa da
  hedeflenmez. Hedef kuralının değişmesi (değerli bölgeyi seçmek, yinelenen tohum) C-44.
- **Fetih Erlik'i büyütmüyor (N9, C-49):** Prolog'da yayılım yalnızca saate bağlıdır; tek
  dolaylı bağ, fethedilen bölgelerin garnizon 1'le kalıp bozulmaya komşuysa yayılım hedefi
  olmasıdır. Konseptin "imparatorluk büyüdükçe Erlik'in gölgesi uzar" mekaniği (aralığın
  ya da yayılım sayısının toprakla ölçeklenmesi) kampanya ölçeğinde C-44'te tasarlanır —
  öğreticiye 7. bağlı kural eklenmez (dikkat bütçesi, N7).
- **Öğretici bölge arındırılmazsa** (C-49): Doğu Obası T3'te L2, T6'da L3 olur; L3'te aday
  değildir, yayılım komşulara (Otağ, Bereket) geçer. Her olgunlaşma Erlik'in Gölgesi'ni
  +1 artırır.
- **Erlik'in Gölgesi eşiği aşılırken başka koşullar:** zafer yalnızca hamleyle (tur
  ortası), Erlik kaybı yalnızca tur sonunda oluşur → aynı anda gerçekleşemez. Tüm bozulma
  arındırılırsa `erlik_power = 0` ve yayılım adayı kalmaz → Erlik kaybı imkânsızlaşır.
  Kaybedilen sahnede bekleyen lütuf sunumu gösterilmez, Ruh korunur (§3.4).
- **Bozuk bölgeyi düşman alırsa**: bozulma kalır; düşman takviyesi etkilenmez
  (düşmanın hazinesi yok, `resource-system.md` F6).
- **Seviye 0 bölgeyi arındırma denemesi**: Geçersiz aksiyon — arındırma yalnızca
  `corruption_level ≥ 1` için sunulur.
- **Yayılım adayı yoksa** (bozuk bölge yok ya da tüm bozuk bölgelerin komşuları
  seviye 3): yayılım o tur atlanır (hata değil); `last_erlik_spread_turn` yine
  güncellenir, sayaç yeniden başlar.
- **Final sahnesi**: Erlik yayılımı hızlanabilir (senaryo override) — bu sistem
  interval'i sahne başına ayarlanabilir olmalı.
- **Sahne geçişi**: Lütuflar taşınır; sahneye özel bozulma durumu sıfırlanır
  (yeni harita = yeni bozulma). Yeni sahnenin 1. turunda sunum kendiliğinden açılmaz
  (şafak kuralı `end_turn` sonrasını kapsar); taşınan Ruh eşiği karşılıyorsa HUD düğmesi
  hemen açar, otomatik modal 2. tur başında gelir (`scene-flow.md` §3.2).

---

## 6. Dependencies

- **Bölge Fethi / Harita** (`region-map-system.md`, kod: `region_data.gd`,
  `map_state.gd`) — `RegionData`'ya `corruption_level` alanı eklenmeli. Erlik kaybı (C-49):
  bu sistem `erlik_power`'ı (§4.7) tanımlar; eşik (`WinCondition.erlik_loss_threshold`) ve
  kontrol noktası (`end_turn` 5. adım) region-map §3.6'ya aittir.
- **Ordu Sistemi** (`army-system.md` §3.3) — arındırma, varış çözümünün 2. dalıdır;
  dal seçimi ve kuvvetin yerleşmesi orada, arındırma kuralları ve Ruh burada.
- **Savaş Çözümü** (`combat-system.md`, kod: `combat_resolver.gd`) — arındırma
  çözümü `CombatResolver.resolve(P_eff, corruption_strength)`'ı yeniden kullanır;
  başarısızlıkta kalan kuvvet bu sistemin kuralıyla 0'dır. Kurt Gücü / Demir Post
  lütufları savaşın "Etkin güç" bölümünü besler (combat §4, M2).
- **Kaynak Yönetimi** (`resource-system.md`) — gelir formülü (F1, F2) bu sistemin
  bozulma çarpanını (`M_c`, §4.3) ve ekonomi lütfunu (Bereket → `B_add`) uygular;
  `M_c` aynı zamanda üretim tavanını da küçültür (F3 `G_eff` üzerinden) — çarpan
  tablosu değişirse Prolog üretim tavanları da değişir. Sürü Kutsaması kilitli (sürü
  formülü yok). Ruh bu sisteme aittir; Kaynak Yönetimi Ruh'u
  okumaz ve yazmaz.
- **Oyun Durumu** (`game_state.gd`) — kalıcı `boons` listesi + `ruh` alanı;
  `MapState.last_erlik_spread_turn` (§3.6).
- **Kayıt / Yükleme** (ADR-0007) — `ruh` + `boons` kaydedilir; bekleyen sunum ve lütuf
  modifikatörleri türetilir (§3.4).
- **Sahne Akışı** (`scene-flow.md`, C-35) — sahne zaferinde zorunlu lütuf dizisini sahneler
  (`k = min(maliyetle sığan, havuz, VICTORY_PICK_CAP)`, F2), sunum durumunu ve `pick_boon`'u
  kullanır; yenilgide sunum göstermez ve sahne girişi `ruh`/`boons` durumuna döner; Kök Böri'nin
  sahne açılışındaki "genesis" görünüşü ve hedef işareti orada tanımlıdır (lütuf sunumundan ayrıdır).
  `ruh`/`boons` sahneler arası taşınır, kayıt noktaları orada (S1–S3).
- **Konsey (Altı Oğul)** (`council-system.md`) — konsey bonusları lütuflarla
  aynı toplamsal modifikatör hattını paylaşmalı (çift sayım önlenmeli).
- **Katmanlı Düşman** (`enemy-layers.md`) — yalnızca *siyasi* krallar; Erlik
  yayılımı/bozulması bu GDD'nin sorumluluğundadır (§3.7), `enemy-layers.md`'ye taşınmaz.

> Karşılıklı bağımlılık notu: ✅ yazılmış GDD'lerin (harita, ordu, savaş, kaynak) geri
> referansları tamam (C-28…C-33); konsey ve katmanlı düşman yazıldığında eklenecek.

---

## 7. Tuning Knobs

| Knob | Etkilediği | Güvenli Aralık | Not |
| ---- | ---- | ---- | ---- |
| `RUH_PER_LEVEL` | Güç eğrisi hızı | 5–20 | Yüksek = hızlı güçlenme |
| `CORR_STR_PER_LEVEL` | Arındırma zorluğu | 2–8 | Yüksek = daha çok ordu gerekir |
| `CORRUPTION_PRODUCTION_MULTIPLIERS` | Bozulmanın ekonomik baskısı | azalan dizi; son eleman 0–0.25 | Son eleman >0 → seviye 3 bölgeler üretmeye devam eder; ara değerler çok düşükse küçük obalar seviye 1–2'de 0'a iner |
| `BASE_BOON_COST` / `BOON_COST_STEP` | Lütuf sıklığı | 10–60 / 5–40 | Düşük = sık lütuf |
| `ERLIK_SPREAD_INTERVAL` | Zaman baskısı | 2–8 tur | Düşük = agresif Erlik. Prolog 3 (C-49 doğrulandı: 2 → ihmal kaybı T10, 4 → T20) |
| `erlik_loss_threshold` (sahibi region-map §7) | Erlik ihmalinin kayıp sınırı | 0 (kapalı) veya başlangıç `erlik_power` + 3 ve üstü; Prolog 9 | Düşük = sert (Prolog 8 → ihmal kaybı T12, 12 boş turluk pasif oyuncu kaybeder); yüksek = baskı hissedilmez (10 → T18, 18 turluk pencerenin sınırı) |
| Başlangıç bozulması (bölüm verisi, `RegionDefinition`) | Öğretici / ilk baskı | Prolog: in 3, Doğu Obası 1 | Öğretici bölge L2 olursa T3'te L3'e olgunlaşır (öğretici olmaktan çıkar); kaldırılırsa sahne ortası lütuf ~T9+'a kayar |
| Lütuf etki değerleri | Build gücü | Kurt Gücü / Demir Post +1–2 güç; Bereket +1–2 altın; Arınma Ustalığı %10–%30; Gök Kalkanı +1–2 tur | Denge kritik — çok yüksek zorluğu bozar; küçük tam sayılarda yüzde yerine düz değer (§3.5) |
| `GOK_KALKANI_MAX_STACKS` | Erlik baskısının alt sınırı | 1–5 (varsayılan 3) | Yüksek = Erlik etkisizleşebilir |
| `GOK_KALKANI_INTERVAL_BONUS` | Yığın başına aralık artışı | 1–2 tur (varsayılan 1) | — |
| Havuz kompozisyonu | Build çeşitliliği | — | Sahne bazlı havuz override mümkün |

---

## 8. Acceptance Criteria

1. Seviye 2 bozulmuş bir bölge, hiç lütuf yokken arındırıldığında oyuncu **tam
   20 Ruh** kazanır (`2 × 10`). *(Otomatik test — BLOCKING)*
2. 1 "Arınma Ustalığı" lütfu varken aynı arındırma **24 Ruh** verir. *(Test)*
3. Toplam Ruh bir arındırmayla ilk kez ≥ `BASE_BOON_COST` (30) olduğunda sunum
   hamleden hemen sonra **açılmaz**; bir sonraki oyuncu turunun başında tam olarak
   **1 sunum** açılır ve **3 lütuf** gösterilir. *(Test)*
4. Aynı `scene_id` ve `boon_index` (= seçilen lütuf sayısı) ile sunum **her
   çalıştırmada aynı 3 lütfu** üretir (determinizm); M1 havuzu, `chapter_id 1`, `n 0` →
   Bereket, Gök Kalkanı, Arınma Ustalığı. *(Test)*
5. Lütuf seçildiğinde maliyet Ruh'tan düşer; seçilmeyenler kaybolur. *(Test)*
6. Alınan lütuflar sahne geçişinde korunur (`GameState.boons` boşalmaz). *(Test)*
7. Seviye 3 bozulmuş bölgenin `gold_per_turn` üretimi **0**'a düşer. *(Test)*
8. Erlik, `ERLIK_SPREAD_INTERVAL` turda bir, kurala göre (en düşük ordulu komşu)
   **deterministik** yayılır; yayılım `end_turn`'ün 2. adımında (AI'dan sonra, gelirden
   önce) çalışır ve o turun geliri yayılan bozulmayı yansıtır. *(Test)*
8b. Prolog verisinde Canavarın İni `NEUTRAL` + `corruption_level 3` + ordu 0, Doğu Obası
   `NEUTRAL` + `corruption_level 1` + ordu 0 yüklenir; Prolog'da `ENEMY` bölgesi yoktur
   (`ENEMY` yalnızca siyasi krallar içindir). *(Test — veri C-36; `region-map-system.md` AC14)*
9. Gök Kalkanı: Prolog aralığı 3 iken 1 yığın → `I_eff = 4`, 3 yığın → 6; 3 yığından
   sonra uygun havuzda yer almaz; hiçbir yığın sayısında bölme/sıfıra bölme yoktur.
   Aralık sahne ortasında uzarsa bir sonraki yayılım `last_erlik_spread_turn`'den
   itibaren sayılır. *(Test)*
10. Bozulmuş bölge görsel olarak temiz bölgeden ayırt edilebilir; seviye 1–3 art
    bible §4 "Bozulma Seviyeleri" kuralıyla (dither yoğunluğu %25/50/75 — C-50) ayırt edilir,
    sahiplik rengi gizlenmez. *(Görsel — screenshot + lead onayı, ADVISORY)*
11. Seviye 2, garnizonsuz bozuk bölgeye P=9 → arındırma başarılı: `corruption_level 0`,
    bölge oyuncunun, army 5, Ruh +20; P=8 → kuvvet kaybolur, bölge ve bozulma aynı
    kalır, Ruh +0. *(Test — BLOCKING)*
12. Bozuk bir bölgeyi savaşla fethetmek `corruption_level`'ı değiştirmez ve Ruh
    vermez. *(Test)*
13. Başarısız arındırma da `actions_remaining`'i 1 azaltır. *(Test)*
14. Bilgi paneli bozuk bölgede seviyeyi ve `corruption_strength`'i gösterir; temiz
    bölgede bu satır yoktur. *(UI — walkthrough/ekran görüntüsü, ADVISORY)*
15. Ertelenen sunum aynı 3 lütufla bir sonraki tur başında yeniden açılır; oyuncu
    kendi turunda HUD düğmesinden açıp seçebilir; seçimden sonra Ruh bir sonraki eşiği
    de karşılıyorsa HUD düğmesi aynı tur ikinci sunumu açar, otomatik modal ise ancak
    bir sonraki tur başında açılır. *(Test + UI walkthrough)*
16. Sahne zaferle biterken sunum bekliyorsa outro'dan önce gösterilir ve ertelenemez;
    seçimden sonra Ruh hâlâ eşiği karşılıyorsa ikinci sunum hemen gelir. *(Test)*
17. Bereket seçildikten sonraki ekonomi adımında tur geliri tam **+1** artar
    (`I_raw = 5` → 6; `resource-system.md` AC23). *(Test)*
18. M1'de gerektirdiği sistem olmayan lütuflar (Kurt Gücü, Demir Post, Sürü
    Kutsaması, Yiğit Ruhu) hiçbir sunumda yer almaz. *(Test)*
19. Sunum durumu kayıttan türetilir: `ruh` ve `boons` yüklendikten sonra bekleyen
    sunum aynı 3 lütufla yeniden oluşur ve lütuf modifikatörleri `boons`'tan yeniden
    kurulur (ADR-0006/0007). *(Test)*
20. Canavarın İni'ni arındıran son hamle sahneyi kazandırdığında `game_won`
    yayıldığı anda Ruh +30 işlenmiştir ve sahne sonu sunumu bekler durumdadır. *(Test)*
21. Hedef üzerine gelince hamle önizlemesi dalı, kaybı, kalanı ve (arındırmada)
    başarı/Ruh'u gösterir; başarısız olacak arındırma ikinci onay ister. Yayılım
    göstergesi kalan tur ve olası hedefi gösterir. *(UI — walkthrough, ADVISORY; C-41/C-45)*
22. `erlik_power` tüm bölgelerin `corruption_level` toplamıdır: Prolog başlangıcında **4**;
    yayılım +1, seviye 2 bölgenin arındırılması −2. **GIVEN** `erlik_loss_threshold = 9` ve
    `erlik_power = 8`, **WHEN** `end_turn`'ün yayılımı bir bölgeyi bozar, **THEN** aynı
    `end_turn`'ün 5. adımında `game_result = LOST`, `game_lost` bir kez yayılır,
    `turn_ended` yayılmaz. Eşik 0 iken aynı durum oyunu sürdürür; oyuncu hamlesi hiçbir
    zaman Erlik kaybı üretmez. *(Test — BLOCKING, kod C-63)*
23. Prolog T1: Otağ'dan (5) Doğu Obası'na 4'lük hamle → arındırma başarısız (4 ≤ 4), 4 birlik
    kaybolur, Doğu L1 kalır; Otağ'da 2 üretip 6'yla → başarılı, Doğu oyuncunun (ordu 4),
    Ruh +10, `erlik_power` 4 → 3. *(Test — C-38 + C-36 verisi)*
24. HUD Erlik'in Gölgesi'ni `erlik_power / eşik` olarak gösterir; `erlik_power = eşik − 1`
    iken uyarı durumu ve yayılım göstergesiyle birlikte "bir sonraki yayılımda kayıp" bilgisi
    görünür. *(UI — walkthrough, ADVISORY; C-41/C-45)*
