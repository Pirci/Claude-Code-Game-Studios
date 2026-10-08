# ULUS: Blood of the Sky Wolf — AI Görsel Üretim Prompt'ları (Pixel Art)

> **Bağlayıcı kaynak:** [design/art/art-bible.md](../art/art-bible.md). Bu dosya
> art bible'ın kurallarını prompt diline çevirir; çelişki olursa bible geçerlidir.
> 2026-10-08'de pixel art yönüne göre baştan yazıldı (önceki sulu boya sürümü git
> geçmişinde).

Platform: **Gemini Nano Banana** (Nano Banana 2 / Nano Banana Pro). Prompt'lar
İngilizce, açıklamalar Türkçe.

---

## 0. AI Çıktısının Rolü — Önce Bunu Oku

AI görselleri **konsept ve kompozisyon referansıdır; doğrudan oyuna girmez.**

Neden: art bible her oyun asset'inden şunları ister — yalnızca global palet
(`art-source/global_palette_ulus.gpl`, 94 renk), **1× native boyut**, harita
birimlerinde ve <16px ikonlarda anti-alias yok, alfa yalnızca 0/255, tutarlı piksel
ızgarası. Görsel üreticiler bunları güvenilir biçimde sağlamaz (düzensiz piksel
boyutu, palet dışı ara tonlar, bulanık kenarlar — "sahte pixel art").

**İş akışı:**

1. Aşağıdaki prompt + **Ortak Stil Bloğu** + **Negatif Blok** ile üret.
2. Çıktıyı en yakın komşu (nearest) ile hedef boyuta küçült
   (illüstrasyon 640×360, sprite referansı Bölüm 8 Boyut Tablosu) — yalnızca
   kompozisyon/silüet/renk dağılımını görmek için.
3. Asset'i **Aseprite'ta, native boyutta, `.gpl` paletiyle elle çiz/temizle**
   (bible §3 çizgi disiplini: jaggies ve doubles yok).
4. `tools/asset-pipeline/validate_palette.gd` ile doğrula (CI de çalıştırır).
5. İsim: `[kategori]_[ad]_[varyant]_[durum].png` (bible §8).

**Prompt kuralı (bible §9):** sanatçı, eser veya oyun adı **yazılmaz**; teknik
tarif edilir ("düz renk alanları, 1px koyu kontur, sınırlı palet"). Sahneyi
**betimle**, anahtar kelime listeleme. Yapı:
`[Konu] + [Eylem/Sahne] + [Ortam] + [Kompozisyon] + [Ortak Stil Bloğu]`.

---

## Ortak Stil Bloğu (her prompt'un sonuna eklenir)

```text
Style: true pixel art drawn on a strict pixel grid at native resolution,
every pixel deliberate, hard pixel edges, uniform pixel size, no
anti-aliasing, no gradients, no blur, no soft brushwork. Flat blocks of
solid colour from a limited palette of at most 32 colours. Characters,
units and UI elements have a 1-pixel dark brown-black outline (#1C170F);
terrain and backgrounds have no outline and are built from geometric
woven-rug blocks, like a hand-woven Turkic steppe kilim seen from above —
borders are drawn by colour change, not lines. Dithering only in
shadows, light effects and dark corruption, never on flat surfaces.
Clean 1:1 and 2:1 pixel diagonals, smooth stepped curves. Iconic,
instantly readable silhouettes, like tamga signs.
```

## Negatif Blok (platform destekliyorsa "avoid" olarak eklenir)

```text
Avoid: painterly or watercolor look, brush strokes, soft shading,
gradients, blur, bloom, lens effects, mixed pixel sizes, sub-pixel
detail, anti-aliased edges, 3D render, photorealism, isometric view,
Western medieval fantasy armour, neon pink or turquoise palettes, text
or letters in the image, watermarks.
```

---

## Palet ve Renk Rolleri (prompt'a hex ile yazılır)

Tam liste: `art-source/global_palette_ulus.gpl` (bible §4). Prompt başına yalnızca
sahneye gereken rampaları yaz — fazlası çıktıyı bulandırır.

| Rol | Hex | Not |
| --- | --- | --- |
| Outline / kontur | `#1C170F` | Birim, karakter, UI |
| Keçe zemin, kâğıt | `#B8A689` `#D4C4A3` `#F2E6C7` | Arka plan, nötr |
| Deri kahve (panel, kenarlık) | `#1C150D` `#3A2817` `#5C4229` `#8A6D4F` | UI panel/çerçeve |
| Ülgen altını (ilahi ışık) | `#C99A3D` `#EDC76B` `#F5DE9E` | Hale, zafer, seçim |
| Ülgen indigosu (gök) | `#141A33` `#2E4178` `#6B87C9` | Gece göğü, ilahi zemin |
| Kök Böri / oyuncu mavisi | `#2E7AB8` `#47A3E8` `#87C4F5` `#D4EDFF` | Kurt, oyuncu sahipliği |
| Erlik moru + kömür (yalnız Erlik) | `#1F0F26` `#33173D` `#522961` `#7A3D8F` `#1A1719` | Leke, körmös |
| Deel kırmızısı (Oğuz vurgusu) | `#992E2E` `#CC4747` | Bayrak, kuşak |
| Pas turuncusu (düşman krallar) | `#9A4220` `#C45A2A` `#E07E45` | Düşman sahipliği |
| Keçe grisi (nötr bölge) | `#4A453C` `#6B655A` `#8F897D` | Sahipsiz bölge |
| Bozkır yeşili (temiz toprak) | `#2B3D1F` `#436129` `#5C8A3D` | Arındırılmış zemin |

Kesin yasaklar: Kök Böri'de kahve/kömür/mor yok; düşman krallarda mor ve Erlik
kömürü yok; Güneş diski Gün Han'ındır, düşmana verilmez (bible §5).

---

## 1. Prolog Kampanya Haritası — Oğuz'un Ata Yurdu (6 bölge)

*Hedef:* Bible §2 "Kampanya Haritası — Normal Tur" ruh hali; üstten bakış, bölge
sınırları renk değişimiyle. Oyundaki referans: `chapter_1_map.tres` (Oğuz Otağı
merkezde, Kutlu Dağ kuzeyde, Batı/Doğu obaları, Bereket Vadisi, Canavarın İni).

```text
Top-down pixel art strategy campaign map at 640x360, the ancestral
homeland of the young hero Oguz on the open Central Asian steppe. Six
regions read as large flat woven-rug fields separated only by colour
change: in the centre a hexagonal sky-blue (#47A3E8) home region with a
small round felt yurt camp; to the north a sacred mountain region with a
stepped two-tone peak; west and east two warm felt-grey (#6B655A)
neutral camp regions with tiny yurts; south-west a fertile valley with a
three-pixel river; south-east a rust-orange (#C45A2A) enemy region, the
lair of a one-horned beast of darkness, with a small purple-black
(#33173D) dithered stain creeping over its rug pattern. Thin straight
paths connect neighbouring regions. Even afternoon light, medium-high
contrast, cream (#D4C4A3) background ground. Generous empty space in the
centre of each region for a name label. Composition: map fills the frame,
slight margin for a top and bottom HUD bar.
[Ortak Stil Bloğu]
```

## 2. Dört Yönün Haritaları (varyant prompt'u)

*Hedef:* Bible §2 "Dört Yönün Görsel Ayrışımı" + §6 ortam imzaları. Köşeli
parantezi yönle değiştir.

```text
Top-down pixel art strategy campaign map at 640x360 of the [DIRECTION]
lands, ten to fifteen regions as flat woven-rug fields separated by
colour change. Some regions are sky-blue (#47A3E8, the player), some
rust-orange (#C45A2A, enemy king), the rest warm felt-grey (#6B655A).
[DIRECTION DETAILS]. Dark corruption of the underworld appears as
irregular purple-black dithered stains (#33173D, #1A1719) lying ON TOP
of region colours without hiding them; clean regions next to a stain
glint with a few gold pixels (#EDC76B).
[Ortak Stil Bloğu]
```

| Yön | `[DIRECTION DETAILS]` |
| --- | --- |
| **Doğu (Cürcet)** | `dense deep-green forest ground (#1A2E17, #3D6B3D) with leaf tiles, small 12x20-pixel trees, a wooden bridge; some trees rotting with purple spots; morning light, warm` |
| **Batı (Urum)** | `felt-grey stony ground, stone castle towers, toppled standing stones and broken totem poles; the widest corruption stains of all; cold dusk light, highest contrast` |
| **Kuzey (İtil/Ural)** | `ice blue-white snow ground (#D4E8FF, #6B99C4) with snow tiles, 8x10-pixel ice crystals, a small boat, frost-bitten trees; dark blue ice cracks; winter light, high value` |
| **Güney (Sındu/Şam)** | `sand ground (#D4C49E, #B89E6B) with sand tiles, small date palms and acacias, dunes, a caravan tent; dry earth cracks; noon light, warm, medium contrast` |

## 3. Savaş Raporu Ekranı (UI mock)

*Hedef:* Bible §2 "Savaş Raporu" + §7 panel sistemi (opak modal, kilim bandı,
koçboynuzu köşeler). Metin yerine yer tutucu blok iste — AI metni bozar.

```text
Pixel art game UI mock-up at 640x360: a battle report modal panel in the
centre of the screen over a dimmed campaign map. The panel is opaque dark
leather brown (#1C150D) with a 1-pixel border (#8A6D4F), a continuous
2-pixel-high woven chevron band along its edges, and 5x5-pixel ram-horn
ornaments in the four corners. Inside: two columns for attacker and
defender, each with a tiny 12x16-pixel unit sprite, a row of short
horizontal bar charts made of flat blocks, and empty grey placeholder
rectangles where text will go. Gains marked with a small green (#87B85C)
up-arrow icon, losses with a light red (#E87A7A) down-arrow icon — never
colour alone. Neutral balanced light, sober and objective mood.
[Ortak Stil Bloğu]
```

## 4. Sahne İntro İllüstrasyonu — Prolog: Doğuş

*Hedef:* Bible §2 "Sahne İntro/Epilog" (tam ekran 640×360, ≤32 renk, altta metin
paneli) + §5 Oğuz Kağan + referans ilkesi: düz perspektif, yüksek ufuk, istiflenmiş
katmanlar.

```text
Full-screen pixel art illustration at 640x360 for an epic opening scene.
Flat perspective with a high horizon and stacked layers: at dawn on the
endless steppe, the young hero Oguz stands beside his horse on a small
rise, wearing a sky-blue (#47A3E8) deel robe with a deep red (#CC4747)
sash and a horned helmet with a plume; broad forehead, dark eyes, sparse
beard. Behind him a faint golden halo (#EDC76B). In the far distance a
huge one-horned beast of darkness is a purple-black (#33173D, #1A1719)
dithered silhouette on the horizon. Above, the sky is layered in flat
bands of gold-orange sunrise and indigo (#2E4178). A faint watermark-like
outline of a sky wolf is woven into the clouds. Ram-horn and roof-wheel
(tunduk) motifs frame the edges. The bottom fifth of the image is a calm
dark band left empty for story text. Epic, monumental, solemn. Maximum 32
colours; manual anti-aliasing allowed only with one in-between tone.
[Ortak Stil Bloğu]
```

## 5. Diplomasi / Kral Karşılaşması

*Hedef:* Düşman kralların kimliği bible §5 "Düşman Krallar" — renk değil tamga ve
kültürel detay ayırır; hepsi pas turuncusu ailesinde.

```text
Pixel art scene at 640x360 of a diplomatic meeting in a large felt tent.
On the left, Oguz in a sky-blue (#47A3E8) deel with a red (#CC4747) sash;
on the right, a rival steppe king in rust-orange (#C45A2A, #9A4220)
clothing with [KING DETAILS], his tamga sign — [TAMGA] — stitched in
cream on a small banner behind him. Between them a low table with a
string of horses, a stack of gold coins and a bow, drawn as small iconic
objects. The tent wall is a geometric kilim pattern in leather brown and
cream. Portrait-like 24x32-pixel faces for both leaders. Balanced, tense,
respectful mood.
[Ortak Stil Bloğu]
```

| Kral | `[KING DETAILS]` | `[TAMGA]` |
| --- | --- | --- |
| Cürcet Kağan (Doğu) | `a pointed peaked helmet, a short bow, light harness, a forest-green sash` | `a diamond with a dot inside` |
| Urum Kağan (Batı) | `a rounded helmet, a heavy shield, iron-grey details` | `a square with an X inside` |
| Kıl Barak (Batı) | `a fur-lined helmet, a long spear, dark leather brown details` | `two stacked triangles pointing up and down` |
| Kuzey kağanı | `a flat fur cap, heavy furs, ice-blue details` | `a six-armed snowflake star` |
| Güney kralı | `a plumed helmet, a curved sword, sand-coloured details` | `a three-pronged fork` |

## 6. Ana Menü Arka Planı

*Hedef:* Bible §2 "Ana Menü" — sakin beklenti; soluk Kök Böri silueti, tündük
kenarları. Başlık ve butonlar oyun içinde çizilir; görselde metin olmamalı.

```text
Pixel art main menu background at 640x360. A calm steppe at golden
sunset: cream-gold (#F5DE9E, #D4C4A3) ground in flat woven bands, indigo
(#2E4178, #141A33) shadows, a wide value range but no hard black. In the
upper centre, a large pale indigo-grey silhouette of a wolf in side
profile, tail raised about 45 degrees, head forward, ears up, at about 30
percent strength so it reads as a distant presence. Gold-lined
roof-wheel (tunduk) motifs in the corners. The centre third stays quiet
and low-detail for the game title and three buttons. Serene, inviting,
mythic mood.
[Ortak Stil Bloğu]
```

## 7. Birim Sprite Referansları (sprite sheet)

*Hedef:* Bible §5 "Oyuncu Birimleri" + §8 Boyut Tablosu. Referans büyük üretilir,
asset native boyutta elle çizilir.

```text
Pixel art character sprite sheet on a flat cream background, four small
side-view units standing in a row, each drawn at its exact native size
and shown enlarged with crisp square pixels: a horse archer cavalry unit
12x16 pixels (rider in sky-blue cloth, brown leather harness, tassel on
the horse's head); a foot archer 10x14 pixels, narrow and upright with a
clear recurve bow silhouette; a heavy infantry unit 12x14 pixels with a
square body and a rectangular dark brown shield; and the hero Oguz 14x18
pixels on horseback, two pixels taller than the cavalry, with a horned
helmet plume and a red (#CC4747) sash. Every unit has a 1-pixel
#1C170F outline and no anti-aliasing. Readable as silhouettes alone.
[Ortak Stil Bloğu]
```

## 8. Harita İkonları ve Tamgalar

*Hedef:* Bible §7 "İkonografi" — 7×7 / 9×9 / 16×16 ızgara, 1px koyu outline,
ikon başına 4–6 renk. (Mevcut tamgalar zaten
`tools/asset-pipeline/generate_tamga_icons.gd` ile üretiliyor; bu prompt yeni
ikon fikirleri içindir.)

```text
Pixel art icon sheet on a flat leather-brown (#1C150D) background, icons
arranged in a neat grid, each on an exact small pixel grid and shown
enlarged with crisp square pixels: resource icons at 9x9 pixels — a gold
coin (#EDC76B, #C99A3D), a stylised horse head for herds (#8A7A5E), a
front-facing wolf head for spirit (#47A3E8); status icons at 7x7 pixels
— a check mark, a warning triangle, a cross, an up arrow, a down arrow.
Every icon has a 1-pixel #1C170F outline, uses 4 to 6 colours, is
symmetric around a centre pixel, and has no anti-aliasing.
[Ortak Stil Bloğu]
```

## 9. Erlik'in Ruhları (Körmös) ve Prolog Canavarı

*Hedef:* Bible §5 "Erlik'in Ruhları" — asimetrik anatomi, zemine değmez, %50 dama
dithering ile yarı saydamlık, kesintili outline (2px çiz / 1px boşluk).

```text
Pixel art sprite sheet of five evil underworld spirits on a flat cream
background, each about 12x14 pixels and shown enlarged with crisp square
pixels, plus one large boss. All spirits share family rules: asymmetric
unnatural anatomy (one long arm and one short, tilted head, crooked
spine), floating one or two pixels above a small ground shadow,
semi-transparency drawn only as a 50 percent checkerboard dither, and a
broken outline (two pixels drawn, one pixel gap). Colours only from dark
purple (#1F0F26, #33173D, #522961) and charcoal (#1A1719, #2E292B), plus
one accent per spirit: a forest spirit with long thin branch-like limbs
(accent #1A2E17); a rot spirit with a melting dripping body (#522961);
a winter spirit with two heads and ice-crystal shoulders (#2E4761); a
drought spirit with a bony cracked dry body (#3D2914); a plague spirit
with a swollen body and seeping spots (#7A3D8F). The boss is a one-horned
beast about 32x40 pixels following the same rules, its single horn the
one readable signature limb.
[Ortak Stil Bloğu]
```

## 10. Kök Böri ve Lütuf Seçimi

*Hedef:* Bible §2 "Kök Böri Belirişi / Lütuf Seçimi" + §5 Kök Böri — outline yok,
kenarlar ışık parçacıklarına dağılır; yalnız mavi + indigo + beyaz + altın.

```text
Pixel art scene at 640x360: a divine moment. On a dark indigo-black
(#0A0D1C, #141A33) background with a faint indigo kilim pattern, a
glowing sky wolf in side profile, about 48x32 pixels at native size,
tail raised about 45 degrees, head forward, ears up. The wolf has no
outline; its edges break into scattered light pixels; its body moves
from sky blue (#47A3E8) to white (#D4EDFF) through dithering, with a
gold (#EDC76B) halo. Below it, three equal card-shaped panels, each with
a 1-2 pixel gold glow and an empty placeholder area for an icon and
text. Colours only blue, indigo, white and gold — no brown, charcoal or
purple anywhere on the wolf. Reverent, radiant, silent mood.
[Ortak Stil Bloğu]
```

---

## Referans Araması (insan için — prompt'a yazılmaz)

Bible §9'daki referanslar; **ilke** öğrenmek içindir, imitasyon için değil.
Tracing ve motifin birebir alınması yasak.

| Arama | Ne için |
| --- | --- |
| `Pazyryk carpet` | Merkez alan + katmanlı bordür → panel/çerçeve sistemi |
| `Gokturk petroglyphs`, `Turkic tamga signs` | Az çizgiyle tanınan silüet → birim ve tamga dili |
| `Turkmen gul motif`, `Kyrgyz shyrdak pattern` | Göl madalyonu, koçboynuzu, şevron → desen kütüphanesi |
| `Timurid miniature painting` | Düz perspektif, yüksek ufuk → intro/epilog kompozisyonu |
| Strateji haritası okunabilirliği (bible §9 #4) | Net tehdit gösterimi, sınırlı anlamlı renk |
| Düz renk alanlı atmosferik pixel art (bible §9 #5) | Seçici parlama ile atmosfer → Kök Böri ve Erlik sahneleri |

---

## Nano Banana Kullanım İpuçları

- **Tek konu, tek prompt:** sprite sheet'te nesne sayısını sınırlı tut (≤6); fazlası
  piksel ızgarasını bozar.
- **Boyutu açıkça yaz:** "at 640x360", "12x16 pixels"; ardından "shown enlarged with
  crisp square pixels" — aksi halde model piksel boyutunu karıştırır.
- **Hex ile renk ver:** renk adı yerine hex; rampayı 2–4 tonla sınırla.
- **Metin isteme:** UI mock'larında "empty placeholder rectangles" kullan — başlık,
  buton yazısı ve sayılar oyunda pixel fontla çizilir.
- **Çıktıyı kontrol et:** nearest ile 1×'e küçült; piksel boyutu tutarsız, kenarlar
  bulanık veya renkler palet dışıysa bu yalnızca referanstır — Aseprite'ta yeniden çiz.
- **Düzeltme turu:** "keep the composition, make every pixel the same size, remove all
  in-between colours, use only these colours: …" ile ikinci tur iste.
