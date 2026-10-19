class_name ResourceController
extends RefCounted
## Tur başı kaynak toplama mantığı (resource-system.md §3.1). Bölge geliri F1 —
## bozulma çarpanı `M_c` [SpiritRules]'tan (spirit §4.3); F2 lütuf terimleri C-37.


var _spirit_rules: SpiritRules = SpiritRules.new()


func bind_services(spirit_rules: SpiritRules) -> void:
	if spirit_rules != null:
		_spirit_rules = spirit_rules


func collect_turn_income(map_state: MapState, game_state: GameState) -> int:
	var total_income: int = forecast_income(map_state)
	game_state.gold += total_income
	return total_income


## Bu turun geliri — ekonomi adımı ile aynı hesap (HUD tahmini, ADR-0010 karar 6).
func forecast_income(map_state: MapState) -> int:
	var total: int = 0
	for region: RegionData in map_state.get_player_regions():
		total += IncomeRules.region_income(region, _spirit_rules.production_multiplier(region.corruption_level))
	return total
