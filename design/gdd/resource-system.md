# Sistem GDD: Kaynak Yönetimi (Altın + Ordu Üretimi)

*Oyun: ULUS: Blood of the Sky Wolf*
*Oluşturulma: 2026-10-08*
*Durum: Designed (inceleme bekliyor — `/design-review` taze oturumda); §4 Prolog doğrulaması C-49 ile güncel (2026-10-19); uygulama C-37 (2026-10-19 — `EconomyConfig`, `IncomeRules`, `ResourceController`, bilgi paneli Ordu Topla + HUD tahmini; §9 geri bildirimleri C-66)*
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
3. **Gelir:** Gelir, tur sonunun **ekonomi adımında** (region-map §3.4'teki 3. adım,
   düşman AI ve Erlik yayılımından sonra) toplanır.
   - Altın, oyuncu bölgelerinin efektif gelirlerinin toplamı kadar artar (formül §4).
   - Bölge başına çarpanlar (ör. Ruh sisteminin bozulma cezası) ve toplam üzerindeki
     lütuf bonusları (ör. Bereket: düz +1, `B_add`; yüzde kaynakları `M_g`) bu sisteme
     girdi olarak gelir; **toplama ve
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
   - Sayaç her yeni oyuncu turunun başında sıfırlanır (tur sonunun 4. adımı).
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
| Bölge üretim sayacı | Tükendi | → Açık (sayaç = 0) | Yeni oyuncu turu (tur sonu 4. adım) |
| Bölge üretim sayacı | Herhangi | → Yok sayılır | Bölge sahip değiştirince (sayaç yeni sahipte de 0'dan başlar) |
| Üretim düğmesi | Etkin | → Pasif | `gold < recruit_cost` veya sayaç tükendi veya bölge oyuncunun değil |
| Hazine | Altın değeri | +gelir / −üretim / −bakım | Ekonomi adımı / Ordu Topla |

### 3.3 Interactions with Other Systems

| Sistem | Giren veri | Çıkan veri | Arayüzün sahibi |
| --- | --- | --- | --- |
| Harita / Tur Akışı (`region-map-system.md`) | Bölge sahipliği, `gold_per_turn`; tur sonu sırası | Ekonomi adımını çağırır (gelir + düşman takviyesi + bakım); 4. adımda sayaçları sıfırlar | Sıra: Harita · İçerik: Kaynak |
| Ordu (`army-system.md`) | — | Üretim `army_count`'u artırır; garnizon ve hareket kuralları değişmez | Kaynak |
| Kök Böri / Ruh (`spirit-system.md`) | Bölge başına üretim çarpanı (bozulma), lütuf gelir bonusları (`B_add`, `M_g`) | — (Ruh'a dokunmaz) | Çarpanlar: Ruh · Uygulama: Kaynak |
| Savaş (`combat-system.md`) | — | — (dolaylı: üretilen ordu savaşa girer) | — |
| Oyun Durumu (`GameState`) | — | `gold` (yalnızca veri) | Kaynak |
| Bölüm verisi (`ChapterMapDefinition`) | `starting_gold`, `enemy_reinforcement_per_turn` | — | Kaynak (ayar) |
| Katmanlı Düşman (`enemy-layers.md`, yazılmadı) | — | Düşman takviyesini devralır (geçici) | Gelecekte: Katmanlı Düşman |
| HUD / Bilgi paneli | — | Altın, tahmini gelir (+X/tur), Ordu Topla (maliyet, kalan tavan) | UI (§10) |

---

## 4. Formulas

Değerler 2026-10-08'de systems-designer + economy-designer önerileri ve kuralları
birebir uygulayan bir Prolog simülasyonuyla seçildi (aday A). C-29 sonrası modelle
(nötr canavar, düşmansız Prolog) **C-49**'da (2026-10-19) yeniden doğrulandı; bu GDD'nin
değerleri değişmedi (aşağıdaki doğrulama).

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
| Ham gelir | `I_raw` | int | 0–75 | Oyuncu bölgelerinin `G_eff` toplamı (Final: 15 bölge × 5) |
| Toplamsal lütuf bonusu | `B_add` | int | 0–10 | Ruh sisteminin tanımladığı düz bonus: Bereket yığını × 1 (M1'de tipik 0–1) |
| Çarpımsal lütuf çarpanı | `M_g` | float | 1.0–2.0 | Ruh sisteminin tanımladığı yüzde bonus; MVP 1.0 |
| Gelir tabanı | `I_floor` | int | 0–3 | Kayıp sonrası toparlanma güvencesi; **MVP 0** |
| Tur geliri | `I_turn` | int | 0–100 | Ekonomi adımında hazineye eklenir |

**Çıktı aralığı:** Prolog'da 2 (yalnızca Otağ) ile 10 (tam fetih) arası.
**Örnek:** Otağ + Bereket Vadisi → `I_raw = 2 + 3 = 5` → `max(0, floor(5 × 1.0)) = 5`.
**Bereket (C-31 kararı):** düz bonus — yığın başına **+1 altın/tur** (`B_add`,
`spirit-system.md` §3.5). Küçük tam sayılarda %10 yuvarlamada kaybolur
(`floor(5 × 1.1) = 5`); +1 her zaman görünür. `M_g` formülde kalır (gelecekteki
yüzde kaynakları için), MVP'de 1.0.

### F3 — Bölge üretim tavanı

`recruit_cap = max(R_min, G_eff)`

| Değişken | Sembol | Tip | Aralık | Açıklama |
| --- | --- | --- | --- | --- |
| Efektif gelir | `G_eff` | int | 0–5 | F1'in çıktısı |
| Asgari tavan | `R_min` | int | 0–2 | Her obanın verebileceği en az yiğit; MVP 1 |
| Tavan | `R_cap` | int | 0–5 | O bölgenin bir turda verebileceği en fazla birlik (MVP `R_min = 1` iken 1–5; `R_min = 0` ise 0 olabilir) |

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
| Birlik maliyeti | `recruit_cost` | int | 1–4 | **Sabit 2 altın** (MVP; güvenli aralık §7) |

**Örnek:** 6 altınla Otağ'da 2 birlik (tavan 2) → 4 altın harcanır, 2 kalır.

### F5 — Başlangıç altını

`gold₀ = starting_gold`. Değer bölüm verisinden gelir; **Prolog'da 6**. Bu, tavan
sınırına takılmadan üç birliklik bir başlangıç demek.

### F6 — Düşman takviyesi

Ekonomi adımında her düşman bölgesi `i` için: `army_i += E_r`. **Prolog'da E_r = 1,
ama boştadır:** Prolog'da `ENEMY` bölgesi yoktur (C-49 kararı — siyasi katman nötr boy
garnizonlarıdır; takviye ilk kez Perde 1'de çalışır).

| Değişken | Sembol | Tip | Aralık | Açıklama |
| --- | --- | --- | --- | --- |
| Takviye | `E_r` | int | 0–3 | `enemy_reinforcement_per_turn` (bölüm verisi) |

**Örnek (genel, Prolog dışı):** orduları 1 ve 3 olan iki düşman bölgesi, `E_r = 1` ile
ekonomi adımından sonra 2 ve 4 ordu olur (AC10).

### F7 — Bakım gideri (MVP'de etkisiz)

`upkeep = max(0, A_total − A_free) × U`; ödenen miktar `min(upkeep, gold)`.

| Değişken | Sembol | Tip | Aralık | Açıklama |
| --- | --- | --- | --- | --- |
| Toplam ordu | `A_total` | int | 0–200 | Oyuncunun tüm bölgelerindeki ordunun toplamı |
| Ücretsiz eşik | `A_free` | int | 0–30 | Bakım ödenmeyen ordu miktarı; varsayılan 10 |
| Birlik başı bakım | `U` | int | 0–2 | **MVP 0** |

### Prolog doğrulaması (C-49, 2026-10-19)

Model: C-29 sonrası Erlik katmanı + C-49 kararları — Canavarın İni **nötr, garnizon 0,
seviye 3** (tek `erlik_foci`); Doğu Obası **öğretici bozulma** (nötr, garnizon 0, seviye 1);
Prolog'da `ENEMY` bölgesi yok (F6 boşta); `ERLIK_SPREAD_INTERVAL = 3`; kayıp = **Erlik'in
Gölgesi** `erlik_power ≥ 9` (`region-map-system.md` §3.6, `spirit-system.md` §4.7). Yöntem:
kuralları birebir uygulayan elle simülasyon (her satır iki kez hesaplandı) + bağımsız tekrar
betiği `tools/balance/prolog_sim.py` (2026-10-19: 12/12 eşleşme); referans
çizgilerinin tur tur tabloları, kurallar ve bütçe kanıtı
[`design/balance/prolog-balance-2026-10-19.md`](../balance/prolog-balance-2026-10-19.md)'de.
Otomatik tekrar (gerçek controller'larla) C-64.

**Prolog verisi** (C-36 bu değerlerle yazılır; bir değer değişirse tablo yeniden üretilir):

| Bölge (`region_id`) | Sahip | Garnizon | `gold_per_turn` | Bozulma | Komşular |
| --- | --- | --- | --- | --- | --- |
| Oğuz Otağı (`otuken`) | Oyuncu | 5 | 2 | 0 | Batı, Doğu, Kutlu Dağ, Bereket |
| Batı Obası (`bati_bozkir`) | Nötr | 3 | 1 | 0 | Otağ, Kutlu Dağ, Bereket |
| Doğu Obası (`dogu_bozkir`) | Nötr | **0** | 1 | **1** (öğretici) | Otağ, İn |
| Kutlu Dağ (`altai`) | Nötr | 2 | 2 | 0 | Otağ, Batı |
| Bereket Vadisi (`guney_vadi`) | Nötr | 0 | 3 | 0 | Otağ, Batı, İn |
| Canavarın İni (`sinir_bolge`) | Nötr | **0** | 1 | **3** (odak) | Doğu, Bereket |

Başlangıç: 6 altın, Ruh 0, `erlik_power = 4`; tam fetih geliri 10. Zafer: 4 nötrden 3'ü
(Doğu Obası arındırılınca sayılır) + inin arındırılması.

| Çizgi | Sonuç | Ruh / lütuf | Not |
| --- | --- | --- | --- |
| **A — en hızlı** | **T5 zafer** (tur ortası) | 30 → 1 lütuf (zaferde) | T1 2 üret + Kutlu Dağ (6 > 2); T2 Bereket; T3 Batı (4 > 3); T4 Batı → Bereket birleştir; T5 Bereket 14 → in (13 > 12). T4 zafer imkânsız (aksiyon + konum bütçesi, rapor §4) |
| E1 — öğretici bölge önce | T7 zafer | 50 → 1 lütuf, 20 Ruh taşınır | T1 Doğu Obası (6 > 4, +10); T3 yayılımıyla bozulan Bereket T5'te arındırılır (+10) |
| **E3 — Erlik'le ilgilenen** | T8 zafer | 30 → **sahne ortası lütuf (T7)**; in +30/36 | Doğu Obası T3'te L2 olur, T5'te 9 > 8 (+20); T6'da yeniden L1, T7'de arındırılır (+10) |
| **C — fethet, Erlik'i yok say** | **T15 sonunda kayıp** | 0 | T1–T3 = A, sonra yalnızca üretim; `erlik_power` 5 / 6 / 7 / 8 / 9 (T3 / 6 / 9 / 12 / 15) |
| P(w) — ilk w tur yalnızca Otağ'da üretim | w = 0 / 3 / 6 / 8 / 9 / 12 → T5 / T8 / T11 / T13 / T14 / T17 zafer | 30–50 → 1 lütuf | Büyük Otağ yığını bozulmuş Bereket'i arındırıp sayacı geri iter |
| P(13) | Uyarıyı (8/9) yok sayarsa **T15 kayıp**; önce arındırırsa T19 zafer | 60 → 1 lütuf | Sütun 3'ün zorladığı karar |
| Tamamen pasif | **T15 sonunda kayıp** | 0 | Zombi oyun yok |
| Üretim olmadan (2026-10-08 kodu) | Kazanılamıyor (çapraz inceleme B1) | — | Değişmedi |

**Değerlendirme:** en hızlı zafer T5 (C-34 tahmini ≈ T6; eski düşmanlı modelde T4). Hata
toleransı eski modelden (≤ 6 boş tur) bilinçli olarak geniştir (≤ 12 boş tur): Prolog
öğreticidir, siyasi baskı Perde 1'de başlar; Prolog baskısı Erlik'in Gölgesi'dir — hiç
arındırmayan oyuncu T15'te kaybeder, uyarı (8/9) T12'de görünür. Tipik oyun 8–12 tur,
konseptteki 10–18 tur penceresinin içinde. Referans çizgilerinde en büyük ordu 23 (P(13));
yalnızca üreten "C" çizgisinde 42 (UI 3 hane — §5). Tur geliri hiçbir referans çizgisinde
2'nin altına düşmedi (bozulmuş Otağ bile 1 verir) → `I_floor = 0` Prolog'da yeterli.

Eski model (C-28, düşman inli): kusursuz T4; 2 / 4 / 6 boş tur → T5 / T11 / T16; 8+ boş tur
→ 18 turda kazanılamıyor. Karşılaştırılan eski adaylar (takviye yalnız ine, başlangıç 4
altın, `ceil(G_eff / 2)` tavan) git geçmişinde.

**1. tur örneği (C-49):** Oyuncu 6 altınla başlıyor. Otağ'da 2 birlik üretiyor (−4 altın),
6 orduyla Kutlu Dağ'ın 2'lik garnizonuna saldırıyor: 6 > 2, kayıp `ceil(2 × 0.5) = 1`,
Kutlu Dağ 5 orduyla oyuncunun. Tur sonu: düşman yok, yayılım yok (1 < 3), gelir 2 + 2 = 4 →
hazine 6. *Alternatif:* aynı 6'lık kuvvet Doğu Obası'na → arındırma 6 > 4, +10 Ruh, Doğu'da
`6 − 2 = 4` kalır (gelir 3). Üretmeden 4'le girilirse 4 ≤ 4 → başarısız, 4 birlik kaybolur
(hamle önizlemesi uyarır — `spirit-system.md` §3.2).

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
- **Ordusu 0 olan düşman bölgesi:** Oluşmaz — beraberlikte boşalan bölge sahipsiz
  olur (`army-system.md` §3.3, C-33/W3); sahipsiz bölge takviye almaz.
- **Nötr bölgeler:** Gelir de takviye de almaz. Oyuncu ele geçirene kadar ordusu
  sabittir.
- **Bakım gideri altını aşarsa** (yalnızca `U > 0` olduğunda): Mevcut altın
  ödenir ve hazine 0 olur. Kalan borç silinir; birlik dağıtılmaz, borç birikmez.
- **Üst sınırlar:** Altında ve orduda üst sınır yoktur; C-49 Prolog referans çizgilerinde
  en büyük ordu 23, zafere gitmeden yalnızca üreten çizgide (T15 Erlik kaybına kadar) 42
  oldu (§4). UI 3 haneye kadar gösterir; daha büyük değerler tasarım dışıdır ve ayar hatası
  sayılır.
- **Düşmansız bölüm (Prolog):** `ENEMY` bölgesi yokken F6 hiçbir şey eklemez;
  `enemy_reinforcement_per_turn` değeri durumu değiştirmez (C-49).
- **Sahne sonu:** Harcanmamış altın silinir (§3.1 R8). Sonraki sahne kendi
  `starting_gold` değeriyle açılır.
- **Düşman turunda üretim:** Mümkün değildir. Üretim yalnızca oyuncunun turunda
  yapılabilir.
- **Oyun bittikten sonra** (`region-map-system.md` §3.7, `game_result ≠ ONGOING`):
  üretim reddedilir.
- **Bozuk bölgedeki garnizonu güçlendirmek:** Yerinde üretim (R4) arındırma girişimi
  değildir; bozuk bölgeye ordu *göndermek* ise arındırma girişimidir (`army-system.md`
  §3.3). Bozuk kendi bölgesini korumak isteyen oyuncu orada üretir (tavan `G_eff`
  bozulmayla düştüğü için en az `R_min`).
- **Ekonomi adımı sırası:** Önce oyuncu geliri, sonra düşman takviyesi, sonra
  bakım. Bu üç işlem birbirini etkilemediği için sıra sonucu değiştirmez.

---

## 6. Dependencies

### Bu sistemin dayandıkları (yukarı akış)

| Sistem | Tür | Arayüz |
| --- | --- | --- |
| Harita / Tur Akışı (`region-map-system.md`) | **Sert** | Bölge sahipliği ve `gold_per_turn` (`MapState`). Tur sonu sırasında ekonomi adımı (3. adım) ve sayaç sıfırlama (4. adım). Bölüm verisi `ChapterMapDefinition`: `starting_gold`, `enemy_reinforcement_per_turn`. |
| Kök Böri / Ruh (`spirit-system.md`) | Yumuşak | Bölge başına bozulma çarpanı `M_c`, lütuf bonusları `B_add` ve `M_g`. Ruh sistemi yoksa değerler `M_c = 1`, `B_add = 0`, `M_g = 1` olur ve sistem tam çalışır. |

### Bu sisteme dayananlar (aşağı akış)

| Sistem | Tür | Arayüz |
| --- | --- | --- |
| Ordu (`army-system.md`) | **Sert** | Üretim `army_count`'u artırır. Ordunun büyüyebildiği tek kaynak bu sistemdir. |
| Harita / Tur Akışı — düşman tarafı | **Sert** | Düşman takviyesi (F6) ekonomi adımında uygulanır. |
| Kök Böri / Ruh (`spirit-system.md`) | Yumuşak | Bereket (`B_add`) bu sistemin gelir formülünden (F2) geçer. Sürü Kutsaması kilitli: sürü formülü tanımlanınca (§3.1, Açık Soru 3) bağlanır. |
| HUD / Bilgi paneli | Sert | Altın, tahmini gelir, Ordu Topla kontrolü (§10). |
| Kayıt / Yükleme (ADR-0007) | Sert | Tur sonu otomatik kayıt: `gold` saklanır; bölge üretim sayaçları 4. adımda sıfırlandığı için kayıt anında hep 0'dır (yüklemede 0 başlatılır); tur ortası kayıt yok. |
| Sahne Akışı (`scene-flow.md`, C-35) | Sert | Her sahne başında `gold = starting_gold` kurar (R8), sahne sonunda (COMMIT) altın 0'lanır, taşınmaz; Yeniden Dene aynı `starting_gold` ile sıfırdan başlar (AC16). |
| Katmanlı Düşman (`enemy-layers.md`, yazılmadı) | Gelecek | Düşman takviyesini devralacak (geçici sözleşme). |

### Diğer GDD'lerde gereken karşı güncellemeler

✅ **Tamamlandı (C-28, 2026-10-08)** — liste tarihsel kayıt olarak duruyor.
Çift yönlü bağımlılık kuralı gereği (C-28 kapsamında yapıldı):

1. **`army-system.md` §6:** Kaynak sistemi bağımlılık olarak eklenecek. §7'deki
   "ordu bakım maliyeti (planlı)" notu bu GDD'nin F7'sine işaret edecek.
2. **`region-map-system.md`:**
   - §4'teki gelir formülü bu GDD'nin F2'sine yönlendirilecek; gelirin sahibi
     artık bu GDD.
   - §3.4'ün ekonomi adımı (artık 3.) "ekonomi adımı (gelir + düşman takviyesi + bakım)" olarak
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
| `starting_gold` | 6 | 0–20 | T1 üretimi küçülür, en hızlı zafer T5'ten geç kalır (C-64 ile ölçülmeli); < 2 → T1'de üretim yok, Doğu Obası T1'de arındırılamaz (4 ≤ 4); 0 → ilk tur üretimsiz | Erken turların geliri değersizleşir | Erlik eşiği ve yayılım aralığıyla birlikte affediciliği belirler (§4 doğrulaması) |
| `enemy_reinforcement_per_turn` | 1 (**boşta** — Prolog'da `ENEMY` yok, C-49) | 0–3 | 0 → siyasi baskı yok | 2+ → birkaç tur boşa harcanınca kazanılamaz (kontrol edilmeli) | Düşmanlı bölümlerde (Perde 1+) yayılım hızıyla birlikte baskıyı belirler |

### Başka sistemlerin sahip olduğu değerler (burada tekrar tanımlanmaz)

| Değer | Sahibi | Bu sisteme etkisi |
| --- | --- | --- |
| Bölge `gold_per_turn` | `region-map-system.md` (bölge verisi) | Hem geliri (F1) hem üretim tavanını (F3) belirler |
| `CORRUPTION_PRODUCTION_MULTIPLIERS` | `spirit-system.md` | Bozulma çarpanı `M_c` |
| `B_add`, `M_g` (lütuflar) | `spirit-system.md` | Tur geliri (F2) |

**Kritik etkileşim:** Başlangıç altını, düşman takviyesi (düşmanlı bölümlerde) ve Erlik
tarafı (`ERLIK_SPREAD_INTERVAL`, `erlik_loss_threshold`, başlangıç bozulması —
`spirit-system.md` §7, `region-map-system.md` §7) birlikte oyuncunun ne kadar hata tolere
edebileceğini belirler. Birini değiştirirken §4'teki doğrulama tablosu yeniden üretilmelidir
(C-64 aracı).

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
- **AC8:** **GIVEN** üretim sayaçları tükenmiş, **WHEN** `end_turn` 4. adımı (yeni tur
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
  **WHEN** ekonomi adımı (3. adım) çalışır, **THEN** o bölge de +1 takviye alır.
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

- **AC15** (C-49 — §4 verisi ve [balance raporu](../balance/prolog-balance-2026-10-19.md)
  referans çizgileri; otomatik: `tests/integration/balance/prolog_balance_test.gd`, C-64):
  - **GIVEN** §4 Prolog verisi, **WHEN** A çizgisi oynanır, **THEN** `game_won` 5. turun
    hamlesinde gelir, Ruh = 30 ve sahne sonu sunumu bekler; hiçbir hamle dizisi 4. turda
    zafer üretmez (C-64 arama).
  - **WHEN** C çizgisi oynanır (T1–T3 = A, sonra yalnızca üretim, hiç arındırma yok),
    **THEN** `erlik_power` T3/T6/T9/T12/T15 sonlarında 5/6/7/8/9 olur ve 15. turun
    `end_turn`'ünde `game_lost` bir kez tetiklenir.
  - **WHEN** oyuncu ilk 8 tur yalnızca Otağ'da üretir ve sonra rapordaki P(8) çizgisini
    oynar, **THEN** zafer 13. turda gelir ve `erlik_power` hiçbir tur sonunda 8'i aşmaz.
  - **WHEN** E3 çizgisi oynanır, **THEN** 7. turda (inden önce) Ruh ≥ 30 olur ve lütuf
    sunumu sahne ortasında bekler.
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
- **Uygulama (C-66, 2026-10-20):** "2 kare" = art bible §7 UI karesi (0.05 sn) × 2 = 0.1 sn renk
  vurgusu (`ValueFeedback.FLASH_SEC`). Rengin tek başına anlam taşımaması için fark metni
  (`↑+X` / `↓-X`) vurgudan uzun, 1.5 sn görünür (`DELTA_HOLD_SEC`); HUD'da altın değerinin hemen
  ardından, gelir tahmininden önce. Haritada yalnız ordu **artışı** bildirilir (düşman takviyesi
  dahil: `Ordu: 4 ↑+1`); azalış hareket/savaş sonucudur, vurgulanmaz. İlk çizim (bağlam açılışı,
  kayıt yüklemesi) geri bildirim üretmez. SFX kimlikleri `recruit` / `income` (`SfxLibrary`).
- **Font notu:** Kayıp işareti `−` (U+2212) pixel fontta yok (C-09 notu); azalmalar
  `↓` ikonuyla gösterilir.

---

## 10. UI Requirements

- **HUD üst bar:** `Altın: X (+Y)`. Y, mevcut sahipliğe göre F2'nin tahmini
  değeridir. Sayılar `NumberFormatter` ile biçimlenir. Tahmin, tur sonunda gelirden
  önce çalışan düşman AI ve Erlik yayılımını (region-map §3.4 adım 1–2) yansıtmaz;
  yayılım hedefi deterministik olduğundan UX bunu ayrıca gösterebilir (C-41/C-45).
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
| 1 | ~~Bereket lütfu düz bonus mu (+1 altın/tur), yüzde mi (%10)?~~ **Çözüldü (C-31, 2026-10-18):** düz +1 altın/tur, yığın başına (`B_add`). | Kullanıcı / game-designer | C-31 ✅ |
| 2 | ~~Prolog simülasyonu (§4) repoya alınsın mı, AC15 otomatik testle mi kontrol edilsin?~~ **Çözüldü (C-64, kullanıcı onayı 2026-10-19):** `tools/balance/prolog_sim.py` (kural tekrarı) repoda kalır; AC15 gerçek controller'larla `tests/integration/balance/prolog_balance_test.gd` (12 çizgi + T4 araması) | Kullanıcı | C-64 ✅ |
| 3 | Sürü ne zaman etkinleşir ve neyi besler/tüketir? Konsept "nüfus ve ordu büyümesi" diyor. | game-designer | Perde 1 tasarımı |
| 4 | Katmanlı Düşman GDD'si takviyeyi devraldığında düşman ekonomisi simetrik mi olacak? | game-designer | `enemy-layers.md` |
| 5 | Toparlanma mekanizması ve bakım gideri (çapraz inceleme D1/D2): `I_floor` ve `U` açılsın mı? | Kullanıcı | İlk Prolog playtesti |
| 6 | ~~Sahne ortası kayıtta altın ve üretim sayaçları nasıl saklanacak?~~ **Çözüldü (ADR-0007, 2026-10-18):** yalnızca tur sonu otomatik kayıt; altın ve üretim sayaçları tur sonunda oturmuş haliyle JSON'a yazılır, tur ortası kayıt yok. | technical-director | C-16 ✅ |
| 7 | ~~Kusursuz oyunla 4 turda zafer öğretici için fazla hızlı mı?~~ **C-49 (2026-10-19):** en hızlı T5, Erlik'le ilgilenen oyun T7–T8, tipik 8–12 tur; ihmal T15'te kaybettirir. Kalan soru playtestte: tipik ilk oyuncu gerçekten 10–18 turda mı bitiriyor? | Kullanıcı | C-42 playtesti |
