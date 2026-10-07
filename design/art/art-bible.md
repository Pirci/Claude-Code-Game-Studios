# Art Bible — ASENA: Path of the Sky Wolf

> **Durum**: Tamamlandı — 9/9 bölüm onaylandı (2026-10-07)
> **Sanat yönü**: Pixel art (2026-10-07'de sulu boyadan geçildi)
> **Teknik çerçeve**: 640×360 base, integer scaling, nearest filter —
> bkz. `.claude/docs/technical-preferences.md` → Display & Scaling
> **Art Director Sign-Off (AD-ART-BIBLE)**: Atlandı — Lean inceleme modu (2026-10-07)

---

## 1. Görsel Kimlik Bildirgesi

### Tek Satırlık Görsel Kural

> **"Her piksel bir bozkır kiliminin ipliği gibi — sade, keskin ve kalıcı; ama
> bir araya geldiğinde Oğuz'un destanını, Ülgen'in ışığını ve Erlik'in
> gölgesini dokur."**

Her ekran geometrik ama canlı bir kilim yüzeyi gibi hissettirmeli. Piksel grid,
bozkırın el dokuma kilimlerinin doğal yapısıdır; tamga sembolleri ve kozmik
motifler bu dokumanın içine işlenir. Organik akışkanlık yerine **geometrik
saflık ve simgesel güç** öndedir — her piksel kasıtlıdır, her form bir tamga
gibi anında tanınır.

### Destekleyici Görsel İlkeler

#### 1. Kozmik İkilik Piksel Dilinde Konuşur

Ülgen'e ait her şey (arındırılmış topraklar, göksel güç, Kök Böri) **parlak,
keskin kenarlı, altın-indigo ışık pikselleriyle** vurgulanır; Erlik'in bozgunu
(çürüyen bölgeler, körmös, karanlık) **mor-siyah lekeler, titreyen dithering ve
düzensiz kenarlarla** ifade edilir. Oyuncu bir bölgeye bakar bakmaz "arındırılmış
mı, bozulmuş mu?" sorusunu renk ve doku farkıyla cevaplayabilmeli.

- **Tasarım testi:** Bir bölge hem fethedilmiş hem bozulmuşsa iki katman görsel
  olarak çatışmalı — dokunmuş kilim üzerinde bir leke gibi. Leke, sahiplik
  rengini silmez; üstüne biner.
- **Bağlı sütun:** İki Katmanlı Tehdit.

#### 2. Kök Böri Varlığı Işıkla İşaretlenir

Gök kurt Kök Böri kritik anlarda (prolog, sahne başı, zafer) **parlayan
gök-mavisi/beyaz piksellerle**, yarı saydam olarak belirir. Hiçbir zaman
haritadaki bir birim gibi katı hatlarla çizilmez — ışık parçacıkları, titreşen
parlama ve kesintili çizgilerle doğaüstü olduğu ayrışır. Profil silueti, lütuf
seçimi ve ruh göstergesi gibi her kritik etkileşimde tekrar eden ilahi motiftir.

- **Tasarım testi:** Kök Böri ekrana geldiğinde oyuncu "doğaüstü varlık" ile
  "haritadaki birim"i anında ayırt edebilmeli — ayıramıyorsa ışık/saydamlık yetersiz.
- **Bağlı sütun:** Destanı Yaşa.

#### 3. Okunabilirlik Her Pikselden Önce Gelir

Her varlık (birim, bölge, UI öğesi) **minimum piksel, maksimum tanınabilirlik**
kuralına uyar. Gereksiz detay gürültüsü, karmaşık dithering ve süsleme yasaktır.
Küçük bir birim sprite'ında yalnızca "bu bir süvari" değil, "bu bir Oğuz
süvarisi ve şu an sağlam" okunabilmeli.

- **Tasarım testi:** Yeni bir oyuncu ilk 10 saniyede haritada hangi bölgenin
  kimin olduğunu ve tehdidin nerede olduğunu anlayabilmeli — anlamıyorsa detay azalt.
- **Bağlı sütun:** Epik Ama Erişilebilir.

### Pixel Art Konumlandırması

ASENA **low-bit disiplin ile orta-bit palet** arasındadır: her asset basit,
ikonik ve hızla okunur; ama kozmik atmosfer için renkler katmanlıdır — **asset
başına 16–32 renk, toplam ~64–128 renklik global palet**. Bu seviye solo
üretim için sürdürülebilir ve kozmik ikiliği taşımaya yeter.

- **Dithering:** Sadece gölge geçişleri, ışık efektleri ve Erlik bozulması için.
  Düz yüzeylerde dithering yok; alanlar temiz renk bloklarıdır.
- **Outline politikası:** Birimler, karakterler ve UI öğeleri **1 piksel koyu
  outline** taşır (okunabilirlik). Harita zemini, arka planlar ve atmosferik
  öğeler outline'sızdır — ama yumuşak/organik değil, **geometrik dokuma
  blokları** halinde (kilim kuralı); sınırlar renk değişimiyle çizilir.
- **Kimlik:** Görsel dili Batı-fantastik pixel art'tan ayıran şey Türk
  mitolojik kimliğidir — tamga UI, kilim dokusu, deel kırmızısı vurgusu.
  Referans kaynaklar ve neyin alınıp neyin alınmayacağı → Bölüm 9.

## 2. Ruh Hali ve Atmosfer

### Atmosfer Felsefesi

Pixel art'ta atmosfer gerçek zamanlı ışıkla değil; **palet ısısı, value
(açık-koyu) aralığı, renk katmanlaması, seçici parlama pikselleri ve dithering**
ile kurulur. Her oyun durumu ayrı bir duygusal iklimdir ve diğerlerinden görsel
olarak ayrışır.

> **Okunabilirlik kuralı (bağlayıcı):** Oyun bilgisi — sahiplik rengi, bozulma
> durumu, birim konumu, seçim — atmosfer tarafından asla bastırılamaz.
> Atmosfer **zemin ve arka plan katmanında** yaşar; oyun öğeleri kontrastla
> ayrışır. Ton kaydırma (`CanvasModulate` / palet swap) **yalnızca zemin ve arka
> plan CanvasLayer'ına** uygulanır; bilgi katmanı (bölge sahiplik dolguları,
> birimler, ikonlar, UI) boyanmaz.

### Oyun Durumları

**Ana Menü** — *Sakin beklenti: destanın kapısındasın, henüz yola çıkmadın.*

- Işık: gün batımı sıcaklığı, yumuşak kontrast; krem-altın zemin, indigo
  gölgeler; value aralığı geniş ama sert siyah yok.
- Sıfatlar: dingin, davetkâr, mitsel, ılık. Enerji: tefekkürlü.
- Taşıyıcı öğe: arka planda soluk indigo-gri Kök Böri silueti (~%30 opaklık),
  kenarlarda altın hatlı tündük motifi.

**Kampanya Haritası — Normal Tur** — *Odaklı kontrol: "buradaki her karar bana ait."*

- Işık: öğleden sonra aydınlığı, orta-yüksek kontrast; nötr zemin tonu,
  sahiplik renkleri doygun ve açık.
- Sıfatlar: net, berrak, stratejik, kontrollü. Enerji: ölçülü.
- Taşıyıcı öğe: bölge sınırları **renk değişimiyle** okunur (outline yok —
  Bölüm 1); seçili/üzerine gelinen bölge 1px açık kontur alır. Bozulma varsa
  leke olarak üstüne biner, sahiplik rengini gizlemez.

**Kampanya Haritası — Erlik Bozgunu Yoğun** — *Baskı altında aciliyet: "ne kadar zamanım var?"*

- Işık: soğuk, gölge ağırlıklı, yüksek kontrast; zemin katmanı mora kayar.
  Temiz bölgeler kontrastı korumak için altın-indigo ışıltıyla **daha parlak**.
- Sıfatlar: tehditli, baskılayıcı, çürümüş, gergin. Enerji: telaşlı.
- Taşıyıcı öğe: mor-siyah lekeler **yavaş animasyonlu dithering** ile "nefes
  alır" — yalnızca zemin katmanında, 2–4 kare/sn, küçük genlik. Temiz alanların
  kenarında altın parlama pikselleri (Ülgen'in direnci).

**Savaş Raporu** — *Ağırbaşlı analiz: "ne oldu, ne kaybettim, ne kazandım?"*

- Işık: nötr, dengeli, orta kontrast; krem-gri zemin, koyu kahve metin; ton kaydırma yok.
- Sıfatlar: ciddi, nesnel, sade. Enerji: tefekkürlü.
- Taşıyıcı öğe: 1–2px kilim kenar motifi çerçeve; geometrik kayıp/kazanç
  çubukları. Kazanç/kayıp ayrımı renge ek olarak ikon/şekille verilir (renk
  körlüğü — Bölüm 4).

**Kök Böri Belirişi / Lütuf Seçimi** — *Saygılı huşu: ilahi bir an, dikkatle seç.*

- Işık: göksel parlaklık, uç kontrast; koyu indigo-siyah zemin, gök-mavisi/beyaz kurt.
- Sıfatlar: ilahi, parlak, sessiz, saygıdeğer. Enerji: tefekkürlü ama yüklü.
- Taşıyıcı öğe: yarı saydam Kök Böri, dithering ile titreyen kenarlar; üç lütuf
  seçeneği 1–2px altın haleyle; arka planda soluk indigo kilim motifi.

**Sahne İntro/Epilog İllüstrasyonu** — *Destanın kalıcılığı: "bu an tarihe geçti."*

- Işık: sahneye özel ama hep dramatik (Prolog gün doğumu altın-turuncu, Batı
  soğuk mor, Final altın-indigo), yüksek kontrast.
- Sıfatlar: epik, anıtsal, dokunaklı, resmî (destan belgesi gibi). Enerji: durağan.
- Taşıyıcı öğe: tam ekran 640×360 illüstrasyon (asset üst sınırı ~32 renk),
  kilim zemin, koçboynuzu/tündük kenarlar, filigran Kök Böri; metin altta koyu
  zemin üzerinde açık renk.

**Zafer** — *Gurur ve tatmin: "bu zaferi hak ettim."*

- Işık: sıcak altın, yüksek kontrast, karanlık çok az.
- Sıfatlar: görkemli, sıcak, göğe yükselen. Enerji: coşkulu ama ağırbaşlı.
- Taşıyıcı öğe: merkezde beyaz-altın parlamalı Kök Böri, altın çerçeveli metin.

**Yenilgi** — *Ağır kayıp: "burada bitti — bedeli öğrendim."*

- Işık: soğuk gri-mor, düşük kontrast, hiç altın yok (Ülgen geri çekilmiş).
- Sıfatlar: hüzünlü, ağır, sönen. Enerji: tefekkürlü.
- Taşıyıcı öğe: %15–20 opaklıkta, kenarları dithering ile dağılan gri Kök Böri.

**Final: Miras / Bölünme** — *Hüzünlü zafer: "kazandım, şimdi devrediyorum."*

- Işık: çift katman — altın (zafer) ve mor (bölünme) aynı ekranda; geniş value aralığı.
- Sıfatlar: epik, anıtsal, çift tonlu, kalıcı. Enerji: tefekkürlü ama yüklü.
- Taşıyıcı öğe: ortada altın-beyaz Kök Böri, çevresinde daire halinde **altı
  oğul ikonu — hepsi eşit parlaklıkta** (destandaki eşit miras; oyuncunun
  yatırımı metin/istatistikle gösterilir). Köşelerde dört yönün renkleri.

### Dört Yönün Görsel Ayrışımı

Yönler harita zemini ve zemin katmanı ton kaydırmasıyla ayrışır; geçişte palet
kayması hissedilir ama global palet sınırları içinde kalınır.

| Yön | Palet vurgusu | Ton | Işık | Doku / taşıyıcı öğe |
| --- | --- | --- | --- | --- |
| **Doğu (Cürcet)** | Yeşil-altın orman | İlk büyük sefer, güç kanıtı | Sabah, sıcak, orta-yüksek kontrast | Dithering yapraklar; **çürümüş orman lekeleri ve körmös** (Erlik'in ilk somut yüzü) |
| **Batı (Urum)** | Mor-siyah, çürümüş toprak | En karanlık sınav, Erlik en yoğun | Alacakaranlık, soğuk, en yüksek kontrast | Mor dithering çürüme; Kök Böri parlaması kontrast için daha keskin |
| **Kuzey (İtil/Ural)** | Beyaz-mavi buz | Doğaya karşı dayanıklılık | Kış ışığı, soğuk, yüksek value | Açık mavi-beyaz kar dokusu; Erlik'in kışı |
| **Güney (Sındu/Şam)** | Turuncu-kahve kum | Zaferin eşiği, sıcak yorgunluk | Öğle güneşi, kurak, orta kontrast | Kum ve kurak zemin; kuraklık/hastalık ruhları |

## 3. Şekil Dili

### Silüet Felsefesi: Her Birim Bir Tamga Gibi Okunur

640×360'ta haritadaki bir birim ~12–16 piksel yüksekliğindedir; bu ölçekte
renk olmadan da "bu bir süvari" okunabilmeli. **Şekil = kimlik**, renkten önce
gelir (Bölüm 1, İlke 3). Her birim tipi **2 renkli (siyah-beyaz) silüet
testini** geçmelidir.

| Birim | Ayırt edici özellik | Şekil imzası | Boyut önerisi* |
| --- | --- | --- | --- |
| **Süvari** | At + binici, yatay genişlik | Genişlik yüksekliğin ~1.2–1.4 katı; baş üstte, geniş at gövdesi ortada | ~12×16 |
| **Okçu** | Dik duruş, yay hattı | Dar, dik dikdörtgen; omuzlar hafif dışa açık | ~10×14 |
| **Ağır piyade** | Kare gövde, kalkan | Kübik; geniş omuz, sağlam ayak; en ≈ boy | ~12×14 |
| **Kahraman (Oğuz)** | +2px boy, belirgin başlık | Süvari tabanlı, tepede 2–3px doruk (miğfer boynuzu/tüy) | ~14×18 |

\* Kesin boyut tablosu → Bölüm 8.

**Oyuncu / düşman / Erlik ayrımı (yalnızca renkle değil — renk körlüğü):**

- **Oyuncu birimleri:** simetrik, dik duruş, düzenli 1px koyu outline.
- **Kral birimleri:** benzer arketip silüeti, farklı kültür detayı (miğfer
  formu, silah tipi, koşum biçimi).
- **Erlik körmösleri:** asimetrik, doğal olmayan anatomi (çift baş, fazla uzuv,
  bükük omurga); outline yer yer kesintili/titrek; zemine tam değmez
  (1–2px havada, yarı saydam).

*Tasarım testi:* 12px yükseklikte yan yana 6 birim — süvari, okçu ve körmös
yalnızca siyah silüetle ayırt edilebilmeli.

### Ortam Geometrisi: Kilim Dokuması Kuralı

Harita zemini, arka planlar ve bölge poligonları **geometrik ve köşelidir**;
organik akışkan eğri yasaktır. Bağlı sütunlar: Epik Ama Erişilebilir (geometrik
sadelik öğrenmeyi kolaylaştırır), Modüler İnşa (poligonlar data-driven; harita
verisi kenar açılarını kısıtlar).

**Bölge poligon grameri:**

1. **Kenar açıları:** yalnızca yatay, dikey, 1:1 (45°) ve 2:1 / 1:2 piksel
   adımları. Serbest eğri yok.
2. **Sınır = renk teması:** bölgeler arasında çizgi/outline yoktur; sınır, iki
   komşu dolgunun doğrudan temasıyla okunur (Bölüm 1). Seçili/üzerine gelinen
   bölge 1px açık kontur alır (Bölüm 2).
3. **Kenarlar sadedir; kilim deseni bölgenin iç dokusundadır.** Kenarlara köşe
   süsü/şevron uygulanmaz — harita (Final'de 15 bölge) sade ve okunur kalır.
4. **İç doku:** bölge dolgusu düz tek renk değil, 2–4 renkli kilim deseni
   (şevron, baklava, petek). Dithering yalnızca zemin katmanında; birim, ikon ve
   etiketlerin altında desen sakinleşir (okunabilirlik kuralı).

**Arındırılmış vs bozulmuş toprak:** Bölge şekli haritanın sabit coğrafyasıdır
ve **bozulmayla değişmez**. Erlik bozgunu, poligonun üstüne binen bir **leke
katmanıdır**:

| Durum | Doku | Leke kenarı | Hareket |
| --- | --- | --- | --- |
| **Arındırılmış (Ülgen)** | Simetrik, düzenli kilim deseni, 2 renk | — | Statik |
| **Bozulmuş (Erlik)** | Desenin üstünde mor-siyah leke, 3–4 renk dithering | Tırtıklı/dişli, düzensiz — ama yine piksel adım kurallarına uyar | Yavaş animasyon (2–4 kare/sn, Bölüm 2) |

*Tasarım testi:* Gri tonlamalı ekranda yan yana arındırılmış ve bozulmuş iki
bölge ayırt edilebilmeli (leke dokusu + kenar düzensizliği).

### UI Şekil Grameri: Tamgadan Piksele

UI dünyanın estetiğini **yankılar** ama haritadan ayrışır: statik, okunaklı,
hızla tanınır. Mevcut temel (keskin köşe, 1px kenarlık) doğrudur.

| Motif | UI kullanımı | Piksel boyutu | Yer |
| --- | --- | --- | --- |
| **Tamga** | Sahiplik ikonu | 7×7 / 9×9 | Bölge merkezi, birim bayrağı |
| **Koçboynuzu** | Çerçeve köşe süsü | 5×5 / 7×7 | Panel ve birincil buton köşeleri |
| **Tündük** | Merkez/ilahi ikon | 16×16 / 24×24 | Ana menü, lütuf seçim paneli |
| **Kilim şevronu** | Panel kenar bandı | 2px yükseklik, kesintisiz tile | Rapor/panel çerçeveleri |

- Köşe süsleri tek sayı boyutlu (3/5/7) — merkez piksel simetrisi.
- İkonlar 7×7 / 9×9 / 16×16; tüm UI öğelerinde 1px koyu outline.
- **Birincil aksiyon** (Tur Bitir, Saldır): 5×5 koçboynuzu köşe süsü, düz dolgu,
  1px kontrast kenarlık. **İkincil** (Geri, İptal): süs yok, daha düşük kontrast.
- **Panel çerçeveleri:** 2px kilim bandı, köşelerde 5×5 koçboynuzu/tündük.
- **Harita HUD:** yarı saydam koyu zemin (~%70), 1px altın kenarlık, köşe süsü
  yok — haritayı kapatmaz.

*Tasarım testi:* Ana menü ve oyun HUD'u yan yana — ikisi de Türk mitolojik
kimliği taşımalı ama karışmamalı (menü süslü, HUD sade).

### Kahraman vs Destekleyici Şekiller

| Katman | Öğe | Yükseklik | Outline | Kontrast |
| --- | --- | --- | --- | --- |
| 1 — en baskın | Kök Böri (ilahi an) | 32–48 px | Yok, parlama | Maksimum (gök-mavisi/beyaz, koyu zemin) |
| 2 — oyuncu odağı | Seçili bölge, kahraman | 16–18 px | Seçili: 1px açık kontur; kahraman: 1px koyu | Yüksek |
| 3 — oynanabilir | Standart birimler, oyuncu bölgeleri | 10–14 px | 1px koyu | Orta |
| 4 — bağlam | Düşman ve nötr bölgeler | 10–14 px | 1px koyu (birimler) | Orta-düşük |
| 5 — zemin | Harita dokusu, arka plan | — | Yok | Düşük |

**Kök Böri'nin şekil imzası:** hiçbir zaman katı outline yok — yarı saydam,
dithering kenarlı (2 kare görünür↔soluk); kurt profili, kuyruk yukarı, baş
ileri, kenarlar ışık parçacıklarına dağılır; haritadaki her birimden 2–3 kat
büyük (≥32px). Ekranın geri kalanı kararırken o parlar.

### Pixel Art Çizgi Disiplini

- **Köşegenler:** 1:1, 2:1 / 1:2; uzun çizgilerde tutarlı 3:1 / 1:3. Tek bir çizgi
  parçasında adım oranı karıştırılmaz.
- **Jaggies yasak:** bir çizgi veya eğride adım uzunlukları düzensiz değişmez
  (1-2-1-3 gibi). Eğriler adım uzunluğunu monoton artırıp azaltarak çizilir
  (1-1-2-3-3-2-1-1).
- **Doubles yasak:** çizgiye hem kenardan hem köşeden temas eden, onu yer yer 2px
  kalınlaştıran fazla piksel (L köşe) temizlenir; 1px çizgi her noktada 1px kalır.
- **Anti-alias:** manuel AA yalnızca büyük statik görsellerde (illüstrasyon, menü
  Kök Böri, ≥24px ikon), en fazla 1 ara ton. Harita birimleri ve <16px UI
  ikonlarında AA yasak (hareket/animasyonda titreşir).

*Tasarım testi:* 12px birim sprite'ı 2× büyütmede net okunmalı, bulanık değil.

## 4. Renk Sistemi

### Renk Felsefesi

Renk sınırlı bir kaynaktır; her ton bir anlam taşır. Global palet **rampalar**
halinde düzenlenir ve **hue-shift'lidir**: koyu tonlar soğuğa/mora (Erlik'in
gölgesi), açık tonlar sıcağa/altına (Ülgen'in ışığı) kayar. Düz siyah/beyaza
lineer karartma ve saf gri yasaktır. Bir asset içinde en fazla 2–3 rampa kullanılır.

### Global Palet

| Rampa | Tonlar (koyudan açığa) | Rol |
| --- | --- | --- |
| **Keçe Krem** | `#1C170F` `#3D3426` `#5C4F3A` `#8A7A5E` `#B8A689` `#D4C4A3` `#F2E6C7` | Arka plan, kâğıt/keçe doku, nötr zemin; birincil metin (açık uç) |
| **Deri Kahve** | `#0D0A06` `#1C150D` `#3A2817` `#5C4229` `#8A6D4F` `#B8945D` | Outline, kontur, kilim kenar deseni, UI panel zemini ve kenarlığı |
| **Ülgen Altını** | `#3D2E0A` `#6B4F12` `#9A7020` `#C99A3D` `#EDC76B` `#F5DE9E` `#FFF4D4` | İlahi ışık, arındırma ışıltısı, zafer, birincil aksiyon, seçim konturu |
| **Ülgen İndigosu** | `#0A0D1C` `#141A33` `#1F2B52` `#2E4178` `#425AA8` `#6B87C9` `#A3B8E8` | Gök katmanı, gece göğü, ilahi an zemini, ana menü arka planı |
| **Kök Böri Gök Mavisi** | `#0A1A29` `#14334D` `#1F5278` `#2E7AB8` `#47A3E8` `#87C4F5` `#D4EDFF` | Kök Böri varlığı, **oyuncu sahiplik rengi**, lütuf konturu |
| **Erlik Moru** | `#120A14` `#1F0F26` `#33173D` `#522961` `#7A3D8F` `#A86BC4` | **Yalnızca Erlik:** bozulma lekesi, körmös, Erlik yoğun zemin tonu |
| **Erlik Kömürü** | `#050505` `#0F0D0E` `#1A1719` `#2E292B` `#47423F` `#6B6561` | Karanlık, ölüm, bozulmuş toprak dokusu, körmös gövdesi |
| **Deel Kırmızısı** | `#240A0A` `#3D1414` `#661F1F` `#992E2E` `#CC4747` `#E87A7A` `#FFADAD` | Oğuz vurgusu (bayrak, kahraman, konsey ikonları); UI uyarı/hata (açık uç) |
| **Pas Turuncusu** | `#2B1208` `#4D200F` `#7A3318` `#9A4220` `#C45A2A` `#E07E45` `#F5A970` | **Düşman kralların sahiplik rengi** (tüm krallar) |
| **Bozkır Yeşili** | `#0F140A` `#1A2614` `#2B3D1F` `#436129` `#5C8A3D` `#87B85C` `#B8D49E` | Arındırılmış/sağlıklı toprak zemini, başarı rengi |
| **Orman Koyu Yeşili** | `#070D05` `#0F1A0D` `#1A2E17` `#294726` `#3D6B3D` `#5C8F5C` | Doğu (Cürcet) zemini, derin orman |
| **Buz Mavi-Beyazı** | `#0D1419` `#1A2B3D` `#2E4761` `#476B8F` `#6B99C4` `#A3C4E8` `#D4E8FF` | Kuzey (İtil/Ural) zemini, kar, buz |
| **Kum** | `#1C140A` `#3D2914` `#614729` `#8A6B47` `#B89E6B` `#D4C49E` `#F5E8CC` | Güney (Sındu/Şam) zemini, çöl, kurak toprak |
| **Keçe Grisi** | `#1A1814` `#2E2A24` `#4A453C` `#6B655A` `#8F897D` `#B5AFA3` `#D9D4C8` | Nötr bölge, devre dışı UI — saf gri değil, sıcak keçe grisi |

**Toplam ~94 renk** (14 rampa). Bir sahnede aktif kullanım ~64–72.

### Semantik Renk Sözlüğü

| Renk | Bu dünyada anlamı | Neden |
| --- | --- | --- |
| **Altın** | Ülgen'in ışığı, göksel otorite, arındırma, zafer | Altay kozmolojisinde Ülgen ışıkla, güneşle bağlıdır; altın han/kağan rengidir. |
| **İndigo** | Gök katmanı, Ülgen'in evi, huşu | Tengri/gök inancı; gece göğü, yıldızlar, derin sessizlik. |
| **Gök mavisi** | Kök Böri, ilahi rehberlik — ve onun koruduğu **oyuncu toprakları** | "Kök/Gök" kurt; oyuncunun bölgesi Kök Böri'nin himayesindedir (Destanı Yaşa). |
| **Mor** | **Sadece Erlik:** kaos, çürüme, doğal olmayan | Mor hiçbir siyasi tarafa verilmez — İki Katmanlı Tehdit'te doğaüstü katmanın tek sahibi. |
| **Siyah/kömür** | Yokluk, gölge, yeraltı | Erlik'in evi yeraltıdır; ışığın yokluğu, Ülgen'in geri çekilmesi. |
| **Turuncu (pas)** | Düşman krallar — siyasi, dünyevi rakip | Hiçbir kozmik anlamla çakışmaz; mavi oyuncu ile renk körlüğünde en güvenli ikili. |
| **Kırmızı (deel)** | Oğuz'un ateşi, hayat gücü — **vurgu**, sahiplik dolgusu değil; açık tonları UI uyarı/hata | Deel kırmızısı Oğuz'un sembolüdür; düşmana verilmez. |
| **Yeşil** | Sağlıklı/arındırılmış toprak, kazanç | Bozkırın restore edilmiş düzeni. |
| **Krem/keçe** | Saflık, boş tuval, metin | Keçe ve yün dokuma — bozkır kültürünün doğal zemini. |
| **Kahve/toprak** | Dayanıklılık, yapı, çizgi | Deri, keçe, ağaç — kilim ve outline'ın malzemesi. |

**Kazanç/kayıp:** kazanç = yeşil + `↑` + "+X"; kayıp = açık kırmızı + `↓` + "−X".
Renk tek başına taşımaz.

### Sahiplik Renkleri (Harita)

Sahiplik dolguları **opaktır** (yarı saydam yasak — zeminle karışıp palet dışı
ton üretir) ve kilim deseni için 3 tonluk mini rampa kullanır.

| Sahip | Ana renk | Mini rampa (koyu / ana / açık) | Renk körlüğü yedeği |
| --- | --- | --- | --- |
| **Oyuncu (Oğuz)** | Gök mavisi `#47A3E8` | `#2E7AB8` / `#47A3E8` / `#87C4F5` | Simetrik kilim deseni + oyuncu tamgası (7×7, bölge merkezi) |
| **Düşman kral (tümü)** | Pas turuncusu `#C45A2A` | `#9A4220` / `#C45A2A` / `#E07E45` | Krala özel tamga + krala özel kilim deseni (data-driven) |
| **Nötr** | Keçe grisi `#6B655A` | `#4A453C` / `#6B655A` / `#8F897D` | Desensiz düz dolgu, tamga yok |
| **Erlik bozgunu** (katman) | `#33173D` + `#1A1719` | `#1A1719` / `#33173D` / `#522961` (dithering) | Tırtıklı leke kenarı + yavaş animasyon + düşük uğultu sesi |
| **Seçili / üzerine gelinen** | Ülgen altını `#EDC76B` | — (1px kontur, dolgu değil) | Kontur + köşelerde 2px `◆` + tık sesi |

- Krallar renkle değil **tamga ve desenle** ayrılır; aynı sahnede iki kral
  (ör. Batı: Urum + Kıl Barak) aynı turuncu ailede, farklı tamgayla durur.
- Bozulma sahiplik rengini **gizlemez, üstüne biner** (Bölüm 1, İlke 1).
- **Harita etiketleri** (bölge adı, ordu sayısı) krem `#F2E6C7` + **1px koyu
  kontur** (`#1C170F`) ile çizilir. Gerekçe: krem metnin gök mavisi dolgu
  üzerindeki kontrastı yalnızca 2.2:1'dir; kontur her dolguda okunabilirliği
  garanti eder.

### Yön Başına Sıcaklık (Zemin Katmanı Ton Kaydırma)

Ton kaydırma yalnızca zemin `CanvasLayer`'ına uygulanır (Bölüm 2). Hex değerleri
**başlangıç değeridir — prototipte birim/etiket okunabilirliğine göre ayarlanır.**

| Yön | Zemin rampaları | Başlangıç modulate | Işık |
| --- | --- | --- | --- |
| **Doğu (Cürcet)** | Orman Koyu Yeşili + Bozkır Yeşili | `#C4D4A3` | Sabah, sıcak, orta-yüksek kontrast |
| **Batı (Urum)** | Erlik Moru + Erlik Kömürü | `#52475C` (bozulma ≥%50 → `#3D334D`, data-driven) | Alacakaranlık, soğuk, en yüksek kontrast |
| **Kuzey (İtil/Ural)** | Buz Mavi-Beyazı + Keçe Grisi | `#D4E8FF` | Kış, soğuk, yüksek value |
| **Güney (Sındu/Şam)** | Kum + Keçe Krem | `#F5E8CC` | Öğle, sıcak, orta kontrast |

### UI Paleti

UI dünya paletinden türer; daha az ton, daha yüksek kontrast. Hedef WCAG AA:
metin ≥4.5:1, UI bileşen kenarları ≥3:1. Oranlar panel zemini üzerinde
**hesaplanmıştır**.

| Öğe | Hex | Kontrast (panel zemini üzerinde) | Kullanım |
| --- | --- | --- | --- |
| Panel zemini | `#1C150D` (Deri Kahve) | — | Tüm paneller, HUD (haritada ~%70 opak) |
| Birincil metin | `#F2E6C7` | 14.7:1 | Metin, etiket, buton yazısı |
| İkincil metin | `#B8A689` | 7.7:1 | Açıklama, alt başlık |
| Devre dışı metin | `#6B655A` | 3.2:1 (kasıtlı düşük) | İnaktif öğe |
| Kenarlık | `#8A6D4F` | 3.8:1 | 1px panel/buton kenarlığı, ayırıcı |
| Vurgu / birincil aksiyon | `#EDC76B` | 11.3:1 | Tur Bitir, Saldır; başlık (HeaderLabel) |
| Hover | `#F5DE9E` | 13.7:1 | Üzerine gelme |
| Başarı | `#87B85C` + `✓`/`↑` | 7.8:1 | Arındırma, kazanç |
| Uyarı | `#E87A7A` + `⚠` | 6.5:1 | "Erlik yayılıyor", tehlike |
| Hata | `#FFADAD` + `✕` | 10.3:1 | Geçersiz hamle, yetersiz kaynak |

Uyarı ve hata aynı aileden olduğu için **ikonla** ayrılır. Metne outline
uygulanmaz (harita etiketleri hariç — yukarıda).

### Renk Körlüğü Güvenliği

| Semantik çift | Risk | Zorunlu yedek |
| --- | --- | --- |
| Oyuncu (mavi) vs düşman (turuncu) | Düşük (en güvenli ikili) | Tamga + desen yine zorunlu |
| Düşman (turuncu) vs nötr (keçe grisi) | Orta (value yakın: 1.3:1) | Nötr desensiz ve tamgasız; düşman desenli ve tamgalı |
| Kazanç vs kayıp | Deuteranopi/protanopi | `↑`/`↓` ikonu + "+/−" rakam |
| Arındırılmış vs bozulmuş | Tritanopi | Tırtıklı leke kenarı + dithering + animasyon + ses |
| Ülgen altını vs Kök Böri mavisi | Tritanopi | Kök Böri: kurt silüeti + titreyen parlama; altın: statik |
| Erlik moru vs Ülgen indigosu | Tritanopi | Erlik: düzensiz kenar + dithering + uğultu; Ülgen: düz geometrik |
| Seçili vs normal | Hafif | Kontur + `◆` köşe işareti + tık sesi |
| Uyarı vs hata | Aynı aile | `⚠` / `✕` ikonu |

- **Bağlayıcı test:** harita, savaş raporu ve lütuf ekranları renk körlüğü
  simülatöründe (Color Oracle vb.) doğrulanır; iki semantik öğe ayrışmıyorsa
  yedek eksiktir.
- **Erişilebilirlik ayarı — "Renk Körlüğü Modu":** açıkken tamgalar bölge
  merkezinde her zaman görünür (normalde sadece seçilince) ve sahiplik
  bölgeleri ek 1px kontur alır.

### Uygulama Notu (koda yansıyacaklar)

Mevcut geçici değerler bu bölüme göre güncellenecek: `region_node.gd` yarı
saydam sahiplik renkleri → opak mini rampalar (oyuncu mavi / düşman pas / nötr
keçe grisi); harita etiketlerine 1px koyu kontur; `default_theme.tres` ve
`generate_ui_theme_icons.gd` paleti → UI paleti tablosu (panel zemini
`#1C150D`, kenarlık `#8A6D4F`).

## 5. Karakter Tasarım Yönü

### Üç Detay Katmanı

Her karakter üç ölçekte aynı özü taşır; küçük ölçekte her piksel kasıtlıdır.

| Katman | Boyut | Korunan | Atılan |
| --- | --- | --- | --- |
| **Harita sprite** | 10–18 px | Silüet, sahiplik rengi, 1–2 tanıtıcı detay (miğfer doruğu, yay) | Yüz, kumaş dokusu, süsleme |
| **Portre** | ~24×32 px | Yüz (göz/alın/sakal), sembol, kıyafet tipi | Kumaş detayı, arka plan bağlamı |
| **İllüstrasyon** | ≥64 px figür (640×360 sahne içinde) | Yüz ifadesi, kumaş, arazi, kozmik ışık | — |

### Oğuz Kağan

Doğaüstü işaretlerle doğmuş ata-kahraman: ağırbaşlı, doğal liderlik.

- **Kimlik her ölçekte aynı:** **gök mavisi deel** (oyuncu rengi) + **deel
  kırmızısı kuşak/omuz vurgusu** (Oğuz'un ateşi) + boynuzlu miğfer/sorguç.
- **Harita (~14×18):** süvari tabanlı, sıradan süvariden +2px boy ve 2–3px
  doruk ile ayrışır.
- **İllüstrasyon/portre:** geniş alın, koyu gözler, seyrek sakal (genç ama olgun);
  arkada soluk altın hale (Ülgen). İllüstrasyon başına ≤32 renk.

### Oyuncu Birimleri

| Birim | Silüet | Renk | Kültürel detay |
| --- | --- | --- | --- |
| **Süvari** | At + binici, yatay (~12×16) | Gök mavisi kumaş, kahve deri koşum | At başında püskül, hafif zırh |
| **Okçu** | Dar, dik (~10×14), yay hattı belirgin | Gök mavisi üst, kahve alt | Kompozit yay silüeti |
| **Ağır piyade** | Kare gövde (~12×14), kalkan | Gök mavisi kaftan, koyu kahve kalkan | Dikdörtgen kalkan |

Tüm birim sprite'ları 1px koyu outline (`#1C170F`).

### Altı Oğul (Konsey)

Haritada birim değil; yalnızca UI portresi (~24×32) ve Final illüstrasyonunda
(daire düzeni) görünürler. **Ortak yüz tabanı + kendi sembolü ve renk vurgusu**
ile ayrışırlar (24×32'de yüz farkı zaten zor okunur). İfade statik, ağırbaşlı.

| Oğul | Sembol | Vurgu | Renk |
| --- | --- | --- | --- |
| **Gün** | Güneş diski (8×8) | Alında altın disk | `#EDC76B` |
| **Ay** | Hilal (7×7) | Omuzda hilal | `#D4C4A3` |
| **Yıldız** | Yıldız (5×5) | Göğüste yıldız | `#C99A3D` |
| **Gök** | Bulut (7×7) | Kaftanda gök motifi | `#425AA8` |
| **Dağ** | Dağ (7×7) | Omuzda dağ tamgası | `#5C4229` |
| **Deniz** | Dalga (7×7) | Kuşakta dalga | `#47A3E8` |

Semboller konsey bonusu ikonu olarak HUD'da da kullanılır. Portre zemini panel
zemini (`#1C150D`), 1px altın kenarlık.

### Düşman Krallar

Hepsi **pas turuncusu** ailesinde (Bölüm 4); renkle değil **tamga + kültürel
detay** ile ayrışır. Tamgalar data-driven (`tamga_id` → 7×7 doku). Miğfer/silah
detayı sprite'ın 2–3 pikselinde — ince ama ayırt edici. Detay renkleri yalnızca
nötr/dünya rampalarından seçilir; **mor ve Erlik kömürü kullanılmaz**.

| Kral | Tamga | Miğfer | Silah / koşum | Detay rengi |
| --- | --- | --- | --- | --- |
| **Cürcet Kağan (Doğu)** | Baklava ◈ | Sivri doruklu | Kısa yay, hafif koşum | Orman yeşili kuşak |
| **Urum Kağan (Batı)** | Çarpı ⊠ | Yuvarlak tepeli | Ağır kalkan | Demir (Keçe Grisi) |
| **Kıl Barak (Batı)** | Çift üçgen ▲▼ | Kürklü | Uzun mızrak | Koyu Deri Kahve |
| **Kuzey kağanları** | Kar tanesi ❅ | Düz kürk başlık | Ağır kürk | Buz mavisi |
| **Güney kralları** | Üç dişli çatal ⋔ | Tüy süslü | Kavisli kılıç | Kum |

(Güneş diski Gün Han'ın sembolüdür — düşmana verilmez.)

### Erlik'in Ruhları (Körmös)

Ortak aile kuralları — diğer tüm birimlerden ayrışma:

- **Asimetrik, doğal olmayan anatomi:** bir kol uzun bir kol kısa, eğik baş,
  çarpık omurga.
- **Zemine değmez** (1–2px havada); **yarı saydamlık %50 dama deseni
  dithering** ile verilir (alfa harmanlama palet dışı renk üretir).
- **Kesintili outline:** 2px çiz, 1px boşluk ritmi.
- Palet: Erlik Moru + Erlik Kömürü; varyant başına tek bir vurgu rengi.
- Boyut: standart birimle aynı (~10–14px).

**Her varyant ayrı çizilir** — silüetleri belirgin biçimde farklı, aile kuralları ortak:

| Körmös | Yön | Silüet imzası | Vurgu |
| --- | --- | --- | --- |
| **Orman ruhu** | Doğu | Dal gibi uzun, ince uzuvlar | `#1A2E17` |
| **Çürüme ruhu** | Batı (temel körmös) | Eriyen, damlayan gövde; en "saf" Erlik formu | `#522961` |
| **Kış ruhu** | Kuzey | Çift baş, buz kristali omuzlar | `#2E4761` |
| **Kuraklık ruhu** | Güney | Kemikli, çatlamış kuru gövde | `#3D2914` |
| **Hastalık ruhu** | Güney | Şiş gövde, sızan lekeler | `#7A3D8F` |

**Erlik canavarları (boss — ör. Prolog'daki tek boynuzlu canavar):** körmös aile
kurallarını taşır, 2–3 kat boyutta (~32–40px); tek, okunur bir imza uzvu (boynuz).

### Kök Böri

- **Form:** yan profil kurt, kuyruk ~45° yukarı, baş ileri, kulaklar dik.
  Haritada/lütuf ekranında 32–48px; illüstrasyonda ≥128px.
- **İmza:** outline yok, kenarlar ışık parçacıklarına dağılır; gök mavisi
  `#47A3E8` → beyaz `#D4EDFF` dithering geçiş, altın `#EDC76B` hale. Alfa
  saydamlık yalnızca koyu ilahi sahnelerde serbest.
- **Poz seti:** profil (varsayılan — lütuf ekranı, sahne başı), cephe (Final,
  altı oğulla), iniş (Prolog — gökten ışık çizgileriyle iner, kanat yok).
- **Renk:** yalnızca gök mavisi + indigo + beyaz + altın. Kahve/kömür/mor asla.

### Poz, İfade ve Animasyon Bütçesi

- **Poz stili:** katı, ağırbaşlı, anıtsal — destan belgesi. Abartılı hareket yok.
- **Harita sprite'ları tek yön (sağa bakan) çizilir;** sola bakış `flip_h` ile
  (negatif scale yasak — technical-preferences).
- **Birim başına bütçe:** idle 2 kare, hareket 2 kare, saldırı 2–3 kare →
  **6–7 kare/birim**.
- **Körmös:** 2 kare idle (titreme), hareket kare animasyonu yok (süzülür — tween).
- **Kök Böri:** 2 kare görünür↔soluk (2 sn döngü); ilahi an sahnelerinde statik.
- **Portreler:** statik, tek ifade.

## 6. Ortam Tasarım Dili

### Doku Felsefesi: Kilim Dokulu Flat Pixel

- **Painted değil:** yumuşak fırça ve gradyan yok — piksel grid keskindir (Bölüm 1).
- **PBR değil:** malzeme/ışık simülasyonu yok — mitolojik soyutlama (Bölüm 2).
- **Kilim:** bozkırın el dokuma kimliği; geometrik sadelik ve zengin sembolizm bir arada.

### Kilim Desen Kütüphanesi

Desenler 8×8 veya 16×16 **kesintisiz tile**'dır ve **mini rampa tonlarıyla
opak** çizilir (yarı saydam desen katmanı yok — palet dışı renk üretir).
Birim/etiket yoğun alanlarda desen sakinleşir (Bölüm 1).

| Desen | Şekil | Kullanım |
| --- | --- | --- |
| **Petek** | Altıgen grid | **Oyuncu bölgeleri** — düzen, Ülgen (simetrik) |
| **Şevron, baklava ve türevleri** | Zikzak / karo | **Düşman bölgeleri** — her krala özel varyant (data-driven) |
| **(desensiz)** | Düz dolgu | **Nötr bölgeler** (Bölüm 4) |
| **Eli belinde** | Simetrik figür | Başkent ve kutsal alan bölgeleri (bindirme) |
| **Koçboynuzu** | Kıvrımlı spiral | **Yalnızca UI** (köşe süsü) — haritada kullanılmaz |
| **Şevron bandı** | 2px zikzak | **Yalnızca UI** panel kenarı (bölge kenarları sadedir — Bölüm 3) |

Fetihte bölgenin deseni yeni sahibininkine geçer.

### Mimari ve Yapılar

**Oğuz tarafı (bozkır):**

| Yapı | Boyut | Şekil imzası | Haritadaki rol |
| --- | --- | --- | --- |
| **Otağ** | ~24×24 | Dairesel taban, sivri tepe, kırmızı kapı, tündük çatı | Başkent ikonu |
| **Yurt** | ~16×12 | Kubbe gövde, keçe doku | Şehir ikonu |
| **Balbal** | ~8×12 | Dik taş, tepede ~3×3 yüz | Arındırılınca dikilir |
| **Ongun direği** | ~6×16 | İnce direk, tepede ~4×4 at başı | Bozulunca kırılır |
| **Tündük** | 16×16 ikon | Daire + 4–8 radyal çizgi, altın | UI ve otağ üstü |

Oğuz yapıları kubbeli/yuvarlak hatlıdır (yurt), düşman yapıları köşeli. Kubbeler
**piksel adım kurallarıyla** çizilen eğrilerdir (Bölüm 3) — "organik eğri
yasağı" zemin ve bölge geometrisi içindir, nesne silüetleri için değil.

**Düşman kültürleri:**

| Kültür | Tanıtıcı yapılar | Şekil |
| --- | --- | --- |
| **Cürcet (Doğu)** | Ahşap kule (~16×20), ağaç köprü | Dik, köşeli ahşap |
| **Urum (Batı)** | Taş kale (~20×24), duvar burcu | Kare, ağır taş |
| **Kıl Barak (Batı)** | Kürklü çadır | Asimetrik, vahşi |
| **Kuzey (İtil/Ural)** | Kütük ev (~12×12), keçe çadır, kayık (~10×6) | Basık, düz çatı |
| **Güney (Sındu/Şam)** | Kare taş kule (~14×18), kervan çadırı | İnce, yüksek |

Yapı renkleri dünya rampalarındandır; **mor leke yalnızca bozulmuş bölgede**
bindirme olarak görünür.

### Harita Prop Yoğunluğu

**Bölge başına en fazla 3–5 öğe:** 1 şehir/otağ ikonu (merkez), 1–2 kaynak ikonu
(altın/sürü, kenara yakın), 0–1 Erlik odağı (bozulmuş bölge), 0–2 balbal/ongun
(çevresel anlatım). *Test:* haritaya 3 sn bak — sahiplik, bozulma ve şehirler
okunuyorsa yoğunluk doğru.

**Bölgeler dışı alan:** düz renk bırakılmaz; **yönün zemin rampasının koyu
tonları** + hafif desen + seyrek **statik** süs prop'ları (küçük taş ~3×3, çimen
~4×4, 1px noktalı yol izi). 640×360 ekranda ~20–30 prop. Süs prop'ları
animasyonsuzdur — hareket anlamlı yerlere ayrılır (Erlik lekesi, Kök Böri,
arındırma).

### Çevresel Anlatım (metinsiz hikâye)

| Detay | Bozulmuş (Erlik) | Arındırılmış (Ülgen) | Geçiş |
| --- | --- | --- | --- |
| **Balbal** | Devrik / yok | Dik | 4 kare dikilme |
| **Ongun direği** | Kırık, tepesiz | Tam, at başı tepede | Altın parçacıkla onarılma |
| **Zemin** | Mor leke, tırtıklı kenar | Temiz kilim deseni | Leke katmanı çekilir |
| **Yapılar** | Duvarda leke, çatı ~2px çökmüş | Temiz, düz çatı | Lekeler silinir |

- **Fetih:** bölge merkezindeki tamga oyuncununkine, dolgu turuncudan gök
  mavisine, desen petek desenine geçer.
- **Erlik yayılımı:** leke katmanı her tur görünür biçimde büyür; yavaş animasyon
  (2–4 kare/sn) ve düşük uğultu sesi eşlik eder.

### Dört Yönün Ortam İmzaları

| Yön | Zemin | Tanıtıcı prop'lar | Erlik izi |
| --- | --- | --- | --- |
| **Doğu (Cürcet)** | Orman Koyu Yeşili + yaprak tile | Ağaç (~12×20), ahşap köprü, yaprak yığını | Mor lekeli çürümüş ağaçlar, orman ruhu |
| **Batı (Urum)** | Keçe Grisi + en yoğun leke | Taş kale burcu, devrik balbal, kırık ongun | Lekenin en geniş hali, çürüme ruhu en sık |
| **Kuzey (İtil/Ural)** | Buz Mavi-Beyazı + kar tile | Buz kristali (~8×10), kayık, don tutmuş ağaç | Koyu mavi buz çatlakları, kış ruhu |
| **Güney (Sındu/Şam)** | Kum + kum tile | Hurma ağacı (~8×14), akasya, kum tepesi, kervan çadırı | Kuraklık çatlakları, kuraklık ve hastalık ruhları |

Prop'lar zemin tonuna uyar ama sahiplik renkleriyle (mavi / turuncu) çakışmaz.

## 7. UI/HUD Görsel Yönü

### HUD Yaklaşımı

**Ekran alanı HUD — ama dünyanın malzemesiyle (tamga, kilim, keçe) inşa
edilmiş.** Diegetik UI 640×360'ta haritaya fazla katman ekler (Bölüm 1, İlke 3);
strateji oyuncusu "stratejist bakışı" oynar. HUD'un kimliği Türk mitolojik
estetiğidir; dünyanın içinde olması gerekmez.

### Tipografi

- **Fontlar:** Fusion Pixel 12px (Latin/Kiril/zh/ja/ko), GNU Unifont 16px
  (Arapça — dil `ar` iken tüm tema Unifont'a geçer). Font boyutları **yalnızca
  native veya tam katı:** Fusion 12/24/36, Unifont 16/32. Ara boyut yasak.
- **Hiyerarşi boyutla değil renkle:** gövde ve butonlar 12px (Arapça 16px);
  başlık vurgusu `HeaderLabel` (altın `#EDC76B`); ikincil metin `#B8A689`.
  24px yalnızca özel tek başlıklar (sahne adı, rapor başlığı); 36px yalnızca oyun
  adı "ASENA" (Latin, her dilde Fusion zinciri — keskin kalır).
- **Arapça:** tek gövde boyutu (16px), hiyerarşi yalnızca renkle; 32px yalnızca
  özel başlık.
- **Büyük harf:** büyük harfli metin çeviri dosyasında doğrudan büyük yazılır;
  programatik `to_upper()` kullanılmaz (Türkçe i→İ / ı→I, Almanca ß→SS tuzakları).
- **Sayılar:** Arap rakamı (Roma rakamı yok). Kazanç `+123` + `↑` (yeşil), kayıp
  `−45` + `↓` (açık kırmızı). Binlik ayırıcı dile göre çeviri key'inden gelir
  (tr/de `.`, en `,` …) — `TranslationServer.format_number()` gruplama yapmaz
  (Godot 4.7'de doğrulandı).

### İkonografi

- **Izgara:** 7×7 / 9×9 (harita), 16×16 (UI), 24×24 (panel merkezi); tek sayı
  boyutlar merkez piksel simetrisi için. 1px koyu outline (`#1C170F`), ikon başına
  4–6 renk, yalnızca global palet.
- **Kaynaklar (9×9):** altın = sikke (`#EDC76B`/`#C99A3D`); sürü = stilize at
  başı (`#8A7A5E`); ruh = cepheden kurt başı (`#47A3E8`).
- **Durum (7×7):** `✓` başarı, `⚠` uyarı, `✕` hata, `↑` kazanç, `↓` kayıp (renkler Bölüm 4).
- **Tamgalar (7×7):** oyuncu tamgası sabit (Oğuz "kaşu" işareti); kral tamgaları
  data-driven (`tamga_id` → doku). Bölge merkezinde sahiplik belirteci.

### Panel Sistemi

9-slice çerçeve: kenar = 2px kilim şevron bandı, köşe = 5×5 koçboynuzu (birincil)
veya düz (ikincil/HUD), merkez = düz dolgu, 1px kenarlık `#8A6D4F`.

| Panel | Zemin | Kenarlık | Köşe | Kullanım |
| --- | --- | --- | --- | --- |
| **HUD** | `#1C150D` ~%70 opak | 1px `#8A6D4F` | Yok | Üst/alt bar, bölge bilgi paneli |
| **Modal** | `#1C150D` opak | 1px `#8A6D4F` + kilim bandı | 5×5 koçboynuzu | Savaş raporu, ayarlar |
| **İlahi** | `#0A0D1C` opak | 2px `#EDC76B` | 7×7 tündük | Kök Böri lütuf seçimi |
| **Konsey** | `#1C150D` opak | 1px `#8A6D4F` | Altı oğul sembolleri | Konsey ekranı |

**Butonlar:** birincil (Tur Bitir, Saldır) = kenarlık + 5×5 koçboynuzu köşe,
altın hover; ikincil (Geri, İptal, menü) = kenarlık, süs yok. Basılınca içerik
1px aşağı (mevcut tema). Butonlar uzun çevirilerde genişler (`custom_minimum_size.x`
ile taban genişlik, ör. Tur Bitir ≥64px).

### UI Animasyonu

Pixel grid bozulmaz: **kesirli ölçek (scale tween) ve alfa fade yasak** (mixel ve
palet dışı renk üretir).

- **Ekran/panel geçişi:** tam piksel adımlı kaydırma (`Discrete` güncelleme) veya
  4 karelik **dither geçişi** (%100→%75→%50→%25 dama maskesi) veya düz kesme.
- **Buton:** basma 1px içerik kayması; hover renk değişimi (anlık).
- **Lütuf kartları:** sırayla belirir (kart başına 4 kare dither + 2 kare bekleme,
  toplam ~0.3 sn); seçilince 1px altın kontur + `◆`.
- **HUD sayı değişimi:** 2 kare renk vurgusu (artış yeşil, azalış kırmızı) —
  boyut değişmez.

### Ekranlar

- **Ana menü:** indigo `#141A33` zemin, soluk Kök Böri silüeti, kenarlarda altın
  tündük; "ASENA" 36px altın; birincil buton süslü, diğerleri sade.
- **Harita HUD:** üst bar (bölüm adı / altın / tur) ve alt bar (Ana Menü / Tur
  Bitir) **%70 opak koyu zemin** üzerinde; sağda 136px bölge bilgi paneli. HUD
  sade, harita odakta.
- **Savaş raporu:** opak modal, kilim bandı, koçboynuzu köşeler; kazanç/kayıp
  listesi ikon + rakam + renk; geometrik çubuklar; "Devam" birincil.
- **Lütuf ekranı:** zemin katmanı koyu indigoya kayar; ilahi panelde Kök Böri
  (32–48px) ve üç lütuf kartı (~80×100; 24×24 ikon, 12px başlık/açıklama).
- **Konsey:** altı portre (~24×32), adı ve bonus satırı; törensel.
- **İntro/epilog:** tam ekran 640×360 illüstrasyon, altta koyu panelde 12px krem
  metin, yavaş tam piksel kaydırma.

### Harita Okunabilirliği (UX kuralları)

- **Bölge adı etiketleri her zaman görünür** (destan coğrafyasını öğretir);
  ayarlardan gizlenebilir. 15 bölgelik Final haritasında prototipte yeniden
  değerlendirilir.
- **Etiketler:** krem + 1px koyu kontur (`LabelSettings`, Bölüm 4); uzun
  çeviriler `…` ile kısaltılır; çevirmen kuralı — bölge adı ≤12 karakter (en),
  diğer dillerde mümkün olan en kısa karşılık.
- **Seçili bölge:** 1px altın kontur + köşelerde 2px `◆`.
- **Tamga ikonu** bölge merkezinde.
- **Klavye odağı:** 1px altın kenarlık (mevcut); dinamik oluşturulan butonlar
  (ör. Ordu Gönder) `focus_neighbor_*` ile odak zincirine bağlanır.

### Erişilebilirlik Ayarları (zorunlu)

| Ayar | Etki |
| --- | --- |
| **Renk Körlüğü Modu** | Tamgalar hep görünür, sahiplik bölgeleri ek 1px kontur (Bölüm 4) |
| **Hareketi Azalt** | Erlik lekesi ve Kök Böri animasyonları durur (orta kare sabit), arındırma anında tamamlanır, UI geçişleri düz kesme |
| **Bölge Adlarını Göster/Gizle** | Varsayılan: göster |

**Ertelenen:** Büyük metin modu (24px — tüm yerleşimlerin ikinci versiyonu
demek) ve Steam Deck dokunmatik hedef boyutları (dokunmatik desteği "None",
Steam Deck post-launch — technical-preferences) post-launch değerlendirilir.

### Uygulama Notu — UI (koda yansıyacaklar)

Üst/alt bara %70 opak zemin; harita etiketlerine `LabelSettings` konturu ve
`text_overrun_behavior` ellipsis; seçili bölge `◆` işaretleri; bölge merkezine
tamga `Sprite2D`; buton taban genişlikleri; ayarlar ekranına üç erişilebilirlik
seçeneği.

## 8. Asset Standartları

### Dosya Formatları

- **Kaynak:** Aseprite (`.aseprite`, ≥1.3) — **repoda**, `art-source/` altında
  (Godot import etmez); alt klasörler `game/assets/art/` ile aynı adlandırılır
  (`units/`, `maps/`, `ui/`, `illustrations/`).
- **Export:** PNG, sRGB, **yalnızca 1× native boyut**. Alfa yalnızca 0 veya 255
  (yarı saydam piksel yok). Ölçeklenmiş varyant (`_2x` vb.) repoya girmez —
  büyütme Godot'un işidir (integer scaling).
- **Global palet:** `art-source/global_palette_asena.ase` (tek kaynak, isimli
  rampalar) → `art-source/global_palette_asena.gpl` (export, GIMP/Krita uyumu).
  Bölüm 4 değişirse: `.ase` güncellenir → `.gpl` export edilir → doğrulayıcı
  yeniden çalışır → etkilenen asset'ler yeniden export edilir.
- **Script ile üretilen asset'ler** (UI tema ikonları, dil adları) kaynak yerine
  `tools/asset-pipeline/*.gd` üreticileriyle yeniden üretilir.

### İsimlendirme

Kalıp: **`[kategori]_[ad]_[varyant]_[durum].png`** (snake_case; durum opsiyonel).
Kategoriler: `unit`, `env`, `ui`, `fx`, `ill`, `portrait`, `icon`, `tile`.

| Asset | Dosya adı |
| --- | --- |
| Oğuz süvari idle şeridi | `unit_oguz_cavalry_idle.png` |
| Kış ruhu körmös idle | `unit_kormos_winter_idle.png` |
| Otağ (temiz / bozulmuş) | `env_otag_clean.png`, `env_otag_corrupted.png` |
| Cürcet tamgası | `icon_tamga_curcet.png` |
| Prolog intro illüstrasyonu | `ill_prolog_intro.png` |
| Oğuz portresi | `portrait_oguz_kagan.png` |

Aynı karakterin üç detay katmanı (Bölüm 5) aynı `ad`'ı taşır:
`unit_oguz_kagan_*`, `portrait_oguz_kagan`, `ill_<sahne>_oguz_kagan`. Harita
sprite'ı küçültülmüş portre **değildir** — her katman kendi ölçeği için sıfırdan
çizilir; kimlik (renkler, miğfer) üçünde aynıdır.

### Boyut Tablosu

**Tuval kuralı:** tuval = görünür sprite + **her kenarda 2px** dolgu (outline ve
parlama tuval kenarına değmez). **Pivot = ayak pikseli** (görünür sprite'ın alt
orta pikseli); Godot'ta `Sprite2D.offset` / `centered=false` ile ayarlanır.

| Kategori | Görünür | Tuval | Pivot |
| --- | --- | --- | --- |
| Süvari | 12×16 | 16×20 | ayak (8, 18) |
| Okçu | 10×14 | 14×18 | ayak (7, 16) |
| Ağır piyade | 12×14 | 16×18 | ayak (8, 16) |
| Kahraman (Oğuz) | 14×18 | 18×22 | ayak (9, 20) |
| Körmös (5 varyant) | ≤12×14 | 16×18 | gölge noktası (8, 16); sprite 1–2px yukarıda çizilir |
| Erlik canavarı (boss) | ≤32×40 | 36×44 | ayak (18, 42) |
| Kök Böri (harita/lütuf) | ≤48×32 (yan profil) | 52×36 | merkez (26, 18) |
| Kök Böri (illüstrasyon) | ≥128 | sahneye özel | — |
| Portre | 24×32 | 28×36 | — (panel içinde hizalanır) |
| Otağ / yurt | 24×24 / 16×12 | 28×28 / 20×16 | ayak |
| Balbal / ongun | 8×12 / 6×16 | 12×16 / 10×20 | ayak |
| İkon | 7×7 / 9×9 / 16×16 / 24×24 | aynı (dolgusuz) | merkez |
| Kilim tile | 8×8 / 16×16 | aynı (kesintisiz) | — |
| İllüstrasyon | 640×360 | 640×360 | — |

### Sprite Sheet ve Animasyon

- **Düzen:** animasyon başına bir PNG, kareler **yatay şerit**, sabit kare boyutu
  (= tuval), 0px aralık. Aseprite frame tag → ayrı şerit export.
- **Godot:** `AnimatedSprite2D` + `SpriteFrames` (şerit grid ile dilimlenir).
  Tek yön çizilir; sola bakış `flip_h` (Bölüm 5).
- **FPS:**

| Animasyon | Kare | FPS | Döngü |
| --- | --- | --- | --- |
| Birim idle | 2 | 1 | loop |
| Birim hareket | 2 | 4 | loop |
| Birim saldırı | 2–3 | 6 | bir kez → idle |
| Körmös idle (titreme) | 2 | 2 | loop |
| Kök Böri görünür↔soluk | 2 | 1 (2 sn döngü) | loop |
| Arındırma (balbal/ongun) | 4 | 8 | bir kez |
| Erlik lekesi | 2–4 | 2–4 (Bölüm 2) | loop |
| Süs prop | 1 | — | statik |

### Godot Import Ayarları (zorunlu)

| Ayar | Değer | Gerekçe |
| --- | --- | --- |
| `compress/mode` | `0` (Lossless) | VRAM sıkıştırma (S3TC/ETC2, 4×4 blok) pixel grid'i ve dithering'i bozar |
| `mipmaps/generate` | `false` | Integer scaling'de mipmap gereksiz; küçültmede bulanıklaştırır |
| `process/fix_alpha_border` | `true` | Saydam kenarda renk sızıntısını önler |
| `process/size_limit` | `0` | PC hedefi |
| `detect_3d/compress_to` | `0` (kapalı) | 2D proje; otomatik VRAM sıkıştırma önerisi devre dışı |
| Filtre | proje varsayılanı Nearest | Doku başına override gerekmez |
| Tekrar (kilim tile) | `CanvasItem.texture_repeat` | Godot 4.7'de import değil node özelliği (doğrulandı) |

### Teknik Bütçeler

- **Sprite sheet:** en fazla **2048×2048**; aşarsa kategoriye böl (oyuncu /
  düşman / körmös). İllüstrasyonlar atlas'a girmez, tekil doku.
- **Draw call:** hedef <200; tahmini harita + UI ~50–80. Batch'i kıranlar: farklı
  doku, farklı material, z_index değişimi, CanvasLayer geçişi, blend mode.
  Tamga/ikon/UI öğeleri ortak atlas'ta toplanır.
- **Bellek:** 640×360 RGBA8 illüstrasyon ≈ **900 KB**; aktif sahne tahmini ~60 MB
  (tavan 512 MB). Küçük ve sık kullanılanlar `preload()` (kullanıldığı yere yakın);
  birim şeritleri ve tile'lar `load()`; illüstrasyon ve bölüm haritaları
  `ResourceLoader.load_threaded_request()`. Kalıcı node'dan büyük preload yasak.

### Erlik Lekesi Uygulaması

- Tüm lekeler **tek, paylaşılan `ShaderMaterial`** ile (bölge başına unique
  material yasak — batch'i kırar). Shader 2–4 dither deseni arasında **kesin
  geçiş** yapar: `int(TIME * fps) % kare_sayısı` ile kare seçimi — `mix()` /
  `smoothstep()` ile harmanlama **yasak** (palet dışı renk üretir).
- Leke, bölge poligonuna **`clip_children`** ile maskelenir (Godot 4.7'de
  Polygon2D dahil tüm CanvasItem'larda var — doğrulandı).
- Katman yapısı: zemin `CanvasLayer` (CanvasModulate + zemin tile'ları + bölge
  dolguları + leke) / bilgi `CanvasLayer` (birimler, etiketler, tamgalar — ton
  kaydırma yok).
- Körmös süzülmesi tween ile; piksel snap açık olduğundan adım adım hareket
  kabul edilir (doğal olmayan hareket karaktere uyar).

### Palet Doğrulama

`tools/asset-pipeline/validate_palette.gd` (GDScript, Godot `Image` API — ek
bağımlılık yok): `game/assets/art/` altındaki tüm PNG'leri tarar; alfa 0 pikselleri
atlar, alfa 0/255 dışını ve global palet (`.gpl`) dışındaki her rengi dosya +
piksel + hex ile raporlar; hata varsa exit 1. CI test adımından sonra çalışır
(`tools/ci/`).

### Teknik Yasaklar

VRAM sıkıştırılmış pixel art · mipmap · linear filtre · ölçeklenmiş export ·
yarı saydam piksel / sahiplik dolgusu · tam sayı olmayan konum ve subpixel kaydırma
· kesirli `scale` ile UI/sprite animasyonu · alfa fade (yerine dither) ·
`scale.x = -1` ile yön çevirme (`flip_h` kullan) · animasyon için `position`
kaydırma (`offset` kullan) · bölge başına unique material · bilgi katmanında
CanvasModulate · kalıcı node'dan büyük sahne preload'u · font antialias / MSDF /
hinting / subpixel.

### Export Kontrol Listesi

- [ ] Global palet yüklü; doğrulayıcı temiz
- [ ] Alfa yalnızca 0/255
- [ ] Tuval = görünür + 2px; pivot ayakta
- [ ] İsim kalıba uygun
- [ ] Şerit: kare boyutu sabit, kare sayısı tabloya uygun
- [ ] 1× export

## 9. Referans Yönü

Görsel kimlik özgündür ama sıfırdan icat edilmez. Her referanstan **tam olarak
ne alındığı** ve **neyden ayrışıldığı** bellidir; iki referans aynı yönü göstermez.

| # | Referans | Ne alınıyor | Ne alınmıyor |
| --- | --- | --- | --- |
| 1 | **Pazırık halısı** (MÖ ~4.–3. yy, Altay; Ermitaj Müzesi) | Merkez alan + çok katmanlı bordür kompozisyonu; tekrar eden atlı/geyik frizleri → panel/çerçeve sistemi ve kilim bandı (Bölüm 7) | Motiflerin birebir kopyası; "müze replikası" tonu |
| 2 | **Altay/Göktürk kaya resimleri ve tamgalar** | Az çizgiyle anında tanınan hayvan silüetleri; işaret olarak tamga → silüet felsefesi (Bölüm 3), tamga ikonları, Kök Böri profili | "İlkel/çocuksu" okuma — piksel disiplini temiz ve kasıtlı kalır |
| 3 | **Türkmen göl motifleri ve Kırgız şırdak desenleri** | Göl madalyonu, koçboynuzu, şevron ve karşıt renk (pozitif/negatif) dokuma mantığı → desen kütüphanesi (Bölüm 6) | Belirli bir boyun/bölgenin gerçek deseninin birebir kopyası; desenler özgün çizilir |
| 4 | **Into the Breach** (2018, Subset Games) | Strateji haritasında bilgi okunabilirliği: net tehdit gösterimi, ikonlu durumlar, sınırlı ve anlamlı renk → Bölüm 1 İlke 3, Bölüm 4 renk körlüğü, Bölüm 7 | Bilim kurgu/mecha estetiği, izometrik ızgara |
| 5 | **Hyper Light Drifter** (2016, Heart Machine) | Büyük düz renk alanları ve seçici parlama ile kurulan atmosfer → Kök Böri anları ve Erlik yoğun sahneler (Bölüm 2) | Neon pembe/turkuaz palet, bilim kurgu kalıntı estetiği, aksiyon odaklı kompozisyon |
| 6 | **Timurlu minyatür geleneği** | Düz perspektif, yüksek ufuk, istiflenmiş katmanlı kompozisyon → tam ekran intro/epilog illüstrasyonları (Bölüm 2, 5) | Saray ihtişamı ve yaldız yoğunluğu — bizim dünyamız bozkır |

### Referans Kullanım Kuralları

- Referanslar **ilke** öğrenmek içindir, imitasyon için değil: "X gibi yap" değil,
  "X bu sorunu nasıl çözüyor — bunu kilim diline uyarla".
- Üretimde referans yan ekranda açık olabilir; **tracing ve motifin birebir
  alınması yasaktır**.
- **AI görsel üretimi:** prompt'larda sanatçı/eser/oyun adı yazılmaz; teknik
  tarif edilir (ör. "düz renk alanları, 1px koyu kontur, sınırlı palet").
  `design/art-reference/ai-art-prompts.md` sulu boya dönemine aittir ve bu
  bölüme göre yeniden yazılmalıdır.
- Temel set sabittir; yeni bir görsel sorun (su, sis, kar efekti vb.) için ek
  referanslar aşağıya eklenir.

### Ek Referanslar

—
