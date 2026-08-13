# Sistem GDD: Savaş Çözümü (Otomatik)

*Oyun: Steppeborn — Path of the Sky Wolf*
*Oluşturulma: 2026-07-14*
*Durum: Belgelenmiş (kod mevcut — `game/features/combat/combat_resolver.gd`)*
*Katman: Core*

> Bu doküman mevcut kodu belgeler (reverse-document). MVP savaş çözümü kompozisyon
> ve arazi olmadan yalnızca ordu sayısına dayanır; genişleme notları §7'de.

---

## 1. Overview

İki ordu karşılaştığında sonuç otomatik hesaplanır — gerçek zamanlı savaş yok.
Saldıran ve savunan ordu sayıları karşılaştırılır; kazanan, kaybeden ve kayıplar
deterministik formüllerle belirlenir. Sonuç bir `CombatResult` nesnesinde döner
ve UI'a ayrıntılı rapor için sunulur.

---

## 2. Player Fantasy

Oyuncu, hamlesinin ağırlığını hisseder: bir ordu göndermek geri alınamaz ve
sayısal üstünlük önemlidir ama ucuz değildir — kazansan bile kayıp verirsin.
"Yeterince güçlü müyüm?" hesabı her saldırının kalbindedir.

---

## 3. Detailed Rules

- Savaş üç girdiyle çözülür: `attacker_army`, `defender_army`.
- Üç sonuç dalı vardır: saldıran üstün, savunan üstün, eşitlik.
- Kazanan taraf bölgeyi elde tutar/alır; kaybeden ordusunu (büyük oranda) yitirir.
- Kalan ordu asla negatif olamaz (`max(0, …)`).
- Eşitlikte **savunan kazanır** (savunma avantajı) ve iki taraf da ağır kayıp verir.

---

## 4. Formulas

Değişkenler: `A` = attacker_army, `D` = defender_army. `ceil` = yukarı yuvarlama.

### Dal 1 — Saldıran üstün (`A > D`)
```
attacker_won   = true
attacker_losses = ceil(D × 0.5)
defender_losses = D
```

### Dal 2 — Savunan üstün (`D > A`)
```
attacker_won   = false
attacker_losses = A
defender_losses = ceil(A × 0.3)
```

### Dal 3 — Eşitlik (`A == D`)
```
attacker_won   = false            # savunma avantajı
attacker_losses = ceil(A × 0.7)
defender_losses = ceil(D × 0.5)
```

### Kalan ordu (her dal)
```
attacker_remaining = max(0, A − attacker_losses)
defender_remaining = max(0, D − defender_losses)
```

**Örnek 1** (A=5, D=3): saldıran üstün → attacker_losses=ceil(1.5)=2,
defender_losses=3, attacker_remaining=3, defender_remaining=0.
**Örnek 2** (A=3, D=6): savunan üstün → attacker_losses=3, defender_losses=ceil(0.9)=1,
attacker_remaining=0, defender_remaining=5.
**Örnek 3** (A=4, D=4): eşitlik → attacker_losses=ceil(2.8)=3, defender_losses=2,
attacker_remaining=1, defender_remaining=2, savunan kazanır.

---

## 5. Edge Cases

- **Sıfır savunan** (`D = 0`): savaş çözülmez — bu durum "barışçıl hareket"
  olarak Ordu Sistemi'nde ele alınır (bkz. `army-system.md` §3), CombatResolver
  çağrılmaz.
- **A = 0**: geçersiz — hareket doğrulaması (`can_move`) ordu > 1 şartıyla bunu önler.
- **Yuvarlama**: tüm kayıplar `ceil` ile hesaplanır → en az 1 kayıp garantisi
  (D≥1 veya A≥1 iken). Küçük ordularda bile kayıpsız zafer olmaz.
- **Kalan negatif**: `max(0, …)` ile engellenir.

---

## 6. Dependencies

- **Ordu Sistemi** (`army-system.md`, kod: `army_controller.gd`) — sonucu bölgeye
  uygular (`apply_combat_result`).
- **Harita/Tur Akışı** (`region-map-system.md`, kod: `map_controller.gd`) —
  `attempt_move` ve düşman AI savaşları tetikler.
- **Ruh Sistemi** (`spirit-system.md`) — arındırma çözümü bu resolver'ı yeniden
  kullanacak (ordu vs. corruption_strength).

---

## 7. Tuning Knobs

Değerler **data-driven**: `CombatConfig` resource'undan gelir
(`game/features/combat/combat_config.gd`, örnek: `data/combat_config.tres`).
`CombatResolver.bind_config()` ile enjekte edilir; config verilmezse `@export`
varsayılanları kullanılır (test kolaylığı).

| Knob (CombatConfig alanı) | Varsayılan | Etki |
| ---- | ---- | ---- |
| `attacker_win_loss_ratio` | 0.5 | Saldıran kazanınca zafer maliyeti |
| `defender_win_loss_ratio` | 0.3 | Savunan kazanınca dayanıklılığı |
| `draw_attacker_loss_ratio` | 0.7 | Eşitlikte saldıran kaybı |
| `draw_defender_loss_ratio` | 0.5 | Eşitlikte savunan kaybı |
| `draw_favors_defender` | true | Eşitlik kazananı (savunma avantajı) |

> Not: Kaybeden taraf her zaman tamamen yok olur (bu bir kural, tunable değil).

**Genişleme (planlı)**: kompozisyon bonusu (süvari>okçu>piyade), arazi etkisi,
taktik seçimi (Hücum/Savunma/Geri Çekilme), kahraman birim modifikatörü —
GDD konseptte var ama kodda henüz yok.

---

## 8. Acceptance Criteria

1. A=5, D=3 → saldıran kazanır; attacker_remaining=3, defender_remaining=0. *(Test — BLOCKING)*
2. A=3, D=6 → savunan kazanır; attacker_remaining=0, defender_remaining=5. *(Test)*
3. A=4, D=4 → savunan kazanır; attacker_remaining=1, defender_remaining=2. *(Test)*
4. Hiçbir `*_remaining` değeri negatif olamaz. *(Test)*
5. Tüm kayıplar `ceil` ile hesaplanır (kayıpsız zafer yok, taraf ≥1 iken). *(Test)*
6. Çözüm deterministiktir — aynı girdi her zaman aynı sonuç. *(Test)*
