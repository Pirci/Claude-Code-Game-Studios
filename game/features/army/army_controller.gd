class_name ArmyController
extends RefCounted
## Ordu hareket doğrulama ve taşıma mantığı.
## Kurallar hamle yapan taraf ([param mover]) için aynıdır (army-system.md §3.1, ADR-0005).


## Hareket geçerli mi? Oyuncu hamlesinde aksiyon bütçesi de kontrol edilir; düşmanın
## bütçesini [MapController] tur sonu döngüsünde yönetir.
func can_move(
	map_state: MapState,
	from_id: StringName,
	to_id: StringName,
	mover: RegionData.Owner = RegionData.Owner.PLAYER,
) -> bool:
	var from_region: RegionData = map_state.get_region(from_id)
	if from_region == null:
		return false
	if from_region.owner != mover:
		return false
	if from_region.army_count <= 1:
		return false
	if to_id not in from_region.adjacent_regions:
		return false
	if mover == RegionData.Owner.PLAYER and map_state.actions_remaining <= 0:
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
	mover: RegionData.Owner = RegionData.Owner.PLAYER,
) -> void:
	var target: RegionData = map_state.get_region(target_id)
	if result.attacker_won:
		target.owner = mover
		target.army_count = result.attacker_remaining
	else:
		target.army_count = result.defender_remaining


func apply_peaceful_move(
	map_state: MapState,
	target_id: StringName,
	moving_army: int,
	mover: RegionData.Owner = RegionData.Owner.PLAYER,
) -> void:
	var target: RegionData = map_state.get_region(target_id)
	if target.owner == mover:
		target.army_count += moving_army
	else:
		target.owner = mover
		target.army_count = moving_army
