# Sistem GDD: Ordu ve Hareket Sistemi

*Oyun: ULUS: Blood of the Sky Wolf*
*Oluşturulma: 2026-07-14*
*Durum: Belgelenmiş (kod mevcut — `game/features/army/army_controller.gd`)*
*Katman: Core*

> Mevcut kodu belgeler. MVP'de ordu tek bir soyut sayıdır (`army_count`) — birim
> tipleri (süvari/okçu/piyade) ve kahramanlar henüz kodda yok (§7).
> **Planlı (kodda yok):** §3.3'teki 2. dal (arındırma) C-30 kararıdır; uygulama C-38.

---

## 1. Overview

Ordu Sistemi, oyuncunun bir bölgeden komşu bölgeye ordu göndermesini yönetir:
hareketin geçerliliğini doğrular, orduyu taşır ve varış bölgesinin durumuna göre
(barışçıl birleşme veya savaş) sonucu uygular. Her bölge tek bir `army_count`
tutar; hareket eden kuvvet, kaynak bölgede daima 1 garnizon bırakır.

---

## 2. Player Fantasy

Oyuncu kuvvetlerini bir satranç taşı gibi konumlandırır: nereden nereye, ne kadar
güçle. Her zaman bir garnizon kalması, "arkamı boş bırakamam" gerilimini yaratır.

---

## 3. Detailed Rules

### 3.1 Hareket Doğrulama (`can_move`)
Kurallar hamle yapan taraf (`mover` ∈ {`PLAYER`, `ENEMY`}) için aynıdır (C-33, W5).
Hareket geçerlidir ancak ve ancak:
- Kaynak bölge hamle yapan tarafa ait (`owner == mover`), **ve**
- Kaynak ordu > 1 (en az 1 garnizon kalmalı), **ve**
- Hedef, kaynağın `adjacent_regions` listesinde, **ve**
- Hamle yapan tarafın aksiyon bütçesi > 0 (oyuncu: `map_state.actions_remaining`;
  düşman: tur başına `enemy_actions_per_turn`, `region-map-system.md` §3.5).

> **Bugünkü kod:** `ArmyController.can_move` yalnızca oyuncu için yazılıdır
> (`owner == PLAYER`); düşman AI aynı kuralları `MapController._run_enemy_ai()`
> içinde satır içi tekrarlar. ADR-0005 uygulaması (C-19) iki yolu bu tek kurala bağlar.

### 3.2 Ordu Taşıma (`move_army`)
- Taşınan kuvvet = `army_count − 1`.
- Kaynak bölge `army_count = 1` olur (garnizon).

### 3.3 Varış Çözümü
Varış, hedefin **o anki** durumuna göre **tek bir dala** gider; dallar aşağıdaki
öncelik sırasıyla denenir. Bir hamle tek bir katmanla uğraşır: önce siyasi
garnizon, sonra Erlik bozulması (C-30, 2026-10-18 — çapraz inceleme B3/B5).
*Yabancı garnizon* = sahibi hamle yapan taraf olmayan ve `army_count > 0` olan bölge
(oyuncu için nötr veya düşman; düşman için nötr veya oyuncu).

1. **Savaş** (hedefte yabancı garnizon var):
   - `CombatResolver.resolve(moving, hedef.army_count)` çağrılır.
   - Kazanılırsa → hedef `owner = mover`, `army_count = attacker_remaining`.
     **Hedefin `corruption_level`'ı değişmez** — fetih arındırmaz, Ruh vermez
     (`spirit-system.md` §3.2).
   - Kaybedilirse → hedef sahibi kalır, `army_count = defender_remaining`. Saldıranın
     hayatta kalanları (yalnızca beraberlikte > 0) **dağılır**: kaynağa dönmez,
     haritaya yerleşmez; savaş raporu bunları gösterir (C-33, W2).
   - **Boş kalan bölge (C-33, W3):** savaştan sonra hedefte 0 birlik kalırsa (ör. 1'e 1
     beraberlik) bölge **sahipsiz** olur: `owner = NEUTRAL`, `army_count = 0`;
     bozulması korunur. Sahipli bir bölge hiçbir zaman 0 orduyla kalmaz.
2. **Arındırma** *(planlı — C-38; yalnızca `mover == PLAYER`)* (yabancı garnizon yok —
   hedef oyuncunun ya da `army_count == 0` — **ve** `corruption_level ≥ 1`):
   - Arındırma gücü `P = moving`: yalnızca gelen kuvvet; hedefte zaten duran
     oyuncu garnizonu katılmaz.
   - `CombatResolver.resolve(P, corruption_strength)` çağrılır
     (`corruption_strength`: `spirit-system.md` §4.1).
   - **Başarı** (`P > corruption_strength`): `corruption_level = 0`, oyuncu Ruh
     kazanır (`spirit-system.md` §3.2). Hayatta kalanlar (`attacker_remaining`)
     yerleşir: hedef oyuncunun değilse `owner = PLAYER`,
     `army_count = attacker_remaining`; oyuncununsa `army_count += attacker_remaining`.
   - **Başarısızlık** (`P ≤ corruption_strength`, eşitlik dahil): gelen kuvvetin
     **tamamı kaybolur**; hedefin sahibi, ordusu ve bozulması değişmez.
3. **Barışçıl** (yabancı garnizon yok ve — oyuncu hamlesinde — bozulma yok):
   - Hedef zaten hamle yapanın → `army_count += moving`.
   - Değilse → `owner = mover`, `army_count = moving`.

**Düşman hamleleri** yalnızca 1. ve 3. dalı kullanır: bozulma düşmanın hedef seçimini
ve varışını etkilemez, düşman arındıramaz ve bozulma düşmanın aldığı bölgede kalır.

### 3.4 Aksiyon Tüketimi
- Her geçerli hareket — hangi dala giderse gitsin; kaybedilen savaş ve başarısız
  arındırma dahil — `actions_remaining` değerini 1 azaltır (Harita/Tur Akışı'nda,
  bkz. `region-map-system.md`). Arındırma ayrı bir eylem değildir, ek aksiyon
  istemez.

---

## 4. Formulas

```
moving_army = source.army_count − 1
```
Barışçıl birleşme (hedef oyuncunun):
```
target.army_count = target.army_count + moving_army
```
Barışçıl işgal (boş/nötr, army=0):
```
target.owner = PLAYER
target.army_count = moving_army
```
Savaş sonucu Savaş Çözümü GDD'sindeki formüllerle belirlenir; kalan ordu oradan gelir.

Arındırma (2. dal; `S` = `corruption_strength = corruption_level × CORR_STR_PER_LEVEL`,
`spirit-system.md` §4.1):
```
P = moving_army
başarı        ⇔ P > S
başarıda kalan = P − ceil(S × attacker_win_loss_ratio)   # CombatResolver Dal 1
başarısızlıkta kalan = 0                                  # gelen kuvvet tamamen kaybolur
```
| Seviye | `S` | En az `P` | Başarı kaybı | Kaynakta gereken ordu |
| ---- | ---- | ---- | ---- | ---- |
| 1 | 4 | 5 | 2 | ≥ 6 |
| 2 | 8 | 9 | 4 | ≥ 10 |
| 3 | 12 | 13 | 6 | ≥ 14 |

**Örnek (arındırma):** Kaynak army=10 → P=9. Hedef garnizonsuz nötr, seviye 2 (S=8)
→ 9 > 8 başarı, kayıp ceil(4)=4, bölge oyuncunun, army=5, `corruption_level=0`,
Ruh +20. Aynı hedefe P=8 gönderilseydi → eşitlik = başarısızlık, 8 birlik kaybolur,
bölge nötr / army 0 / seviye 2 kalır.

**Örnek**: Kaynak army=5 → moving=4, kaynak=1. Hedef boş nötr → hedef oyuncunun,
army=4. Hedefte 3 düşman varsa → savaş (4 vs 3, combat Dal 1): attacker_losses =
ceil(3 × 0.5) = 2, saldıran kazanır, hedef army=2 (C-33 düzeltmesi, W1 — eski metin 3
diyordu).
**Örnek (boş kalan bölge):** Kaynak army=2 → moving=1; hedefte 1 düşman → 1'e 1
beraberlik (Dal 3): iki taraf da 1 kayıp → hedefte 0 birlik → hedef `NEUTRAL`, army 0.

---

## 5. Edge Cases

- **army_count == 1**: hareket edilemez (`can_move` reddeder) — garnizon korunur.
- **Komşu olmayan hedef**: reddedilir.
- **Aksiyon kalmadı**: reddedilir (tur bitmeli).
- **Hedef boş nötr (army=0)**: savaş yok, barışçıl işgal.
- **Kendi bölgene hareket**: barışçıl birleşme (takviye).
- **Seçili kaynak yokken hareket denemesi**: Harita akışı bunu engeller
  (`attempt_move` seçili bölge yoksa `false` döner).
- **Bozulmuş + yabancı garnizonlu hedef**: 1. dal (savaş). Kazanılırsa oyuncu bölgeyi
  bozulmasıyla devralır (düşük üretim, `resource-system.md` F1); arındırmak için
  sonraki bir hamlede bölgeye kuvvet gönderir (2. dal, kendi bölgesi). İki katman =
  iki hamle.
- **Kendi bozuk bölgene takviye**: 2. dal — takviye bir arındırma girişimidir;
  `P ≤ S` ise gelen kuvvet kaybolur, garnizon değişmez. Bilgi paneli seviyeyi ve
  direnci gösterir (`spirit-system.md` §3.2), sonuç hamleden önce hesaplanabilir.
- **Başarısız arındırma**: aksiyon harcanır, kuvvet kaybolur, kaynakta garnizon (1) kalır.
- **Beraberlikte iki taraf da tükenirse**: bölge sahipsiz olur (§3.3, W3); bozuksa bir
  sonraki oyuncu hamlesi 2. dala (arındırma) gider.
- **Kaybedilen saldırıda hayatta kalanlar**: dağılır (§3.3, W2); kaynakta yalnızca
  garnizon (1) kalır.

---

## 6. Dependencies

- **Savaş Çözümü** (`combat-system.md`, kod: `combat_resolver.gd`) — savaş dalında
  kullanılır.
- **Harita/Tur Akışı** (`region-map-system.md`, kod: `map_controller.gd`) —
  `attempt_move`'u çağırır, aksiyon sayacını yönetir; düşman AI aynı (sahip-bağımsız,
  §3.1) taşıma kurallarını kullanır — bugün kodda satır içi kopya, C-19'da birleşir.
- **Ruh Sistemi** (`spirit-system.md`) — arındırma, varış çözümünün 2. dalıdır
  (§3.3); arındırma kuralları, `corruption_strength` ve Ruh kazanımı spirit §3.2 /
  §4.1–4.2'ye aittir. Bu sistem yalnızca dal seçimini ve kuvvetin yerleşmesini uygular.
- **Kaynak Yönetimi** (`resource-system.md`) — "Ordu Topla" üretimi `army_count`'u
  artırır; ordunun büyüyebildiği tek kaynak budur (garnizon ve hareket kuralları
  değişmez).

---

## 7. Tuning Knobs

| Knob | Mevcut | Not |
| ---- | ---- | ---- |
| Garnizon minimumu | 1 | Kaynakta kalan zorunlu kuvvet |
| Aksiyon başına hareket | 1 aksiyon | Tur başına aksiyon `actions_per_turn` |

**Genişleme (planlı)**: birim tipleri ve kompozisyon (süvari/okçu/piyade),
kahraman birimleri, hareket menzili/maliyeti — konseptte var, kodda yok. Ordu
üretimi ve bakım gideri `resource-system.md`'de tanımlıdır (F4, F7; bakım MVP'de 0).

---

## 8. Acceptance Criteria

1. `army_count == 1` olan bölgeden hareket **reddedilir**. *(Test — BLOCKING)*
2. Komşu olmayan hedefe hareket **reddedilir**. *(Test)*
3. `actions_remaining == 0` iken hareket **reddedilir**. *(Test)*
4. Geçerli harekette kaynak `army_count = 1` olur, taşınan = eski−1. *(Test)*
5. Boş nötr bölgeye hareket → bölge oyuncunun, army = taşınan. *(Test)*
6. Oyuncunun bölgesine hareket → takviye (army += taşınan). *(Test)*
7. Düşman bölgeye hareket → savaş tetiklenir ve sonuç uygulanır. *(Test)*
8. Garnizonsuz nötr, seviye 2 (S=8) bölgeye P=9 → bölge oyuncunun, army=5,
   `corruption_level=0`, Ruh +20. *(Test — BLOCKING, C-38)*
9. Aynı bölgeye P=8 → kuvvet tamamen kaybolur; bölge nötr, army 0, seviye 2 kalır;
   Ruh değişmez; `actions_remaining` 1 azalır. *(Test, C-38)*
10. Seviye 1 bozuk, 3 garnizonlu nötr bölgeye P=5 → savaş dalı; kazanılınca bölge
    oyuncunun, army=3, `corruption_level` hâlâ 1, Ruh değişmez. *(Test, C-38)*
11. Oyuncunun seviye 1 bozuk bölgesine (garnizon 2, S=4) P=5 → arındırma başarılı,
    army = 2 + (5 − 2) = 5, `corruption_level=0`. *(Test, C-38)*
12. Düşman AI bozuk bir bölgeye girdiğinde `corruption_level` değişmez ve kimse Ruh
    kazanmaz. *(Test, C-38)*
13. 1'e 1 beraberlikten sonra hedef `NEUTRAL` ve army 0 olur (sahipli 0 ordulu bölge
    kalmaz); kaybeden saldıranın hayatta kalanları hiçbir bölgeye eklenmez. *(Test, C-52)*
