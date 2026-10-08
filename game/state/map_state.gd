class_name MapState
extends RefCounted
## Haritanın tüm durumunu tutar. Mantık yok, sadece veri.


var regions: Dictionary = {}  # StringName -> RegionData
var current_turn: int = 1
var actions_remaining: int = 1
var actions_per_turn: int = 1
var enemy_actions_per_turn: int = 1
var selected_region_id: StringName = &""
var chapter_id: int = 1
## Sahip → tamga (art bible §5/§7). Fetihte bölgenin tamgası yeni sahibinkine geçer.
var player_tamga_id: StringName = &""
var enemy_tamga_id: StringName = &""


func get_region(region_id: StringName) -> RegionData:
	return regions.get(region_id) as RegionData


## [param owner] sahibinin tamga id'si; nötr bölgeler tamgasızdır (boş).
func get_owner_tamga_id(owner: RegionData.Owner) -> StringName:
	match owner:
		RegionData.Owner.PLAYER:
			return player_tamga_id
		RegionData.Owner.ENEMY:
			return enemy_tamga_id
		_:
			return &""


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
