class_name ArmyController
extends RefCounted
## Ordu hareket doğrulama ve taşıma mantığı.


func can_move(map_state: MapState, from_id: StringName, to_id: StringName) -> bool:
	var from_region: RegionData = map_state.get_region(from_id)
	if from_region == null:
		return false
	if from_region.owner != RegionData.Owner.PLAYER:
		return false
	if from_region.army_count <= 1:
		return false
	if to_id not in from_region.adjacent_regions:
		return false
	if map_state.actions_remaining <= 0:
		return false
	return true


func move_army(map_state: MapState, from_id: StringName, to_id: StringName) -> int:
	var from_region: RegionData = map_state.get_region(from_id)
	var moving: int = from_region.army_count - 1
	from_region.army_count = 1
	return moving


func apply_combat_result(
	map_state: MapState,
	target_id: StringName,
	result: CombatResolver.CombatResult,
	moving_army: int,
) -> void:
	var target: RegionData = map_state.get_region(target_id)
	if result.attacker_won:
		target.owner = RegionData.Owner.PLAYER
		target.army_count = result.attacker_remaining
	else:
		target.army_count = result.defender_remaining


func apply_peaceful_move(
	map_state: MapState,
	target_id: StringName,
	moving_army: int,
) -> void:
	var target: RegionData = map_state.get_region(target_id)
	if target.owner == RegionData.Owner.PLAYER:
		target.army_count += moving_army
	else:
		target.owner = RegionData.Owner.PLAYER
		target.army_count = moving_army
