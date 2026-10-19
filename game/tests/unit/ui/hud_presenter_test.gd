extends GdUnitTestSuite
## HudPresenter — saf HUD modeli (ADR-0011 karar 3; C-39).


func _state(ruh: int) -> GameState:
	var state: GameState = GameState.new()
	state.gold = 7
	state.ruh = ruh
	var otag: RegionData = RegionData.new()
	otag.region_id = &"otag"
	otag.owner = RegionData.Owner.PLAYER
	otag.gold_per_turn = 2
	var vadi: RegionData = RegionData.new()
	vadi.region_id = &"vadi"
	vadi.owner = RegionData.Owner.PLAYER
	vadi.gold_per_turn = 3
	vadi.corruption_level = 2
	state.map_state = MapState.new()
	state.map_state.regions = {&"otag": otag, &"vadi": vadi}
	state.map_state.current_turn = 4
	return state


func _spirit(state: GameState) -> SpiritController:
	var modifiers: ModifierController = ModifierController.new()
	modifiers.bind_services(state)
	var spirit: SpiritController = SpiritController.new()
	spirit.bind_services(state)
	spirit.bind_boons(load("res://features/bozkurt/data/boon_catalog.tres") as BoonCatalog, modifiers)
	return spirit


func test_hud_model_uses_economy_forecast_and_offer_condition() -> void:
	var state: GameState = _state(30)
	var resources: ResourceController = ResourceController.new()
	var model: HudModel = HudPresenter.build(state, resources, _spirit(state), [] as Array[StatModifier])
	assert_int(model.gold).is_equal(7)
	assert_int(model.income_forecast).is_equal(resources.forecast_income(state.map_state))
	assert_int(model.income_forecast).is_equal(3)
	assert_int(model.turn).is_equal(4)
	assert_int(model.ruh).is_equal(30)
	assert_bool(model.boon_offer_available).is_true()


func test_boon_button_hidden_after_game_over_or_below_threshold() -> void:
	var state: GameState = _state(30)
	state.map_state.game_result = MapState.GameResult.WON
	var resources: ResourceController = ResourceController.new()
	assert_bool(HudPresenter.build(state, resources, _spirit(state), [] as Array[StatModifier]).boon_offer_available).is_false()
	var poor: GameState = _state(29)
	assert_bool(HudPresenter.build(poor, resources, _spirit(poor), [] as Array[StatModifier]).boon_offer_available).is_false()
