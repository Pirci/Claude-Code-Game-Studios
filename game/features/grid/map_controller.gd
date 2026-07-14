class_name MapController
extends RefCounted
## Harita tur akışını yönetir. State'i mutasyona uğratır, sinyaller ile UI'a bildirir.


signal region_selected(region_id: StringName)
signal region_deselected
signal army_moved(from_id: StringName, to_id: StringName, army_count: int)
signal combat_occurred(from_id: StringName, to_id: StringName, result: CombatResolver.CombatResult)
signal turn_ended(new_turn: int)
signal income_collected(amount: int)
signal game_won
signal game_lost

var _map_state: MapState
var _game_state: GameState
var _army_controller: ArmyController
var _resource_controller: ResourceController
var _combat_resolver: CombatResolver
var _win_condition: WinCondition


func bind_services(
	map_state: MapState,
	game_state: GameState,
	army_controller: ArmyController,
	resource_controller: ResourceController,
	combat_resolver: CombatResolver,
	win_condition: WinCondition,
) -> void:
	_map_state = map_state
	_game_state = game_state
	_army_controller = army_controller
	_resource_controller = resource_controller
	_combat_resolver = combat_resolver
	_win_condition = win_condition


func select_region(region_id: StringName) -> void:
	if _map_state.selected_region_id == region_id:
		_map_state.selected_region_id = &""
		region_deselected.emit()
		return
	_map_state.selected_region_id = region_id
	region_selected.emit(region_id)


func attempt_move(target_id: StringName) -> bool:
	var from_id: StringName = _map_state.selected_region_id
	if from_id == &"":
		return false
	if not _army_controller.can_move(_map_state, from_id, target_id):
		return false

	var moving: int = _army_controller.move_army(_map_state, from_id, target_id)
	var target: RegionData = _map_state.get_region(target_id)

	if target.owner != RegionData.Owner.PLAYER and target.army_count > 0:
		var result: CombatResolver.CombatResult = _combat_resolver.resolve(moving, target.army_count)
		_army_controller.apply_combat_result(_map_state, target_id, result, moving)
		combat_occurred.emit(from_id, target_id, result)
	else:
		_army_controller.apply_peaceful_move(_map_state, target_id, moving)
		army_moved.emit(from_id, target_id, moving)

	_map_state.actions_remaining -= 1
	_map_state.selected_region_id = &""
	region_deselected.emit()

	if _win_condition.is_met(_map_state):
		game_won.emit()

	return true


func end_turn() -> void:
	_run_enemy_ai()

	var income: int = _resource_controller.collect_turn_income(_map_state, _game_state)
	income_collected.emit(income)

	_map_state.current_turn += 1
	_map_state.actions_remaining = _map_state.actions_per_turn
	turn_ended.emit(_map_state.current_turn)

	if _win_condition.is_met(_map_state):
		game_won.emit()
	elif _map_state.get_player_regions().size() == 0:
		game_lost.emit()


func _run_enemy_ai() -> void:
	var enemy_regions: Array[RegionData] = _map_state.get_enemy_regions()
	for region: RegionData in enemy_regions:
		if region.army_count <= 1:
			continue
		var best_target: RegionData = null
		for adj_id: StringName in region.adjacent_regions:
			var adj: RegionData = _map_state.get_region(adj_id)
			if adj == null or adj.owner == RegionData.Owner.ENEMY:
				continue
			if best_target == null or adj.army_count < best_target.army_count:
				best_target = adj
		if best_target == null:
			continue
		var moving: int = region.army_count - 1
		region.army_count = 1
		if best_target.army_count > 0:
			var result: CombatResolver.CombatResult = _combat_resolver.resolve(moving, best_target.army_count)
			if result.attacker_won:
				best_target.owner = RegionData.Owner.ENEMY
				best_target.army_count = result.attacker_remaining
			else:
				best_target.army_count = result.defender_remaining
			combat_occurred.emit(region.region_id, best_target.region_id, result)
		else:
			best_target.owner = RegionData.Owner.ENEMY
			best_target.army_count = moving
			army_moved.emit(region.region_id, best_target.region_id, moving)
		break  # MVP: düşman tur başına 1 aksiyon
