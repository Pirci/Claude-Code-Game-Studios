class_name MapState
extends RefCounted
## Haritanın tüm durumunu tutar. Mantık yok, sadece veri.


var regions: Dictionary = {}  # StringName -> RegionData
var current_turn: int = 1
var actions_remaining: int = 1
var actions_per_turn: int = 1
var selected_region_id: StringName = &""
var chapter_id: int = 1


func get_region(region_id: StringName) -> RegionData:
	return regions.get(region_id) as RegionData


func get_player_regions() -> Array[RegionData]:
	var result: Array[RegionData] = []
	for region: RegionData in regions.values():
		if region.owner == RegionData.Owner.PLAYER:
			result.append(region)
	return result


func get_enemy_regions() -> Array[RegionData]:
	var result: Array[RegionData] = []
	for region: RegionData in regions.values():
		if region.owner == RegionData.Owner.ENEMY:
			result.append(region)
	return result
