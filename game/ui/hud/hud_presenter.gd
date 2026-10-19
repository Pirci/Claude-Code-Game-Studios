class_name HudPresenter
extends RefCounted
## [HudModel]'i durumdan ve saf kurallardan kuran saf fonksiyon (ADR-0011 karar 3):
## gelir tahmini [ResourceController.forecast_income] (F2, ekonomi adımıyla aynı), sunum
## koşulu [method SpiritController.is_offer_pending] (türetilmiş durum).


static func build(
	game_state: GameState,
	resources: ResourceController,
	spirit: SpiritController,
	modifiers: Array[StatModifier],
	win_condition: WinCondition = null,
) -> HudModel:
	var map_state: MapState = game_state.map_state
	var model: HudModel = HudModel.new()
	model.gold = game_state.gold
	model.income_forecast = resources.forecast_income(map_state, modifiers)
	model.turn = map_state.current_turn
	model.ruh = game_state.ruh
	model.game_result = map_state.game_result
	model.boon_offer_available = (
		map_state.game_result == MapState.GameResult.ONGOING and spirit.is_offer_pending())
	if win_condition != null:
		_fill_objective(model, map_state, win_condition)
	return model


## Hedef ilerlemesi ve Erlik'in Gölgesi — kazanma koşulunun kendi saf fonksiyonlarından.
static func _fill_objective(model: HudModel, map_state: MapState, win: WinCondition) -> void:
	model.objective_key = win.description_key
	model.neutral_conquered = win.conquered_neutral_count(map_state)
	model.neutral_required = win.required_neutral_conquests
	model.foci_total = win.erlik_foci.size()
	for focus_id: StringName in win.erlik_foci:
		var focus: RegionData = map_state.get_region(focus_id)
		if focus != null and focus.corruption_level == 0:
			model.foci_cleansed += 1
	model.erlik_power = WinCondition.erlik_power(map_state)
	model.erlik_threshold = win.erlik_loss_threshold
	model.erlik_warning = win.erlik_loss_threshold > 0 \
		and model.erlik_power == win.erlik_loss_threshold - 1
