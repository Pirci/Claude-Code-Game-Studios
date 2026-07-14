# Sistem GDD: Ordu ve Hareket Sistemi

*Oyun: Steppeborn — Path of the Sky Wolf*
*Oluşturulma: 2026-07-14*
*Durum: Belgelenmiş (kod mevcut — `game/features/army/army_controller.gd`)*
*Katman: Core*

> Mevcut kodu belgeler. MVP'de ordu tek bir soyut sayıdır (`army_count`) — birim
> tipleri (süvari/okçu/piyade) ve kahramanlar henüz kodda yok (§7).

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
Hareket geçerlidir ancak ve ancak:
- Kaynak bölge oyuncuya ait (`owner == PLAYER`), **ve**
- Kaynak ordu > 1 (en az 1 garnizon kalmalı), **ve**
- Hedef, kaynağın `adjacent_regions` listesinde, **ve**
- `map_state.actions_remaining > 0`.

### 3.2 Ordu Taşıma (`move_army`)
- Taşınan kuvvet = `army_count − 1`.
- Kaynak bölge `army_count = 1` olur (garnizon).

### 3.3 Varış Çözümü
- **Barışçıl** (hedef oyuncunun VEYA `army_count == 0`):
  - Hedef zaten oyuncunun → `army_count += moving`.
  - Hedef değilse → `owner = PLAYER`, `army_count = moving`.
- **Savaş** (hedef oyuncunun değil ve `army_count > 0`):
  - `CombatResolver.resolve(moving, hedef.army_count)` çağrılır.
  - Kazanılırsa → hedef `owner = PLAYER`, `army_count = attacker_remaining`.
  - Kaybedilirse → hedef sahibi kalır, `army_count = defender_remaining`.

### 3.4 Aksiyon Tüketimi
- Her başarılı hareket `actions_remaining` değerini 1 azaltır (Harita/Tur
  Akışı'nda, bkz. `region-map-system.md`).

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

**Örnek**: Kaynak army=5 → moving=4, kaynak=1. Hedef boş nötr → hedef oyuncunun,
army=4. Hedefte 3 düşman varsa → savaş (4 vs 3), saldıran kazanır, hedef army=3
(bkz. combat-system Örnek 1).

---

## 5. Edge Cases

- **army_count == 1**: hareket edilemez (`can_move` reddeder) — garnizon korunur.
- **Komşu olmayan hedef**: reddedilir.
- **Aksiyon kalmadı**: reddedilir (tur bitmeli).
- **Hedef boş nötr (army=0)**: savaş yok, barışçıl işgal.
- **Kendi bölgene hareket**: barışçıl birleşme (takviye).
- **Seçili kaynak yokken hareket denemesi**: Harita akışı bunu engeller
  (`attempt_move` seçili bölge yoksa `false` döner).

---

## 6. Dependencies

- **Savaş Çözümü** (`combat-system.md`, kod: `combat_resolver.gd`) — savaş dalında
  kullanılır.
- **Harita/Tur Akışı** (`region-map-system.md`, kod: `map_controller.gd`) —
  `attempt_move`'u çağırır, aksiyon sayacını yönetir, düşman AI aynı taşıma
  kurallarını kullanır.
- **Ruh Sistemi** (`spirit-system.md`) — arındırma da ordu gönderimi kullanır.

---

## 7. Tuning Knobs

| Knob | Mevcut | Not |
| ---- | ---- | ---- |
| Garnizon minimumu | 1 | Kaynakta kalan zorunlu kuvvet |
| Aksiyon başına hareket | 1 aksiyon | Tur başına aksiyon `actions_per_turn` |

**Genişleme (planlı)**: birim tipleri ve kompozisyon (süvari/okçu/piyade),
kahraman birimleri, hareket menzili/maliyeti, ordu bakım maliyeti — konseptte
var, kodda yok.

---

## 8. Acceptance Criteria

1. `army_count == 1` olan bölgeden hareket **reddedilir**. *(Test — BLOCKING)*
2. Komşu olmayan hedefe hareket **reddedilir**. *(Test)*
3. `actions_remaining == 0` iken hareket **reddedilir**. *(Test)*
4. Geçerli harekette kaynak `army_count = 1` olur, taşınan = eski−1. *(Test)*
5. Boş nötr bölgeye hareket → bölge oyuncunun, army = taşınan. *(Test)*
6. Oyuncunun bölgesine hareket → takviye (army += taşınan). *(Test)*
7. Düşman bölgeye hareket → savaş tetiklenir ve sonuç uygulanır. *(Test)*
