@tool
class_name WinCondition
extends Resource
## Bir bölümün kazanma koşullarını tanımlar.


@export var required_neutral_conquests: int = 0
@export var must_defeat_all_enemies: bool = true
@export var description_key: StringName = &""


func is_met(map_state: MapState) -> bool:
	if must_defeat_all_enemies:
		if map_state.get_enemy_regions().size() > 0:
			return false

	var player_regions: Array[RegionData] = map_state.get_player_regions()
	var conquered_count: int = player_regions.size() - 1  # -1: başlangıç bölgesi
	return conquered_count >= required_neutral_conquests
