class_name IncomeRules
extends RefCounted
## Ekonominin saf formülleri (resource-system.md F1–F4, F7; ADR-0010 karar 6). Ekonomi adımı,
## üretim ve HUD tahmini aynı fonksiyonları kullanır.


## Lütufların gelir stat'ı: FLAT → `B_add`, PERCENT → `M_g − 1` (ADR-0006).
const STAT_GOLD_INCOME: StringName = &"gold_income"


## F1: bölgenin etkin geliri `floor(G_base × M_c)`.
static func region_income(region: RegionData, production_multiplier: float) -> int:
	return floori(region.gold_per_turn * production_multiplier)


## F3: bölgenin bir turdaki üretim tavanı `max(R_min, G_eff)`.
static func recruit_cap(region: RegionData, production_multiplier: float, config: EconomyConfig) -> int:
	return maxi(config.recruit_min_cap, region_income(region, production_multiplier))


## F2: `max(I_floor, floor((I_raw + B_add) × M_g))`; oyuncunun bölgesi yoksa 0.
static func turn_income(raw_income: int, has_regions: bool, modifiers: Array[StatModifier], config: EconomyConfig) -> int:
	if not has_regions:
		return 0
	var b_add: float = StatResolver.flat_sum(STAT_GOLD_INCOME, modifiers)
	var m_g: float = clampf(1.0 + StatResolver.percent_sum(STAT_GOLD_INCOME, modifiers), 1.0, config.max_income_multiplier)
	return maxi(config.income_floor, floori((raw_income + b_add) * m_g))


## F7: `max(0, A_total − A_free) × U` (borç; ödenen = min(borç, altın)).
static func upkeep(total_army: int, config: EconomyConfig) -> int:
	return maxi(0, total_army - config.upkeep_free_armies) * config.upkeep_per_army
