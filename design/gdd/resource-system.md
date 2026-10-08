# Sistem GDD: Kaynak Yönetimi (Altın + Ordu Üretimi)

*Oyun: ULUS: Blood of the Sky Wolf*
*Oluşturulma: 2026-10-08*
*Durum: Designed (inceleme bekliyor — `/design-review` taze oturumda)*
*Creative Director Review (CD-GDD-ALIGN): atlandı — lean mod*
*Katman: Core*
*Uyguladığı sütun: Epik Ama Erişilebilir · İki Katmanlı Tehdit*

> Kapsam (2026-10-08 kararı): MVP'de **altın** geliri ve **ordu üretimi** bu GDD'de
> tam tanımlıdır. **Sürü** yalnızca veri-güdümlü kaynak arayüzüyle (sonraki perde)
> tanımlanır. **Ruh** `spirit-system.md`'ye aittir. Çapraz inceleme B1'i çözer
> (`gdd-cross-review-2026-10-08.md`).

---

## 1. Overview

Kaynak Yönetimi, haritadaki toprağın ekonomik değerini orduya dönüştüren
sistemdir. Oyuncunun sahip olduğu her bölge her tur sonunda kendi altın gelirini
(`gold_per_turn`) hazineye ekler. Oyuncu bu altını, kendi bölgelerinde yeni ordu
birlikleri toplamak için harcar. Böylece "Kaynak topla → Ordu üret → Fethet"
döngüsü kapanır: fetih geliri büyütür, gelir orduyu, ordu bir sonraki fethi.
Sistem kaynakları veri-güdümlü bir liste olarak tutar. MVP'de tek aktif kaynak
altındır; sürü sonraki perdede aynı arayüzle eklenir; ruh ise Kök Böri sistemine
aittir. Gelir pasif akar (oyuncu yalnızca sonucunu görür). Üretim ise her turun
aktif kararıdır: altını şimdi mi harcamalı, hangi cepheyi güçlendirmeli, yoksa
daha büyük bir hamle için mi biriktirmeli? Bu sistem olmadan altının hiçbir
anlamı yoktur ve ordu yalnızca azalan bir sayıdır. Fetih kalıcı bir büyüme
yaratmaz ve konseptin temel döngüsü kırılır.

---

## 2. Player Fantasy

**Boyları toplayan kagan.** Oyuncu ücretli asker satın alan bir hazinedar değil,
dağınık boyları bir bayrak altında toplayan Oğuz'dur. Altın, kağanın boylara
dağıttığı armağandır: fethedilen her oba hazineye katılır, hazine de yeni
yiğitleri obaya çağırır. Oyuncunun içinden geçen cümle şudur: *"Ordum,
birleştirdiğim halkın büyüklüğü kadardır."*

- **Doğrudan katman (üretim):** Her tur kağan bir karar verir: hazinedeki armağanı
  şimdi hangi cepheye dağıtacak, yoksa daha büyük bir hamle için biriktirecek mi?
  Yeni birliklerin bir bölgede belirmesi, kararın ağırlığını taşır: o cephe
  güçlenir, diğeri bekler.
- **Dolaylı katman (gelir):** Tur sonunda obaların armağanı kendiliğinden gelir.
  Oyuncu hesap yapmaz, sonucu görür: hazinenin her fetihle biraz daha dolması,
  "birleştirdikçe güçleniyorum" duygusunu besler.

**Sütun bağı:**

- **Destanı Yaşa:** "mekanikler destanın hizmetinde". Ekonomi, Prolog'un "boyları
  birleştir" perdesinin mekanik karşılığıdır, kuru bir muhasebe değildir.
- **Epik Ama Erişilebilir:** "her hamle ağır ve anlamlı hissettirmeli ama öğrenmesi
  kolay olmalı". Tek kaynak ve tek karar ("nereye, ne kadar") ile ilk turda
  öğrenilir; ağırlığı ise kıtlıktan gelir.

**Kaçınılacak his:** Muhasebe, mikro yönetim, "her tur hep harca" otomatizmi.
Biriktirmek de gerçek bir seçenek olmalı.

---

## 3. Detailed Rules

### 3.1 Core Rules

1. **Kaynak listesi:** Kaynaklar `GameState` içinde yalnızca veri olarak tutulur.
   - MVP'de tek aktif kaynak **altın**dır (tam sayı, ≥ 0).
   - **Sürü** tanımlıdır ama pasiftir: bölge verisinde `herd_per_turn` alanı
     ayrılır, sürü etkinleşene kadar hiçbir hesaba girmez.
   - **Ruh** `spirit-system.md`'ye aittir; bu sistem Ruh'u okumaz ve yazmaz.
2. **Başlangıç:** Sahne başında `gold = starting_gold` olur. Değer bölüm verisinden
   (`ChapterMapDefinition`) gelir; koddaki sabit 100 kalkar.
3. **Gelir:** Gelir, tur sonunun **ekonomi adımında** (region-map §3.4'teki 2. adım,
   düşman AI'dan sonra) toplanır.
   - Altın, oyuncu bölgelerinin efektif gelirlerinin toplamı kadar artar (formül §4).
   - Bölge başına çarpanlar (ör. Ruh sisteminin bozulma cezası) ve toplam üzerindeki
     çarpanlar (ör. Bereket lütfu) bu sisteme girdi olarak gelir; **toplama ve
     yuvarlama bu sistemindir**. Gelir formülünün sahibi bu GDD'dir (çapraz
     inceleme W8).
4. **Ordu Topla (üretim):** Oyuncunun kendi turunda, sahip olduğu herhangi bir
   bölgede yapılır.
   - Oyuncu `k ≥ 1` birlik seçer.
   - Koşullar: `k ≤ kalan_tavan` ve `gold ≥ k × recruit_cost`.
   - Sonuç: `gold −= k × recruit_cost`, bölgenin `army_count += k`.
   - **Aksiyon harcamaz.** Birlikler hemen kullanılabilir, aynı tur hareket edebilir.
5. **Bölge tavanı:** Her bölge bir turda en fazla `recruit_cap` birlik çıkarabilir.
   Tavan, bölgenin efektif üretiminden türer (§4); büyük obalar daha çok yiğit verir.
   - Sayaç her yeni oyuncu turunun başında sıfırlanır (tur sonunun 3. adımı).
6. **Düşman takviyesi** (geçici sözleşme): Ekonomi adımında her düşman bölgesine
   `+enemy_reinforcement_per_turn` ordu eklenir. Değer bölüm verisinden gelir.
   - Düşmanın hazinesi yoktur.
   - Katmanlı Düşman GDD'si (`enemy-layers.md`) yazıldığında bu kuralı devralır.
7. **Bakım gideri:** `upkeep_per_army` ayarı tanımlıdır; **MVP değeri 0**, yani
   bakım yoktur. 0'dan büyük olduğunda ekonomi adımında, gelirden sonra ödenir;
   altın yetmezse ne olacağı §5'te tanımlanır.
8. **Sahne geçişi:** Altın sahneler arasında **taşınmaz**; her sahne kendi
   `starting_gold` değeriyle açılır. Sahneler bağımsız dengelenir; sahneler arası
   taşınan güç Kök Böri lütuflarıdır.
9. **Yapılamayanlar:**
   - Altın negatife düşemez.
   - Ordu altına çevrilemez (satış yok).
   - Altın bölgeler arasında taşınmaz; hazine ortaktır.
   - Düşman ya da nötr bölgede üretim yapılamaz.
   - Ruh altınla alınamaz.

### 3.2 States and Transitions

| Varlık | Durum | Geçiş | Tetik |
| --- | --- | --- | --- |
| Bölge üretim sayacı | Açık (`üretilen < recruit_cap`) | → Tükendi | Üretim tavana ulaşınca |
| Bölge üretim sayacı | Tükendi | → Açık (sayaç = 0) | Yeni oyuncu turu (tur sonu 3. adım) |
| Bölge üretim sayacı | Herhangi | → Yok sayılır | Bölge sahip değiştirince (sayaç yeni sahipte de 0'dan başlar) |
| Üretim düğmesi | Etkin | → Pasif | `gold < recruit_cost` veya sayaç tükendi veya bölge oyuncunun değil |
| Hazine | Altın değeri | +gelir / −üretim / −bakım | Ekonomi adımı / Ordu Topla |

### 3.3 Interactions with Other Systems

| Sistem | Giren veri | Çıkan veri | Arayüzün sahibi |
| --- | --- | --- | --- |
| Harita / Tur Akışı (`region-map-system.md`) | Bölge sahipliği, `gold_per_turn`; tur sonu sırası | Ekonomi adımını çağırır (gelir + düşman takviyesi + bakım); 3. adımda sayaçları sıfırlar | Sıra: Harita · İçerik: Kaynak |
| Ordu (`army-system.md`) | — | Üretim `army_count`'u artırır; garnizon ve hareket kuralları değişmez | Kaynak |
| Kök Böri / Ruh (`spirit-system.md`) | Bölge başına üretim çarpanı (bozulma), toplam gelir çarpanları (lütuflar) | — (Ruh'a dokunmaz) | Çarpanlar: Ruh · Uygulama: Kaynak |
| Savaş (`combat-system.md`) | — | — (dolaylı: üretilen ordu savaşa girer) | — |
| Oyun Durumu (`GameState`) | — | `gold` (yalnızca veri) | Kaynak |
| Bölüm verisi (`ChapterMapDefinition`) | `starting_gold`, `enemy_reinforcement_per_turn` | — | Kaynak (ayar) |
| Katmanlı Düşman (`enemy-layers.md`, yazılmadı) | — | Düşman takviyesini devralır (geçici) | Gelecekte: Katmanlı Düşman |
| HUD / Bilgi paneli | — | Altın, tahmini gelir (+X/tur), Ordu Topla (maliyet, kalan tavan) | UI (§10) |

---

## 4. Formulas

Değerler 2026-10-08'de systems-designer + economy-designer önerileri ve kuralları
birebir uygulayan bir Prolog simülasyonuyla seçildi (aday A — aşağıdaki doğrulama).

### F1 — Bölgenin efektif geliri

`effective_region_income = floor(G_base × M_c)`, burada
`M_c = CORRUPTION_PRODUCTION_MULTIPLIERS[C]` (Ruh sistemi, §4.3).

| Değişken | Sembol | Tip | Aralık | Açıklama |
| --- | --- | --- | --- | --- |
| Taban gelir | `G_base` | int | 0–5 | Bölge tanımındaki `gold_per_turn` |
| Bozulma seviyesi | `C` | int | 0–3 | Ruh sisteminden gelir; MVP Prolog'da 0 |
| Seviye çarpanları | — | float[4] | azalan, 1.0 → 0.0 | `CORRUPTION_PRODUCTION_MULTIPLIERS` (Ruh sistemi): [1.0, 0.75, 0.5, 0.0] |
| Bozulma çarpanı | `M_c` | float | 0.0–1.0 | Seviyenin çarpanı; Ruh sisteminden gelen girdi |
| Efektif gelir | `G_eff` | int | 0–5 | Aşağı yuvarlanmış |

**Çıktı aralığı:** 0–5. Seviye 3 bozulmada her bölge 0 (`M_c = 0`).
**Örnek:** Otağ `floor(2 × 1.0) = 2`; 2. seviye bozulmuş Bereket Vadisi
`floor(3 × 0.5) = 1`.

### F2 — Tur geliri

`turn_income = max(I_floor, floor((I_raw + B_add) × M_g))`, burada `I_raw = Σ G_eff`.
Toplam yalnızca oyuncu bölgeleri üzerinden alınır; oyuncunun hiç bölgesi yoksa
sonuç 0'dır.

| Değişken | Sembol | Tip | Aralık | Açıklama |
| --- | --- | --- | --- | --- |
| Ham gelir | `I_raw` | int | 0–50 | Oyuncu bölgelerinin `G_eff` toplamı |
| Toplamsal lütuf bonusu | `B_add` | int | 0–10 | Ruh sisteminin tanımladığı düz bonus (ör. "+1 altın/tur"); MVP 0 |
| Çarpımsal lütuf çarpanı | `M_g` | float | 1.0–2.0 | Ruh sisteminin tanımladığı yüzde bonus; MVP 1.0 |
| Gelir tabanı | `I_floor` | int | 0–3 | Kayıp sonrası toparlanma güvencesi; **MVP 0** |
| Tur geliri | `I_turn` | int | 0–100 | Ekonomi adımında hazineye eklenir |

**Çıktı aralığı:** Prolog'da 2 (yalnızca Otağ) ile 10 (tam fetih) arası.
**Örnek:** Otağ + Bereket Vadisi → `I_raw = 2 + 3 = 5` → `max(0, floor(5 × 1.0)) = 5`.
**Not:** Lütfün düz bonus mu yüzde mi olacağına C-31 karar verecek. Ekonomi
tasarımcısı küçük tam sayılarda %10'un yuvarlamada kaybolduğunu, bu yüzden
"+1 altın/tur"un daha iyi olduğunu söylüyor. Formül iki biçimi de destekliyor.

### F3 — Bölge üretim tavanı

`recruit_cap = max(R_min, G_eff)`

| Değişken | Sembol | Tip | Aralık | Açıklama |
| --- | --- | --- | --- | --- |
| Efektif gelir | `G_eff` | int | 0–5 | F1'in çıktısı |
| Asgari tavan | `R_min` | int | 0–2 | Her obanın verebileceği en az yiğit; MVP 1 |
| Tavan | `R_cap` | int | 1–5 | O bölgenin bir turda verebileceği en fazla birlik |

**Çıktı aralığı:** Prolog'da 1–3. Tam fetihte toplam tavan 10/tur; bunun maliyeti
20 altın, gelir ise 10. Yani geç oyunda kısıt **altın** olur ve biriktirme kararı
anlam kazanır.
**Örnek:** Bereket Vadisi 3, Otağ 2, Batı Obası 1. Seviye 3 bozulmada bile tavan 1.

### F4 — Üretim maliyeti

`toplam_maliyet = k × recruit_cost`. Koşullar: `1 ≤ k ≤ kalan_tavan` ve
`toplam_maliyet ≤ gold`.

| Değişken | Sembol | Tip | Aralık | Açıklama |
| --- | --- | --- | --- | --- |
| Birlik sayısı | `k` | int | 1–`R_cap` | Oyuncunun seçimi |
| Birlik maliyeti | `recruit_cost` | int | 1–5 | **Sabit 2 altın** (MVP) |

**Örnek:** 6 altınla Otağ'da 2 birlik (tavan 2) → 4 altın harcanır, 2 kalır.

### F5 — Başlangıç altını

`gold₀ = starting_gold`. Değer bölüm verisinden gelir; **Prolog'da 6**. Bu, tavan
sınırına takılmadan üç birliklik bir başlangıç demek.

### F6 — Düşman takviyesi

Ekonomi adımında her düşman bölgesi `i` için: `army_i += E_r`. **Prolog'da E_r = 1.**

| Değişken | Sembol | Tip | Aralık | Açıklama |
| --- | --- | --- | --- | --- |
| Takviye | `E_r` | int | 0–3 | `enemy_reinforcement_per_turn` (bölüm verisi) |

**Örnek:** 1. turun sonunda düşmanın inde 1 + 1 = 2, yeni aldığı Doğu Obası'nda
3 + 1 = 4 ordu olur.

### F7 — Bakım gideri (MVP'de etkisiz)

`upkeep = max(0, A_total − A_free) × U`; ödenen miktar `min(upkeep, gold)`.

| Değişken | Sembol | Tip | Aralık | Açıklama |
| --- | --- | --- | --- | --- |
| Toplam ordu | `A_total` | int | 0–200 | Oyuncunun tüm bölgelerindeki ordunun toplamı |
| Ücretsiz eşik | `A_free` | int | 0–30 | Bakım ödenmeyen ordu miktarı; varsayılan 10 |
| Birlik başı bakım | `U` | int | 0–2 | **MVP 0** |

### Prolog doğrulaması

Yukarıdaki değerlerle, kuralları birebir uygulayan simülasyon:

| Durum | Sonuç |
| --- | --- |
| Kusursuz oyun | 4. turda zafer (tur başına 1 aksiyonla mümkün olan en kısa süre) |
| İlk 2 / 4 / 6 tur boşa | 5. / 11. / 16. turda zafer |
| İlk 8+ tur boşa | 18 turda kazanılamıyor |
| Tamamen pasif | Oyuncu hayatta kalıyor, ama 18. turda 4 bölge düşmanda ve her birinde 18–19 ordu var. Kazanma yolu kalmıyor. |
| Üretim olmadan (2026-10-08 kodu) | Kazanılamıyor (çapraz inceleme B1 doğrulandı) |

Karşılaştırılan adaylar: takviye yalnız ine (oyuncu 10 tur boşa harcasa bile
kazanıyor — baskı zayıf); başlangıç 4 altın (tolerans 4 tura iniyor); tavan
`ceil(G_eff / 2)` + tüm bölgelere takviye (4 tur boşa → kaybedilen — öğretici
için sert). Gelir tabanı Prolog'da hiç devreye girmedi (Otağ her zaman ≥ 2 verir).

**1. tur örneği:** Oyuncu 6 altınla başlıyor. Otağ'da 2 birlik üretiyor (−4 altın),
6 orduyla boş Bereket Vadisi'ne yürüyor. Düşman AI inden en zayıf komşusu Doğu
Obası'na saldırıyor: 5'e 3, düşman kazanıyor ve bölgede 3 ordusu kalıyor. Ekonomi
adımında oyuncunun geliri 2 + 3 = 5, hazinesi 7 altın oluyor. Takviyeyle düşmanın
inde 2, Doğu Obası'nda 4 ordu oluyor.

---

## 5. Edge Cases

- **Altın birlik maliyetinin altındaysa:** "Ordu Topla" pasif olur; ipucu metni
  eksik altını gösterir.
- **İstenen `k` kalan tavanı aşıyorsa ya da altın yetmiyorsa:** İşlem reddedilir.
  Kısmi üretim yapılmaz, altın harcanmaz.
- **Aynı bölgede bir turda birden fazla üretim:** İzinlidir; toplam,
  `recruit_cap`'i aşamaz.
- **Üretim onaylandıktan sonra:** Geri alma ve iade yoktur. Seçim önce artı/eksi
  ile ayarlanır, onaylandıktan sonra kesindir.
- **Bu tur ele geçirilen bölge:** Hemen üretim yapılabilir. Sayaç 0'dan başlar,
  tavan o bölgenin `G_eff` değeridir.
- **Üretip aynı tur hareket etmek:** İzinlidir. Hareket eden kuvvet
  `army_count − 1`'dir ve yeni birlikleri de içerir; garnizon kuralı değişmez.
- **Üretim yapılan bölgeyi düşman aynı tur sonunda alırsa:** Birlikler savaş
  sonucuna göre kaybedilir, altın iade edilmez.
- **Oyuncunun hiç bölgesi kalmazsa:** Gelir 0 olur (gelir tabanı uygulanmaz) ve
  kaybetme kontrolü devreye girer.
- **`G_base = 0` olan bölge:** Gelir 0, tavan `R_min` (1).
- **Seviye 3 bozulma:** Gelir 0 olur, tavan 1'de kalır ("her obada birkaç yiğit").
- **Düşman tur sonunda yeni bir bölge ele geçirirse:** Takviye ekonomi adımında,
  düşman AI'dan sonra uygulandığı için yeni bölge de aynı tur +E_r alır.
- **Ordusu 0 olan düşman bölgesi:** Berabere sonucunda kalabilir (çapraz inceleme
  W3). Sahibi düşman olduğu sürece +E_r takviye alır.
- **Nötr bölgeler:** Gelir de takviye de almaz. Oyuncu ele geçirene kadar ordusu
  sabittir.
- **Bakım gideri altını aşarsa** (yalnızca `U > 0` olduğunda): Mevcut altın
  ödenir ve hazine 0 olur. Kalan borç silinir; birlik dağıtılmaz, borç birikmez.
- **Üst sınırlar:** Altında ve orduda üst sınır yoktur; Prolog simülasyonunda en
  büyük ordu 19 oldu. UI 3 haneye kadar gösterir; daha büyük değerler tasarım
  dışıdır ve ayar hatası sayılır.
- **Sahne sonu:** Harcanmamış altın silinir (§3.1 R8). Sonraki sahne kendi
  `starting_gold` değeriyle açılır.
- **Düşman turunda üretim:** Mümkün değildir. Üretim yalnızca oyuncunun turunda
  yapılabilir.
- **Ekonomi adımı sırası:** Önce oyuncu geliri, sonra düşman takviyesi, sonra
  bakım. Bu üç işlem birbirini etkilemediği için sıra sonucu değiştirmez.

---

## 6. Dependencies

### Bu sistemin dayandıkları (yukarı akış)

| Sistem | Tür | Arayüz |
| --- | --- | --- |
| Harita / Tur Akışı (`region-map-system.md`) | **Sert** | Bölge sahipliği ve `gold_per_turn` (`MapState`). Tur sonu sırasında ekonomi adımı (2. adım) ve sayaç sıfırlama (3. adım). Bölüm verisi `ChapterMapDefinition`: `starting_gold`, `enemy_reinforcement_per_turn`. |
| Kök Böri / Ruh (`spirit-system.md`) | Yumuşak | Bölge başına bozulma çarpanı `M_c`, lütuf bonusları `B_add` ve `M_g`. Ruh sistemi yoksa değerler `M_c = 1`, `B_add = 0`, `M_g = 1` olur ve sistem tam çalışır. |

### Bu sisteme dayananlar (aşağı akış)

| Sistem | Tür | Arayüz |
| --- | --- | --- |
| Ordu (`army-system.md`) | **Sert** | Üretim `army_count`'u artırır. Ordunun büyüyebildiği tek kaynak bu sistemdir. |
| Harita / Tur Akışı — düşman tarafı | **Sert** | Düşman takviyesi (F6) ekonomi adımında uygulanır. |
| Kök Böri / Ruh (`spirit-system.md`) | Yumuşak | Bereket ve Sürü Kutsaması lütuflarının etkisi bu sistemin gelir formülünden (F2) geçer. |
| HUD / Bilgi paneli | Sert | Altın, tahmini gelir, Ordu Topla kontrolü (§10). |
| Kayıt / Yükleme (C-16, ADR yazılacak) | Sert | Sahne ortasında kayıt alınırsa `gold` ve bölge üretim sayaçları saklanmalı. |
| Katmanlı Düşman (`enemy-layers.md`, yazılmadı) | Gelecek | Düşman takviyesini devralacak (geçici sözleşme). |

### Diğer GDD'lerde gereken karşı güncellemeler

Çift yönlü bağımlılık kuralı gereği (C-28 kapsamında yapılır):

1. **`army-system.md` §6:** Kaynak sistemi bağımlılık olarak eklenecek. §7'deki
   "ordu bakım maliyeti (planlı)" notu bu GDD'nin F7'sine işaret edecek.
2. **`region-map-system.md`:**
   - §4'teki gelir formülü bu GDD'nin F2'sine yönlendirilecek; gelirin sahibi
     artık bu GDD.
   - §3.4'ün 2. adımı "ekonomi adımı (gelir + düşman takviyesi + bakım)" olarak
     yeniden adlandırılacak.
   - §6'ya bu GDD eklenecek. AC5 F2'ye göre güncellenecek.
3. **`spirit-system.md` §6:** "Kaynak Sistemi (yazılmadı)" ifadesi
   `resource-system.md`'ye bağlanacak.
4. **`systems-index.md`:** Kaynak Yönetimi satırı bu dosyaya bağlanacak.

---

## 7. Tuning Knobs

### Oyun geneli

Savaş ayarları gibi veri dosyasında tutulur; dosyanın adı ve yeri uygulama
kararıdır (→ ADR / uygulama).

| Ayar | MVP | Güvenli aralık | Çok düşükse | Çok yüksekse | Etkileşim |
| --- | --- | --- | --- | --- | --- |
| `recruit_cost` | 2 | 1–4 | Altın anlamsızlaşır, ordu seli | Ordu büyümesi durur, Prolog kazanılamaz hale gelir | Gelirle oranı belirleyicidir (Prolog: 2→10 gelir = 1→5 birlik/tur) |
| `R_min` (asgari tavan) | 1 | 0–2 | 0: tam bozulmuş ya da 0 gelirli bölgede üretim olmaz | 2: küçük obalar büyüklerle eşitlenir | F3 |
| `I_floor` (gelir tabanı) | 0 | 0–3 | — | Kaybeden oyuncu bile rahat toparlanır, kayıp cezası kalmaz | Prolog'da etkisiz; kayıplı sahnelerde açılabilir |
| `upkeep_per_army` (`U`) | 0 | 0–2 | — | Büyük ordu tutmak imkânsızlaşır, ekonomi çöker | `A_free` ile birlikte |
| `A_free` (ücretsiz eşik) | 10 | 0–30 | Erken oyun da bakım öder | Bakım hiç devreye girmez | Yalnızca `U > 0` iken anlamlı |

### Bölüm başına (`ChapterMapDefinition`)

| Ayar | Prolog | Güvenli aralık | Çok düşükse | Çok yüksekse | Etkileşim |
| --- | --- | --- | --- | --- | --- |
| `starting_gold` | 6 | 0–20 | 4 → oyuncunun boşa harcayabileceği tur sayısı 4'e iner; 0 → ilk tur pasif | Erken turların geliri değersizleşir | Düşman takviyesiyle birlikte affediciliği belirler (§4 doğrulaması) |
| `enemy_reinforcement_per_turn` | 1 | 0–3 | 0 → baskı yok, pasif oyun cezasız | 2+ → birkaç tur boşa harcanınca kazanılamaz (kontrol edilmeli) | Yayılım hızıyla birlikte düşman baskısını belirler |

### Başka sistemlerin sahip olduğu değerler (burada tekrar tanımlanmaz)

| Değer | Sahibi | Bu sisteme etkisi |
| --- | --- | --- |
| Bölge `gold_per_turn` | `region-map-system.md` (bölge verisi) | Hem geliri (F1) hem üretim tavanını (F3) belirler |
| `CORRUPTION_PRODUCTION_MULTIPLIERS` | `spirit-system.md` | Bozulma çarpanı `M_c` |
| `B_add`, `M_g` (lütuflar) | `spirit-system.md` | Tur geliri (F2) |

**Kritik etkileşim:** Başlangıç altını ve düşman takviyesi birlikte oyuncunun ne
kadar hata tolere edebileceğini belirler. Birini değiştirirken §4'teki doğrulama
tablosu yeniden üretilmelidir.

---

## 8. Acceptance Criteria

qa-lead doğrulaması: 2026-10-08 (ifade düzeltmeleri + 7 eksik kriter eklendi).
Test tipi her grubun başında; birim ve entegrasyon testleri BLOCKING.

### Birim (BLOCKING)

- **AC1:** **GIVEN** Prolog başlıyor, **WHEN** sahne yüklenir, **THEN** `gold = 6`
  olur ve değer `ChapterMapDefinition.starting_gold`'dan okunur (sabit kod değil).
- **AC2:** **GIVEN** oyuncunun Otağ (2) ve Bereket Vadisi (3) bölgeleri var,
  bozulma ve lütuf yok, **WHEN** ekonomi adımı çalışır, **THEN** altın tam 5 artar.
- **AC3:** **GIVEN** `gold_per_turn` 2 ve bozulma çarpanı 0.75 olan bölge,
  **WHEN** gelir hesaplanır, **THEN** efektif gelir 1 olur.
- **AC4:**
  - **GIVEN** `I_raw=5`, `B_add=1`, `M_g=1.0`, `I_floor=0`, **THEN** tur geliri 6.
  - **GIVEN** `I_raw=0`, `I_floor=1` ve oyuncunun en az 1 bölgesi var, **THEN** 1.
  - **GIVEN** oyuncunun hiç bölgesi yok, **THEN** `I_floor` ne olursa olsun 0.
- **AC5:** **GIVEN** 6 altın ve Otağ (tavan 2), **WHEN** Otağ'da 2 birlik üretilir,
  **THEN** `gold = 2` ve Otağ'ın ordusu +2 olur.
- **AC6:** **GIVEN** Otağ bu tur 2 birlik üretmiş (tavan 2), **WHEN** 1 birlik daha
  istenir, **THEN** reddedilir; altın ve ordu değişmez.
- **AC7:** **GIVEN** 3 altın ve maliyet 2, **WHEN** `k=2` istenir, **THEN** tamamen
  reddedilir (kısmi üretim yok), altın 3 kalır.
- **AC8:** **GIVEN** üretim sayaçları tükenmiş, **WHEN** `end_turn` 3. adımı (yeni tur
  başlangıcı) tamamlanır, **THEN** oyuncunun tüm bölgelerinde sayaç 0 olur.
- **AC9:** **GIVEN** efektif geliri 0 olan bölge (`G_base` 0 veya seviye 3 bozulma),
  **THEN** `recruit_cap = 1`.
- **AC10:** **GIVEN** orduları 1 ve 3 olan iki düşman bölgesi ve
  `enemy_reinforcement_per_turn = 1`, **WHEN** ekonomi adımı çalışır, **THEN**
  ordular 2 ve 4 olur.
- **AC12:**
  - **GIVEN** `U=0`, **WHEN** ekonomi adımı çalışır, **THEN** ordu büyüklüğü ne
    olursa olsun altın düşülmez.
  - **GIVEN** `U=1`, `A_free=10`, toplam ordu 13, altın 2, **WHEN** ekonomi adımı
    çalışır, **THEN** altın 0 olur (3 borcun 2'si ödenir), kalan 1 silinir ve birlik
    dağıtılmaz.
- **AC14:** **GIVEN** nötr ya da düşman bölgesi, **WHEN** üretim denenir, **THEN**
  reddedilir.
- **AC18:** **GIVEN** 1 aksiyon kaldı ve 4 altın var, **WHEN** 1 birlik üretilir,
  **THEN** `actions_remaining` hâlâ 1'dir.
- **AC20:** **GIVEN** Bereket Vadisi (tavan 3) ve 10 altın, **WHEN** önce 1, sonra 2
  birlik üretilir, **THEN** ordu +3, altın −6 olur ve sayaç tükenir. **WHEN** 1 birlik
  daha istenir, **THEN** reddedilir.
- **AC22:** **GIVEN** orduları 2 ve 4 olan iki nötr bölge, **WHEN** ekonomi adımı
  çalışır, **THEN** ordular 2 ve 4 kalır ve gelir hesabına girmezler.

### Entegrasyon (BLOCKING)

- **AC11:** **GIVEN** düşman AI `end_turn`'ün 1. adımında bir bölge ele geçirmiş,
  **WHEN** 2. adım çalışır, **THEN** o bölge de +1 takviye alır.
- **AC13:** **GIVEN** oyuncu bir bölgede üretip aynı tur oradan hareket ediyor,
  **THEN** hareket eden kuvvet yeni birlikler dahil `army_count − 1`'dir.
- **AC19:** **GIVEN** oyuncu bu tur bir bölge ele geçirmiş, **WHEN** orada üretim
  dener, **THEN** sayaç 0'dan başlar ve o bölgenin tavanına kadar üretim yapılabilir.
- **AC21:** **GIVEN** oyuncu bir bölgede üretim yapmış, **WHEN** düşman AI aynı tur
  sonunda o bölgeyi ele geçirir, **THEN** harcanan altın iade edilmez.
- **AC23:**
  - **GIVEN** `I_raw=5` ve Ruh sisteminden `B_add=1`, `M_g=1.0`, **WHEN** ekonomi
    adımı çalışır, **THEN** gelir 6.
  - **GIVEN** `M_g=1.2`, **THEN** gelir `floor(6 × 1.2) = 7`.
- **AC24:** **GIVEN** Bereket Vadisi (`G_base=3`) seviye 2 bozulmada (`M_c=0.5`) ve
  oyuncunun tek bölgesi, **WHEN** ekonomi adımı çalışır, **THEN** gelir 1.

### Sistem / simülasyon (ADVISORY)

- **AC15:**
  - **GIVEN** GDD değerleriyle Prolog, **WHEN** kusursuz bir hamle dizisi oynanır,
    **THEN** 4. turda zafer mümkündür.
  - **WHEN** oyuncu 8 tur yalnızca Otağ'da üretir, **THEN** 18. turdan önce zafer
    mümkün değildir.
- **AC16:** **GIVEN** 1. sahne harcanmamış altınla bitiyor, **WHEN** 2. sahne başlar,
  **THEN** `gold`, 2. sahnenin `starting_gold` değerine eşit olur.

### UI (ADVISORY, manuel)

- **AC17:**
  - **GIVEN** `gold < recruit_cost`, **THEN** Ordu Topla pasif olur ve ipucu eksik
    altını gösterir (çeviri anahtarı, ör. `RECRUIT_NOT_ENOUGH_GOLD` + miktar).
  - **GIVEN** sayaç tükenmiş, **THEN** pasif olur ve ipucu tavanı gösterir
    (`RECRUIT_CAP_REACHED`, ör. "2/2").
  - **GIVEN** iki kısıt da yok, **THEN** etkin olur.
  - HUD'daki tahmini gelir (+X/tur) mevcut sahipliğe göre F2'ye eşittir.

---

## 9. Visual/Audio Requirements

Tamamı art bible'a bağlıdır.

- **Altın ikonu:** 9×9 sikke, `#EDC76B` / `#C99A3D` (bible §7 İkonografi). HUD'da
  altın değerinin yanında durur.
- **Üretim geri bildirimi:** Bölgenin ordu sayısı artınca 2 kare yeşil (`#87B85C`)
  vurgu, altın azalınca 2 kare açık kırmızı vurgu (bible §7 "HUD sayı değişimi").
  Ölçek ve saydamlık animasyonu yok (bible §7 UI Animasyonu).
- **Gelir:** Tur sonunda HUD'daki altında "+X" ve `↑` ile 2 kare yeşil vurgu. Renk
  tek başına anlam taşımaz (renk körlüğü kuralı).
- **Düşman takviyesi:** Düşman bölgesinin ordu etiketinde 2 kare vurgu ve "+1" metni.
  Baskı okunur hale gelir.
- **Hareketi Azalt açıkken:** Vurgular anında uygulanır ve kalıcıdır; kare
  animasyonu olmaz.
- **Ses** (ses altyapısı C-23 sonrası): Üretim onayında kısa bir davul vuruşu,
  gelirde sikke sesi. İkisi de SFX ses ayarıyla ölçeklenir.
- **Font notu:** Kayıp işareti `−` (U+2212) pixel fontta yok (C-09 notu); azalmalar
  `↓` ikonuyla gösterilir.

---

## 10. UI Requirements

- **HUD üst bar:** `Altın: X (+Y)`. Y, mevcut sahipliğe göre F2'nin tahmini
  değeridir. Sayılar `NumberFormatter` ile biçimlenir.
- **Bilgi paneli, oyuncu bölgesi — "Ordu Topla" bölümü:**
  - −/+ seçici: `k` 1 ile `min(kalan tavan, altınla alınabilecek)` arasında.
  - Maliyet satırı: `k × 2 = Z altın`.
  - Tavan satırı: `kullanılan / R_cap`.
  - Onayla butonu.
  - Pasif durumlarda ipucu (AC17).
- **Bilgi paneli, düşman bölgesi:** `Takviye: +E_r / tur` bilgi satırı.
- **Odak zinciri:** Yeni kontroller C-08'deki zincire eklenir: Ordu Gönder ↕ Ordu
  Topla ↕ Tur Bitir. Zinciri ebeveyn (`GameContext`) kurar.
- **Yerleşim:** Panel 136px genişliğinde. Almanca ve Rusçada sığmalı; sığmayan metin
  `…` ile kısaltılır.
- **Yeni çeviri anahtarları (11 dil):** `RECRUIT`, `RECRUIT_CONFIRM`,
  `RECRUIT_COST`, `RECRUIT_CAP`, `RECRUIT_NOT_ENOUGH_GOLD`, `RECRUIT_CAP_REACHED`,
  `INCOME_PER_TURN`, `ENEMY_REINFORCEMENT`.

---

## 11. Open Questions

| # | Soru | Sahibi | Hedef |
| --- | --- | --- | --- |
| 1 | Bereket lütfu düz bonus mu (+1 altın/tur), yüzde mi (%10)? | Kullanıcı / game-designer | C-31 |
| 2 | Prolog simülasyonu (§4) repoya alınsın mı (ör. `tools/balance/`), AC15 otomatik testle mi kontrol edilsin? | Kullanıcı | Uygulama görevi |
| 3 | Sürü ne zaman etkinleşir ve neyi besler/tüketir? Konsept "nüfus ve ordu büyümesi" diyor. | game-designer | Perde 1 tasarımı |
| 4 | Katmanlı Düşman GDD'si takviyeyi devraldığında düşman ekonomisi simetrik mi olacak? | game-designer | `enemy-layers.md` |
| 5 | Toparlanma mekanizması ve bakım gideri (çapraz inceleme D1/D2): `I_floor` ve `U` açılsın mı? | Kullanıcı | İlk Prolog playtesti |
| 6 | Sahne ortası kayıtta altın ve üretim sayaçları nasıl saklanacak? | technical-director | C-16 (Save/Load ADR) |
| 7 | Kusursuz oyunla 4 turda zafer öğretici için fazla hızlı mı? Hedef: tipik oyuncu 10–18 tur. | Kullanıcı | İlk Prolog playtesti |
