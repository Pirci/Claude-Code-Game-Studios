class_name ResourceController
extends RefCounted
## Tur başı kaynak toplama mantığı.


func collect_turn_income(map_state: MapState, game_state: GameState) -> int:
	var total_income: int = 0
	for region: RegionData in map_state.get_player_regions():
		total_income += region.gold_per_turn
	game_state.gold += total_income
	return total_income
