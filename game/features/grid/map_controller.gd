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
var _enemy_ai: EnemyAIController


func bind_services(
	map_state: MapState,
	game_state: GameState,
	army_controller: ArmyController,
	resource_controller: ResourceController,
	combat_resolver: CombatResolver,
	win_condition: WinCondition,
	enemy_ai: EnemyAIController,
) -> void:
	_map_state = map_state
	_game_state = game_state
	_army_controller = army_controller
	_resource_controller = resource_controller
	_combat_resolver = combat_resolver
	_win_condition = win_condition
	_enemy_ai = enemy_ai


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


## Düşman aksiyonları: karar → uygula döngüsü (ADR-0005). [EnemyAIController] yalnızca
## karar verir; mutasyon ve sinyaller burada, oyuncuyla aynı [ArmyController] kurallarıyla.
func _run_enemy_ai() -> void:
	var acted: Array[StringName] = []
	for _i: int in _map_state.enemy_actions_per_turn:
		var intent: EnemyAIController.MoveIntent = _enemy_ai.decide(_map_state, acted)
		if intent == null:
			return
		_apply_enemy_move(intent)
		# Bu tur ele geçirilen bölge de aynı tur tekrar hareket etmez.
		acted.append(intent.from_id)
		acted.append(intent.to_id)


func _apply_enemy_move(intent: EnemyAIController.MoveIntent) -> void:
	var enemy: RegionData.Owner = RegionData.Owner.ENEMY
	if not _army_controller.can_move(_map_state, intent.from_id, intent.to_id, enemy):
		push_warning("EnemyAIController geçersiz hamle önerdi: %s → %s" % [intent.from_id, intent.to_id])
		return
	var moving: int = _army_controller.move_army(_map_state, intent.from_id, intent.to_id)
	var target: RegionData = _map_state.get_region(intent.to_id)
	if target.army_count > 0:
		var result: CombatResolver.CombatResult = _combat_resolver.resolve(moving, target.army_count)
		_army_controller.apply_combat_result(_map_state, intent.to_id, result, moving, enemy)
		combat_occurred.emit(intent.from_id, intent.to_id, result)
	else:
		_army_controller.apply_peaceful_move(_map_state, intent.to_id, moving, enemy)
		army_moved.emit(intent.from_id, intent.to_id, moving)
