# Seviye: Perde 1 — Doğu (Cürcet Yönü)

*Oyun: ULUS: Blood of the Sky Wolf · Görev: C-43 · `chapter_id` = 2 (Prolog = 1) · `campaign.tres` kimliği: `perde1_dogu`*

**Durum: Onaylı (C-43, 2026-10-20) — değerler gerçek controller denge testiyle uygulamada yeniden doğrulanacak**

> **Kaynak sırası.** Bu belge Adım 1–5 onaylı çıktılarının derlemesidir; içerik değiştirilmedi. Çakışmada
> geçerli olan: garnizon/takviye = Adım 3 (Adım 2'yi geçersiz kılar); `adjacency_line_color` = `#5C8F5C`
> (Adım 4, Adım 1'in `#294726`'sını geçersiz kılar); nehir rotası, otağ propu yeri, varlık listesi = Adım 4.
> Terimler `scene-flow.md` ile aynıdır (*sahne* = *bölüm* = `chapter_id`).

---

## 1. Hızlı Bakış

| Alan | Değer |
| ---- | ---- |
| Bölge / Tema | Doğu ormanları; Cürcet Kağan'ın yönü. Kapalı, koyu, dikey orman; sabah ışığı |
| Tür | Sıra tabanlı bölge-fetih + Erlik odağı arındırma (Karma) |
| Tahmini süre | Hedef T10–15 tur, medyan T12 (aralık T10–18); sahne başına 20–35 dk (`scene-flow.md` §2) |
| Zorluk | Prolog'dan yüksek: ilk kez karşılık veren düşman + yayılan Erlik (iki cephe) |
| Önkoşul | Prolog kazanılmış (doğrusal açılma, `scene-flow.md` F1) |
| Durum | Layout onaylı; Graybox/uygulama bekliyor |
| Harita bütçesi | 8 bölge, 9 komşuluk, 640×360 |

## 2. Anlatı Bağlamı

| Alan | İçerik |
| ---- | ---- |
| Hikâye anı | Oğuz artık Kağan; ilk dış sefer, güç kanıtı. Tema: "sözüm ne kadar uzağa geçer?" |
| Anlatı amacı | Buyruk dört yöne gitti, doğudan cevap yok; Cürcet Kağan boyun eğmiyor, doğu ormanı çürüyor |
| Duygusal yay | Giriş: özgüven → orta: sıkışma (iki cephe) → çıkış: kanıtlanmış güç / bereket |
| Cürcet Kağan | Gururlu, meşru hükümdar, "karşı saf" (kötü değil). Doğrudan konuşmaz; ozan aktarır, en çok 1 kısa cümle ("Cürcet Kağan dedi: Boyun eğmem."). Yenilgisi ağırbaşlı ("diz çöktü"); baş kesme yok |
| Erlik ilişkisi | İş birliği YOK. Kağan gururundan ormanı ihmal eder; orman çürür. Siyasi katman ile Erlik katmanı ayrı |
| Dil kuralları | Arındırma = "şifa", "av" değil. Körmös hiç konuşmaz, yalnız betimlenir |
| Keşif / lore | Kök Böri: "Ormanın kalbi çürüyor, Oğuz. Önce ışığı oraya taşı." Teaser: batıda Urum |

### Anlatı ekranları

| Sayfa | İçerik |
| ---- | ---- |
| Giriş G-1 (başlıklı) | Buyruk dört yöne; doğudan cevap yok |
| Giriş G-2 | "Boyun eğmem" + doğu ormanlarından kara sis |
| Giriş G-3 (Kök Böri, PROFILE) | `CHAPTER_2_KOKBORI_1` + `CHAPTER_2_KOKBORI_LINE` |
| Çıkış O-1 | Orman nefes alır, körmös fısıltıları dağılır |
| Çıkış O-2 (başlıklı "Kanglı") | Cürcet diz çöker, ganimet kağnılarla, Kanglı boyu doğar; teaser: Urum |

### Anlatı tetikleyicileri (sahne içi)

| Tetikleyici | Metin key'i |
| ---- | ---- |
| İlk tur düşman görünür | `HINT_ENEMY_KING` |
| Düşman ilk saldırı | `BATTLE_LOST_DEFENSE` (`MoveIntent.reason = &"strike"`). *(C-44 inceleme (2026-10-21), W-5:)* `BATTLE_HELD_DEFENSE` yalnız `A ≤ P_eff` saldırıları için ayrılmıştır; Perde 1 R1'i üretmez (anahtar korunur) |
| Odak önizleme | `CHAPTER_2_HUNT_READY` / `_NOT_READY` |
| Arındırma | `CHAPTER_2_CLEANSED_HEADING/LINE` / `CHAPTER_2_HUNT_FAILED` |
| Yayılım | mevcut `TURN_SUMMARY_*` |
| Başkent ilk önizleme (tek sefer) | `HINT_CAPITAL` |

**Key listesi (`translations.csv`, 11 dil):** `CHAPTER_1_TEASER`, `CHAPTER_2_TITLE`, `CHAPTER_2_INTRO_1/2`,
`CHAPTER_2_KOKBORI_1`, `CHAPTER_2_KOKBORI_LINE`, `WIN_CONDITION_CH2`, `CHAPTER_2_HUNT_HEADING/READY/NOT_READY`,
`CHAPTER_2_CLEANSED_HEADING/LINE`, `CHAPTER_2_HUNT_FAILED`, `CHAPTER_2_OUTRO_1/2`, `CHAPTER_2_KANGLI_TITLE`,
`CHAPTER_2_TEASER`, `HINT_ENEMY_KING`, `HINT_CAPITAL`, `REGION_*` ×8, `CAMPAIGN_END_DEMO_1` güncellemesi.

**Kararlar:** Cürcet çevirileri tarihsel Jurchen (zh/ja 女真, ko 여진); kaynak nüshası doğrulanmadı, destandan
doğrudan alıntı yok, "tarihsel Cürcet" iddiası yapılmaz. `DEFEAT_REASON_ERLIK` metni sahneden bağımsızlaştırılır
("Erlik'in gölgesi bozkırı yuttu" benzeri), 11 dil.

## 3. Yerleşim

### 3.1 Bölge tablosu (batı → doğu, koordinatlar 640×360)

| id | EN | merkez | poligon | sahip | ordu | altın | bozulma | karakter |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| orman_agzi | Forest Gate | (100,190) | altıgen 80×54 | PLAYER | 6 | 2 | 0 | Bozkır-orman eşiği, başlangıç |
| kayin_koruluk | Birch Grove | (200,270) | dikdörtgen 110×54 | NEUTRAL | 2 | 1 | 0 | Açık huş koruluğu, ucuz ilk nötr hedef |
| kuzey_aksu | Northern Whitewater | (225,101) | 100×58 (üst kenar y=72) | NEUTRAL | 3 | 2 | 0 | Kuzeyde nehir, balıkçı obaları |
| tahta_kopru | Timber Bridge | (345,96) | dar dikey 64×68 | NEUTRAL | 2 | 1 | 0 | Nehri geçen köprü, kilit nokta |
| kurt_ini_ormani | Wolfden Wood | (445,100) | 100×56 | ENEMY | **2** | 1 | 1 | Çam, Cürcet avcı obası; bozulma 1 (öğretici tohum) |
| curuk_koru | Rotting Grove | (335,240) | 110×56 | NEUTRAL | 0 | 2 | 3 | Erlik odağı; körmös = bozulma direnci, ayrı birim değil |
| curcet_oba | Jurchen Camp | (460,205) | 100×54 | ENEMY | **4** | 2 | 0 | Kağan ön karakolu |
| curcet_otagi | Jurchen Khan's Court | (562,125) | sekizgen 96×66 | ENEMY | **4** | 3 | 0 | Düşman başkenti; zafer için alınmalı |

Kalın değerler Adım 3 son değerleridir (Adım 2: 3 / 6 / 7).

### 3.2 Komşuluk (9 kenar)

| # | Kenar | Not |
| ---- | ---- | ---- |
| 1 | orman_agzi – kayin_koruluk | Güney yolu |
| 2 | orman_agzi – kuzey_aksu | Kuzey yolu |
| 3 | kayin_koruluk – curuk_koru | |
| 4 | kuzey_aksu – tahta_kopru | |
| 5 | tahta_kopru – kurt_ini_ormani | Grafik darboğazı |
| 6 | kurt_ini_ormani – curuk_koru | Kiriş, korunur (geçerli hamle) |
| 7 | kurt_ini_ormani – curcet_otagi | |
| 8 | curuk_koru – curcet_oba | |
| 9 | curcet_oba – curcet_otagi | |

### 3.3 Genel Bakış Haritası

```
 y45-60  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ nehir (x0 -> ~386)
                                                    ~
   [aksu]------[köprü]===(tahta)---[kurt_ini]-------[OTAĞ]     ~ y~140 gölcük
    (3)          (2)        |         (2, c1)  \      (4,*)
      \                     |        /           \      |
 [AĞZI S]                 (nehir)   /             [oba]
  (6)  \                          /                (4)
        \                       /                  /
       [kayın]-----------[ÇÜRÜK KORU]--------------+
        (2)               (0, c3, ODAK)

 S=başlangıç  *=başkent  c=bozulma  ()=ordu     (şematik; ölçek yok)
```

### 3.4 Kritik yol

1. **Kuzey yolu:** orman_agzi → kuzey_aksu → tahta_kopru → kurt_ini_ormani → curcet_otagi.
2. **Güney yolu:** orman_agzi → kayin_koruluk → curuk_koru (arındırma; +30 Ruh, erlik −3) → curcet_oba → curcet_otagi.
3. Zafer: en az 2 nötr fetih + tüm düşman bölgeleri alınmış + başkent alınmış + odak (curuk_koru) bozulmamış (§6).
4. İlk Erlik yayılımı T3 (büyük olasılıkla kayin_koruluk).

### 3.5 İsteğe bağlı yollar ve ödüller

| Yol | Erişim | Ödül | İpucu |
| ---- | ---- | ---- | ---- |
| kurt_ini L1 arındırma | Bölge alınır | +10 Ruh | Çürük ağaç slotları (440,142), (478,140) |
| Yayılımla oluşan L1 arındırma | Yayılım sonrası | +10 Ruh | Çürük ağaç görünür |
| Kiriş geçişi curuk_koru ↔ kurt_ini | Komşuluk 6 | Yol değiştirme | Çizgi `#5C8F5C` |

Gizli alan yoktur (Uygulanmaz: gizli/toplanabilir; Ruh arzı için bkz. §6).

### 3.6 Temas noktaları ve tempo

| Konu | Değer |
| ---- | ---- |
| Temas noktaları | köprü–kurt_ini, curuk_koru–kurt_ini, curuk_koru–curcet_oba; başta temas yok |
| AI ilk saldırı penceresi | T5–7 |
| Hedef tempo | T10–15, medyan T12 |

## 4. Karşılaşmalar

### 4.1 Düşman bölgeleri

| ID | Konum | Garnizon | Zorluk | Not |
| ---- | ---- | ---- | ---- | ---- |
| E-01 | kurt_ini_ormani | 2 | 3/10 | Kuzey mevzii; bozulma 1; köprüden gelen oyuncuyu karşılar |
| E-02 | curcet_oba | 4 | 5/10 | Ön karakol; güney yolunun kilidi |
| E-03 | curcet_otagi | 4 (+takviye) | 7/10 | Başkent; E_r=1/tur YALNIZ burada |

### 4.2 Cürcet AI (ADR-0005 saf `decide()`, deterministik, tur başına en çok 1 hamle)

| Kural | Tanım |
| ---- | ---- |
| R1 Karşı vuruş | tur ≥ `attack_start_turn` (5). Kaynak E (ordu ≥ 2), hedef komşu OYUNCU bölgesi P; A = E.ordu − 1; koşul A > P_eff **ve** 2A ≥ 3·P_eff (oran ≥ 1.5; `P_eff` = oyuncunun etkin savunması, Demir Post dahil — C-44, [`enemy-layers.md`](../gdd/enemy-layers.md) F-E1). Sıra: en zayıf P_eff, en büyük A, alfabetik `from`, alfabetik `to` |
| Savunma tutma | [`enemy-layers.md`](../gdd/enemy-layers.md) F-E2 (tek tanım, C-44): E'nin iki veya daha fazla oyuncu komşusu varsa ve A ≥ 2 ise E saldırmaz |
| R2 savunma kaydırması | KAPALI (simülasyonda tempoyu bozdu) |
| Bekle | Başka hamle yoksa `null` |
| Kapsam dışı | Nötr bölgelere (çürük koru dahil) girmez; bozulmayı yok sayar (`spirit-system.md` §3.7) |
| Veri | `EnemyAIProfile` (`attack_start_turn=5`, oran 3/2); varsayılan profil eski davranışı korur |

### 4.3 Takviye (F6)

E_r = 1/tur, yalnız `curcet_otagi`. Yeni bölüm verisi: `enemy_reinforcement_region_ids = [curcet_otagi]`; boş liste = tüm
düşman bölgeleri (Prolog / eski davranış). Başkent geri alınırsa takviye yeniden başlar.

### 4.4 Erlik karşılaşması (odak)

| Alan | Değer |
| ---- | ---- |
| Odak | `erlik_foci = [curuk_koru]` (başkent odak değil; başlangıç odağı yok) |
| Başlangıç `erlik_power` | 4 |
| `erlik_spread_interval` | 3 (arındırma aralığı sıfırlamaz) |
| `erlik_loss_threshold` | 9 |
| Arındırma | curuk_koru: P ≥ 13; +30 Ruh, erlik −3 |
| Körmös | Ayrı birim değil, bozulma direnci; yalnız betimlenir |

## 5. Tempo Grafiği

```
Yoğunluk
10 |                                        *  (başkent)
 8 |                              *   *  *
 6 |                    *  *  *               (AI vuruşu T5-7, yayılım T3/6/9/12)
 4 |        *  *  *
 2 |  * *
 0 |T1----T3----T5----T7----T9----T12----T15
    [kurulum] [temas+yayılım] [sıkışma] [başkent]
```

| Evre | Tur | Ritim |
| ---- | ---- | ---- |
| Kurulum | T1–4 | Nötr fetih, Kök Böri işareti, HINT_ENEMY_KING; ilk yayılım T3 |
| Sıkışma | T5–9 | AI karşı vuruşu (T5–7), arındırma kararı, iki cephe |
| Çıkış | T10–15 | Başkent saldırısı; pasif oyuncuda T15 Erlik kaybı baskısı |
| Dinlenme | — | "Tur Bitir" hep açık; gelir gelir (kilitlenme yok) |

### Simülasyon sonuçları (başlangıç değerleri; replay ile doğrulanacak)

| Senaryo | Sonuç |
| ---- | ---- |
| N-fast | Zafer T12 |
| S-purify-first | Zafer **T20** (AI vuruşu T7) — C-44 düzeltmesi: eski "T14" orkestratör tablo okuma hatasıydı |
| Mixed | Zafer T14 (AI vuruşu T5) |
| 3 tur boş | Zafer T15 |
| 6 tur boş | Zafer T18 |
| N-no-purify | Kayıp T18 (Erlik) |
| Pasif | Kayıp T15 (Erlik) |

Oyuncu modeli basit planlayıcıdır; gerçek değerler C-64 tarzı controller testiyle yeniden doğrulanacak.

> **RİSK (C-44, 2026-10-21):** Güney yolu (önce arındır) basit oyuncu modelinde T20 — başkent
> Cürcet Obası'nı geri alıyor (R1 geri alma), arkada 1 ordu bırakan oyuncu cezalanır. Değerler
> şimdilik değişmez; C-47 gerçek controller replay'i esas; gerekirse `attack_start_turn` veya
> başkent takviyesi ayarlanır. (T20, hedef aralığın T10–18 dışındadır; yalnız bu basit modelde.
> Mixed W14 doğrudur.) Ayrıntı: [denge raporu](../balance/boon-balance-2026-10-21.md).

## 6. Kazanma Koşulu, Sahne Verisi ve Kaynak

| Alan | Değer |
| ---- | ---- |
| `required_neutral_conquests` | 2 |
| `must_defeat_all_enemies` | true |
| `erlik_foci` | [curuk_koru] |
| `erlik_loss_threshold` | 9 |
| `objective_region_ids` | [curcet_otagi] |
| `erlik_spread_interval` | 3 |
| `starting_gold` | 6 |
| `enemy_reinforcement_per_turn` | 1 (yalnız `enemy_reinforcement_region_ids`) |
| `actions_per_turn` | 1 |
| Kayıp nedeni | Tüm bölgeler kaybı = mevcut `NO_REGIONS` (yeni enum yok); Erlik kaybı `DEFEAT_REASON_ERLIK` |

| Ruh kaynağı | Miktar | Durum |
| ---- | ---- | ---- |
| curuk_koru L3 arındırma | +30 | Zorunlu. C-44 (2026-10-21): Prolog'da lütuf alan oyuncu için Perde 1'deki sıradaki lütuf 50 Ruh; Çürük Koru +30 tek başına yetmez, seçim opsiyonel arındırmalara (+10 / +10) bağlıdır |
| kurt_ini L1 | +10 | İsteğe bağlı |
| Yayılımla oluşan L1 | +10 | Duruma bağlı |
| Perde 1 toplamı | ~40–60 | İlgili oyuncu |

## 7. Görsel Yön

### 7.1 Palet ve ışık

| Öğe | Değer |
| ---- | ---- |
| `ground_color` | `#0F1A0D` |
| `adjacency_line_color` | `#5C8F5C` (zemine 4.72:1; `#294726` 1.72:1 reddedildi) |
| Orman rampası | `#070D05 #0F1A0D #1A2E17 #294726 #3D6B3D #5C8F5C` |
| Işık uçları | `#87B85C #B8D49E` yalnız ağaç tepesinde |
| Nehir | `#1F2B52 #2E4761` (dolgu, 1.87:1) + `#476B8F` kıyı çizgisi (3.21:1) |
| Çürük ağaç vurgusu | `#A86BC4` pikselleri (kırık taç konturu), 4.74:1 |
| Yasak | Pas turuncusu ışık, gök mavisi su, Ülgen altını süs, Erlik moru gölge, palet dışı alfa/fade/modulate |

### 7.2 Yön işaretleri ve yerleşim kuralları

| Kural | Değer |
| ---- | ---- |
| Poligonlar | Dokunulmaz; dekor bölge dışı boşluklarda; etiket/tamga alanı boş; bölge başına ≤5 prop |
| Ağaç yoğunluğu | Batıda seyrek → doğuda sık (≈26 ağaç) |
| Başlangıç | Batı/ortada; SOL-ÜST başlangıç yok (ipucu balonu); SAĞ-ALT köşe boş (136 px bilgi paneli) |
| Çürük ağaç | Bozulma verisinden çizilir (corruption ≥ 1), arınınca kalkar; anlam biçimde (taçsız, kırık), renkte değil |
| Körmös | Bölge İÇİNDE durur |

### 7.3 Nehir (onaylı L-dönüşü)

- y45–60 bandı, x0 → ≈386; sonra köprü ile kurt_ini arasındaki aralıktan (x382–390) güneye y≈140'a iner, ≈12×8 gölcükte biter; y150'yi geçmez.
- Üst sınır ≥ `_top_bar_height()` + 4 (ekran görüntüsüyle ölçülecek).
- Köprü tahtası 16×10, ayak (386,98); köprü–kurt_ini komşuluk çizgisi üstünde.

### 7.4 Otağ (Cürcet Kağan)

Prop poligonun ÜSTÜNDE: ayak (584,90), x570–598 y66–90; 28×24 görünür / 32×28 kanvas. Tamga: `icon_tamga_curcet.png` (mevcut).

### 7.5 Dekor yerleşimi (ayak noktaları)

| Grup | Konum | Adet |
| ---- | ---- | ---- |
| Orman Ağzı batı | (30,120), (48,300) | 2 |
| Doğu kapı kümesi | (150,184), (158,200), (148,212) | 3 |
| Köprü–koru boşluğu | x≤346, y150–205 | 4 |
| Kayın altı (yayılım slotu) | (168,322), (232,324) | 2 |
| Koru–oba arası | — | 3 |
| Kuzey şerit çamları | ayak y62–68 | 6 |
| Otağ–oba sağı | — | 5 |
| Çürük koru slotları (corr ≥ 1) | (292,208), (322,206), (362,205), (350,272), (310,276) | 5 |
| kurt_ini L1 slotları | (440,142), (478,140) | 2 |
| Körmös (OVERLAY) | curuk_koru içi: x287–299 y247–261 ve x371–383 y247–261 | 2 |

Poligon sınırları (dekor çakışma testi için): orman_agzi x60–140 y163–217; kuzey_aksu x175–275 y72–130; tahta_kopru x313–377 y62–130;
kurt_ini x395–495 y72–128; curuk_koru x280–390 y212–268; curcet_oba x410–510 y178–232; curcet_otagi x514–610 y92–158.

### 7.6 Dekor sistemi (en küçük çözüm)

> **✅ Veri modeli C-84 (2026-10-29):** `features/grid/map_decor_item.gd` (`frames`, ayak `position`, `layer`, `bound_region_id`, `min/max_corruption`, `fps`; saf `is_visible(level)`, `is_animated()`), `features/grid/map_decor.gd` (`items`, `water_rects`, `items_in_layer` ayak-y → x sıralı), `ChapterMapDefinition.decor = null`; test `tests/unit/grid/map_decor_item_test.gd`. Çizim (`MapDecorLayer`) C-85.

> **✅ Çizim C-85 (2026-10-29):** `features/grid/map_decor_layer.gd`; `CampaignMap.set_decor()` → `build_map` üç katman kurar (GROUND + su, çizgiler, PROP, bölgeler, OVERLAY), `refresh()` bozulma seviyelerini geçirir, `apply_accessibility` Hareketi Azalt'ı (kare 0, `_process` kapalı); `_process` yalnız görünür animasyonlu öğe varken; nehir dolgu `#1F2B52` + birleşik 1 px kıyı `#476B8F` (L-dönüşünde iç çizgi yok); ayak → tuval `CANVAS_PAD = 2` (varlık kuralı). Test `tests/integration/grid/map_decor_layer_test.gd` (7), kanıt `production/qa/evidence/c85-decor-layer*.png` (Prolog haritasında test dekoru). **Bulgu (C-98'e):** koyu mor körmös mor bozulma lekesi üstünde düşük kontrast — Perde 1 yerleşimi lekesiz köşeye ya da ayrı çerçeve/gölge kararı ister.

| Parça | Tanım |
| ---- | ---- |
| `MapDecorItem` (Resource) | texture/frames, position (ayak), layer {GROUND, PROP, OVERLAY}, `bound_region_id`, `min_corruption`, `max_corruption` (-1 sınırsız), fps; saf `is_visible(level)` |
| `MapDecor` | items + su dikdörtgen listeleri |
| `MapDecorLayer` (Node2D) | features/grid |
| `ChapterMapDefinition.decor` | `MapDecor = null` (Prolog null → davranış değişmez) |
| `CampaignMap.set_decor()` | `build_map` öncesi |
| Çizim sırası | ColorRect → GROUND (nehir) → çizgiler → PROP (ağaç, köprü, otağ) → RegionNode → OVERLAY (körmös); katman içinde ayak y sıralı |
| Bozulma bağlı görünürlük | Çürük ağaç `min=1`; aynı noktadaki sağlıklı ağaç `max=0`; `refresh()` zincirinde apply_corruption |
| VFX | Körmös 2 kare, 2 fps (kare 1: 1 px yukarı), alfa yok; Hareketi Azalt → `set_process(false)`, kare 0; `_process` yalnız görünür animasyonlu öğe varken |

### 7.7 Varlıklar (`tools/asset-pipeline/generate_env_forest.gd`, char-grid, deterministik, palet doğrulayıcı)

| Varlık | Boyut (görünür/kanvas) |
| ---- | ---- |
| env_tree_healthy_01 | 12×20 / 16×24 |
| env_tree_healthy_02 | 12×18 / 16×22 |
| env_tree_rotten_01, _02 | 10×16 / 14×20 |
| env_bridge_wood_01 | 16×10 / 20×14 |
| env_otag_curcet_01 | 28×24 / 32×28 |
| unit_kormos_forest_idle_0/_1 | 12×14 / 16×18 |
| Nehir | Kodla çizilir (varlık yok) |

> **C-46 (2026-10-21):** Üretildi — `game/assets/art/maps/env/env_*.png`, `game/assets/art/units/unit_kormos_forest_idle_0/_1.png` (art bible adlandırması: `unit_` kategorisi; eski taslak adı `char_spirit_forest_idle`). Test: `tests/unit/art/env_forest_assets_test.gd` (tuval boyutu, ikili alfa, boş dolgu, körmös 1px süzülme); kanıt `production/qa/evidence/c46-env-forest-sheet.png`.

### 7.8 Erişilebilirlik (BLOCKING çözümleri)

| # | Sorun | Çözüm |
| ---- | ---- | ---- |
| 1 | Çürük ağaç kontrastı 1.1:1 | `#A86BC4` vurgu pikselleri; anlam ayrıca bölge lekesi + bilgi paneli seviye sayısı |
| 2 | Düşman–nötr renk körlüğü (protanopi 1.09) | ENEMY bölgelerde owner tamgası HER ZAMAN görünür (renk körlüğü modundan bağımsız); nötrde tamga yok. Prolog etkilenmez |
| 3 | Komşuluk çizgisi 1.72:1 | `#5C8F5C`; zemine kontrast ≥ 3:1 testle kilitlenir |
| R1 | Nehir | `#476B8F` kıyı çizgisi |
| R2 | Hedef | Mevcut `icon_objective_marker` + HUD Hedef satırı yeterli |
| R3 | Bilişsel yük | HUD'a "Yayılım: N tur" sayacı; takviye (yalnız başkent) ve AI kuralı `HINT_ENEMY_KING` / `HINT_CAPITAL` metninde |

Ertelenen (cila): saldırıya uğrayan bölge harita işareti; ses ipuçları eşlemesi.

## 8. Ses Yönü

Onaylı girdi yok. Müzik/ambiyans ve sahne içi ses işaretleri `audio-director` ile belirlenecek (açık). Ses ipuçları eşlemesi
Adım 4'te cilaya ertelendi. Mevcut `AudioController` / `SfxLibrary` (ADR-0008) kullanılır.

## 9. Toplanabilirler ve Gizli Alanlar

Uygulanmaz — ULUS'ta toplanabilir/gizli alan yoktur. İsteğe bağlı ödüller: bkz. §3.5 ve §6.

## 10. Teknik Notlar

| Alan | Değer |
| ---- | ---- |
| Nesne sayısı | 8 bölge + ≈26 ağaç + 7 çürük/slot + 2 körmös + köprü + otağ + nehir (draw call bütçesi < 200 içinde) |
| Akış / streaming | Uygulanmaz; bölüm haritası `load()` ile yüklenir (ADR-0012) |
| Performans | `_process` yalnız görünür animasyonlu dekor varken |
| Kayıt / yükleme | Dekor bozulmadan türetilir; yükleme sonrası aynı |
| Gerekli sistemler | Bölge haritası, kaynak (F6), Ruh/arındırma, Erlik yayılımı, `EnemyAIProfile`, sahne akışı, yerelleştirme |

## 11. Kenar Durumlar (kararlar)

| Durum | Sonuç |
| ---- | ---- |
| Komşu olmayan hamle | Reddedilir; kiriş (curuk_koru–kurt_ini) geçerli |
| Kilitlenme | Yok. Tek bölge + 1 ordu + 0 altın: oyunu Erlik eşiği bitirir (KARAR) |
| Aynı turda zafer + Erlik kaybı | Mevcut "önce kaybetme" kuralı (`region-map-system.md` §3.4, `scene-flow.md`) (KARAR) |
| Son düşman bölgesi | Tümü alınmadan zafer yok |
| Başkent geri alınırsa | Takviye yeniden başlar |
| Arındırma | Yayılım aralığını sıfırlamaz |

## 12. Gerekli GDD/ADR Güncellemeleri

| Belge | Bölüm | Değişikliğin özü |
| ---- | ---- | ---- |
| `design/gdd/region-map-system.md` | AI kuralları; WinCondition; sahip tamgası; kayıp nedeni | R1 karşı vuruş + savunma tutma + `EnemyAIProfile`; `MoveIntent.reason`; Perde 1 WinCondition alanları; ENEMY bölgede tamga her zaman görünür / nötrde yok; Erlik kaybı metni sahneden bağımsız |
| `design/gdd/resource-system.md` | F6 takviye; "boşta" notu | Takviye bölge listesi `enemy_reinforcement_region_ids` (boş = tüm düşman bölgeleri); Perde 1 için "boşta" notu |
| `design/gdd/spirit-system.md` | Ruh arzı; §3.7 | Perde 1 Ruh arzı (+30 / +10 / +10, ~40–60); AI bozulmayı yok sayar ve nötr bölgelere girmez |
| `design/gdd/scene-flow.md` | Sahne kataloğu §3.1; veri modeli §3.10; yenilgi §3.7 | `perde1_dogu` (`chapter_id=2`) girişi, G-1..G-3 / O-1..O-2, `map_path`, `enemy_reinforcement_region_ids`; Perde 2 bağlantısı (§13); `DEFEAT_REASON_ERLIK` sahneden bağımsız |
| `design/art/art-bible.md` (otağ boyut satırı) | Boyut tablosu | `env_otag_curcet_01` 28×24 görünür / 32×28 kanvas; ağaç/köprü boyutları (§7.7); orman rampası ve nehir renkleri zaten küresel palette (`#A86BC4` Erlik moru rampasının açık ucu — yalnız Erlik anlamında, kural ihlali yok) |
| `docs/architecture/adr-0005-ai-architecture.md` | Ek | `decide()` R1 kuralı, `EnemyAIProfile` veri kaynağı, `MoveIntent.reason`, determinizm |
| `docs/architecture/adr-0011-presentation-layer-reports.md` | Ek | `MapDecorLayer`, `MapDecorItem.is_visible(level)`, `refresh()` zincirinde apply_corruption, HUD "Yayılım: N tur" sayacı, tamga görünürlük kuralı |
| `design/narrative/narrative-voice.md` | Ad sözlüğü | Cürcet / Jurchen girişi (zh/ja 女真, ko 여진); doğrulanmamış nüsha notu; "av" değil "şifa" dili; körmös konuşmaz |
| `design/registry/entities.yaml` (Adım 3'ten; istenen listede yok) | Kayıt | Yeni varlıklar/sabitler: `EnemyAIProfile`, `attack_start_turn`, `enemy_reinforcement_region_ids` |

## 13. Uygulama Görevleri (sıralı)

| # | Parça | Görev | Bağımlılık |
| ---- | ---- | ---- | ---- |
| 1 | Kod | `EnemyAIController.decide` R1 + `EnemyAIProfile` + `MoveIntent.reason`; `tests/unit/ai/` | — |
| 2 | Kod | `ResourceController` F6 takviye bölge listesi (boş = eski davranış); `tests/unit/resources/` | — |
| 3 | Kod | `MapDecorItem` / `MapDecor` / `MapDecorLayer`, `ChapterMapDefinition.decor`, `CampaignMap.set_decor()`, bozulma bağlı görünürlük | — |
| 4 | Kod | HUD "Yayılım: N tur" sayacı; ENEMY tamga her zaman görünür; `adjacency_line_color` `#5C8F5C` | 3 |
| 5 | Kod | `DEFEAT_REASON_ERLIK` sahneden bağımsız | — |
| 6 | İçerik | `generate_env_forest.gd` üreticisi + varlıklar (§7.7), palet doğrulayıcı güncellemesi | — |
| 7 | İçerik | Perde 1 `.tres` harita + WinCondition + `decor` + sahne tanımı; `campaign.tres`'e `perde1_dogu` | 1–3, 6 |
| 8 | İçerik | `translations.csv` anahtarları (11 dil) | 7 |
| 9 | Test | Birim: AI (13; C-44 inceleme, bilgi notu), F6 (3), win_condition (4), map_decor_item, map_decor_geometry, ui kontrast, hud_presenter | 1–5, 7 |
| 10 | Test | `integration/balance/perde1_balance_test` (gerçek controller replay): N-fast W12, S-purify **W20** (C-44: eski W14 yanlıştı; RİSK notu §5), Mixed W14, no-purify L18, pasif L15, 3 boş tur 15'ten önce zafer yok. Fark çıkarsa replay esas alınır, belge güncellenir; S-purify T20 ise `attack_start_turn` / başkent takviyesi ayarı değerlendirilir | 1, 2, 7 |
| 11 | Test | `integration/campaign/perde1_playthrough_test`: UI ile intro → zafer → outro → menü | 7, 8 |
| 12 | Doğrulama | Ekran görüntüsü (nehir `_top_bar_height()+4`), 12 maddelik playtest | 7 |
| 13 | Belge | §12 güncellemeleri | Onaydan sonra |

### Kabul kriterleri

| # | Kriter | Seviye |
| ---- | ---- | ---- |
| 1 | Tüm birim testleri geçer | BLOCKING |
| 2 | Denge replay tam tur | BLOCKING |
| 3 | Pasif T15 Erlik kaybı; 3 tur boş bekleyen 15'ten önce kazanamaz | BLOCKING |
| 4 | AI tur < 5 saldırmaz; nötr/Erlik bölgesine girmez | BLOCKING |
| 5 | Düşman tamgası hep görünür; kontrast ≥ 3:1 | BLOCKING |
| 6 | Prolog davranışı değişmez (null decor, boş F6 listesi) | BLOCKING |
| 7 | Kayıt/yükleme sonrası dekor eşit | BLOCKING |
| 8 | Ekran görüntüsü kanıtı | ADVISORY |
| 9 | Playtest 12 madde | ADVISORY |
| 10 | Medyan T10–15 bandı playtest verisiyle | ADVISORY |
| 11 | *(C-44 inceleme (2026-10-21), D1 / H1)* Replay'de **S-purify (önce arındır) ≤ T16**. Sağlanmazsa seviye verisi ayarlanır (ör. `attack_start_turn`, başkent takviyesi, garnizon); Kök Böri'nin sözü değişmez | BLOCKING |
| 12 | *(C-44 inceleme, D5 / H2, H3, H4, W-7)* C-47 replay ölçüm maddeleri yapılmıştır (aşağıdaki "C-47 ölçüm maddeleri" listesi); sonuçlar kabul / erteleme kaydıyla yazılır | BLOCKING (ölçüm yapılmış olması) |

**Birim test adları:** `unit/ai` — `test_counterattack_before_turn_five_never_strikes`, `_at_turn_five_strikes_when_ratio_met`,
`_ratio_exactly_one_and_half_strikes` (2A=3P), `_ratio_just_below_threshold_holds`, `_requires_attacker_greater_than_defender`,
`_holds_when_source_defends_other_player_neighbor`, `_never_enters_neutral_region`, `_ignores_corruption_level`,
`_weakest_target_largest_attacker_alphabetical_ties`, `_is_deterministic_across_runs`. `unit/resources` F6 — `test_reinforcement_empty_region_list_matches_legacy_all_enemy_regions`,
`_capital_only_list_adds_to_capital_alone`, `_non_enemy_listed_region_gets_nothing`. `unit/grid/win_condition` —
`test_perde1_victory_requires_two_neutral_conquests_and_capital_cleared`, `_not_met_with_two_conquests_and_enemy_alive`,
`_not_met_when_focus_corrupted`, `_erlik_threshold_nine_is_loss_at_nine_not_eight`. `unit/grid/map_decor_item`: çürük ağaç 0'da gizli / 1'de
görünür; sağlıklı ağaç 1'de gizli (`max=0`); sınırsız max (-1). `unit/grid/map_decor_geometry` (.tres): proplar poligon dışı; üst bar + 4 altı;
nehir y150 üstü; overlay bağlı bölge içinde; bölge başına ≤5 prop. `unit/ui`: kontrast `#5C8F5C` ≥ 3:1; düşman tamgası renksiz görünür;
nötrde tamga yok. `unit/ui/hud_presenter`: yayılım sayacı geri sayar, yayılım turunda sıfır.

### C-47 ölçüm maddeleri (C-44 inceleme (2026-10-21), D5)

Replay'de ölçülür; sonuçlar için kabul / erteleme kaydı yazılır:

| Madde | Ölçüm | Kaynak |
| ---- | ---- | ---- |
| T5 sonrası AI adayı | "T5 sonrası uygun AI adayı olan tur oranı" (H2). Düşükse başkent F-E2'den muaf tutulması **kullanıcıya sorulur** | H2 |
| Felç + yeniden arındırma | Ruh/tur çizgisi (odağı L3 bırak, komşu yayılımları yeniden arındır); aşılırsa `spirit-system.md` ×0.5 yedeği açılır | H3 |
| Giriş varyantları | GK1 (Gök Kalkanı ×1) ve Bereket1 ile girişte replay (lütufsuz giriş kabul #3'ü yalnız tek başına geçer). **Pasif + GK1 oyuncusunun kaybı > T18 ise Perde 1 `erlik_loss_threshold` 9 → 8** | H4 |
| N4 / N5 / N6 / N8 / N9 | Perde 1 için ölçülür, kabul / erteleme kaydı yazılır (`spirit-system.md` §3.7, §5 işaretçileri "C-47 replay sonrası") | W-7 / D5 |

### Playtest listesi (12)

1 Prolog→Perde 1 geçişi, G-1..G-3 · 2 ilk tur `HINT_ENEMY_KING` · 3 nehir HUD altında, köprüden geçiliyor · 4 ağaç yoğunluğu batı seyrek / doğu sık, çürük ağaçlar Erlik bölgesinde ·
5 düşman tamgası hep görünür · 6 komşuluk çizgileri okunur · 7 "Yayılım: N tur" azalıyor · 8 ilk düşman saldırısı T5–7, `BATTLE_LOST_DEFENSE` (HELD değil; C-44 inceleme, W-5) ·
9 koru arındırma → CLEANSED + Ruh +30 · 10 `HINT_CAPITAL` bir kez · 11 zafer/kayıp T10–18 · 12 kayıt/yükleme dekor + sahiplik aynı.

## 14. Açık Bağımlılıklar

| Konu | Durum | Not |
| ---- | ---- | ---- |
| Perde 2 | UNRESOLVED — `design/levels/` altında belge yok | Yalnız sahne akışı bağlantısı: Perde 1 zaferi → anlatı çıkışı (O-2, teaser: batıda Urum) → sefer haritasında sonraki sahnenin açılması (`scene-flow.md` F1). Perde 2 yerleşimi/kimliği bu belgede tanımlanmaz |
| C-44 | Çözüldü (2026-10-21) | Perde 1 Ruh çıktısı ~40–60; lütuf seçimi zorunlu değil (zayıf oyuncu seçimsiz bitirebilir, Ruh taşınır). Bkz. [denge raporu](../balance/boon-balance-2026-10-21.md), `spirit-system.md` §4.4 |
| Denge | Açık | Simülasyon değerleri gerçek controller replay ile doğrulanacak (§13 #10); S-purify T20 riski (§5) C-47'de izlenir. C-44 inceleme (2026-10-21): S-purify ≤ T16 BLOCKING kriteri (D1, §13 kabul #11); D5 ölçüm maddeleri (§13 "C-47 ölçüm maddeleri"); H4 — pasif + GK1 > T18 ise `erlik_loss_threshold` 9 → 8 |
| Ses | Açık | `audio-director` girdisi yok (§8) |
| Nehir üst sınırı | Açık | `_top_bar_height()` ölçümü (§7.3) |
