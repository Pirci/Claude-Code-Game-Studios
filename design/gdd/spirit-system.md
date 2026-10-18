# Sistem GDD: Kök Böri / Ruh Sistemi

*Oyun: ULUS: Blood of the Sky Wolf*
*Oluşturulma: 2026-07-14*
*Durum: Taslak (kod henüz yok — tasarım spesifikasyonu)*
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
    sayıyla gösterilir (§3.2, C-30); haritadaki seviye görseli (dither yoğunluğu /
    leke boyutu) art bible'da henüz tanımsız → **C-50** (C-38'den önce).
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
- **Çözüm:** `CombatResolver.resolve(P, corruption_strength)`; `P` = gelen kuvvet
  (`kaynak.army_count − 1`). Hedefte zaten duran oyuncu garnizonu katılmaz.
- **Başarı** (`P > corruption_strength`): `corruption_level = 0`, üretim geri döner,
  oyuncu `ruh_gain` (§4.2, arındırma *öncesi* seviyeyle) kadar Ruh kazanır. Hayatta
  kalanlar (`P − ceil(S × attacker_win_loss_ratio)`) bölgeye yerleşir: bölge
  oyuncunun değilse `owner = PLAYER` olur; oyuncununsa garnizona eklenir.
- **Başarısızlık** (`P ≤ corruption_strength`, eşitlik dahil): gelen kuvvetin
  **tamamı kaybolur** ("Erlik yuttu"); bölgenin sahibi, ordusu ve bozulması
  değişmez; Ruh kazanılmaz. (Savaş §7 "kaybeden taraf tamamen yok olur" kuralıyla aynı.)
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
- **Prolog canavarı:** Canavarın İni (seviye 3) `S = 12` → en az 13'lük kuvvet
  (kaynakta ≥ 14 ordu) gerekir; başarı 30 Ruh verir = ilk lütuf eşiği
  (`BASE_BOON_COST`). Önerilen garnizon 0 (canavar = bozulma direncinin kendisi);
  kesin veri ve kazanılabilirlik hesabı **C-49**'da; lütuf sunum zamanı §3.4.

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
     (Ruh bir sonraki eşiğin altına inene ya da havuz boşalana kadar) devam eder.
  Arındırma hamlesinin hemen ardından tur ortasında kendiliğinden açılmaz — hamle
  akışı kesilmez (dikkat bütçesi, çapraz inceleme D6).
- **Erteleme:** Oyuncu tur başı modalını "Ertele" ile kapatabilir. Sunum aynı 3
  lütufla bekler (§4.5 girdileri değişmez); oyuncu kendi turunda HUD'daki Kök Böri
  düğmesinden istediği an açıp seçebilir; seçilmezse her yeni tur başında yeniden
  gösterilir. Sahne sonundaki sunum ertelenemez. Kaybedilen sahnede sunum gösterilmez
  (Ruh korunur; kampanya kaybının akışı C-32 / C-35).
- **Seçim:** uygun havuzdan **3 lütuf** gösterilir, oyuncu **1** seçer; maliyeti
  Ruh'tan düşülür, seçilmeyen 2'si kaybolur. Seçimden sonra koşul hâlâ sağlanıyorsa
  bir sonraki sunum *bir sonraki* tur başında gelir (sahne sonundaysa hemen).
- **Etkinin başlangıcı:** seçildiği an. Lütuf `ModifierController.add_source()` ile
  `GameState.modifiers`'a işlenir (ADR-0006); o andan sonraki her hesap — aynı turun
  kalan hamleleri ve sonraki `end_turn` ekonomisi — etkiyi görür. Geriye dönük etki
  yoktur (ör. Bereket, seçildiği turun sonundaki gelire yansır).
- Lütuflar `GameState.boons` listesinde birikir, sahneler arası taşınır.
- Lütuf etkileri pasif ve toplamsaldır: aynı lütuf yeniden alınınca kaydın `stacks`
  değeri artar (ADR-0006 tekillik değişmezi). Yığılma sınırı olan lütuf sınıra
  ulaşınca uygun havuzdan çıkar.
- 3'lü sunum **deterministik** seçilir (bkz. Formüller — test edilebilirlik için).

### 3.5 Lütuf Kataloğu (Başlangıç Havuzu) — C-31 revizyonu
Etkiler ADR-0006 modifikatör hattından geçer (`stat_id`, `FLAT`/`PERCENT`, yığın
başına değer). **Uygun havuz** = katalog − gerektirdiği sistemi etkin olmayanlar −
yığılma sınırına ulaşmışlar, `boon_id`'ye göre sıralı.

| Lütuf (`boon_id`) | Etki (yığın başına) | Stat / tür | Gerektirir | Yığılma sınırı | İlk kademe |
| ---- | ---- | ---- | ---- | ---- | ---- |
| Arınma Ustalığı (`arinma_ustaligi`) | Arındırma başına Ruh +%20 | `ruh_gain` / PERCENT +0.20 | — | — | M1 |
| Bereket (`bereket`) | Tur geliri +1 altın | `gold_income` / FLAT +1 (→ resource `B_add`) | — | — | M1 |
| Demir Post (`demir_post`) | Savunan oyuncu bölgesine +1 etkin güç | `army_defense` / FLAT +1 | Savaş etkin gücü (`combat-system.md` §4 "Etkin güç") | — | M2 |
| Gök Kalkanı (`gok_kalkani`) | Erlik yayılım aralığı +1 tur | `erlik_spread_interval` / FLAT +1 | — | 3 | M1 |
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
- **Prolog baskısı (D3):** Canavarın İni seviye 3'te başlar (üretimi durur, arındırması
  öğretici hedeftir); `ERLIK_SPREAD_INTERVAL` Prolog sahnesinde **3** tura iner
  (sahne override, bkz. Edge Cases "Final sahnesi" ile aynı mekanizma). Kesin değerler
  `/balance-check` ile doğrulanacak (C-33 / C-49).
- **Zafer kapsamı (D4) — ✅ C-32:** zafer = siyasi koşul + nötr genişleme + bölümün
  `erlik_foci` listesindeki odakların arındırılması (`region-map-system.md` §3.6);
  odak dışı bozulma zaferi engellemez. Prolog: 3 nötr (odak hariç) + Canavarın İni.
- **Arındırmanın yeri ve fetihte bozulma (B3/B5):** ✅ C-30 — §3.2 (varışın 2. dalı;
  fetih bozulmayı korur). Lütuf zamanlaması: ✅ C-31 — §3.4.

> **Etki uyarısı:** Canavarın İni nötr olduğundan Prolog'da `ENEMY` bölgesi kalmaz →
> düşman AI ve düşman takviyesi (`resource-system.md` F6) Prolog'da boşta kalır,
> `game_lost` (oyuncunun bölgesi kalmaz) tetiklenemez ve Prolog'un denge hesabı
> (resource-system §4, canavar eşiği "A ≥ 7") yeniden doğrulanmalıdır. Takip: **C-49**.

### 3.8 MVP Alt Kümesi (C-31)
- **M1 — Prolog Demo** (C-38, C-39): `corruption_level`, arındırma (§3.2), Ruh kazanımı
  + HUD göstergesi, Kök Böri sunum akışı (tur başı / sahne sonu / erteleme) ve
  **M1 uygun havuzu = Arınma Ustalığı, Bereket, Gök Kalkanı** (gerektirdiği sistem
  M1'de olmayan lütuflar havuza girmez). Etkiler ADR-0006 hattıyla uygulanır.
- **M2 — Vertical Slice** (C-44, C-47): savaş etkin gücü (`combat-system.md` §4 "Etkin güç") ile
  Kurt Gücü + Demir Post, sahneler arası taşıma (AC6), lütuf dengesi `/balance-check`.
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
(Prolog'da tipik 1: canavar 30 Ruh), finalde **6–8 lütuf** — 6 sahnede toplam
~600–800 Ruh arzı. Çapraz incelemedeki "18 lütuf = 3 600 Ruh" hedefi geçersizdir;
katalogda 5 uygun lütuf olduğundan 6–8 yığın, "finalde tümü aktif" vaadini karşılar.
Arz tahmini Perde 1 verisiyle M2'de doğrulanır (C-44 `/balance-check`).

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
Yığılma sınırına (3) ulaşınca Gök Kalkanı uygun havuzdan çıkar.

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
  Böri'nin ilk görünüşü bu ana denk gelebilir (C-35).
- **Gök Kalkanı yığılma sınırı**: 3 yığından sonra sunulmaz; sınır knob'u düşürülürse
  mevcut fazla yığınlar korunur ama etkileri `min(k, sınır)` ile kırpılır.
- **Arındırma başarısız olursa** (`P ≤ S`): gelen kuvvet tamamen kaybolur; bölge
  bozuk kalır; Ruh verilmez; kısmi ilerleme kaydedilmez; aksiyon harcanmış olur.
- **Eşitlik** (`P == S`): başarısızlıktır (CombatResolver Dal 3, savunma avantajı
  direnç lehine).
- **Bozulmuş + yabancı garnizonlu bölge**: önce savaş (fetih), bozulma kalır;
  arındırma ayrı, sonraki bir hamledir (§3.2).
- **Ruh çiftçiliği riski**: Arındırılmış bölge yayılımla yeniden bozulabilir; tekrar
  arındırılınca yine Ruh verir — Erlik'i geri püskürtmek bilinçli olarak
  ödüllendirilir. Risk: oyuncu kaynak bölgeyi (seviye 3) bilerek bırakıp komşusunu
  her yayılımda tekrar arındırabilir (≈ her interval'de 10 Ruh; bedeli 2 ordu +
  1 aksiyon). Artan lütuf maliyeti (§4.4) ve sahne zaman baskısı bunu sınırlar;
  C-49 `/balance-check`'inde izlenir, gerekirse "tekrar arındırma çarpanı" knob'u eklenir.
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
  (yeni harita = yeni bozulma).

---

## 6. Dependencies

- **Bölge Fethi / Harita** (`region-map-system.md`, kod: `region_data.gd`,
  `map_state.gd`) — `RegionData`'ya `corruption_level` alanı eklenmeli.
- **Ordu Sistemi** (`army-system.md` §3.3) — arındırma, varış çözümünün 2. dalıdır;
  dal seçimi ve kuvvetin yerleşmesi orada, arındırma kuralları ve Ruh burada.
- **Savaş Çözümü** (`combat-system.md`, kod: `combat_resolver.gd`) — arındırma
  çözümü `CombatResolver.resolve(P, corruption_strength)`'ı yeniden kullanır;
  başarısızlıkta kalan kuvvet bu sistemin kuralıyla 0'dır.
- **Kaynak Yönetimi** (`resource-system.md`) — gelir formülü (F1, F2) bu sistemin
  bozulma çarpanını (`M_c`, §4.3) ve ekonomi lütuflarını (`B_add` / `M_g`:
  Bereket, Sürü Kutsaması) uygular. Ruh bu sisteme aittir; Kaynak Yönetimi Ruh'u
  okumaz ve yazmaz.
- **Oyun Durumu** (`game_state.gd`) — kalıcı `boons` listesi + `ruh` alanı.
- **Konsey (Altı Oğul)** (`council-system.md`) — konsey bonusları lütuflarla
  aynı toplamsal modifikatör hattını paylaşmalı (çift sayım önlenmeli).
- **Katmanlı Düşman** (`enemy-layers.md`) — yalnızca *siyasi* krallar; Erlik
  yayılımı/bozulması bu GDD'nin sorumluluğundadır (§3.7), `enemy-layers.md`'ye taşınmaz.

> Karşılıklı bağımlılık notu: yukarıdaki dokümanlar yazıldığında bu sisteme
> geri referans vermeli (Ruh alanı, corruption_level, CombatResolver kullanımı).

---

## 7. Tuning Knobs

| Knob | Etkilediği | Güvenli Aralık | Not |
| ---- | ---- | ---- | ---- |
| `RUH_PER_LEVEL` | Güç eğrisi hızı | 5–20 | Yüksek = hızlı güçlenme |
| `CORR_STR_PER_LEVEL` | Arındırma zorluğu | 2–8 | Yüksek = daha çok ordu gerekir |
| `CORRUPTION_PRODUCTION_MULTIPLIERS` | Bozulmanın ekonomik baskısı | azalan dizi; son eleman 0–0.25 | Son eleman >0 → seviye 3 bölgeler üretmeye devam eder; ara değerler çok düşükse küçük obalar seviye 1–2'de 0'a iner |
| `BASE_BOON_COST` / `BOON_COST_STEP` | Lütuf sıklığı | 10–60 / 5–40 | Düşük = sık lütuf |
| `ERLIK_SPREAD_INTERVAL` | Zaman baskısı | 2–8 tur | Düşük = agresif Erlik |
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
8b. Prolog verisinde Canavarın İni `NEUTRAL` + `corruption_level 3` yüklenir; `ENEMY`
   sahip yalnızca siyasi krallar içindir. *(Test — veri C-36/C-49 ile gelir)*
9. Gök Kalkanı: Prolog aralığı 3 iken 1 yığın → `I_eff = 4`, 3 yığın → 6; 3 yığından
   sonra uygun havuzda yer almaz; hiçbir yığın sayısında bölme/sıfıra bölme yoktur.
   Aralık sahne ortasında uzarsa bir sonraki yayılım `last_erlik_spread_turn`'den
   itibaren sayılır. *(Test)*
10. Bozulmuş bölge görsel olarak temiz bölgeden ayırt edilebilir (seviyeye göre
    renk). *(Görsel — screenshot + lead onayı, ADVISORY)*
11. Seviye 2, garnizonsuz bozuk bölgeye P=9 → arındırma başarılı: `corruption_level 0`,
    bölge oyuncunun, army 5, Ruh +20; P=8 → kuvvet kaybolur, bölge ve bozulma aynı
    kalır, Ruh +0. *(Test — BLOCKING)*
12. Bozuk bir bölgeyi savaşla fethetmek `corruption_level`'ı değiştirmez ve Ruh
    vermez. *(Test)*
13. Başarısız arındırma da `actions_remaining`'i 1 azaltır. *(Test)*
14. Bilgi paneli bozuk bölgede seviyeyi ve `corruption_strength`'i gösterir; temiz
    bölgede bu satır yoktur. *(UI — walkthrough/ekran görüntüsü, ADVISORY)*
15. Ertelenen sunum aynı 3 lütufla bir sonraki tur başında yeniden açılır; oyuncu
    kendi turunda HUD düğmesinden açıp seçebilir. *(Test + UI walkthrough)*
16. Sahne zaferle biterken sunum bekliyorsa outro'dan önce gösterilir ve ertelenemez;
    seçimden sonra Ruh hâlâ eşiği karşılıyorsa ikinci sunum hemen gelir. *(Test)*
17. Bereket seçildikten sonraki ekonomi adımında tur geliri tam **+1** artar
    (`I_raw = 5` → 6; `resource-system.md` AC23). *(Test)*
18. M1'de gerektirdiği sistem olmayan lütuflar (Kurt Gücü, Demir Post, Sürü
    Kutsaması, Yiğit Ruhu) hiçbir sunumda yer almaz. *(Test)*
19. Sunum durumu kayıttan türetilir: `ruh` ve `boons` yüklendikten sonra bekleyen
    sunum aynı 3 lütufla yeniden oluşur (ADR-0007). *(Test)*
