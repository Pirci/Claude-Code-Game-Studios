# Sistem GDD: Kök Böri / Ruh Sistemi

*Oyun: Steppeborn — Path of the Sky Wolf*
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
  - Görsel: zehir yeşili → mor → siyah (seviyeye göre)
  - Ceza: o bölgenin `gold_per_turn` ve `herd_per_turn` üretimi `corruption_level`
    başına %25 azalır (seviye 3 = üretim durur)
  - Bir "arınma direnci" (`corruption_strength`) taşır (bkz. Formüller)

### 3.2 Arındırma (Purification)
- Oyuncu, komşu/sahip olduğu bir bölgeden bozulmuş bölgeye **ordu göndererek**
  arındırma başlatır.
- Çözüm mevcut savaş sistemini yeniden kullanır: gönderilen ordu gücü vs.
  `corruption_strength`.
- **Başarı** (ordu > direnç): bölge `corruption_level = 0` olur, üretim geri
  döner, oyuncu `ruh_gain` kadar Ruh kazanır. Ordu kaybı savaş formülüne göre.
- **Başarısızlık**: ordu kaybeder, bölge bozuk kalır, Ruh kazanılmaz.
- Bir bölge tek arındırmada tamamen temizlenir (kısmi arındırma yok — MVP sadeliği).

### 3.3 Ruh Kaynağı
- Ruh, `GameState` içinde tutulan kalıcı bir kaynaktır (altın/sürüden ayrı).
- Sadece arındırmadan kazanılır (tek musluk). Harcama tek yer: lütuf.

### 3.4 Kök Böri Lütufları (Boons)
- Toplam Ruh, bir sonraki lütuf eşiğine (`boon_cost(n)`) ulaştığında Kök Böri
  bir **sunum** yapar: havuzdan **3 lütuf** gösterilir, oyuncu **1** seçer.
- Seçilen lütfun maliyeti Ruh'tan düşülür; seçilmeyen 2'si kaybolur.
- Lütuflar `GameState.boons` listesinde birikir, sahneler arası taşınır.
- Lütuf etkileri pasif ve toplamsaldır (aynı lütuf birden çok kez alınabilir,
  etkisi yığılır — aksi belirtilmedikçe).
- 3'lü sunum **deterministik** seçilir (bkz. Formüller — test edilebilirlik için).

### 3.5 Lütuf Kataloğu (Başlangıç Havuzu)
| Lütuf | Etki | Tip |
| ---- | ---- | ---- |
| Kurt Gücü | Ordu saldırı gücü +%5 | Askeri |
| Demir Post | Ordu savunma gücü +%5 | Askeri |
| Bereket | Altın geliri +%10 | Ekonomi |
| Sürü Kutsaması | Sürü geliri +%10 | Ekonomi |
| Arınma Ustalığı | Arındırma başına Ruh +%20 | Ruh |
| Gök Kalkanı | Erlik yayılma hızı -%20 | Savunma |
| Yiğit Ruhu | Kahraman birim gücü +%10 | Askeri |

### 3.6 Erlik Yayılımı (AI Katmanı)
- Her `ERLIK_SPREAD_INTERVAL` turda bir, Erlik yayılır (bkz. Formüller).
- Yayılım deterministiktir: kurallı hedef seçimi (rastgele değil).

---

## 4. Formulas

Değişkenler ve varsayılan (tuning) değerleri:

| Değişken | Anlam | Varsayılan | Aralık |
| ---- | ---- | ---- | ---- |
| `RUH_PER_LEVEL` | Seviye başına Ruh kazanımı | 10 | 5–20 |
| `CORR_STR_PER_LEVEL` | Seviye başına arınma direnci | 4 | 2–8 |
| `PROD_PENALTY_PER_LEVEL` | Seviye başına üretim cezası | 0.25 | 0.1–0.34 |
| `BASE_BOON_COST` | İlk lütuf maliyeti | 30 | 10–60 |
| `BOON_COST_STEP` | Lütuf başına maliyet artışı | 20 | 5–40 |
| `ERLIK_SPREAD_INTERVAL` | Yayılma periyodu (tur) | 4 | 2–8 |

### 4.1 Arınma direnci
```
corruption_strength = corruption_level × CORR_STR_PER_LEVEL
```
Örnek: seviye 2 bölge → `2 × 4 = 8` direnç.

### 4.2 Ruh kazanımı
```
ruh_gain = round( corruption_level × RUH_PER_LEVEL × (1 + arinma_ustaligi_bonusu) )
```
`arinma_ustaligi_bonusu` = alınan "Arınma Ustalığı" lütufu sayısı × 0.20.
Örnek: seviye 2, 1 Arınma Ustalığı lütfu → `round(2 × 10 × 1.20) = 24` Ruh.

### 4.3 Üretim cezası
```
efektif_uretim = base_uretim × max(0, 1 − corruption_level × PROD_PENALTY_PER_LEVEL)
```
Örnek: base 3 altın, seviye 2 → `3 × (1 − 0.5) = 1.5 → floor = 1` altın.

### 4.4 Lütuf maliyeti (n = daha önce alınan lütuf sayısı)
```
boon_cost(n) = BASE_BOON_COST + n × BOON_COST_STEP
```
Örnek: 0→30, 1→50, 2→70, 3→90.

### 4.5 Deterministik 3'lü sunum
```
seed = (scene_id × 31 + boon_index × 7) mod pool_size
offer[k] = pool[ (seed + k × step) mod pool_size ]  , k ∈ {0,1,2}
step = 1 (çakışma varsa bir sonraki farklı indekse kaydır)
```
`boon_index` = o ana kadar yapılan sunum sayısı. Bu, rastgelelik olmadan
tekrarlanabilir sunum üretir (test determinizmi). İleride oyuncu-görünmez bir
seed `GameState`'e eklenerek çeşitlilik artırılabilir.

### 4.6 Erlik yayılımı
Her `ERLIK_SPREAD_INTERVAL` turda:
```
hedef = temiz VEYA seviyesi < 3 olan, herhangi bir bozuk bölgeye komşu bölgeler
        içinden, army_count'u EN DÜŞÜK olan (eşitlikte region_id alfabetik ilk)
hedef.corruption_level = min(3, hedef.corruption_level + 1)
```
"Gök Kalkanı" lütfu varsa efektif interval: `ceil(ERLIK_SPREAD_INTERVAL / (1 − 0.20 × kalkan_sayisi))`
(kalkan_sayısı arttıkça yayılım seyrekleşir; alt sınır interval değeri kadar).

---

## 5. Edge Cases

- **Ruh eşiği aşırı birikimi**: Oyuncu bir sunumu ertelерse ve Ruh birikirse, tek
  seferde birden çok sunum tetiklenmez — her seferinde 1 sunum, seçim sonrası bir
  sonraki eşik kontrol edilir.
- **Yeterli Ruh yokken sunum**: Sunum yalnızca `toplam_ruh ≥ boon_cost(n)` iken
  yapılır. Seçim anında maliyet düşülür; kalan Ruh birikmeye devam eder.
- **Havuz tükenmesi**: Havuzdaki benzersiz lütuf sayısı 3'ten azsa, sunum mevcut
  olanları tekrar edebilir (aynı lütuf iki slotta görünebilir) — 3 slot her zaman dolu.
- **Arındırma sırasında ordu yok olursa**: Ordu direnci geçemezse bölge bozuk kalır;
  Ruh verilmez; kısmi ilerleme kaydedilmez.
- **Seviye 0 bölgeyi arındırma denemesi**: Geçersiz aksiyon — arındırma yalnızca
  `corruption_level ≥ 1` için sunulur.
- **Erlik yayılacak temiz komşu yoksa**: Yayılım o tur atlanır (hata değil).
- **Final sahnesi**: Erlik yayılımı hızlanabilir (senaryo override) — bu sistem
  interval'i sahne başına ayarlanabilir olmalı.
- **Sahne geçişi**: Lütuflar taşınır; sahneye özel bozulma durumu sıfırlanır
  (yeni harita = yeni bozulma).

---

## 6. Dependencies

- **Bölge Fethi / Harita** (`region-map-system.md`, kod: `region_data.gd`,
  `map_state.gd`) — `RegionData`'ya `corruption_level` alanı eklenmeli.
- **Savaş Çözümü** (`combat-system.md`, kod: `combat_resolver.gd`) — arındırma
  çözümü `CombatResolver`'ı yeniden kullanır (ordu vs. corruption_strength).
- **Kaynak Yönetimi** (`resource-system.md`) — Ruh yeni bir kaynak tipi;
  `GameState.ruh` alanı.
- **Oyun Durumu** (`game_state.gd`) — kalıcı `boons` listesi + `ruh` alanı.
- **Konsey (Altı Oğul)** (`council-system.md`) — konsey bonusları lütuflarla
  aynı toplamsal modifikatör hattını paylaşmalı (çift sayım önlenmeli).
- **Katmanlı Düşman** (`enemy-layers.md`) — Erlik yayılımı bu sistemin AI tarafı.

> Karşılıklı bağımlılık notu: yukarıdaki dokümanlar yazıldığında bu sisteme
> geri referans vermeli (Ruh alanı, corruption_level, CombatResolver kullanımı).

---

## 7. Tuning Knobs

| Knob | Etkilediği | Güvenli Aralık | Not |
| ---- | ---- | ---- | ---- |
| `RUH_PER_LEVEL` | Güç eğrisi hızı | 5–20 | Yüksek = hızlı güçlenme |
| `CORR_STR_PER_LEVEL` | Arındırma zorluğu | 2–8 | Yüksek = daha çok ordu gerekir |
| `PROD_PENALTY_PER_LEVEL` | Bozulmanın ekonomik baskısı | 0.1–0.34 | 0.34×3 ≈ üretim durması |
| `BASE_BOON_COST` / `BOON_COST_STEP` | Lütuf sıklığı | 10–60 / 5–40 | Düşük = sık lütuf |
| `ERLIK_SPREAD_INTERVAL` | Zaman baskısı | 2–8 tur | Düşük = agresif Erlik |
| Lütuf etki yüzdeleri | Build gücü | %3–%15 | Denge kritik — çok yüksek zorluğu bozar |
| Havuz kompozisyonu | Build çeşitliliği | — | Sahne bazlı havuz override mümkün |

---

## 8. Acceptance Criteria

1. Seviye 2 bozulmuş bir bölge, hiç lütuf yokken arındırıldığında oyuncu **tam
   20 Ruh** kazanır (`2 × 10`). *(Otomatik test — BLOCKING)*
2. 1 "Arınma Ustalığı" lütfu varken aynı arındırma **24 Ruh** verir. *(Test)*
3. Toplam Ruh ilk kez ≥ `BASE_BOON_COST` (30) olduğunda tam olarak **1 sunum**
   tetiklenir ve **3 lütuf** gösterilir. *(Test)*
4. Aynı `scene_id` ve `boon_index` ile sunum **her çalıştırmada aynı 3 lütfu**
   üretir (determinizm). *(Test)*
5. Lütuf seçildiğinde maliyet Ruh'tan düşer; seçilmeyenler kaybolur. *(Test)*
6. Alınan lütuflar sahne geçişinde korunur (`GameState.boons` boşalmaz). *(Test)*
7. Seviye 3 bozulmuş bölgenin `gold_per_turn` üretimi **0**'a düşer. *(Test)*
8. Erlik, `ERLIK_SPREAD_INTERVAL` turda bir, kurala göre (en düşük ordulu komşu)
   **deterministik** yayılır. *(Test)*
9. "Gök Kalkanı" lütfu efektif yayılma interval'ini artırır (yayılım seyrekleşir).
   *(Test)*
10. Bozulmuş bölge görsel olarak temiz bölgeden ayırt edilebilir (seviyeye göre
    renk). *(Görsel — screenshot + lead onayı, ADVISORY)*
