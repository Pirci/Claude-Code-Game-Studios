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
	return model
