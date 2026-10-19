# Sistem GDD: Bölge Haritası ve Tur Akışı

*Oyun: ULUS: Blood of the Sky Wolf*
*Oluşturulma: 2026-07-14*
*Durum: Belgelenmiş (kod mevcut — `game/features/grid/`, `game/state/`) + planlı bölümler (§3.4 yayılım adımı, §3.6–3.7 oyun sonu: C-38, C-51; Erlik kaybı C-49 → kod C-63)*
*Katman: Core*

> Mevcut kodu belgeler. Harita bir **bölge grafiğidir** (tile-grid değil):
> bölgeler düğüm, komşuluk kenardır. Prolog haritası 6 bölgeyle çalışır.

---

## 1. Overview

Harita, veri-güdümlü bölgelerden (`.tres`) oluşan bir grafiktir. Her bölge sahip
(oyuncu/nötr/düşman), ordu ve tur başı gelir taşır. Oyuncu bölge seçer, ordu
gönderir; tur bitince düşman AI oynar, gelir toplanır ve kazanma/kaybetme kontrol
edilir. Görsel katman (tıklanabilir çokgenler, bağlantı çizgileri, bilgi paneli)
state'ten ayrıdır — controller state'i mutasyona uğratır, sinyallerle UI'ı bilgilendirir.

---

## 2. Player Fantasy

Oyuncu tüm bozkırı tek bakışta okur: kim nerede güçlü, hangi sınır zayıf. Her tur
"bu turdaki tek hamlem ne olmalı?" kararıdır — sıra tabanlı, sakin ama ağırlıklı.

---

## 3. Detailed Rules

### 3.1 Veri Yapısı
Alanların **sahibi** (anlamını tanımlayan GDD) parantez içinde; state yalnızca veri
tutar (ADR-0004). *planlı* = kodda henüz yok.
- **RegionData**: `region_id`, `display_name_key`, `owner` (NEUTRAL/PLAYER/ENEMY),
  `army_count`, `gold_per_turn` (resource F1 `G_base`), `position`, `polygon_points`,
  `adjacent_regions`; *planlı:* `corruption_level` (spirit §3.1, C-38),
  `recruited_this_turn` — üretim sayacı (resource §3.2, C-37), `herd_per_turn` (resource
  §3.1, pasif).
- **MapState**: `regions` (id→RegionData), `current_turn` (sahne başında **1**),
  `actions_remaining`, `actions_per_turn`, `enemy_actions_per_turn`,
  `selected_region_id`, `chapter_id`, `player_tamga_id`, `enemy_tamga_id`;
  *planlı:* `last_erlik_spread_turn` (spirit §3.6, başlangıç 0), `erlik_spread_interval`
  (sahnenin taban aralığı, spirit §4), `game_result` (§3.7, C-51).
- Harita tanımı `ChapterMapDefinition` Resource'undan üretilir (`create_map_state()`).
  **İçerik alanları** (bölüm başına, kaydedilmez — ADR-0007): bölge tanımları
  (`RegionDefinition`: yukarıdaki statik alanlar + başlangıç `owner`/`army_count` +
  *planlı* başlangıç `corruption_level` = `initial_owner` kaynağı), `actions_per_turn`,
  `enemy_actions_per_turn`, `player_tamga_id`/`enemy_tamga_id`, `starting_gold` ve
  `enemy_reinforcement_per_turn` (resource §7), `win_condition` (§3.6, `erlik_foci` ve
  *planlı* `erlik_loss_threshold` dahil — C-49), *planlı* `erlik_spread_interval` (spirit —
  Prolog 3) ve lütuf havuzu override'ı (spirit §7, MVP'de yok). `erlik_power` hiçbir yerde
  saklanmaz; bölgelerin `corruption_level`'larından türetilir (spirit §4.7).

### 3.2 Bölge Seçimi (`select_region`)
- Boş alandan farklı bir bölgeye tıklama → o bölge seçilir (bilgi paneli açılır).
- Zaten seçili bölgeye tekrar tıklama → seçim kalkar (toggle).

### 3.3 Hareket (`attempt_move`)
- Seçili bölge kaynak, tıklanan bölge hedeftir.
- Ordu Sistemi doğrulaması geçerse varış çözülür — savaş, arındırma veya barışçıl
  dal (`army-system.md` §3.3) — `actions_remaining−=1`, seçim temizlenir, kazanma
  kontrol edilir. Kazanma sağlanırsa oyun **o anda biter** (§3.7): `game_won` bir kez
  yayılır, kalan aksiyonlar geçersizdir, `end_turn` çalışmaz.

### 3.4 Tur Bitişi (`end_turn`)
Oyun `ONGOING` değilse hiçbir adım çalışmaz (§3.7). Sıra: **(1)** düşman AI oynar → **(2)** Erlik yayılımı (`spirit-system.md` §3.6;
yalnızca yayılım turunda, aksi halde atlanır) → **(3)** ekonomi adımı: oyuncu
geliri + düşman takviyesi + bakım (`resource-system.md` §3.1) → **(4)**
`current_turn+=1`, `actions_remaining = actions_per_turn`, bölge üretim sayaçları
sıfırlanır → **(5)** oyun sonu kontrolü: önce kaybetme (bölgesiz **veya** Erlik eşiği —
§3.6), sonra kazanma (§3.6–3.7). Erlik kaybı 2. adımda oluşsa da 5. adımda değerlendirilir
(3–4. adımlar çalışır; `turn_ended` yayılmaz — aşağıda).

- **Erken çıkış (C-53, S2-b):** 1. adımdan sonra oyuncunun hiç bölgesi kalmamışsa sonuç
  hemen `LOST` olur; 2–4. adımlar çalışmaz (ölü oyunda olay yayılmaz).
- **Sinyal ve kayıt sırası (C-53, W-D):** 5. adımda sonuç değişirse yalnızca `game_lost`
  / `game_won` yayılır. Oyun sürüyorsa `turn_ended(new_turn)` **5. adımdan sonra**
  yayılır; tur sonu otomatik kayıt (ADR-0007) ve HUD yenilemesi bu sinyali dinler —
  böylece kaybedilmiş ya da bitmiş bir durum asla kaydedilmez. Ardından oyuncu turu
  başlar (bekleyen Kök Böri sunumu — `spirit-system.md` §3.4). Zaferin kalıcılığı
  (`chapters_completed`, lütuf seçimleri → kayıt sırası) `scene-flow.md`'ye (C-35) aittir.
  *Kod (C-51, 2026-10-19): `MapController.end_turn` bu sırayı ve `game_result` kilidini uygular
  (Erlik yayılımı adımı C-38, Erlik kaybı C-63 ile eklenir).*

> **Neden yayılım gelirden önce (C-29, 2026-10-18):** yayılan bozulmanın üretim
> cezası (`M_c`) o turun gelirine hemen yansır — oyuncu çürümenin bedelini aynı
> tur öder. Sıra ADR-0005'teki `end_turn` şemasıyla (AI → Erlik) uyumludur.
> Erlik yayılımının **sahibi `spirit-system.md`**'dir; bu sistem yalnızca sırayı tutar.

### 3.5 Düşman AI
> **Durum (C-19, 2026-10-19):** Kurallar `game/features/ai/enemy_ai_controller.gd`
> (`EnemyAIController.decide(map_state, acted)`) içinde; `MapController` karar → uygula
> döngüsüyle uygular (ADR-0005, Accepted). Alfabetik eşitlik bozma ve işlem sırası C-52.

Hedef mimaride düşman AI saf bir karar servisidir (bkz. [ADR-0005](../../docs/architecture/adr-0005-ai-architecture.md)):
`EnemyAIController.decide(map_state) -> Array[MoveIntent]` yalnızca `MapState`'i
**okur** ve deterministik bir hamle listesi (intent) döndürür — state'i değiştirmez,
sinyal yaymaz. `MapController.end_turn()` intent'leri `ArmyController`/`CombatResolver`
üzerinden **uygular** ve mevcut sinyalleri yayar.

- Düşman bölgeleri `region_id` artan (alfabetik) sırayla işlenir (C-33, W6).
  **İçerik notu:** `enemy_actions_per_turn = 1` iken hamle yapabilen ilk düşman bölgesi
  (alfabetik) turun tek hamlesini yapar — `region_id` fiilen AI önceliğidir; bölüm
  verisi yazarları bunu bilerek adlandırır.
- Her düşman bölgesi için (army > 1):
  - Komşular arasında düşman-olmayan, `army_count`'u en düşük hedefi seç; eşitlikte
    `region_id` alfabetik ilk (W6 — Erlik yayılımı ve ADR-0005 ile aynı kural).
  - Kuvvet (army−1) gönder; hedefte ordu varsa savaş, yoksa işgal.
- Düşman tur başına en fazla `enemy_actions_per_turn` aksiyon yapar (data-driven,
  `MapState.enemy_actions_per_turn`; her düşman bölgesi en fazla 1 hamle). MVP: 1.

### 3.6 Kazanma / Kaybetme — C-32 kararı (2026-10-18)
- **Kazanma** (`WinCondition.is_met`) üç koşulun **hepsi** sağlanınca:
  1. **Siyasi:** `must_defeat_all_enemies` ise hiç `ENEMY` bölgesi kalmamış.
  2. **Genişleme:** başlangıçta nötr olan ve Erlik odağı olmayan bölgelerden oyuncunun
     elindekilerin sayısı `required_neutral_conquests`'e ulaşmış (formül §4).
  3. **Erlik odağı (kapsam kararı, D4):** bölümün `erlik_foci` listesindeki her bölge
     arındırılmış (`corruption_level == 0`). Odak dışındaki bozulma zaferi engellemez —
     hedef "bu yönü fethet + Erlik odağını temizle"dir (konsept), bütün bozulmayı
     silmek değil. Liste boşsa koşul kendiliğinden sağlanır.
- **Kaybetme** (C-49 ile genişledi) — ikisinden biri yeterli:
  1. **Siyasi:** oyuncunun hiç bölgesi kalmazsa.
  2. **Erlik kaybı (C-49):** `erlik_loss_threshold > 0` **ve** `erlik_power ≥
     erlik_loss_threshold` (`erlik_power = Σ corruption_level`, `spirit-system.md` §4.7).
     Eşik bölüm verisidir (`WinCondition`); **Prolog 9** (başlangıç `erlik_power` 4); 0 =
     kapalı. Prolog'da `ENEMY` olmadığından (spirit §3.7) Prolog'un tek gerçekçi kayıp yolu
     budur: hiç arındırmayan oyuncu 15. turun sonunda kaybeder (`resource-system.md` §4).
- **Öncelik:** İkisi aynı anda sağlanamaz: kazanma en az bir oyuncu bölgesi ister ve tur
  sonunda zafer oluşmaz (Erlik eşiği yalnızca yayılımla aşılır, yayılım zafer üretemez).
  Savunmacı kural: bir kontrol noktasında önce kaybetme, sonra kazanma değerlendirilir.
- **Kontrol noktaları:** (a) her geçerli oyuncu hamlesinden sonra yalnızca kazanma
  (oyuncu kendi hamlesiyle son bölgesini kaybedemez — kaynakta garnizon kalır; hamle
  `erlik_power`'ı yalnızca düşürebilir); (b) `end_turn` 5. adımında kaybetme (siyasi,
  Erlik) → kazanma.

### 3.7 Oyun Sonu (C-32)
- Oyun sonucu state'te tutulur: `MapState.game_result` ∈ {`ONGOING`, `WON`, `LOST`}
  (ADR-0004: yalnızca veri). Başlangıç `ONGOING`.
- Sonuç `ONGOING` dışına çıktığında **bir kez** ilgili sinyal yayılır (`game_won` /
  `game_lost`) ve oyun kilitlenir: `attempt_move` `false` döner, `end_turn` hiçbir adımı
  çalıştırmaz (AI, yayılım, gelir, tur artışı yok), üretim reddedilir. Bölge seçimi
  (bilgi paneli) okuma amaçlı serbesttir. **Lütuf seçimi kilitten muaftır** (C-53, S1-c):
  zafer sonrası bekleyen Kök Böri sunumları kilit altında yapılır.
- **İşleme sırası (S1-a):** `game_won` yalnızca hamlenin bütün sonuçları (sahiplik,
  ordu, bozulma, Ruh, aksiyon) işlendikten sonra yayılır; dinleyiciler tutarlı son
  durumu görür.
- Tur ortası zaferde kalan aksiyonlar ve o turun geliri kaybolur — zafer anında sahne
  biter. Ardından sahne akışı devralır: bekleyen Kök Böri sunumları
  (`spirit-system.md` §3.4) → outro (`scene-flow.md`, C-35).

---

## 4. Formulas

### Gelir
Gelir formülünün sahibi `resource-system.md`'dir (F1 efektif bölge geliri, F2 tur
geliri). MVP'de bozulma ve lütuf yokken F2, oyuncu bölgelerinin `gold_per_turn`
toplamına eşittir. Örnek (Prolog başlangıcı, sadece Oğuz Otağı, gold_per_turn=2):
tur geliri = 2.

### Kazanma kontrolü (C-32; eski metin W7'deki bire-bir hatayı taşıyordu)
```
N = { r : initial_owner(r) == NEUTRAL  ∧  r ∉ erlik_foci }
conquered_neutral_count = | { r ∈ N : r.owner == PLAYER } |
siyasi    = (NOT must_defeat_all_enemies) OR (düşman_bölgesi == 0)
genişleme = conquered_neutral_count ≥ required_neutral_conquests
odak      = ∀ f ∈ erlik_foci : f.corruption_level == 0
kazandı   = siyasi AND genişleme AND odak AND (oyuncu_bölgesi ≥ 1)
```
`initial_owner` bölüm tanımından (`ChapterMapDefinition`, içerik) okunur; kayda
yazılmaz (ADR-0007). Eski formül `oyuncu_bölge_sayısı − 1` başlangıç bölgesi
kaybedilince eksik, ele geçirilen düşman bölgelerini ve odağı nötr fethi gibi sayıyordu.
**Örnek (Prolog, C-36 verisiyle):** 4 nötr + Canavarın İni (odak) + Otağ. Oyuncu 3 nötrü
alıp ini arındırınca `conquered_neutral_count = 3 ≥ 3`, odak temiz, düşman yok → zafer;
yalnızca 3 nötr alınmış ve in bozuksa zafer yok. Doğu Obası (öğretici bozulma, C-49)
arındırmayla yerleşilince `N`'nin üyesi olarak sayılır.

### Kaybetme kontrolü (C-49)
```
erlik_power = Σ r.corruption_level                     # spirit §4.7, türetilir
siyasi_kayıp = (oyuncu_bölgesi == 0)
erlik_kaybı  = erlik_loss_threshold > 0  AND  erlik_power ≥ erlik_loss_threshold
kaybetti     = siyasi_kayıp OR erlik_kaybı            # yalnızca end_turn 5. adımı (+ 1. adım erken çıkışı: siyasi)
```
**Örnek (Prolog, eşik 9):** başlangıç 4; oyuncu hiç arındırmazsa yayılımlar T3/T6/T9/T12/T15
sonlarında 5/6/7/8/9 → T15'in 5. adımında `LOST`. Oyuncu T13'te seviye 2 bir bölgeyi
arındırırsa 8 → 6 olur ve T15 sonunda 7'de kalır.

### Düşman AI hedef seçimi
```
hedef = argmin(army_count) over { komşular : owner ≠ ENEMY }
        eşitlikte region_id alfabetik ilk          # C-33, W6 (eski: "ilk bulunan")
işlem sırası = düşman bölgeleri region_id artan; bütçe enemy_actions_per_turn bitince dur
```

---

## 5. Edge Cases

- **Aynı bölgeye çift tık**: seçim toggle (aç/kapa).
- **Aksiyon bitti**: hareket reddedilir; oyuncu tur bitirmeli.
- **Düşman hareket edemiyor** (kaynak düşman bölgesinin ordusu ≤ 1, ya da tüm
  komşuları düşman): o düşman bölgesi atlanır, bütçeden harcamaz.
- **Kazanma tur ortasında** (`attempt_move` sonrası): oyun anında biter (§3.7);
  `game_won` bir kez, `end_turn` artık çalışmaz — o turun düşman AI'ı, yayılımı ve
  geliri olmaz.
- **Kazanma/kaybetme tur sonunda**: `end_turn` 5. adımında önce kaybetme, sonra kazanma.
- **Oyun bittikten sonra hamle/tur bitirme denemesi**: reddedilir (`false` / no-op),
  sinyal tekrar yayılmaz.
- **Başlangıç bölgesi kaybedildi**: sayım `initial_owner`'a dayandığı için etkilenmez;
  oyuncunun başka bölgesi varsa oyun sürer.
- **Odak arındırıldı, sonra yayılımla yeniden bozuldu**: odak koşulu kontrol anındaki
  duruma bakar → yeniden arındırılana kadar zafer yok.
- **Ele geçirilen düşman bölgesi**: genişleme sayımına girmez (siyasi koşulun parçasıdır).
- **Beraberlikte boşalan bölge** (çapraz inceleme W3, C-33): savaştan sonra 0 birlikle
  kalan bölge sahipsiz olur (`army-system.md` §3.3). Bu yüzden 0 ordulu `ENEMY` ya da
  `PLAYER` bölgesi hiç oluşmaz: siyasi koşulu veya `game_lost`'u yapay olarak
  engelleyen "hayalet" bölge kalmaz.
- **Prolog kazanma kriteri**: `required_neutral_conquests = 3` + Canavarın İni
  **arındırılmalı** (C-29: canavar siyasi düşman değil, bozulmuş nötr bölgedir —
  `spirit-system.md` §3.7). Kural C-32'de tanımlandı; kod C-51, veri C-36. C-49: Prolog'da
  `ENEMY` yoktur (bilinçli) → siyasi koşul kendiliğinden sağlanır; inin garnizonu 0'dır,
  böylece son hamle her zaman arındırmadır ve zafer o hamlede gelir (garnizonlu odak
  hamleyi savaşa çevirir — AC14 bunu veriyle engeller).
- **Erlik kaybı** (C-49): eşik yalnızca tur sonunda aşılabildiğinden tur ortasında zaferle
  çakışmaz; 2. adımda aşılırsa 3–4. adımlar (gelir, tur artışı) yine çalışır, 5. adımda
  `game_lost` bir kez yayılır, `turn_ended` ve otomatik kayıt olmaz (W-D kuralı).
  Başlangıçta `erlik_power ≥ eşik` bir veri hatasıdır (AC14). Eşik 0 → Erlik kaybı yok.
  Kayıp ekranının metni ve tekrar dene akışı `scene-flow.md`'ye (C-35) aittir.
- **Erlik kaybı, odak arındırılmışken:** mümkündür (diğer bozuk bölgeler eşiği doldurabilir)
  ama Prolog'da odak arındırılınca genellikle zafer de gelir; gelmezse (3 nötr eksik)
  oyuncu nötrleri alana kadar Erlik saati işlemeye devam eder.

---

## 6. Dependencies

- **Ordu Sistemi** (`army-system.md`, kod: `army_controller.gd`).
- **Savaş Çözümü** (`combat-system.md`, kod: `combat_resolver.gd`).
- **Kaynak Yönetimi** (`resource-system.md`, kod: `resource_controller.gd`) —
  ekonomi adımı (gelir F2, düşman takviyesi F6, bakım F7), üretim sayaçları;
  `ChapterMapDefinition` bu sistemin `starting_gold` ve
  `enemy_reinforcement_per_turn` ayarlarını taşır.
- **Oyun Durumu** (`game_state.gd`) — `map_state`, `gold`, (planlı: `ruh`, `boons`).
- **Ruh Sistemi** (`spirit-system.md`) — `RegionData`'ya `corruption_level`
  eklenecek; Erlik yayılımı `end_turn` 2. adımında çalışır (§3.4). Erlik modeli,
  sahiplik ve yayılımın sahibi: `spirit-system.md` §3.7. Arındırma oyuncu
  hamlesinin bir varış dalıdır (`army-system.md` §3.3, spirit §3.2); bilgi paneli
  bozuk bölgede seviye + direnç gösterir.
- **Kök Böri / Kozmik katman**: düşman AI'nin yanına Erlik yayılım AI'si eklenecek
  (ADR-0005, `ErlikSpreadController`).
- **Sahne Akışı** (`scene-flow.md`, C-35) — `game_won` / `game_lost` ve `game_result`
  kilidinin tüketicisi: zaferde sonuç kartı → zorunlu lütuf seçimleri → kayıt → outro, yenilgide
  yenilgi ekranı (§3.7 sonrası akış orada). Sahne başında haritayı `create_map_state()` +
  `starting_gold` ile kurar; Kök Böri hedef işareti `WinCondition.erlik_foci` ve
  `description_key`'den okunur (scene-flow §3.5). Kayıp ekranı metni için `game_lost` ile birlikte
  okunabilir bir **kayıp sebebi** (`loss_reason`: `ERLIK` = Erlik kaybı, `NO_REGIONS` = bölgesiz
  kalma) gerekir — üretimi C-63.

---

## 7. Tuning Knobs

| Knob | Kaynak | Not |
| ---- | ---- | ---- |
| `actions_per_turn` | ChapterMapDefinition | MVP: 1 |
| Bölge sayısı / layout | `.tres` (veri-güdümlü) | Prolog: 6 |
| `required_neutral_conquests` | WinCondition | Prolog: 3 |
| `must_defeat_all_enemies` | WinCondition | Prolog: true (C-49 kararı: Prolog'da `ENEMY` yok, siyasi katman nötr boylar → koşul kendiliğinden sağlanır) |
| `erlik_foci` | WinCondition | Arındırılması zorunlu Erlik odakları (region_id listesi). Prolog: [`sinir_bolge`] (C-36), garnizon 0 (AC14) |
| `erlik_loss_threshold` | WinCondition | Erlik kaybı eşiği (`erlik_power`, spirit §4.7); 0 = kapalı. **Prolog 9** (C-49) — güvenli aralık: başlangıç `erlik_power` + 3 … 3 × bölge sayısı. 8 → ihmal kaybı T12 (sert), 10 → T18 (baskı zayıf). Değişirse `resource-system.md` §4 tablosu yeniden üretilir |
| Bölge `army_count` / `gold_per_turn` | `.tres` | Denge |
| `enemy_actions_per_turn` | ChapterMapDefinition / MapState | Düşmanın tur başına toplam aksiyonu (data-driven; MVP: 1) |
| `player_tamga_id` / `enemy_tamga_id` | ChapterMapDefinition → MapState | Sahiplik tamgası (`icon_tamga_<id>.png`, art bible §5/§7). Prolog: `oguz` / `erlik_beast` *(C-29: canavar artık nötr olduğundan `enemy_tamga_id` Prolog'da kullanılmaz; Erlik görseli tamga değil bozulma katmanıdır — C-36'da veri temizlenir)*. Bölgenin tamgası sahibinden türetilir → fetihte değişir; nötr tamgasız |

---

## 8. Acceptance Criteria

1. Prolog haritası 6 bölgeyle yüklenir; sahiplikler doğru (Oğuz Otağı=oyuncu,
   Canavarın İni=nötr + `corruption_level 3` + ordu 0, Doğu Obası=nötr + `corruption_level 1`
   + ordu 0, Batı Obası 3 / Kutlu Dağ 2 / Bereket Vadisi 0 nötr). *(Test — veri C-36,
   değerler `resource-system.md` §4; o zamana dek mevcut `chapter_1_map.tres` eski modelde:
   Canavarın İni=düşman, 6 ordu.)*
2. Seçili bölgeye tekrar tıklama seçimi kaldırır. *(Test)*
3. Geçerli hareket `actions_remaining`'i 1 azaltır. *(Test)*
4. `end_turn` sırası: AI → Erlik yayılımı → gelir → tur artışı → kontrol. *(Test)*
5. Tur geliri `resource-system.md` F2'ye eşittir (bozulma ve lütuf yokken oyuncu
   bölgelerinin `gold_per_turn` toplamı). *(Test)*
6. Düşman AI en düşük ordulu düşman-olmayan komşuya saldırır; eşit ordulu iki komşuda
   `region_id` alfabetik ilkini seçer; düşman bölgeleri `region_id` sırasıyla işlenir.
   *(Test — eşitlik bozma kodu C-52)*
7. 3 nötr (odak hariç) ele geçirilip düşman kalmayınca ve odaklar temizken, hamleden
   hemen sonra `game_won` **bir kez** tetiklenir; ardından `end_turn` çağrılsa da AI,
   yayılım, gelir ve tur artışı çalışmaz. *(Test — kod C-51)*
8. Oyuncunun bölgesi kalmazsa `game_lost` tetiklenir; sonra `attempt_move` `false` döner.
   Düşman AI son bölgeyi 1. adımda alırsa 2–4. adımlar çalışmaz ve `turn_ended`
   yayılmaz. *(Test — kod C-51)*
9. Seçili bölgenin merkez ekseninde sahibinin tamgası görünür (nötrde yok); fetihten
   sonra tamga yeni sahibinkine geçer. Renk Körlüğü Modu açıkken tamga seçimden
   bağımsız olarak her sahipli bölgede görünür (C-07). *(Test)*
10. Başlangıç bölgesi kaybedilmiş, 3 başlangıçta-nötr bölge oyuncudaysa genişleme
    koşulu sağlanır (eski `−1` formülünün hatası yok). *(Test — kod C-51)*
12. Oyun sürerken `turn_ended`, 5. adımdaki kontrolden sonra yayılır; tur sonu otomatik
    kayıt yalnızca bu sinyalle ve `ONGOING` iken çalışır. *(Test — kod C-51 / C-56)*
11. Odak bölge bozukken diğer koşullar sağlansa da zafer yok; odak arındırılınca o
    hamlenin sonunda zafer. *(Test — bozulma C-38 ile gelir)*
13. **Erlik kaybı (C-49):** `erlik_loss_threshold = 9`, `erlik_power = 8`, oyuncunun bölgeleri
    var; `end_turn`'ün yayılımı bir bölgeyi bozunca 5. adımda `game_result = LOST` olur,
    `game_lost` bir kez yayılır, `turn_ended` yayılmaz, sonra `attempt_move` `false` ve
    `end_turn` no-op. Aynı durumda eşik 0 → oyun sürer. `erlik_power = 9` olan bir duruma
    oyuncu hamlesiyle (arındırma) gelinemez; hamle sonrası kontrol kayıp üretmez.
    *(Test — kod C-63)*
14. **Prolog veri kabul kriteri (C-49, S1-e):** `chapter_1_map.tres` yüklenince —
    `erlik_foci == [sinir_bolge]`; her odak `NEUTRAL`, başlangıç ordusu **0**, başlangıç
    `corruption_level ≥ 1` (in: 3); `dogu_bozkir` `NEUTRAL`, ordu 0, `corruption_level 1`;
    hiçbir bölge `ENEMY` değil; `erlik_loss_threshold = 9` ve başlangıç `erlik_power` (4) <
    eşik; `erlik_spread_interval = 3`; `starting_gold = 6`; `required_neutral_conquests = 3`.
    Genel kural (her bölüm): `erlik_loss_threshold > 0` ise başlangıç `erlik_power` < eşik.
    *(Veri testi — C-36)*
