# Sistem GDD: Savaş Çözümü (Otomatik)

*Oyun: ULUS: Blood of the Sky Wolf*
*Oluşturulma: 2026-07-14*
*Durum: Belgelenmiş (kod mevcut — `game/features/combat/combat_resolver.gd`) + planlı: "Etkin güç" (M2)*
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

- Savaş iki girdiyle çözülür: `attacker_army`, `defender_army` (planlı üçüncü girdi:
  oyuncunun lütuf modifikatörleri → §4 "Etkin güç", M2).
- Üç sonuç dalı vardır: saldıran üstün, savunan üstün, eşitlik.
- Kazanan taraf bölgeyi elde tutar/alır. Kaybeden tarafın hayatta kalanları
  (yalnızca beraberlikte > 0 olabilir) haritada kalmaz — **dağılır**; rapor bunları
  gösterir (C-33, W2). Uygulamayı Ordu Sistemi yapar (`army-system.md` §3.3).
- Kalan ordu asla negatif olamaz (`max(0, …)`).
- Eşitlikte varsayılan olarak **savunan kazanır** (savunma avantajı,
  `draw_favors_defender = true`) ve iki taraf da ağır kayıp verir.
- Savaştan sonra bölgede 0 birlik kalırsa bölge sahipsiz olur (`army-system.md` §3.3,
  W3) — bu sistem yalnızca sayıları üretir.

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
attacker_won   = NOT draw_favors_defender   # varsayılan true → false (savunma avantajı)
attacker_losses = ceil(A × 0.7)
defender_losses = ceil(D × 0.5)
```
`draw_favors_defender = false` yapılırsa beraberlikte saldıran kazanır ve
`attacker_remaining` ile bölgeyi alır; 0 kalırsa bölge sahipsiz olur (W3). Kayıp
oranları knob'dan bağımsızdır (C-33, W4).

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

### Etkin güç (lütuf modifikatörleri) — *planlı, M2 (C-31 kararı)*
Kurt Gücü / Demir Post lütufları (`spirit-system.md` §3.5) **etkin gücü** değiştirir;
birlik sayısı değişmez. Modifikatörler yalnızca **oyuncunun** tarafına uygulanır
(ADR-0006 `StatResolver`, yuvarlama `ceil`):
```
A_eff = ceil(resolve(&"army_attack",  A))   # saldıran oyuncuysa; değilse A_eff = A
D_eff = ceil(resolve(&"army_defense", D))   # savunan oyuncuysa; değilse D_eff = D
Dal seçimi A_eff ile D_eff karşılaştırılarak yapılır.
Dal 1 (A_eff > D_eff): attacker_losses = ceil(D_eff × awr),  defender_losses = D
Dal 2 (D_eff > A_eff): attacker_losses = A,                  defender_losses = ceil(A_eff × dwr)
Dal 3 (A_eff = D_eff): attacker_losses = ceil(D_eff × dar),  defender_losses = ceil(A_eff × ddr)
kalan = max(0, kendi_birlik − kayıp)
```
`awr/dwr/dar/ddr` = §7'deki oranlar. Kural: bir tarafın kaybını **karşı tarafın etkin
gücü** belirler. Modifikatör yokken (`A_eff = A`, `D_eff = D`) formüller yukarıdaki
Dal 1–3 ile birebir aynıdır (Dal 3'te `A = D` olduğundan `ceil(D × 0.7) = ceil(A × 0.7)`).
Arındırmada `D = corruption_strength`'tir ve savunma modifikatörü almaz.
**Örnek** (Kurt Gücü 1 yığın, A=4, D=4): `A_eff = 5 > 4` → Dal 1, attacker_losses =
ceil(4 × 0.5) = 2, attacker_remaining = 2, defender_remaining = 0 — lütufsuz aynı savaş
berabere (savunan kazanır) olurdu.

---

## 5. Edge Cases

- **Sıfır savunan** (`D = 0`): savaş çözülmez — bu durum "barışçıl hareket"
  olarak Ordu Sistemi'nde ele alınır (bkz. `army-system.md` §3), CombatResolver
  çağrılmaz.
- **A = 0**: geçersiz — hareket doğrulaması (`can_move`) ordu > 1 şartıyla bunu önler.
- **Yuvarlama**: tüm kayıplar `ceil` ile hesaplanır → en az 1 kayıp garantisi
  (D≥1 veya A≥1 iken). Küçük ordularda bile kayıpsız zafer olmaz.
- **Kalan negatif**: `max(0, …)` ile engellenir.
- **Arındırma çağrısı** (`spirit-system.md` §3.2, C-30): resolver `A = P_eff` (gelen
  kuvvetin etkin gücü; M1'de `P`), `D = corruption_strength` ile çağrılır. Başarı
  **yalnızca** `A > D` (Dal 1) ile tanımlıdır; eşitlik her zaman başarısızlıktır —
  `draw_favors_defender` arındırmaya uygulanmaz (C-53). Başarıda kalan
  `attacker_remaining`'dir (kayıp Dal 1: `ceil(D × attacker_win_loss_ratio)`);
  başarısızlıkta gelen kuvvet **tamamen** kaybolur (Dal 3'ün kalanı kullanılmaz) ve
  `defender_remaining` yok sayılır — bozulma kısmen azalmaz.
- **Fetih ve bozulma**: savaş sonucu yalnızca sahipliği ve orduyu değiştirir;
  hedefin `corruption_level`'ı korunur (çapraz inceleme B5, `army-system.md` §3.3).

---

## 6. Dependencies

- **Ordu Sistemi** (`army-system.md`, kod: `army_controller.gd`) — sonucu bölgeye
  uygular (`apply_combat_result`).
- **Harita/Tur Akışı** (`region-map-system.md`, kod: `map_controller.gd`) —
  `attempt_move` ve düşman AI savaşları tetikler.
- **Ruh Sistemi** (`spirit-system.md`) — Kurt Gücü / Demir Post lütufları etkin gücü
  değiştirir (§4 "Etkin güç", ADR-0006); arındırma çözümü bu resolver'ı yeniden
  kullanır (`resolve(P, corruption_strength)`, §5); başarı/başarısızlığın sonucunu
  Ruh ve Ordu sistemleri uygular (`spirit-system.md` §3.2, `army-system.md` §3.3).

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

> Not: Kaybeden tarafın hayatta kalanları dağılır — haritaya geri dönmez (kural,
> tunable değil; W2). Kayıp formülleri değişmez; rapordaki `*_remaining` kaybeden için
> "dağılan" sayısıdır.

**Genişleme (planlı)**: kompozisyon bonusu (süvari>okçu>piyade), arazi etkisi,
taktik seçimi (Hücum/Savunma/Geri Çekilme), kahraman birim modifikatörü —
GDD konseptte var ama kodda henüz yok.

---

## 8. Acceptance Criteria

1. A=5, D=3 → saldıran kazanır; attacker_remaining=3, defender_remaining=0. *(Test — BLOCKING)*
2. A=3, D=6 → savunan kazanır; attacker_remaining=0, defender_remaining=5. *(Test)*
3. A=4, D=4 → savunan kazanır; attacker_remaining=1 (dağılır), defender_remaining=2. *(Test)*
4. Hiçbir `*_remaining` değeri negatif olamaz. *(Test)*
5. Tüm kayıplar `ceil` ile hesaplanır (kayıpsız zafer yok, taraf ≥1 iken). *(Test)*
6. Çözüm deterministiktir — aynı girdi her zaman aynı sonuç. *(Test)*
7. Modifikatör yokken etkin güç yolu AC1–3 sonuçlarını değiştirmez. *(Test — M2)*
8. Kurt Gücü 1 yığınla A=4, D=4 → saldıran kazanır; attacker_remaining=2,
   defender_remaining=0. Demir Post 1 yığınla oyuncu savunurken A=4, D=4 →
   `D_eff = 5`, savunan kazanır; defender_losses = ceil(4 × 0.3) = 2. *(Test — M2)*
9. `draw_favors_defender = false` iken A=4, D=4 → `attacker_won = true`,
   attacker_remaining=1; A=D=1 → iki taraf 0 (bölgeyi sahipsiz yapma kararı Ordu
   Sistemi'nde, `army-system.md` AC13). *(Test)*
