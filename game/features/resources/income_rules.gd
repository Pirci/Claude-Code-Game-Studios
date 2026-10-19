class_name IncomeRules
extends RefCounted
## Gelirin saf formülleri (resource-system.md F1; ADR-0010 karar 6). Ekonomi adımı ve
## HUD tahmini aynı fonksiyonu kullanır. F2'nin lütuf terimleri (B_add, M_g) C-37 ile.


## F1: bölgenin etkin geliri `floor(G_base × M_c)`.
static func region_income(region: RegionData, production_multiplier: float) -> int:
	return floori(region.gold_per_turn * production_multiplier)
