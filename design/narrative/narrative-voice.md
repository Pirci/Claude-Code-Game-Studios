# Anlatı Sesi Rehberi — Raporlar, Kök Böri İşareti, Canavar Anı

*Oyun: ULUS: Blood of the Sky Wolf*
*Oluşturulma: 2026-10-19 — Görev C-54 (çapraz inceleme D7 / N10; `scene-flow.md` Q8)*
*Durum: Taslak (gece modu — kullanıcıya ait kararlar önerilen seçenekle verildi, §9)*
*Sahip: narrative-director (metin taslakları writer düzeyinde, ana dil incelemesi bekliyor)*

> Bu belge oyuncunun **okuduğu** metnin sesini tanımlar. Kural, sayı ve formül değiştirmez: tüm
> sayılar `MoveOutcome`, `HudModel`, `MapState.loss_reason` gibi mevcut verilerden gelir (ADR-0010,
> ADR-0011). Metin anahtarları `game/assets/locale/translations.csv`'de 11 dilde mevcuttur (§8).

---

## 1. Sorun ve Hedef

Çapraz inceleme D7/N10: harita, ordu ve savaş "kuru savaş oyunu aritmetiği" gibi okunuyor; Prolog'un
doruğu "14 yığ ve yürü"den ibaret; Kök Böri yalnızca son modalda görünüyor. Anti-sütun **"Kuru Tarih
Simülasyonu DEĞİL"** risk altında.

**Hedef:** Hiçbir sayı gizlenmeden her rapor bir destan dizesi gibi açılsın; Kök Böri sahnenin başında
hedefi gösterip canavar anında geri dönsün; yenilgi bile bir "sazın susması" olsun.
**Bitti kriteri (C-54):** rapor ekranlarında "kuru hesap" dili yok (§7 denetimi), metin rehberi + key listesi
(§8).

## 2. Ton Sütunları

| Sütun | Anlamı | Test |
| ---- | ---- | ---- |
| **Destan ağzı, sade söz** | Oğuz Kağan Destanı'nın sözlü ritmi: kısa, paralel cümleler ("Canavar düştü… otlar yeşerdi"), somut imgeler (ocak, sürü, mızrak, ışık, leke) | Cümle sesli okunduğunda saz eşliğine uyar mı? |
| **Arkaizm yok** | "Erdi", "eyledi", "ol" gibi eski biçimler yalnızca tek bir tanınmış alıntıda ("Ben sizlere oldum Kağan"); geri kalan çağdaş ve anlaşılır | İlk kez oynayan 12 yaşındaki biri anlar mı? |
| **Epik ama erişilebilir** | Başlık satırı duygu, altındaki satırlar sayı. Sayı hiçbir zaman cümlenin içine gömülmez | Oyuncu 2 saniyede "ne kaybettim, ne kazandım"ı okur mu? |
| **Ağırbaşlı** | Art bible §2 "Savaş Raporu: ciddi, nesnel, sade". Ünlem, şaka, abartı sıfatı yok; Arapça/İspanyolca'da ünlem işareti hiç kullanılmaz | Rapor bir yas ya da zafer haberini ağırlıkla mı veriyor? |
| **İki katman, iki dil** | Siyasi katman "ordu, saf, toprak" konuşur; Erlik katmanı "leke, gölge, yutmak, karanlık"; Ülgen/Kök Böri "ışık, yol, uluma" | Bir satırdan hangi katmanın konuştuğu anlaşılıyor mu? |

## 3. Anlatıcı Kararı: Kim Konuşuyor?

**Karar (önerilen, uygulandı): iki ses.**

1. **Ozan (varsayılan ses).** Oğuz'un boyundan bir ozan; raporları, tur özetini, yenilgiyi ve HUD
   uyarısını söyler. Birinci çoğul ("akıncılarımız", "son toprağımız"), geçmiş zaman, isimsiz (ozan
   kendini hiç anmaz). Karşı taraf "karşı saf / düşman / onlar"dır; Prolog'daki nötr boylara "düşman"
   denmez (onlar birleşecek boylardır).
2. **Kök Böri (kutsal ses).** Yalnızca dört anda konuşur: genesis sayfası, hedef işareti, canavar avı
   hazır olduğunda (uluma), lütuf sunumu (C-39). Oğuz'a ikinci tekil ("Işığımı izle, Oğuz"), emir kipi,
   en çok iki kısa cümle. Seyrekliği kutsallığını korur.

| Seçenek | Artı | Eksi | Sonuç |
| ---- | ---- | ---- | ---- |
| A. Ozan + seyrek Kök Böri | Raporlar sıcak ve tutarlı; Kök Böri anları olay olarak kalır; SDT-ilişki ("bizim boy") | İki sesin ayrımı çevirmene anlatılmalı (§6) | **Seçildi** |
| B. Her raporu Kök Böri anlatır | Mitik varlık sürekli | Her tur konuşan tanrı sıradanlaşır; yenilgide "tanrı alay ediyor" tonu | Reddedildi |
| C. Nötr kronik ("Saldıran 3 kayıp verdi") | Çeviri kolay | D7'nin kendisi; anti-sütun ihlali | Reddedildi |

**Oyuncuya doğrudan hitap** (sistem satırları: onay ipucu, ilerleme güvencesi) mevcut UI'ın hitap
biçimini izler: tr/de/es "sen", fr "vous", ru "вы", pt "você"; Kök Böri'nin sözünde fr "tu", ru "ты".
Japonca/Korece/Çince'de destan kipi (である / -다 / 書面語) kullanılır.

## 4. Rapor Biçimi: Dize + Sayılar

Her rapor modalı aynı üç katmanı izler (art bible §7 "Savaş raporu"):

```
[Başlık 24px, altın]      Meydandan Haber
[Ozan dizesi, 12px krem]  Akıncılarımız safı yardı. Toprak artık bizim.
[Sayı satırları + ikon]   ↓ Düşen yiğitlerimiz: 2
                          ↓ Karşı saftan düşen: 3
                            Ayakta kalan yiğitlerimiz: 3
```

- Sayılar **her zaman** görünür; `NumberFormatter.format_int` ile biçimlenip `%s`'e verilir. Kazanç
  işaretini kod ekler (`+30`), kayıp satırları işaretsizdir; `↑`/`↓` piksel ikon ya da Fusion'da bulunan
  ok glifi, kayıp için ASCII `-` (ADR-0009). Metinde `−` `⚠` `✕` `✓` yok.
- Etiketler "kim, ne oldu" der, muhasebe terimi değil: *Kayıp/Kalan/Saldıran/Savunan* yerine
  *düşen yiğitlerimiz / ayakta kalan / bozkıra dağılan / karanlığa giden / toprağa yerleşen*.
- Dize satırı en çok 2 satır (≈ 96 Latin karakter), sayı satırı tek satır.

### Yapma / Yap

| Yapma (kuru hesap) | Yap (aynı bilgi, destan ağzı) |
| ---- | ---- |
| Saldıran kazandı. Kayıp: 2, Kalan: 3 | Akıncılarımız safı yardı. Toprak artık bizim. / Düşen yiğitlerimiz: 2 / Ayakta kalan yiğitlerimiz: 3 |
| Savunan kazandı. Saldıran birlikleri dağıldı: 1 | Karşı saf dayandı. Hücumumuz onlara çarpıp dağıldı. / Bozkıra dağılan: 1 |
| Arındırma başarısız. Kayıp: 8 | Erlik yuttu. Gidenlerden kimse dönmedi. / Karanlığa giden: 8 / Erlik direnci 12 idi. Daha büyük bir orduyla dön. |
| Arındırma başarılı. +30 Ruh | Ülgen'in ışığı döndü. Toprak yeniden arındı. / Kazanılan Ruh: +30 |
| Bozulma +1 (Doğu Obası) | Erlik'in lekesi yayıldı: Doğu Obası |
| Kaybettiniz: bozulma eşiği aşıldı | Erlik'in gölgesi ata yurdunu yuttu. / Erlik'in Gölgesi: 9 / 9 |

## 5. Mitik Anlar

### 5.1 Kök Böri hedef işareti (Prolog, `scene-flow.md` §3.5)

- Genesis sayfası `CHAPTER_1_KOKBORI_1`: destandaki iniş — "gökten bir ışık indi, ışığın içinden gök
  yeleli büyük bir kurt çıktı" — ve ilk söz: "Kalk, Oğuz. Yolu ben göstereceğim."
- Hedef paneli: Kök Böri sözü `CHAPTER_1_KOKBORI_LINE` = **"Işığımı izle, Oğuz. Işığın düştüğü yerde
  canavar bekliyor."** Mekanik hedef (`OBJECTIVE_LABEL` + `WIN_CONDITION_CH1`) düz kalır; söz ile harita
  ışığı (`icon_objective_marker`) aynı imgeyi taşır: ışığın düştüğü yer = işaretli bölge.

### 5.2 Canavar anının ritüel çerçevesi (N10)

Kural aynı (Canavarın İni: `S = 12`, başarı `P > 12`, spirit §3.2). Değişen, o hamlenin **sunumudur** —
"14 yığ ve yürü" bir av ritüeline dönüşür. Üç vuruş:

| Vuruş | Tetik (mevcut veri) | Metin | Sunum notu (öneri: art/audio) |
| ---- | ---- | ---- | ---- |
| 1. **Çağrı** | Hamle önizlemesi hedefi sahnenin Erlik odağı ve `purified == true` | Başlık `CHAPTER_1_HUNT_HEADING` "Canavar Avı" + `CHAPTER_1_HUNT_READY` "Kök Böri uludu. Canavarın son saati geldi." | Haritadaki hedef işareti 2 kare parlar; kısa uluma (`sfx_kok_bori_appear` kısaltması). Hareketi Azalt: parlama yok |
| 1'. **Henüz değil** | Aynı hedef, `purified == false` | `CHAPTER_1_HUNT_NOT_READY` "Canavar bu ordudan güçlü. Daha çok yiğit topla." + ikinci seçim onayı `PURIFY_CONFIRM_AGAIN` | Uluma yok — Kök Böri hazır olmayanı çağırmaz |
| 2. **Av** | Hamle uygulanır, rapor | Başarı: `CHAPTER_1_SLAIN_HEADING` "Canavar Yenildi" + `CHAPTER_1_SLAIN_LINE` "Oğuz mızrağını canavara sapladı. Bozkır yeniden nefes alıyor." + Ruh satırı. Başarısızlık: `CHAPTER_1_HUNT_FAILED` "Canavar hâlâ yaşıyor. İni orduyu yuttu." | Rapordan sonra zafer dizisi (`VICTORY_BEAT`) gelir; çıkış O-1 aynı imgeyi sürdürür |

**Veri bağı (öneri → C-40 / C-62):** `SceneDefinition`'a isteğe bağlı dört sunum alanı:
`focus_heading_key`, `focus_ready_key`, `focus_not_ready_key`, `focus_success_key` (+ `focus_fail_key`);
boşsa genel arındırma anahtarları kullanılır. Prolog bunları `CHAPTER_1_HUNT_*` / `CHAPTER_1_SLAIN_*` ile
doldurur; Perde 1'in "çürümüş orman" odakları kendi ritüel metnini alır (C-43). Kural katmanına dokunmaz.

### 5.3 Yenilgi (scene-flow §3.7)

Ozan sazı susar, destan bitmez: neden satırı + güvence satırı (`DEFEAT_PROGRESS_KEPT`) + `ERLIK`
sebebinde `ERLIK_SHADOW_VALUE` ("Erlik'in Gölgesi: 9 / 9" — öğrenme geri bildirimi).

| `loss_reason` | Anahtar | tr |
| ---- | ---- | ---- |
| `ERLIK` | `DEFEAT_REASON_ERLIK` | Erlik'in gölgesi ata yurdunu yuttu. |
| `NO_REGIONS` | `DEFEAT_REASON_NO_REGIONS` | Son toprağımız da düştü. Hiçbir ocağımızda ateş kalmadı. |
| `NONE` / eşlemesiz | `DEFEAT_REASON_GENERIC` | Destan burada sustu, şimdilik. |

### 5.4 Erlik'in Gölgesi HUD uyarısı (C-41)

`erlik_power == eşik − 1` iken: `ERLIK_SHADOW_WARNING` **"Bir yayılım daha olursa bozkır Erlik'e
düşer."** Değer satırı her zaman `ERLIK_SHADOW_VALUE`. Uyarı rengi + piksel ikon; `⚠` glifi yok.

### 5.5 Gece ve şafak

Tur sonu = **gece** (`TURN_SUMMARY_HEADING` "Gece Çökerken"), lütuf sunumu = **şafak** (spirit §3.4'teki
"şafak kuralı" ile aynı imge). Yayılım ilk kez bulaşırsa "yayıldı", var olan lekeyi derinleştirirse
"derinleşti"; hiçbir şey olmadıysa `TURN_SUMMARY_QUIET` (özetin hiç gösterilmeyip gösterilmeyeceği C-41).

## 6. Yazım ve Çeviri Kuralları

1. **Glif (ADR-0009):** her metin kendi dilinin native fontunda çizilebilmeli (`glyph_coverage_test.gd`).
   Yasak: `−` U+2212, `⚠`, `✕`, `✓`, U+202F, emoji, akıllı tırnak. Konuşma tırnakla değil iki noktayla
   verilir ("Konuştu: Ben Kök Böri'yim…"). ÇJK'da yalnız yaygın karakterler (GB2312 1. düzey, JIS 1. düzey
   tercih); nadir karakter yerine sade karşılık (ör. 篝火 yerine 火堆).
2. **Yer tutucu:** yalnız `%s` (sayılar kodda biçimlenir). Türkçe ek uyumu sorunu nedeniyle bölge adı ve
   sayı **iki noktadan sonra** ya da ekten bağımsız konumda durur ("yayıldı: %s", "%s idi"); Korece'de
   `%s`'e ek getirilmez (이/가, 였다 yok).
3. **Harf:** büyük/küçük harf çeviride; kod `to_upper()` yapmaz.
4. **CSV:** virgül içeren alan çift tırnakla; alan içinde satır sonu yok; çift tırnak karakteri kullanılmaz.
5. **Ad sözlüğü:** Kök Böri — Latin/Kiril/Arapça'da çevriyazı (Kök Böri / Кёк Бёри / كوك بوري); ÇJK'da
   alt başlıkla tutarlı anlam adı (苍狼 / 蒼き狼 / 하늘 늑대). Erlik — zh 埃尔利克 (`WIN_CONDITION_CH1` ile aynı),
   ja エルリク, ko 에를리크, ru Эрлик, ar إرليك. Ülgen — zh 乌尔根, ja ウルゲン, ko 울겐, ru Ульгень, ar أولغن.
   Ruh — en Spirit, de Geist, fr Esprit, es/pt Espíritu/Espírito, zh 灵魂, ja 魂, ko 영혼, ru Дух, ar الروح.
   Lütuf — en blessing (C-39 aynı terimi kullanmalı). Kağan — zh 可汗, ar خاقان, ru каган.
6. **Arapça:** ünlem yok; hareke yalnız gerekiyorsa; RTL'yi motor çözer (ADR-0009 §6).

## 7. "Kuru Hesap Yok" Denetimi (Kabul Ölçütleri)

- **AC-V1 (içerik, C-41'de otomatik test önerisi):** `BATTLE_*`, `REPORT_*`, `PURIFY_*`, `TURN_SUMMARY_*`,
  `CHAPTER_*_HUNT_*`, `CHAPTER_*_SLAIN_*` anahtarlarının `en` metni şu sözcükleri bütün sözcük olarak
  içermez: *Attacker, Defender, Losses, Remaining, Casualties, Units*; `tr` metni: *Saldıran, Savunan,
  Kayıp, Kayıplar, Birlik*. (Bu belgeyle birlikte eklenen 45 anahtar geçer.)
- **AC-V2:** Her rapor türünde bir ozan dizesi + en az bir sayı satırı vardır; sayı `MoveOutcome` alanına
  eşittir (ADR-0011 doğrulama listesi).
- **AC-V3:** Kök Böri metni yalnız §3'teki dört anda görünür (grep: `KOKBORI`, `HUNT_READY`).
- **AC-V4 (bütçe):** §8'deki `en` karakter bütçeleri aşılmaz; anlatı sayfaları F4/F5'e uyar (giriş toplamı
  ≈ 465 ≤ 1100, çıkış ≈ 275 ≤ 900; başlıklı sayfa ≤ 150 — Arapça Unifont'ta 2 satır sınırı).
- **AC-V5 (playtest):** 5 oyuncudan en az 4'ü canavar hamlesinden sonra anı "canavarı yendim" diye anlatır
  ("14 askerle saldırdım" değil).

## 8. Anahtar Listesi

Bütçe = `en` için üst sınır (Latin karakter). Modal satırı ≈ 48, panel satırı ≈ 22, 24px başlık ≈ 24
karakter. Diğer diller bu sınırın ~%130'una kadar çıkabilir (de/fr/ru); F4/L6 dil başına sığmayı test eder.

| Anahtar | Nerede | Yer tutucu | Bütçe | en |
| ---- | ---- | ---- | ---- | ---- |
| `BATTLE_REPORT_HEADING` | BattleReport başlığı (mevcut `BATTLE_REPORT` değişmedi) | — | 24 | Word from the Field |
| `BATTLE_WON_ATTACK` | Oyuncu saldırdı, kazandı | — | 64 | Our riders broke their line. The land is ours. |
| `BATTLE_LOST_ATTACK` | Oyuncu saldırdı, savunan dayandı (beraberlik dahil) | — | 64 | They held. Our charge broke against them. |
| `BATTLE_HELD_DEFENSE` | Düşman saldırdı, oyuncu dayandı (tur özeti, Perde 1+) | — | 64 | The foe came, and our camp held. |
| `BATTLE_LOST_DEFENSE` | Düşman saldırdı, toprağı aldı | — | 64 | The foe took the land. Our warriors fell. |
| `BATTLE_BOTH_FELL` | İki tarafın kalanı 0 (bölge sahipsiz, W3) — önce denetlenir | — | 64 | Both hosts fell. The land stands empty. |
| `REPORT_OUR_FALLEN` | Oyuncu kaybı (savaş + başarılı arındırma) | sayı | 28 | Our fallen: %s |
| `REPORT_THEIR_FALLEN` | Karşı tarafın kaybı | sayı | 28 | Their fallen: %s |
| `REPORT_OUR_STANDING` | Kazanan oyuncunun kalanı | sayı | 28 | Ours still standing: %s |
| `REPORT_THEIR_STANDING` | Kazanan karşı tarafın kalanı | sayı | 28 | Theirs still standing: %s |
| `REPORT_SCATTERED` | Kaybedenin dağılan hayatta kalanları (`dispersed` > 0) | sayı | 28 | Scattered to the steppe: %s |
| `PURIFY_REPORT_HEADING` | PurificationReport başlığı | — | 24 | The Cleansing |
| `PURIFY_SUCCESS` | Arındırma başarılı | — | 64 | Ülgen's light returns. The land is clean again. |
| `PURIFY_SPIRIT_GAINED` | Ruh satırı (kod `+30` verir) | sayı | 28 | Spirit gained: %s |
| `PURIFY_SETTLED` | Bölgeye yerleşen hayatta kalanlar | sayı | 28 | Settled in the land: %s |
| `PURIFY_FAILED` | Arındırma başarısız ("Erlik yuttu") | — | 64 | Erlik swallowed the host. No one came back. |
| `PURIFY_LOST` | Başarısızlıkta kaybolan kuvvet | sayı | 28 | Lost to the dark: %s |
| `PURIFY_FAILED_HINT` | Başarısızlıkta öğrenme satırı (`S`) | S | 48 | Erlik's hold was %s. Return with more. |
| `PURIFY_PREVIEW_OK` | Hamle önizlemesi, başarılı arındırma | — | 40 | Enough to cleanse the land. |
| `PURIFY_PREVIEW_FAIL` | Hamle önizlemesi, başarısız arındırma | — | 40 | Erlik would swallow this host. |
| `PURIFY_CONFIRM_AGAIN` | İkinci seçim onayı (ADR-0011 §6) | — | 40 | Select again to send them anyway. |
| `CHAPTER_1_HUNT_HEADING` | Canavar hedefi önizleme/rapor başlığı | — | 24 | The Hunt of the Beast |
| `CHAPTER_1_HUNT_READY` | Önizleme: canavar yenilebilir (Kök Böri ulur) | — | 64 | Kök Böri howls. The beast's last hour has come. |
| `CHAPTER_1_HUNT_NOT_READY` | Önizleme: kuvvet yetmiyor | — | 64 | The beast is stronger than this host. Gather more. |
| `CHAPTER_1_SLAIN_HEADING` | Canavar raporu başlığı (başarı) | — | 24 | The Beast Is Slain |
| `CHAPTER_1_SLAIN_LINE` | Canavar raporu dizesi (başarı) | — | 64 | Oğuz drove his spear into the beast. The steppe breathes again. |
| `CHAPTER_1_HUNT_FAILED` | Canavar raporu dizesi (başarısızlık) | — | 64 | The beast still lives. Its lair swallowed the host. |
| `OBJECTIVE_LABEL` | Hedef paneli + HUD hedef satırı etiketi (C-40 yeniden eklemesin) | — | 16 | Objective |
| `CHAPTER_1_KOKBORI_LINE` | Hedef paneli Kök Böri sözü (`kok_bori_line_key`) | — | 90 | Follow my light, Oğuz. Where it falls, the beast waits. |
| `CHAPTER_1_INTRO_1` | G-1 (başlıklı sayfa) | — | 150 | At dawn the eastern sky turned gold, and Oğuz was born. He tasted his mother's milk once, then asked for meat. In forty days he walked. |
| `CHAPTER_1_INTRO_2` | G-2 | — | 220 | The tribes lived scattered, each by its own fire. Then from the earth below came Erlik's beast. Where it walked the grass turned black, and the herds fell silent. |
| `CHAPTER_1_KOKBORI_1` | G-3 genesis | — | 220 | Then a light fell from the sky, and out of it stepped a great wolf with a sky-blue mane. It spoke: I am Kök Böri, sent by Ülgen. Rise, Oğuz. I will lead the way. |
| `CHAPTER_1_OUTRO_1` | O-1 | — | 220 | The beast fell, and its black stain sank back into the earth. Grass rose green where it had walked. Kök Böri's light touched the land: Ülgen had won the first day. |
| `CHAPTER_1_OUTRO_2` | O-2 (başlıklı sayfa) | — | 150 | The tribes came from every fire to a great feast. Under one banner Oğuz spoke: I have become your Kağan. |
| `CHAPTER_1_KAGAN_TITLE` | O-2 başlık kartı (24px) | — | 24 | Oğuz Kağan |
| `DEFEAT_REASON_ERLIK` | Yenilgi, `ERLIK` | — | 64 | Erlik's shadow has swallowed the homeland. |
| `DEFEAT_REASON_NO_REGIONS` | Yenilgi, `NO_REGIONS` | — | 64 | Our last land has fallen. No hearth of ours still burns. |
| `DEFEAT_REASON_GENERIC` | Yenilgi, `NONE`/eşlemesiz | — | 64 | Here the song falls silent, for now. |
| `DEFEAT_PROGRESS_KEPT` | Yenilgi güvence satırı | — | 64 | The Spirit and blessings from earlier chapters stay with you. |
| `ERLIK_SHADOW_VALUE` | HUD göstergesi + yenilgi (`ERLIK`) | güç, eşik | 28 | Erlik's Shadow: %s / %s |
| `ERLIK_SHADOW_WARNING` | HUD uyarısı, `erlik_power == eşik − 1` (C-41) | — | 48 | One more spread and the steppe falls to Erlik. |
| `TURN_SUMMARY_HEADING` | TurnSummaryReport başlığı | — | 24 | As Night Fell |
| `TURN_SUMMARY_SPREAD` | Yayılım temiz bölgeye (0 → 1) | bölge adı | 48 | Erlik's stain spread: %s |
| `TURN_SUMMARY_DEEPENED` | Yayılım bozuk bölgeyi derinleştirdi | bölge adı | 48 | Erlik's stain deepened: %s |
| `TURN_SUMMARY_QUIET` | Olaysız gece (gösterilirse) | — | 48 | The night passed quietly. |

**Seçim sırası (BattleReport):** `BOTH_FELL` (iki kalan 0) → oyuncu saldırgansa `WON_ATTACK` /
`LOST_ATTACK` → düşman saldırgansa `LOST_DEFENSE` / `HELD_DEFENSE`. Kaybeden tarafın kalanı `SCATTERED`
satırıyla, kazananınki `*_STANDING` ile gösterilir. **PurificationReport:** hedef sahnenin Erlik odağıysa
ve sahnenin ritüel anahtarları doluysa §5.2, değilse `PURIFY_*`.

**Yazılmayanlar:** `CHAPTER_1_TEASER` ve `end_pages` metni Perde 1 adlandırmasına (Cürcet Kağan'ın ÇJK/Arapça
adı) bağlı → C-43. Lütuf kartı metinleri → C-39 (bu rehberin §3 ve §6.5'ine uyar).

## 9. Karar Günlüğü (C-54, gece modu — önerilen seçenek uygulandı)

| Karar | Seçilen | Reddedilen | Geri alma maliyeti |
| ---- | ---- | ---- | ---- |
| Anlatıcı | Ozan (biz, geçmiş zaman) raporlarda; Kök Böri yalnız 4 kutsal anda, 2. tekil | Kök Böri her raporda; nötr kronik | Düşük — yalnız metin |
| Sayıların yeri | Dize + etiketli sayı satırları (sayı hep görünür) | Sayıyı cümleye gömmek; yalnız tablo | Düşük |
| Canavar anı | Sunum ritüeli (önizlemede çağrı/uluma, özel rapor), kural değişmedi; sahne başına `SceneDefinition` odak anahtarları önerisi | Ayrı "ritüel" eylemi / QTE; tüm odaklar için tek genel metin | Düşük–orta (C-40/C-62 veri alanı) |
| Adlar | Kök Böri çevriyazı, ÇJK'da anlam adı; Ruh = Spirit, lütuf = blessing; zh Erlik 埃尔利克 | Her dilde çevriyazı; "Boon" | Düşük |
| Hitap | Mevcut UI'a uyum (fr vous, ru вы, pt você), Kök Böri'de tu/ты | Her yerde tu/ты | Düşük |
| Kapsam | Prolog anlatı sayfaları da yazıldı (scene-flow Q8); TEASER C-43'e | Sayfaları C-40'a bırakmak | Düşük |
| Rapor başlığı | Yeni `BATTLE_REPORT_HEADING`; mevcut satırlar değişmedi | `BATTLE_REPORT` metnini değiştirmek | Düşük |
