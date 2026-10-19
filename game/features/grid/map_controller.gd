class_name MapController
extends RefCounted
## Harita tur akışını yönetir. State'i mutasyona uğratır, sinyaller ile UI'a bildirir.


signal region_selected(region_id: StringName)
signal region_deselected
signal army_moved(from_id: StringName, to_id: StringName, army_count: int)
signal combat_occurred(from_id: StringName, to_id: StringName, result: CombatResolver.CombatResult)
## Arındırma hamlesi (başarılı ya da değil) uygulandı — rapor/HUD sonucu buradan okur.
signal purification_resolved(outcome: MoveOutcome)
## Tur sonu Erlik yayılımı bir bölgeyi bir seviye derinleştirdi.
signal corruption_spread(region_id: StringName)
signal turn_ended(new_turn: int)
signal income_collected(amount: int)
signal game_won
signal game_lost

var _map_state: MapState
var _game_state: GameState
var _army_controller: ArmyController
var _resource_controller: ResourceController
var _win_condition: WinCondition
var _enemy_ai: EnemyAIController
var _move_resolver: MoveResolver
var _spirit: SpiritController
var _erlik_spread: ErlikSpreadController
var _modifier_controller: ModifierController = null


## [param move_resolver] verilmezse [param combat_resolver] ile kurulan bir tane kullanılır
## (aynı savaş ayarı; testler ve eski çağrılar için).
func bind_services(
	map_state: MapState,
	game_state: GameState,
	army_controller: ArmyController,
	resource_controller: ResourceController,
	combat_resolver: CombatResolver,
	win_condition: WinCondition,
	enemy_ai: EnemyAIController,
	move_resolver: MoveResolver = null,
) -> void:
	_map_state = map_state
	_game_state = game_state
	_army_controller = army_controller
	_resource_controller = resource_controller
	_win_condition = win_condition
	_enemy_ai = enemy_ai
	_move_resolver = move_resolver
	if _move_resolver == null:
		_move_resolver = MoveResolver.new()
		_move_resolver.bind_services(combat_resolver)
	_spirit = SpiritController.new()
	_spirit.bind_services(game_state)
	_erlik_spread = ErlikSpreadController.new()


## Erlik katmanı servisleri (ADR-0005/0006, registry `spirit_state`). Çağrılmazsa varsayılan
## kurallarla kurulanlar ve lütufsuz (boş) değiştirici listesi kullanılır.
func bind_erlik_layer(
	spirit: SpiritController,
	erlik_spread: ErlikSpreadController,
	modifier_controller: ModifierController = null,
) -> void:
	if spirit != null:
		_spirit = spirit
	if erlik_spread != null:
		_erlik_spread = erlik_spread
	_modifier_controller = modifier_controller


func select_region(region_id: StringName) -> void:
	if _map_state.selected_region_id == region_id:
		_map_state.selected_region_id = &""
		region_deselected.emit()
		return
	_map_state.selected_region_id = region_id
	region_selected.emit(region_id)


## Seçili bölgeden [param target_id]'ye hamlenin sonucu — durumu değiştirmez (ADR-0010).
## Aynı durumda [method attempt_move]'un uygulayacağı sonuçla alan alan aynıdır.
func preview_move(target_id: StringName) -> MoveOutcome:
	return _move_resolver.resolve(_map_state, _map_state.selected_region_id, target_id,
		RegionData.Owner.PLAYER, _modifiers())


## Oyun bitince (`game_result` ONGOING değil) hamle reddedilir (region-map §3.7).
## Hamlenin bütün sonuçları (sahiplik, ordu, aksiyon, seçim) işlendikten sonra sinyaller
## yayılır; zafer kontrolü en sonda (S1-a).
func attempt_move(target_id: StringName) -> bool:
	if _map_state.game_result != MapState.GameResult.ONGOING:
		return false
	var from_id: StringName = _map_state.selected_region_id
	if from_id == &"":
		return false
	var outcome: MoveOutcome = _move_resolver.resolve(_map_state, from_id, target_id,
		RegionData.Owner.PLAYER, _modifiers())
	if not outcome.is_valid():
		return false
	_army_controller.apply_outcome(_map_state, outcome)
	_spirit.apply_purification(_map_state, outcome)
	_map_state.actions_remaining -= 1
	_map_state.selected_region_id = &""

	_emit_move(outcome)
	region_deselected.emit()
	# Hamleden sonra yalnızca kazanma (oyuncu kendi hamlesiyle kaybedemez — §3.6 a).
	if _win_condition.is_met(_map_state):
		_finish(MapState.GameResult.WON)
	return true


## Tur sonu (region-map §3.4): (1) düşman AI → erken kayıp çıkışı → (2) Erlik yayılımı
## → (3) ekonomi → (4) tur artışı → (5) önce kaybetme (bölgesiz ∨ Erlik), sonra kazanma; oyun
## sürüyorsa `turn_ended` en sonda. Oyun bitmişse hiçbir adım çalışmaz.
func end_turn() -> void:
	if _map_state.game_result != MapState.GameResult.ONGOING:
		return
	_run_enemy_ai()
	# Erken çıkış yalnızca siyasi kayıpta (ölü oyunda olay yayılmaz — §3.4, S2-b).
	if _map_state.get_player_regions().is_empty():
		_lose(MapState.LossReason.NO_REGIONS)
		return
	_run_erlik_spread()

	var income: int = _resource_controller.collect_turn_income(_map_state, _game_state)
	income_collected.emit(income)

	_map_state.current_turn += 1
	_map_state.actions_remaining = _map_state.actions_per_turn

	var loss: MapState.LossReason = _win_condition.loss_reason(_map_state)
	if loss != MapState.LossReason.NONE:
		_lose(loss)
	elif _win_condition.is_met(_map_state):
		_finish(MapState.GameResult.WON)
	else:
		turn_ended.emit(_map_state.current_turn)


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
	var outcome: MoveOutcome = _move_resolver.resolve(
		_map_state, intent.from_id, intent.to_id, RegionData.Owner.ENEMY)
	if not outcome.is_valid():
		push_warning("EnemyAIController geçersiz hamle önerdi: %s → %s (%s)" % [
			intent.from_id, intent.to_id, outcome.invalid_reason])
		return
	_army_controller.apply_outcome(_map_state, outcome)
	_emit_move(outcome)


## (2) Erlik yayılımı (spirit §3.6, §4.6): etkin aralık = bölüm tabanı + lütuflar
## (`erlik_spread_interval` stat'ı, ADR-0006); karar saf, uygulama SpiritController'da.
func _run_erlik_spread() -> void:
	var interval: int = roundi(StatResolver.resolve(
		ErlikSpreadController.STAT_SPREAD_INTERVAL, float(_map_state.erlik_spread_interval), _modifiers()))
	var decision: ErlikSpreadController.SpreadDecision = _erlik_spread.decide(_map_state, interval)
	_spirit.apply_spread(_map_state, decision)
	if decision.is_spread_turn and decision.target_id != &"":
		corruption_spread.emit(decision.target_id)


## Lütuf etkileri — yalnızca saf kurallara aktarılır, burada okunmaz (ADR-0006).
func _modifiers() -> Array[StatModifier]:
	if _modifier_controller == null:
		return [] as Array[StatModifier]
	return _modifier_controller.get_modifiers()


func _lose(reason: MapState.LossReason) -> void:
	if _map_state.game_result != MapState.GameResult.ONGOING:
		return
	_map_state.loss_reason = reason
	_finish(MapState.GameResult.LOST)


## Sonucu bir kez yazar ve sinyali bir kez yayar; sonrası kilitlidir (§3.7).
func _finish(result: MapState.GameResult) -> void:
	if _map_state.game_result != MapState.GameResult.ONGOING:
		return
	_map_state.game_result = result
	if result == MapState.GameResult.WON:
		game_won.emit()
	else:
		game_lost.emit()


## Uygulanmış bir hamlenin sinyali — oyuncu ve düşman için aynı (ADR-0010).
func _emit_move(outcome: MoveOutcome) -> void:
	match outcome.branch:
		MoveOutcome.Branch.COMBAT:
			combat_occurred.emit(outcome.from_id, outcome.to_id, outcome.combat)
		MoveOutcome.Branch.PURIFICATION:
			purification_resolved.emit(outcome)
		MoveOutcome.Branch.PEACEFUL:
			army_moved.emit(outcome.from_id, outcome.to_id, outcome.moving)
