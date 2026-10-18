# Sistem GDD: Bölge Haritası ve Tur Akışı

*Oyun: ULUS: Blood of the Sky Wolf*
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
  `actions_per_turn`, `selected_region_id`, `chapter_id` (planlı:
  `last_erlik_spread_turn` — yayılım sayacı, `spirit-system.md` §3.6, C-31).
- Harita tanımı `ChapterMapDefinition` Resource'undan üretilir (`create_map_state()`).

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
Sıra: **(1)** düşman AI oynar → **(2)** Erlik yayılımı (`spirit-system.md` §3.6;
yalnızca yayılım turunda, aksi halde atlanır) → **(3)** ekonomi adımı: oyuncu
geliri + düşman takviyesi + bakım (`resource-system.md` §3.1) → **(4)**
`current_turn+=1`, `actions_remaining = actions_per_turn`, bölge üretim sayaçları
sıfırlanır → **(5)** oyun sonu kontrolü: önce kaybetme, sonra kazanma (§3.6–3.7).

> **Neden yayılım gelirden önce (C-29, 2026-10-18):** yayılan bozulmanın üretim
> cezası (`M_c`) o turun gelirine hemen yansır — oyuncu çürümenin bedelini aynı
> tur öder. Sıra ADR-0005'teki `end_turn` şemasıyla (AI → Erlik) uyumludur.
> Erlik yayılımının **sahibi `spirit-system.md`**'dir; bu sistem yalnızca sırayı tutar.

### 3.5 Düşman AI (`EnemyAIController.decide`)
Düşman AI, saf bir karar servisidir (bkz. [ADR-0005](../../docs/architecture/adr-0005-ai-architecture.md)):
`EnemyAIController.decide(map_state) -> Array[MoveIntent]` yalnızca `MapState`'i
**okur** ve deterministik bir hamle listesi (intent) döndürür — state'i değiştirmez,
sinyal yaymaz. `MapController.end_turn()` intent'leri `ArmyController`/`CombatResolver`
üzerinden **uygular** ve mevcut sinyalleri yayar.

- Her düşman bölgesi için (army > 1):
  - Komşular arasında düşman-olmayan, `army_count`'u en düşük hedefi seç.
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
- **Kaybetme**: oyuncunun hiç bölgesi kalmazsa.
- **Öncelik:** İkisi aynı anda sağlanamaz (kazanma en az bir oyuncu bölgesi ister).
  Savunmacı kural: bir kontrol noktasında önce kaybetme, sonra kazanma değerlendirilir.
- **Kontrol noktaları:** (a) her geçerli oyuncu hamlesinden sonra yalnızca kazanma
  (oyuncu kendi hamlesiyle son bölgesini kaybedemez — kaynakta garnizon kalır);
  (b) `end_turn` 5. adımında kaybetme → kazanma (gelecekte tur sonunda sahiplik
  değiştiren sistemler için; bugün tur sonu kazanma üretemez).

### 3.7 Oyun Sonu (C-32)
- Oyun sonucu state'te tutulur: `MapState.game_result` ∈ {`ONGOING`, `WON`, `LOST`}
  (ADR-0004: yalnızca veri). Başlangıç `ONGOING`.
- Sonuç `ONGOING` dışına çıktığında **bir kez** ilgili sinyal yayılır (`game_won` /
  `game_lost`) ve oyun kilitlenir: `attempt_move` `false` döner, `end_turn` hiçbir adımı
  çalıştırmaz (AI, yayılım, gelir, tur artışı yok), üretim reddedilir. Bölge seçimi
  (bilgi paneli) okuma amaçlı serbesttir.
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
yalnızca 3 nötr alınmış ve in bozuksa zafer yok.

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
- **Ordusu 0 kalan düşman bölgesi** (berabere, çapraz inceleme W3): hâlâ `ENEMY` sayılır
  ve siyasi koşulu engeller — W3 kararı C-33'te.
- **Prolog kazanma kriteri**: `required_neutral_conquests = 3` + Canavarın İni
  **arındırılmalı** (C-29: canavar siyasi düşman değil, bozulmuş nötr bölgedir —
  `spirit-system.md` §3.7). Veri/zafer koşulu güncellemesi C-32 / C-49 / C-36.

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

---

## 7. Tuning Knobs

| Knob | Kaynak | Not |
| ---- | ---- | ---- |
| `actions_per_turn` | ChapterMapDefinition | MVP: 1 |
| Bölge sayısı / layout | `.tres` (veri-güdümlü) | Prolog: 6 |
| `required_neutral_conquests` | WinCondition | Prolog: 3 |
| `must_defeat_all_enemies` | WinCondition | Prolog: true (C-29 sonrası Prolog'da düşman yok → koşul kendiliğinden sağlanır; C-49) |
| `erlik_foci` | WinCondition | Arındırılması zorunlu Erlik odakları (region_id listesi). Prolog: [Canavarın İni] (C-36) |
| Bölge `army_count` / `gold_per_turn` | `.tres` | Denge |
| `enemy_actions_per_turn` | ChapterMapDefinition / MapState | Düşmanın tur başına toplam aksiyonu (data-driven; MVP: 1) |
| `player_tamga_id` / `enemy_tamga_id` | ChapterMapDefinition → MapState | Sahiplik tamgası (`icon_tamga_<id>.png`, art bible §5/§7). Prolog: `oguz` / `erlik_beast` *(C-29: canavar artık nötr olduğundan `enemy_tamga_id` Prolog'da kullanılmaz; Erlik görseli tamga değil bozulma katmanıdır — C-36'da veri temizlenir)*. Bölgenin tamgası sahibinden türetilir → fetihte değişir; nötr tamgasız |

---

## 8. Acceptance Criteria

1. Prolog haritası 6 bölgeyle yüklenir; sahiplikler doğru (Oğuz Otağı=oyuncu,
   Canavarın İni=nötr + `corruption_level 3`, diğer 4 nötr). *(Test — veri
   güncellemesi C-36/C-49 ile gelir; o zamana dek mevcut `chapter_1_map.tres`
   eski modelde: Canavarın İni=düşman.)*
2. Seçili bölgeye tekrar tıklama seçimi kaldırır. *(Test)*
3. Geçerli hareket `actions_remaining`'i 1 azaltır. *(Test)*
4. `end_turn` sırası: AI → Erlik yayılımı → gelir → tur artışı → kontrol. *(Test)*
5. Tur geliri `resource-system.md` F2'ye eşittir (bozulma ve lütuf yokken oyuncu
   bölgelerinin `gold_per_turn` toplamı). *(Test)*
6. Düşman AI en düşük ordulu düşman-olmayan komşuya saldırır. *(Test)*
7. 3 nötr (odak hariç) ele geçirilip düşman kalmayınca ve odaklar temizken, hamleden
   hemen sonra `game_won` **bir kez** tetiklenir; ardından `end_turn` çağrılsa da AI,
   yayılım, gelir ve tur artışı çalışmaz. *(Test)*
8. Oyuncunun bölgesi kalmazsa `game_lost` tetiklenir; sonra `attempt_move` `false` döner. *(Test)*
9. Seçili bölgenin merkez ekseninde sahibinin tamgası görünür (nötrde yok); fetihten
   sonra tamga yeni sahibinkine geçer. *(Test)*
10. Başlangıç bölgesi kaybedilmiş, 3 başlangıçta-nötr bölge oyuncudaysa genişleme
    koşulu sağlanır (eski `−1` formülünün hatası yok). *(Test)*
11. Odak bölge bozukken diğer koşullar sağlansa da zafer yok; odak arındırılınca o
    hamlenin sonunda zafer. *(Test — bozulma C-38 ile gelir)*
