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
		_fill_m2(model, map_state, win_condition, modifiers)
	return model


## M2 alanları (hud §5.1, §5.2, §5.5; H1–H3, H8–H10) — tur sonu ve AI ile aynı saf kurallardan.
static func _fill_m2(model: HudModel, map_state: MapState, win: WinCondition, modifiers: Array[StatModifier]) -> void:
	model.spread_visible = win.erlik_loss_threshold > 0
	model.spread_turns_left = ErlikSpreadController.turns_until_spread(map_state, modifiers)
	model.spread_target_id = ErlikSpreadController.new().decide(
		map_state, ErlikSpreadController.effective_interval(map_state, modifiers)).target_id
	model.focus_at_risk = model.spread_turns_left == 0 and model.spread_target_id != &"" \
		and model.spread_target_id in win.erlik_foci
	model.enemy_regions_initial = map_state.enemy_region_ids_initial.size()
	model.enemy_counter_visible = win.must_defeat_all_enemies and model.enemy_regions_initial > 0
	for region_id: StringName in map_state.enemy_region_ids_initial:
		var region: RegionData = map_state.get_region(region_id)
		if region != null and region.owner != RegionData.Owner.ENEMY:
			model.enemy_regions_taken += 1
	model.red_warning = warning_for(model)


## H8 önceliği; oyun bitince uyarı yok.
static func warning_for(model: HudModel) -> HudModel.Warning:
	if model.game_result != MapState.GameResult.ONGOING:
		return HudModel.Warning.NONE
	if model.erlik_warning:
		return HudModel.Warning.ERLIK_LOSS
	if model.focus_at_risk:
		return HudModel.Warning.FOCUS_AT_RISK
	if model.spread_visible and model.spread_turns_left == 0:
		return HudModel.Warning.SPREAD_NOW
	return HudModel.Warning.NONE


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
