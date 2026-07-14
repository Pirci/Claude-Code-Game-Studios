# Sistem GDD: Bölge Haritası ve Tur Akışı

*Oyun: Steppeborn — Path of the Sky Wolf*
*Oluşturulma: 2026-07-14*
*Durum: Belgelenmiş (kod mevcut — `game/features/grid/`, `game/state/`)*
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
- **RegionData**: `region_id`, `display_name_key`, `owner` (NEUTRAL/PLAYER/ENEMY),
  `army_count`, `gold_per_turn`, `position`, `polygon_points`, `adjacent_regions`.
- **MapState**: `regions` (id→RegionData), `current_turn`, `actions_remaining`,
  `actions_per_turn`, `selected_region_id`, `chapter_id`.
- Harita tanımı `ChapterMapDefinition` Resource'undan üretilir (`create_map_state()`).

### 3.2 Bölge Seçimi (`select_region`)
- Boş alandan farklı bir bölgeye tıklama → o bölge seçilir (bilgi paneli açılır).
- Zaten seçili bölgeye tekrar tıklama → seçim kalkar (toggle).

### 3.3 Hareket (`attempt_move`)
- Seçili bölge kaynak, tıklanan bölge hedeftir.
- Ordu Sistemi doğrulaması geçerse hareket/savaş uygulanır, `actions_remaining−=1`,
  seçim temizlenir, kazanma kontrol edilir.

### 3.4 Tur Bitişi (`end_turn`)
Sıra: **(1)** düşman AI oynar → **(2)** gelir toplanır → **(3)** `current_turn+=1`,
`actions_remaining = actions_per_turn` → **(4)** kazanma/kaybetme kontrolü.

### 3.5 Düşman AI (`_run_enemy_ai`)
- Her düşman bölgesi için (army > 1):
  - Komşular arasında düşman-olmayan, `army_count`'u en düşük hedefi seç.
  - Kuvvet (army−1) gönder; hedefte ordu varsa savaş, yoksa işgal.
- MVP: düşman tur başına **1 aksiyon** (ilk uygun hamleden sonra `break`).

### 3.6 Kazanma / Kaybetme
- **Kazanma** (`WinCondition.is_met`): `must_defeat_all_enemies` ise düşman bölgesi
  kalmamalı **ve** ele geçirilen nötr sayısı `required_neutral_conquests`'e ulaşmalı.
- **Kaybetme**: oyuncunun hiç bölgesi kalmazsa.

---

## 4. Formulas

### Gelir (Kaynak Sistemi ile ortak — `resource_controller.gd`)
```
tur_geliri = Σ (oyuncu bölgeleri).gold_per_turn
game_state.gold += tur_geliri
```
Örnek (Prolog başlangıcı, sadece Oğuz Otağı, gold_per_turn=2): tur geliri = 2.

### Ele geçirilen nötr sayısı (kazanma kontrolü)
```
conquered_count = oyuncu_bölge_sayısı − 1     # −1: başlangıç bölgesi
kazandı = (düşman_bölgesi == 0) AND (conquered_count ≥ required_neutral_conquests)
```

### Düşman AI hedef seçimi
```
hedef = argmin(army_count) over { komşular : owner ≠ ENEMY }
        eşitlikte ilk bulunan
```

---

## 5. Edge Cases

- **Aynı bölgeye çift tık**: seçim toggle (aç/kapa).
- **Aksiyon bitti**: hareket reddedilir; oyuncu tur bitirmeli.
- **Düşman hareket edecek hedef yok** (tüm komşular düşman veya army≤1): o düşman
  atlanır.
- **Kazanma tur ortasında** (`attempt_move` sonrası): anında `game_won` sinyali.
- **Kazanma/kaybetme tur sonunda**: `end_turn` sonunda kontrol.
- **Prolog kazanma kriteri**: `required_neutral_conquests = 3` + düşman (Canavarın
  İni) yenilmeli (`chapter_1_map.tres`).

---

## 6. Dependencies

- **Ordu Sistemi** (`army-system.md`, kod: `army_controller.gd`).
- **Savaş Çözümü** (`combat-system.md`, kod: `combat_resolver.gd`).
- **Kaynak Yönetimi** (`resource-system.md`, kod: `resource_controller.gd`) —
  tur geliri.
- **Oyun Durumu** (`game_state.gd`) — `map_state`, `gold`, (planlı: `ruh`, `boons`).
- **Ruh Sistemi** (`spirit-system.md`) — `RegionData`'ya `corruption_level`
  eklenecek; Erlik yayılımı tur akışına girecek.
- **Kök Böri / Kozmik katman**: düşman AI'nin yanına Erlik yayılım AI'si eklenecek.

---

## 7. Tuning Knobs

| Knob | Kaynak | Not |
| ---- | ---- | ---- |
| `actions_per_turn` | ChapterMapDefinition | MVP: 1 |
| Bölge sayısı / layout | `.tres` (veri-güdümlü) | Prolog: 6 |
| `required_neutral_conquests` | WinCondition | Prolog: 3 |
| `must_defeat_all_enemies` | WinCondition | Prolog: true |
| Bölge `army_count` / `gold_per_turn` | `.tres` | Denge |
| Düşman AI aksiyon/tur | kod sabiti | MVP: 1 (`break`) — **teknik borç: data-driven olmalı** |

---

## 8. Acceptance Criteria

1. Prolog haritası 6 bölgeyle yüklenir; sahiplikler doğru (Oğuz Otağı=oyuncu,
   Canavarın İni=düşman, 4 nötr). *(Test)*
2. Seçili bölgeye tekrar tıklama seçimi kaldırır. *(Test)*
3. Geçerli hareket `actions_remaining`'i 1 azaltır. *(Test)*
4. `end_turn` sırası: AI → gelir → tur artışı → kontrol. *(Test)*
5. Tur geliri = oyuncu bölgelerinin `gold_per_turn` toplamı. *(Test)*
6. Düşman AI en düşük ordulu düşman-olmayan komşuya saldırır. *(Test)*
7. 3 nötr ele geçirilip düşman yenilince `game_won` tetiklenir. *(Test)*
8. Oyuncunun bölgesi kalmazsa `game_lost` tetiklenir. *(Test)*
