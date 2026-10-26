# Sistem GDD: Katmanlı Düşman (Siyasi Krallar)

*Oyun: ULUS: Blood of the Sky Wolf*
*Oluşturulma: 2026-10-21 — C-44; kullanıcı onaylı (§11 kararları, 2026-10-21)*
*Durum: Designed (C-44). Kod henüz yok (R1 / `EnemyAIProfile` / `reason` uygulaması C-44 uygulama görevi).*
*Creative Director Review (CD-GDD-ALIGN): yapılmadı*
*Katman: Feature*
*Uyguladığı sütun: İki Katmanlı Tehdit · Epik Ama Erişilebilir · Destanı Yaşa*

> **Kapsam.** Bu GDD yalnızca **siyasi katmanı** (krallar: `owner = ENEMY`) tanımlar. **Erlik bu belgede
> değildir**: bozulma, yayılım, Erlik'in Gölgesi ve Erlik kaybı `spirit-system.md` §3.7 / §4.7'de kalır
> (C-29). Siyasi düşman Erlik ile iş birliği yapmaz, bozulmayı yok sayar, nötr bölgelere girmez.
> **Diplomasi / ittifak** M2 dışıdır (`diplomacy-system.md`, ayrı GDD; `systems-index.md`).
> **Tam tanım:** Perde 1 — Cürcet Kağan. **Yalnız şablon:** Perde 2–4 (§3.8). Kural kaynağı sırası:
> bölüm verisi → [`perde1-dogu-curcet.md`](../levels/perde1-dogu-curcet.md) §4 (onaylı, C-43) → bu belge.
> Çakışmada seviye belgesinin sayısal değerleri geçerlidir.
> **Tek yeni karar (C-44):** AI, oyuncunun **etkin** savunma gücünü okur (§3.3, F-E1); gerisi C-43 / C-29 / C-49
> kararlarının derlemesidir.

---

## 1. Overview

Katmanlı Düşman, oyunun iki tehdit katmanından **siyasi olanını** tanımlar: oyuncuyla aynı kuralları
paylaşan, bölge tutan ve oyuncu zayıf göründüğünde karşılık veren kral AI'ı. Kral her tur en çok bir
hamle yapar; hamle `EnemyAIProfile` veri kaynağıyla parametrelenen, saf ve deterministik `decide()`
kararından çıkar (ADR-0005). Perde 1'de Cürcet Kağan **karşı vuruş** (R1) stratejisini kullanır: belirli
bir turdan sonra, yalnızca komşu bir oyuncu bölgesini açık bir ordu üstünlüğüyle (oran ≥ 3/2) görürse
saldırır; "üstünlük" oyuncunun **etkin** savunma gücüne göre ölçülür (lütuflar dahil); birden fazla oyuncu
komşusu varsa savunmada kalır; nötr bölgelere ve Erlik bozulmasına hiç bakmaz. Kralın tek ekonomisi,
başkentine tur başı gelen sabit takviyedir (hazine yok). Bu belge `resource-system.md` §3.1 kural 6'daki
takviye kuralının **sahibidir** (yürütme resource F6'da kalır). Sistem, "krallar ihmal edilirse saldırır"
ile "Erlik ihmal edilirse yayılır" arasındaki gerilimi kuran ikinci yarıdır: oyuncu iki cepheyi aynı anda
yönetmek zorundadır, ama kral hiçbir zaman keyfî ya da gizli davranmaz.

---

## 2. Player Fantasy

**Gururlu, meşru bir hasımla ölçüşen kağan.** Cürcet Kağan kötü değildir; "karşı saftır". Oyuncu onu
bir canavar gibi ezmez, bir hükümdarı diz çöktürür. Oyuncunun içinden geçen cümle: *"Zayıf yerimi
görürse vurur; bunu bilerek planlarım."* Düşman okunabilir olduğu için oyuncu yenilgiyi kendi kararına
bağlar (Competence): kimse haksızlığa uğramaz, kimse zar atmaz.

- **Doğrudan katman (karşılık):** İlk vuruş turu T5'ten önce yoktur; sonra, komşu bölgeni oran
  eşiğinin altında bırakırsan Kağan vurur. Savunma bir seçimdir: üretmek mi, ordu toplamak mı, lütufla
  savunmayı güçlendirmek mi, yoksa çekilmemek mi? Kağan lütfunu da görür: "oyuncuya uygulanan kural
  AI'ya da uygulanır" — Demir Post gerçekten caydırır.
- **Dolaylı katman (baskı):** Başkent her tur büyür (+1). Beklemek Kağan'ı güçlendirir; oyuncu
  "şimdi mi, biraz daha hazırlanıp mı" sorusunu hisseder (Sütun 3, zaman baskısı).
- **Anlatı tonu (seviye belgesi §2):** Kağan konuşmaz; ozan aktarır, en çok 1 kısa cümle ("Boyun eğmem.").
  Yenilgisi ağırbaşlıdır ("diz çöktü"); baş kesme yok.

**Sütun bağı:** *İki Katmanlı Tehdit* (siyasi = fethedilir, Erlik = arındırılır; ayrı AI, ayrı dil);
*Epik Ama Erişilebilir* (tek kural cümlesiyle anlatılabilir: "Kağan ancak açık üstünlükle vurur");
*Destanı Yaşa* (hasım saygıdeğer).

**Kaçınılacak his:** Cezalandırıcı sürpriz ("bunu nereden bilecektim?"), her turu savunmada geçirmek,
Kağan'ın Erlik'le iş birliği yaptığı izlenimi.

---

## 3. Detailed Rules

### 3.1 Çekirdek kavramlar

1. **Siyasi düşman = `owner = ENEMY` bölgeleri.** `ERLIK` sahip türü yoktur (`spirit-system.md` §3.7).
2. **Kral AI'ı saf karar servisidir:** `EnemyAIController.decide(map_state, acted, defense_modifiers) -> MoveIntent`
   (ADR-0005 + C-43/C-44 ekleri). `EnemyAIProfile` bölüm başına `bind_config` ile enjekte edilir; oyuncunun
   savunma modifikatörleri `defense_modifiers` parametresiyle **açık girdi** olarak verilir (servis kendisi
   durum okumaz/yazmaz). *(C-44 inceleme (2026-10-21), W-15 / D6; `region-map-system.md` §3.5 imzası bu karara
   göre güncellenir.)* `MapState`'i
   yalnızca okur; durumu değiştirmez, sinyal yaymaz, rastgelelik kullanmaz. Uygulamayı `MapController`
   yapar (karar → uygula döngüsü; her hamle öncekinin sonucunu görür).
3. **Düşman bölgesi hamle kuralları oyuncuyla aynıdır** (`army-system.md` §3, `mover = ENEMY`): kaynakta
   daima 1 garnizon kalır, hareket eden kuvvet `army − 1`, savaşı `CombatResolver` çözer. Düşman
   modifikatör (lütuf) **almaz** (`combat-system.md` §4 "Etkin güç": modifikatörler yalnız oyuncu tarafına
   uygulanır). Ama AI karar verirken oyuncunun etkin gücünü **okur** (§3.3, F-E1).
4. **Bütçe:** `enemy_actions_per_turn` (Perde 1: **1**). Her düşman bölgesi tur başına en çok 1 hamle
   (`acted` listesi). Bütçe bitince AI durur.
5. **Hazine yok.** Düşman altın tutmaz, ordu satın almaz; tek ordu kaynağı takviyedir (§3.5).
6. **Sıra:** `end_turn` 1. adım = düşman AI; 2. adım = Erlik yayılımı; 3. adım = ekonomi (gelir + **takviye**
   + bakım); 4. adım = tur artışı (`region-map-system.md` §3.4). Takviye AI'dan **sonra** uygulanır.

### 3.2 Profil: `EnemyAIProfile`

Veri kaynağı (Resource), bölümün `ChapterMapDefinition`'ına bağlanır. Varsayılan profil (Prolog / eski
test davranışı) **eski kuralı** korur: ordusu > 1 olan düşman bölgeleri, düşman-olmayan komşular arasında
ordusu en düşük olana saldırır (eşitlikte `region_id` alfabetik).

| Alan | Tür | Perde 1 (Cürcet) | Anlamı |
| --- | --- | --- | --- |
| `attack_start_turn` | int | **5** | Bu turdan önce AI hiç saldırmaz (öğretici nefes) |
| `strike_ratio_num` / `strike_ratio_den` | int, int | **3 / 2** | Karşı vuruş için gereken en az oran `A / P_eff ≥ num/den` |
| `strike_enabled` | bool | **true** (varsayılan profilde `false`) | R1 kuralı açık; kapalıysa eski "en düşük ordulu komşu" davranışı |

Alan adları **onaylıdır** (C-44, §11 K5) ve ADR-0005 eki ile aynıdır. Başka alanlar **eklenmez** (yeni
mekanik yok). Takviye parametreleri bölüm verisinde kalır (§3.5); `enemy_actions_per_turn` `MapState` alanıdır.

### 3.3 Perde 1 kuralları (Cürcet) — `decide()` sırası

Girdi: `current_turn`, `acted`, profil, oyuncu savunma modifikatörleri. Çıktı: tek `MoveIntent` ya da `null`.

1. **Tur kapısı:** `current_turn < attack_start_turn` ise `null` (bekle).
2. **Aday üretimi (R1 Karşı vuruş):** her düşman bölgesi E için (E `acted`'te değil, `E.army ≥ 2`):
   - `A = E.army − 1` (gönderilecek kuvvet).
   - E'nin her komşu **OYUNCU** bölgesi P için aday (E→P), koşul **F-E1**: `A > P_eff` **ve**
     `strike_ratio_den · A ≥ strike_ratio_num · P_eff`, burada `P_eff` = P'nin **etkin savunma gücü**
     (`combat-system.md` §4 "Etkin güç"; lütuflar dahil — Demir Post, Gök Kalkanı vb.). Perde 1: `2A ≥ 3·P_eff`.
3. **Savunma tutma (tek tanım, F-E2):** E'nin **iki veya daha fazla** komşu oyuncu bölgesi varsa **ve** `A ≥ 2`
   ise E hiçbir aday üretmez (kaynak bölgeyi açıkta bırakmaz). Bu, ADR-0005 okumasıdır; "ordu−1 ≥ 2"
   kaynağa (A) aittir.
4. **Seçim sırası (deterministik, küresel):** en küçük `P_eff` → en büyük `A` → `from_id` alfabetik → `to_id`
   alfabetik. İlk aday `MoveIntent(from, to, reason = &"strike")` olur. Sıra tüm düşman bölgeleri üzerinde
   **küresel** uygulanır; `region_id` yalnız en son eşitlik bozucudur (`region-map-system.md` §3.5 notu).
5. **Aday yoksa `null`.** (R2 savunma kaydırması **KAPALI**: simülasyonda tempoyu bozdu.)
6. **Hiçbir zaman:** nötr bölgeye girmez; `corruption_level`'i okumaz, bozulmuş bölgeyi ayrıcalıklı
   hedef saymaz (`spirit-system.md` §3.7); Erlik odağına (`curuk_koru`, nötr) hamle yapmaz.
7. Oyuncu bölgesi ele geçirilirse hedef `owner = ENEMY` olur; bozulma bölgede kalır (`army-system.md`).

`enemy_actions_per_turn > 1` ise `MapController` `decide()`'ı güncel `acted` ile yeniden çağırır; her
çağrı yukarıdaki sırayı baştan işler. (Perde 1'de bütçe 1.)

**Etkin güç okuması (C-44 kararı, kullanıcı onaylı):** AI, "oyuncuya uygulanan kural AI'ya da" ilkesiyle
P'nin **etkin** savunmasını görür. Saflık korunur: `decide()` durum değiştirmez; modifikatörler çağıran
(MapController) `defense_modifiers` girdisi olarak verilir ve `decide()` saf `StatResolver`'ı (ADR-0006)
çağırır. *(C-44 inceleme (2026-10-21), W-15 / D6: önceki "kalıbın tersi değil" ifadesi kaldırıldı.)*
Gerekçe: C-44 lütuf denge analizi — ham `P.army` okunursa Demir Post gibi savunma lütufları AI kararını
etkilemez, lütuf cezasız bir "tuzak" (AI uygunsuz vuruş yapar) ya da etkisiz kalır; etkin okumayla lütuf
gerçek bir caydırıcıdır ve AI'nın başarısız vuruşa sürüklenmesi (tahmin edilebilir kaybeden AI) önlenir.

### 3.4 Rapor / geri bildirim sözleşmesi

- `MoveIntent.reason = &"strike"`: sunum katmanı (ADR-0011 savaş raporu) bununla savunma raporu
  metnini seçer: `BATTLE_LOST_DEFENSE` (oyuncu savunmayı kaybetti). **Not:** AI yalnız `A > P_eff` iken
  vurduğu için (`combat-system.md` Dal 1) R1 vuruşu her zaman başarılıdır; `BATTLE_HELD_DEFENSE` R1
  vuruşundan **üretilmez** (yalnız varsayılan profil / ileride `A ≤ P_eff` saldırıları için ayrılmıştır).
  *(C-44 inceleme (2026-10-21), W-5:)* HELD yalnız `A ≤ P_eff` saldırıları için ayrılmıştır; Perde 1 R1'i
  üretmez — anahtar korunur.
- İlk tur düşman görünürlüğü: `HINT_ENEMY_KING` (bir kez). Başkent ilk önizlemesi: `HINT_CAPITAL` (bir kez).
  Metinlerin sahibi `narrative-voice.md`; bu belge yalnız tetikleyicileri tanımlar.
- AI niyeti oyuncuya **önceden gösterilmez** (K8): hamle sonrası rapor + kural ipucu; okunabilirlik kural
  bilgisini ipucu metnine koyarak sağlanır (seviye belgesi §7.8 R3: takviye yalnız başkent + AI kuralı
  `HINT_ENEMY_KING` / `HINT_CAPITAL` metninde). Niyet önizlemesi M3'e ertelendi.

### 3.5 Düşman takviyesi (resource-system §3.1 kural 6 — kural sahibi bu belge)

Bu belge takviyenin **kural sahibidir** (K2); ekonomi adımında çağrılması ve formül yürütmesi
`resource-system.md` §3.1 kural 6 ve F6'da kalır (çapraz referans). Kural:

1. Ekonomi adımında (AI'dan sonra) takviye alan her düşman bölgesine `army += E_r`.
2. Takviye alanlar: `enemy_reinforcement_region_ids` boşsa **tüm** `ENEMY` bölgeler (Prolog / eski davranış);
   doluysa listedeki **ve** o an `ENEMY` olan bölgeler.
3. **Perde 1:** `E_r = enemy_reinforcement_per_turn = 1`, `enemy_reinforcement_region_ids = [curcet_otagi]`
   (başkent). `kurt_ini_ormani` ve `curcet_oba` takviye almaz.
4. Başkent oyuncuya geçerse takviye durur (listedeki bölge `ENEMY` değil); geri alınırsa yeniden başlar.
5. Düşman AI'ın o tur yeni aldığı bölge, listedeyse, aynı tur +E_r alır (`resource-system.md` Edge Cases).
6. Düşmanın hazinesi yoktur; takviye ordudur, altın değil. Nötr bölgeler takviye almaz.
7. `E_r` ve bölge listesi **bölüm verisidir**; sabit kodlanmaz.

> **✅ C-83 (2026-10-25):** `ChapterMapDefinition.enemy_reinforcement_region_ids` → `MapState` (kopya; kaydedilmez, yüklemede harita tanımından), `ResourceController.reinforce_enemies` liste süzgeci; AC11 (3 test), AC12, AC14 → `tests/unit/resources/reinforcement_region_list_test.gd`. Profil `MapState`'e kopyalanmaz: `ChapterMapDefinition.enemy_ai_profile` → `EnemyAIController.bind_config` (ADR-0005 D6, C-82) tek kaynaktır.

**Asimetrik ekonomi (K7):** düşman ekonomisi oyuncununkiyle simetrik değildir — hazine yok, sabit takviye,
modifikatör yok. `resource-system.md` Açık Soru 4 bu karar ile kapanmıştır.

### 3.6 Perde 1 — Cürcet Kağan (tam tanım)

| Alan | Değer | Kaynak |
| --- | --- | --- |
| Karakter | Gururlu, meşru hükümdar, "karşı saf"; kötü değil; doğrudan konuşmaz | seviye §2 |
| Ağırlık | Orman savunması; iki kapı: köprü yönü (kuzey) ve çürük koru yönü (güney) | seviye §3 |
| Başlangıç düşman bölgeleri | `kurt_ini_ormani` (2 ordu), `curcet_oba` (4), `curcet_otagi` (4, başkent) | seviye §3.1, §4.1 |
| Başkent | Takviye yalnız burada (+1/tur); zafer için alınmalı | seviye §4.3 |
| AI profili | `attack_start_turn = 5`, oran 3/2, R1 + savunma tutma, R2 kapalı | seviye §4.2 |
| Erlik ilişkisi | İş birliği yok; Kağan gururundan ormanı ihmal eder, orman çürür | seviye §2 |
| Yenilgi | Başkent alınır ve tüm düşman bölgeleri biter → Cürcet diz çöker (zafer); baş kesme yok | seviye §2 |
| Zorluk (E-01 / E-02 / E-03) | 3/10, 5/10, 7/10 | seviye §4.1 |
| İlk saldırı penceresi | T5–7 (tasarım hedefi; replay ile doğrulanır) | seviye §3.6 |

**Oyuncuya karşı kaybetme yolları** (bu belge yeni sebep eklemez, K4): tüm bölgeler kaybı = mevcut
`NO_REGIONS`; Erlik kaybı ayrı (`ERLIK`, `scene-flow.md` §3.7). Yeni `loss_reason` değeri **yoktur**.

### 3.7 Zafer bağı

Zafer koşulunu `WinCondition` yürütür (`region-map-system.md` §3.6). Perde 1: `must_defeat_all_enemies =
true`, `objective_region_ids = [curcet_otagi]` (`SceneDefinition` alanı, `scene-flow.md` §3.10 — W-14, C-44
inceleme (2026-10-21)), 2 nötr fetih, odak (`curuk_koru`) bozulmamış. Bu belgenin
sorumluluğu: düşman bölgelerinin sahipliğini bozmak (AI ele geçirme) ya da oyuncunun almasına izin vermek;
koşul mantığı bu belgede **yoktur**.

### 3.8 Profil şablonu — Perde 2–4 (yalnız şablon; yeni mekanik yok)

Şablon alanları: **ad, karakter, farklılaşacak mevcut parametreler**. Sayılar bu belgede **belirlenmez**
(K9); her biri kendi seviye belgesinde ve denge replay'inde onaylanır. Farklılaşabilecek parametre kümesi
sabittir: `attack_start_turn`, `strike_ratio_num/den`, `enemy_actions_per_turn`,
`enemy_reinforcement_per_turn`, `enemy_reinforcement_region_ids`, garnizon dağılımı.
(Kaynak: `game-concept.md` Perde tanımları.)

| Perde | Kral / düşman | Karakter (concept'ten, yeni lore yok) | Farklılaşacak parametreler | Not |
| --- | --- | --- | --- | --- |
| 2 Batı | Urum Kağan (+ Kıl Barak halkı) | En zorlu sınav; Erlik en yoğun | Daha erken `attack_start_turn`, daha düşük oran eşiği veya `enemy_actions_per_turn = 2`; takviye bölge listesi geniş | Kıl Barak = nötr boy garnizonu (K6) |
| 3 Kuzey | Kuzey boyları / kağanları | Doğaya karşı direniş (kışla birlikte) | Çok bölgeli takviye listesi, düşük `E_r`; savaş baskısı mevsim mekaniğiyle (başka GDD) | Mevsim bu belgede yok |
| 4 Güney | Güney kralları | Zaferin eşiği; kahramanlar zirvede | M2'de tek `ENEMY` / tek profil (K6); çoklu profil Perde 4 seviye tasarımında yeniden değerlendirilir | Kahraman birimi bu belgede yok |
| Final | — (birleşme; siyasi düşman yok) | Erlik son saldırısı | Düşman profili yok; F6 listesi boş | `systems-index` / concept: "Siyasi Düşman: —" |

---

## 4. Formulas

### F-E1 — Karşı vuruş uygunluğu (R1)

Tam sayı aritmetiği (float yok; `ceil` yalnız `P_eff` çözümünde, `combat-system.md` ile aynı):

```
A        = E.army − 1
P_eff    = 0                                              , P.army = 0   (barışçıl işgal, savaş yok;
                                                                         PLAYER hedef için ulaşılamaz — savunmacı dal)
         = ceil(resolve(&"army_defense", P.army))         , P.army ≥ 1   (combat-system §4 "Etkin güç")
koşul_1  = A > P_eff
koşul_2  = strike_ratio_den · A ≥ strike_ratio_num · P_eff        # Perde 1: 2A ≥ 3·P_eff
uygun    = strike_enabled AND (current_turn ≥ attack_start_turn)
           AND (E.army ≥ 2) AND (E ∉ acted)
           AND (P.owner = PLAYER) AND (P komşu E)
           AND koşul_1 AND koşul_2
           AND NOT SAVUNMA_TUTMA(E)
```

| Değişken | Sembol | Tip | Aralık | Açıklama |
| --- | --- | --- | --- | --- |
| Kaynak ordusu | `E.army` | int | ≥ 0 | Düşman bölgesinin `army_count` değeri |
| Gönderilecek kuvvet | `A` | int | 0 – ∞ | Kaynakta 1 garnizon kalır |
| Hedef ordusu | `P.army` | int | ≥ 0 | Oyuncu bölgesinin ham `army_count`'u |
| Hedef etkin savunma | `P_eff` | int | ≥ 0 | Lütuf modifikatörleri dahil (`ceil`); modifikatör yokken `P_eff = P.army` |
| Oran eşiği | `num/den` | int/int | 1/1 – 2/1 | Perde 1: 3/2 |
| Başlangıç turu | `attack_start_turn` | int | 1 – 20 | Perde 1: 5 |

**Çıktı:** bool. **Örnekler (Perde 1, lütufsuz):** E.army = 8 → A = 7; P = 4 → 14 ≥ 12 → **uygun**; P = 5 → 14 ≥ 15
değil → uygun değil. E.army = 2 → A = 1; P = 1 → 2 ≥ 3 değil → uygun değil (başlangıç `kurt_ini_ormani` (A = 1)
hiçbir koşulda vuramaz; sahipli bir bölge 0 orduyla kalmadığından `P.army = 0` dalı PLAYER hedef için ulaşılamaz —
`army-system.md` §3.3, `region-map-system.md` §5). *(C-44 inceleme (2026-10-21), W-4)* **Örnek (Demir Post, P.army = 4 → P_eff = 6):** A = 7 → 14 ≥ 18 değil → AI
vurmaz; lütufsuz aynı durumda (P_eff = 4) vururdu.

> **Not (fazlalık):** `P_eff ≥ 1` iken `koşul_2 ⇒ koşul_1` (yalnız oran > 1 ise; `1/1` oranında `A = P_eff`
> için `koşul_2` sağlanır, `koşul_1` sağlanmaz — C-44 inceleme (2026-10-21), bilgi notu); `koşul_1` yalnız
> okunabilirlik içindir ve `P_eff = 0` durumunda `A ≥ 1` ile sağlanır. Test iki koşulu da ayrı doğrular (seviye belgesindeki
> `_requires_attacker_greater_than_defender`).

### F-E2 — Savunma tutma (tek tanım)

```
SAVUNMA_TUTMA(E) = (|{ Q : Q komşu E, Q.owner = PLAYER }| ≥ 2) AND (A ≥ 2)
```
Doğruysa E hiç aday üretmez. `A ≥ 2` ADR-0005 eki "E.army − 1 ≥ 2" ifadesidir (kaynağa ait). Seviye belgesi
§4.2'deki parantez bu tanıma bağlanmalıdır (§12 C1).

### F-E3 — Başkent ordu birikimi (takviye, F6 çıktısı)

Başkent hiç saldırmaz, saldırılmazsa ve hep düşmanda kalırsa, tur `t`'nin **AI adımından önce**:

```
capital_army(t) = capital_army(1) + (t − 1) · E_r          # Perde 1: 4 + (t − 1)
```

| Değişken | Aralık | Açıklama |
| --- | --- | --- |
| `capital_army(1)` | 4 | Başlangıç garnizonu (seviye §3.1) |
| `E_r` | 1 | Tur başı takviye |
| `t` | 1 – 20 | Sahne turu (hedef T10–15, medyan T12; T20 gerçekleşir — C-44 inceleme (2026-10-21), bilgi notu) |

**Örnek:** T5'te 8 (A = 7: P_eff ≤ 4 olan komşu oyuncu bölgesine uygun); T12'de 15. Oyuncu başkenti ne kadar
geç saldırırsa o kadar büyük ordu gerekir: baskı doğrusaldır, patlayıcı değil. Üst sınır yoktur (K3, §5).

### F-E4 — Karşı vuruşun sonucu (combat-system'e yönlendirme)

Vuruş sonucu `combat-system.md` dal formülleriyle çözülür; bu belge **yeni savaş formülü tanımlamaz**.
Düşman saldıran: `A_eff = A`; oyuncu savunan: `D_eff = ceil(resolve(&"army_defense", P.army))` = F-E1'deki
`P_eff`. AI ile resolver aynı değeri kullandığından, AI vurduğunda `A > D_eff` (Dal 1) garantilidir:
vuruş **her zaman** bölgeyi düşürür.

**Örnek (lütufsuz):** E.army = 8, P.army = 4: A = 7 > 4 → Dal 1: `attacker_losses = ceil(4 × 0.5) = 2`,
saldıran kalan 5, P bölgesi düşer, `owner = ENEMY`. **Örnek (D_eff = 8):** A = 7 < 8 → AI **hiç vurmaz**
(eski ham okumada Dal 2 ile saldıran yok olurdu).

---

## 5. Edge Cases

- **Tur < `attack_start_turn`:** AI `null` döner; hiçbir bölge hareket etmez. Takviye yine işler.
- **Kaynak ordusu ≤ 1:** o bölge atlanır, bütçeden harcamaz (`region-map-system.md` §5).
- **Hedef bölge ordusu 0:** barışçıl işgal; savaş çağrılmaz (`combat-system.md` §5). `P_eff = 0` tanımlıdır
  (modifikatör uygulanmaz); F-E1 `A ≥ 1` ile sağlanır.
- **Modifikatör yok / boş liste:** `P_eff = P.army`; davranış ham okumayla aynıdır.
- **Eşit uygun adaylar:** sıra `P_eff` → `A` → `from_id` → `to_id` alfabetik; sonuç her çalıştırmada aynıdır.
- **Bozulmuş oyuncu bölgesi hedef olabilir mi?** Evet, yalnızca sıradan bir oyuncu bölgesi olarak; AI
  `corruption_level`'ı okumaz (seviye 3 bozulmuş bölge de ayrıcalıksızdır).
- **Çürük koru (nötr, Erlik odağı):** AI girmez, hedef almaz. `curuk_koru` oyuncuya geçmişse o da oyuncu bölgesidir
  ve (komşu `curcet_oba`/`kurt_ini_ormani` üzerinden) hedef olabilir.
- **Birden fazla oyuncu komşusu:** savunma tutma devreye girer (F-E2); AI o bölgeden saldırmaz.
- **Başkent kaybı:** takviye durur (§3.5 kural 4); oyuncu başkenti geri verirse (yeniden `ENEMY`) yeniden başlar.
- **Takviye üst sınırı yok (K3):** başkent ordusu uzun sahnede büyür (F-E3). Bilinçli zaman baskısı; sınır
  eklenmez. Tasarım dışı değerler (ör. > 40) C-47 replay'inde ölçülür ve gerekirse `E_r` / liste ayarlanır.
- **Düşmanın tek bölgesi kalırsa:** takviye listesi o bölgeyi içeriyorsa +1, içermiyorsa 0; bölge ≤ 1
  ordulu ise AI hareket etmez.
- **Düşman bölgesi kalmadı:** `WinCondition` (siyasi koşul) zaten sağlanırsa zafer kontrolü sahibidir;
  AI `null` döner.
- **Aynı turda zafer + Erlik kaybı:** "önce kaybetme" kuralı (`region-map-system.md` §3.4, `scene-flow.md`);
  bu belge değiştirmez.
- **Prolog (ENEMY yok):** `decide()` her zaman `null`; F6 boşta; davranış değişmez (seviye kabul #6).
- **Varsayılan profil:** `strike_enabled = false` iken eski "en düşük ordulu komşu" davranışı birebir
  korunur (modifikatör okunmaz); kapı (`attack_start_turn`) varsayılan profilde 1.
- **Kayıt / yükleme:** AI durumsuzdur; yalnız `MapState` + profil + aktif lütuf modifikatörleri gerekir (lütuflar
  zaten kayıtlıdır, `spirit-system.md`). Yükleme sonrası aynı kararı verir (`acted` tur sonu kaydında boştur —
  tur ortası kayıt yok, ADR-0007).
- **Uygulayıcı çağrılırken oyun bitmişse** (`game_result ≠ ONGOING`): `end_turn` çalışmaz, AI çağrılmaz.
- **Dejenere strateji — "başkent bekleme / köprü kilitleme":** oyuncu başkent komşusu bölgeyi zayıf
  bırakırsa vuruş uygun olur. Bu bir hata değil, kural: savunmayı ihmal eden cezalanır.
- **Dejenere strateji — "iki komşu ile AI'ı felç etme":** savunma tutma nedeniyle iki oyuncu komşusu
  olan kaynak saldırmaz; oyuncu bunu kasıtlı kullanabilir. Kabul edilen strateji (Sirlin: sağlıklı ustalık);
  *(C-44 inceleme (2026-10-21), H2:)* başkent komşuları (`kurt_ini_ormani`, `curcet_oba`) ikisi de zafer için
  zorunludur; oyuncu ikisini birden tutarsa başkent kalıcı olarak felç olur (F-E2). Bu, kabul edilen strateji
  kapsamındadır ama "ikisi aynı anda tutulamaz" değildir. **D5 metriği (C-47 replay):** "T5 sonrası uygun AI
  adayı olan tur oranı" ölçülür; düşükse başkent F-E2'den muaf tutulması kullanıcıya sorulur (karar verilmedi).
  Replay ile doğrulanacak (§8 AC).
- **Dejenere strateji — "Demir Post ile AI'ı kilitleme":** savunma lütufu yığılırsa `P_eff` eşiği aşar ve AI hiç
  vurmaz. Bu, lütfun amaçlanan değeridir (caydırma); fakat lütuf yığın tavanı (`ModifierSource.max_stacks`; Demir Post için
  `DEMIR_POST_MAX_STACKS = 3` — C-44 inceleme (2026-10-21), W-3 / D2) ve lütuf maliyeti zaten sınırlar. Perde 1 replay'inde "savunma lütufu + pasif oyun" hattı ölçülür (AC15).
- **Etkin güç AI'ya sızıntısı yok:** `P_eff` yalnız **savunma** için hesaplanır; AI kendi `A` değerine modifikatör
  uygulamaz.

---

## 6. Dependencies

### Bu sistemin dayandıkları (yukarı akış)

| Sistem | Tür | Arayüz |
| --- | --- | --- |
| Harita / Tur Akışı (`region-map-system.md`) | **Sert** | `MapState` (bölgeler, `current_turn`, `enemy_actions_per_turn`), `end_turn` sırası (AI 1. adım, takviye 3. adım), `WinCondition`, `ChapterMapDefinition` (profil + `enemy_reinforcement_*`) |
| Ordu (`army-system.md`) | **Sert** | Düşman hamleleri aynı kurallarla `mover = ENEMY` uygulanır; kaynakta 1 garnizon |
| Savaş (`combat-system.md`) | **Sert** | `CombatResolver` düşman saldırısını çözer; etkin güç (§4) yalnız oyuncu tarafına uygulanır, AI `P_eff` değerini aynı tanımla okur |
| Kaynak (`resource-system.md`) | **Sert** | Takviyenin ekonomi adımında yürütülmesi (F6); kural sahibi bu belge |
| Kök Böri / Ruh (`spirit-system.md`) | **Okuma** | Savunma lütuflarının (Demir Post vb.) modifikatörleri `P_eff` için okunur (ADR-0006 `StatResolver`); bozulma ve nötr bölgeler AI kapsamı dışıdır (§3.7); Erlik'in Gölgesi ayrı |

### Bu sisteme dayananlar (aşağı akış)

| Sistem | Tür | Arayüz |
| --- | --- | --- |
| Sahne Akışı (`scene-flow.md`) | Yumuşak | Zafer/yenilgi sonucu; kayıp sebebi enum'u değişmez (K4) |
| Sunum (ADR-0011 savaş raporu) | Sert | `MoveIntent.reason` (`&"strike"`) ile `BATTLE_LOST_DEFENSE` metni |
| Diplomasi (`diplomacy-system.md`, yazılmadı, M2 dışı) | Gelecek | Kral bölgeleri üzerinde ittifak/fetih; bu belge diplomasi içermez |
| Seviye belgeleri (`design/levels/`) | Sert | Profil + takviye + garnizon verisi; Perde 1 `perde1-dogu-curcet.md` |

### Karşı güncellemeler (C-44 durumu)

1. `resource-system.md`: §3.1 kural 6 sahibi bu belge; Açık Soru 4 kapandı — **yapıldı**.
2. `region-map-system.md` §3.5: `decide(map_state, acted) -> MoveIntent`, R1 küresel sıra notu — **yapıldı**.
3. `spirit-system.md` §6: `enemy-layers.md` zaten "Erlik burada değil" notunu içerir; çapraz referans geçerli.
   Lütuf modifikatörlerinin AI tarafından okunması (`P_eff`) spirit §3.5 tarafında not edilmeli — **yapıldı ✅**
   *(C-44 inceleme (2026-10-21), W-9)*.
4. `scene-flow.md` §6 satırı: "yeni `loss_reason`" ifadesi düzeltildi — **yapıldı**.
5. `systems-index.md`: Katmanlı Düşman satırı — **yapıldı**.
6. `adr-0005-ai-architecture.md`: `EnemyAIProfile` alan listesi + `P_eff` eki — **yapıldı**.
7. `design/levels/perde1-dogu-curcet.md` §4.2 (savunma tutma parantezi → F-E2, `P_eff`) ve §3.4 madde 3 (§7→§6)
   — **yapıldı ✅** *(C-44 inceleme (2026-10-21), W-9)*.
8. `combat-system.md` §4 "Etkin güç": "AI savunma etkin gücünü okur" notu — **yapıldı ✅** *(W-9)*.

---

## 7. Tuning Knobs

| Ayar | Perde 1 | Güvenli aralık | Kategori | Çok düşükse | Çok yüksekse | Gerekçe |
| --- | --- | --- | --- | --- | --- | --- |
| `attack_start_turn` | 5 | 3 – 8 | Gate | T3–4: oyuncu kurulumu bitmeden vurulur, ilk saldırı haksız hissedilir | T9+: AI hiç tehdit etmez, düşman "dekor" olur | Kurulum T1–4, sıkışma T5–9 (seviye §5) |
| `strike_ratio` (num/den) | 3/2 | 1/1 – 2/1 | Curve | 1/1: her eşitsizlikte vurur, öngörülemez | 2/1: AI neredeyse hiç vurmaz | Replay: yalnız açık üstünlükte vurur; 3/2 test sınırı (`_ratio_exactly_one_and_half_strikes`) |
| `strike_enabled` | true | bool | Gate | false: eski davranış (Prolog) | — | Varsayılan profil geriye uyumlu |
| `enemy_actions_per_turn` | 1 | 1 – 2 | Gate | — | 2: tempo ikiye katlanır, T5–7 penceresi bozulur | `MapState` alanı; Perde 1 tek hamle |
| `enemy_reinforcement_per_turn` (`E_r`) | 1 | 0 – 3 | Curve | 0: baskı yok | 2+: birkaç tur boşa harcanırsa kazanılamaz | `resource-system.md` §7 ile aynı değer |
| `enemy_reinforcement_region_ids` | `[curcet_otagi]` | boş = tüm düşman bölgeleri | Curve | boş (Perde 1'de) tüm bölgeler büyür: tempo bozulur | — | Seviye §4.3: yalnız başkent |
| Başlangıç garnizonları | 2 / 4 / 4 | 1 – 8 | Curve | Çok düşükse Kurt İni bedava | Çok yüksekse güney/kuzey yolu kilitlenir | Seviye §3.1 Adım 3 son değerleri |
| R2 savunma kaydırması | KAPALI | — | (sabit karar) | — | — | Simülasyonda tempoyu bozdu (seviye §4.2) |

Hiçbir değer koda gömülmez: profil `EnemyAIProfile` `.tres`, takviye değerleri `ChapterMapDefinition` verisi.
**Sahiplik (C-44 inceleme (2026-10-21), W-13):** değerler: bölüm verisi (seviye belgesi → `.tres`); kural:
bu belge; yürütme: `resource-system.md` F6.
Kural değişirse (özellikle `P_eff` okuması sonrası) seviye belgesi §5 simülasyon tablosu yeniden üretilir
(C-47 replay).

---

## 8. Acceptance Criteria

### Birim (BLOCKING) — `tests/unit/ai/` (Perde 1 listesi seviye belgesi §13'ten)

> **✅ C-82 (2026-10-25):** AC1–AC10, AC19, AC20 → `tests/unit/ai/enemy_ai_counterattack_test.gd` (15 test; adlar §13'teki `test_counterattack_*`). Profil `EnemyAIProfile`, harita alanı `ChapterMapDefinition.enemy_ai_profile`.

- **AC1:** GIVEN tur 4, profil `attack_start_turn=5`, uygun bir hedef var, WHEN `decide`, THEN `null`
  (`test_counterattack_before_turn_five_never_strikes`).
- **AC2:** GIVEN tur 5, E.army = 8, P.army = 4, WHEN `decide`, THEN `MoveIntent(E→P, reason=&"strike")`
  (`_at_turn_five_strikes_when_ratio_met`).
- **AC3:** GIVEN A = 6, P_eff = 4 (2A = 12 = 3P), THEN vurur; GIVEN A = 5, P_eff = 4 (10 < 12), THEN `null`
  (`_ratio_exactly_one_and_half_strikes`, `_ratio_just_below_threshold_holds`).
- **AC4:** GIVEN A ≤ P_eff, THEN vurmaz (`_requires_attacker_greater_than_defender`).
- **AC5:** GIVEN E'nin iki komşu oyuncu bölgesi ve A ≥ 2, THEN E vurmaz; GIVEN iki komşu ve A = 1, THEN
  koşul F-E2'ye göre savunma tutma yok (`_holds_when_source_defends_other_player_neighbor`).
- **AC6:** GIVEN yalnız nötr komşular (çürük koru dahil), THEN `null`
  (`_never_enters_neutral_region`).
- **AC7:** GIVEN iki özdeş durum yalnızca `corruption_level` farkıyla, THEN aynı kararı verir
  (`_ignores_corruption_level`).
- **AC8:** GIVEN birden çok aday, THEN sıra en zayıf P_eff → en büyük A → alfabetik `from` → alfabetik `to`
  (`_weakest_target_largest_attacker_alphabetical_ties`).
- **AC9:** GIVEN aynı `MapState`, WHEN 100 kez çağrılır, THEN sonuç aynı; `decide` durumu değiştirmez
  (`_is_deterministic_across_runs`).
- **AC10:** GIVEN varsayılan profil ve eski senaryo, THEN eski "en düşük ordulu komşu" davranışı birebir
  korunur (Prolog regresyon testi).
- **AC11 (F6 devri):** GIVEN `enemy_reinforcement_region_ids = []`, THEN tüm `ENEMY` bölgeler +E_r;
  `[curcet_otagi]` iken yalnız başkent; listedeki ama `ENEMY` olmayan bölge hiçbir şey almaz
  (`unit/resources`: `..._empty_region_list_matches_legacy...`, `_capital_only_list...`, `_non_enemy_listed_region_gets_nothing`).
- **AC12 (F-E3):** GIVEN Perde 1, saldırı yok, WHEN 8 tur geçer, THEN başkent ordusu 12 olur (4 + 8).
- **AC19 (etkin güç okuması):** GIVEN E.army = 8 (A = 7), P.army = 4 ve Demir Post yığını `P_eff = 6`, WHEN
  `decide`, THEN `null` (14 < 18); GIVEN aynı durum modifikatörsüz, THEN `MoveIntent(E→P)`
  (`_reads_effective_defense_from_modifiers`). GIVEN P.army = 0, THEN `P_eff = 0` ve vurur
  (`_empty_target_ignores_modifiers`). AC8 sıralaması `P_eff` ile test edilir.
- **AC20 (saflık):** GIVEN aynı `MapState` ve modifikatör listesi, WHEN `decide` çağrılır, THEN ne `MapState` ne
  modifikatör listesi değişir (`_does_not_mutate_inputs`).

### Entegrasyon (BLOCKING)

- **AC13:** GIVEN T5+, uygun hedef, WHEN `end_turn`, THEN `battle_resolved` raporu `reason = &"strike"` taşır, bölge
  düşer ve sunum katmanı `BATTLE_LOST_DEFENSE` seçer (R1 vuruşu `A > P_eff` olduğundan `BATTLE_HELD_DEFENSE` üretilmez).
- **AC14:** GIVEN düşman AI tur sonunda bir bölge aldı ve bölge takviye listesindeyse, THEN aynı tur +E_r alır.
- **AC15:** `integration/balance/perde1_balance_test` (gerçek controller replay): N-fast W12, S-purify W20,
  Mixed W14, no-purify L18, pasif L15, 3 boş tur 15'ten önce zafer yok; ilk AI vuruşu T5–7 aralığında
  (seviye §13 #10; fark çıkarsa replay esas alınır). `P_eff` okuması sonrası tablo yeniden üretilir (C-47).
  *(C-44 inceleme (2026-10-21), R-1: S-purify W14 → W20, seviye §13 #10 ve boon-balance ile hizalı.)*
- **AC21 (BLOCKING, C-47 — D1 / H1):** S-purify (önce arındır) hattı ≤ T16'da kazanır. Sağlanmazsa seviye verisi
  ayarlanır (ör. `attack_start_turn`, başkent takviyesi, garnizon); Kök Böri'nin sözü değişmez.
- **AC22 (C-47 ölçüm maddeleri — D5):** replay şunları ölçer ve kabul / erteleme kaydı yazar: T5 sonrası AI adayı
  tur oranı (H2); "felç + yeniden arındırma" çizgisi Ruh/tur (H3 → ×0.5 yedeğinin tetiği); GK1 / Bereket1 giriş
  varyantları (H4 → pasif + GK1 > T18 ise Perde 1 `erlik_loss_threshold` 9 → 8); N4/N5/N6/N8/N9 Perde 1 için
  (W-7; işaretçiler "C-47 replay sonrası"na taşınır).

### Sistem / deneyim (ADVISORY)

- **AC16 (playtest):** GIVEN ilk kez oynayan oyuncu, WHEN ilk AI vuruşu gelir, THEN oyuncu nedenini kural
  ipucu metninden açıklayabilir (12 maddelik playtest, madde 8). Ölçüt: >= 4/5 oyuncu "nedenini biliyordum".
- **AC17:** Medyan sahne süresi T10–15 (seviye kabul #10).
- **AC18:** Hiçbir playtest oturumunda AI'ın Erlik bölgesine girdiği ya da kral ile Erlik'in "iş birliği"
  izlenimi yaratıldığı bildirilmez (anlatı uyumu).

---

## 9. Visual/Audio Requirements

Görsel ve ses yönü art bible / seviye belgesine bağlıdır; bu belge yeni varlık istemez.

- **Düşman tamgası:** ENEMY bölgelerde owner tamgası **her zaman** görünür (renk körlüğü modundan bağımsız);
  nötrde tamga yok (seviye §7.8 #2). Pas turuncusu = düşman kral; mor yalnız Erlik (art bible).
- **Takviye:** Başkent ordu etiketinde `+1` vurgusu (`resource-system.md` §9, 2 kare); diğer düşman bölgelerinde yok.
- **Saldırıya uğrayan bölge işareti** ve **ses ipuçları eşlemesi:** cilaya ertelendi (seviye §7.8, §8);
  `audio-director` girdisi yok. Mevcut `AudioController` / `SfxLibrary` kullanılır.
- **Hareketi Azalt:** vurgular anında ve kalıcıdır (resource §9 ile aynı).

---

## 10. UI Requirements

- **Bilgi paneli, düşman bölgesi:** `Takviye: +E_r / tur` satırı yalnız takviye alan bölgelerde (başkent);
  `curcet_oba` / `kurt_ini_ormani` satırı göstermez.
- **Bilgi paneli, oyuncu bölgesi — kural bilgisi satırı (C-44 inceleme (2026-10-21), D3 / W-6, H5; C-45 (2026-10-21) K2):**
  Düşmana komşu oyuncu bölgesinin panelinde, `strike_enabled` iken **1. turdan itibaren her tur** görünür;
  yeni key `ENEMY_STRIKE_THRESHOLD` (kısa metin, `%s` = N). `N = max(P_eff+1, ceil(num·P_eff/den))`
  (`P_eff = 0` → 1; lütuflar dahil), F-E1'den türetilir. "Lütuflar dahil / T5'ten itibaren" açıklaması
  satırda değil `HINT_ENEMY_KING` ipucundadır. Niyet önizlemesi değildir (K8 korunur). Tam spec: `design/ux/hud.md` §5.3.
- **Kural ipucu (kalıcı bilgi):** `HINT_ENEMY_KING` (ilk tur, bir kez): "Kağan T5'ten sonra açık üstünlükle vurur;
  yalnız başkent büyür." `HINT_CAPITAL` (başkent ilk önizlemesi, bir kez). AI niyet önizlemesi **yoktur** (K8).
- **Savaş raporu:** `BATTLE_LOST_DEFENSE` (ADR-0011 `ModalQueue`; tek seferde bir modal).
- Yeni çeviri anahtarı: **yalnız `ENEMY_STRIKE_THRESHOLD`** (C-45 (2026-10-21), K2; `translations.csv`'ye önce `en`); diğerleri seviye belgesi §2'de listeli. Biçim kuralları ADR-0009'a uyar;
  glif kapsamı için `−` `⚠` `✕` `✓` kullanılmaz.

---

## 11. Kararlar (eski Açık Sorular)

Tümü **onaylıdır: "Karar (C-44, 2026-10-21)"** (kullanıcı onayı).

| # | Konu | Karar (C-44, 2026-10-21) |
| --- | --- | --- |
| K1 | Savunma tutma ifadesi | ADR-0005 okuması: **iki veya daha fazla** oyuncu komşusu **ve** `A ≥ 2` (F-E2). Seviye belgesi ifadesi bu tek tanıma bağlanır (§6 madde 7) |
| K2 | Takviye devri | Kural ve değerler bu GDD'de (§3.5); F6 yürütmesi `resource-system.md`'de kalır; iki belge çapraz bağlı |
| K3 | Başkent ordu üst sınırı | **Yok.** C-47 replay'inde başkent ordusu ölçülür; aşırı değerde `E_r` / liste ayarlanır |
| K4 | `loss_reason` | **Yeni enum yok** (`NO_REGIONS`, `ERLIK`); `scene-flow.md` §6 satırı buna göre düzeltildi |
| K5 | `EnemyAIProfile` alanları | `attack_start_turn`, `strike_ratio_num`, `strike_ratio_den`, `strike_enabled`; ADR-0005 eki ile aynı |
| K6 | Çoklu hasım | M2'de tek profil / tek `ENEMY`; Kıl Barak nötr boy garnizonu; çoklu profil sonra |
| K7 | Düşman ekonomisi | Asimetrik: hazine yok, sabit takviye, modifikatör yok (`resource-system.md` Açık Soru 4 kapandı) |
| K8 | AI niyeti önceden gösterilsin mi | **Hayır.** Hamle sonrası rapor + kural ipucu; önizleme M3'e |
| K9 | Perde 2–4 sayıları | Her perdenin kendi seviye belgesinde / replay'inde belirlenir (§3.8) |
| K10 | AI'nın okuduğu savunma gücü *(yeni, kullanıcı onaylı)* | AI, oyuncunun **etkin** savunma gücünü (`P_eff`, lütuflar dahil) okur: "oyuncuya uygulanan kural AI'ya da". F-E1'de `P` yerine `P_eff`. Kaynak: C-44 lütuf denge analizi (Demir Post aksi halde etkisiz). `decide()` saf kalır; modifikatörler girdi (ADR-0005 eki) |

**Sonuç notu (K10):** R1 vuruşu artık hep başarılı (F-E4) ve `BATTLE_HELD_DEFENSE` R1'den üretilmez; sunum katmanı
bu metni yalnız `A ≤ P_eff` saldırıları (şu an yok) için saklar. Perde 1 simülasyon tablosu C-47'de yeniden
üretilmelidir.

---

## 12. Kaynak Çelişkileri

| # | Çelişki | Durum |
| --- | --- | --- |
| C1 | Seviye §4.2 savunma tutma parantezi ↔ ADR-0005 eki (K1) | **Çözüldü (C-44):** ADR esas (F-E2). Seviye belgesi metni düzeltmesi **yapıldı ✅** (C-44 inceleme (2026-10-21), W-9) |
| C2 | `scene-flow.md` bağımlılık satırı ("yeni loss_reason") ↔ seviye §6/§12 ("yeni enum yok") (K4) | **Çözüldü (C-44):** seviye esas; `scene-flow.md` düzeltildi |
| C3 | `region-map-system.md` §3.5 imzası `decide(map_state) -> Array[MoveIntent]` ↔ ADR-0005 / kod `decide(map_state, acted) -> MoveIntent` | **Çözüldü (C-44):** kod + ADR esas; GDD düzeltildi |
| C4 | Mevcut kod `decide()` R1 / `EnemyAIProfile` / `reason` / `P_eff` içermiyor; GDD'ler Perde 1 kurallarını "onaylı" sayıyor | **Açık — uygulama:** C-44 uygulama görevi (seviye §13 #1); test AC1–AC20 |
| C5 | `region-map-system.md` §3.5 "region_id fiilen AI önceliği" ↔ R1 sırası (küresel) | **Çözüldü (C-44):** not yalnız varsayılan profil için; R1 küresel sıra (§3.3 madde 4) |
| C6 | Seviye §3.4 madde 3 "(§7)" ↔ koşul §6'da | **Çözüldü ✅** (C-44 inceleme (2026-10-21), W-9): seviye belgesinde düzeltildi |
| C7 | `systems-index.md` Katmanlı Düşman bağımlılıkları eksik (Savaş, Ruh, Sahne Akışı) | **Çözüldü (C-44):** index güncellendi |
| C8 | Seviye §5 simülasyon tablosu ham `P.army` okumasıyla üretildi; `P_eff` okuması (K10) sonuçları değiştirebilir | **Açık — replay:** C-47'de yeniden üretilir; savunma lütuflu hat eklenir |
