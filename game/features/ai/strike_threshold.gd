class_name StrikeThreshold
extends RefCounted
## Kağan vuruş eşiği (enemy-layers F-E1; hud §5.3 D3): oyuncu bölgesinin etkin savunması `P_eff` iken
## düşmanın vurabilmesi için gereken en küçük gönderilen kuvvet `A`. AI kararı ([EnemyAIController])
## ve HUD satırı aynı fonksiyonu kullanır — kural tekrarı yok (ADR-0011).


## `N = max(P_eff + 1, ceil(num · P_eff / den))`, tam sayı; `P_eff = 0` → 1. `A ≥ N` ⇔ `A > P_eff` ve
## `den · A ≥ num · P_eff`.
static func min_force(p_eff: int, ratio_num: int, ratio_den: int) -> int:
	var ratio_floor: int = (ratio_num * p_eff + ratio_den - 1) / ratio_den
	return maxi(p_eff + 1, ratio_floor)
