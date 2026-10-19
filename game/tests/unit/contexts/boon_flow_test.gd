extends GdUnitTestSuite
## Kök Böri sunum akışı GameContext'te — spirit-system.md §3.4, AC3, AC15, AC16; ADR-0011
## karar 5 (tek modal, harita kilidi, odak geri verilir) (C-39).


func before_test() -> void:
	TranslationServer.set_locale("en")


func _game(ruh: int) -> GameContext:
	var state: GameState = GameState.new()
	state.ruh = ruh
	var game: GameContext = (load("res://contexts/game_context/game_context.tscn") as PackedScene).instantiate() as GameContext
	game.bind_services(state, AccessibilitySettings.new())
	add_child(game)
	auto_free(game)
	return game


func _queue(game: GameContext) -> ModalQueue:
	return game.find_child("ModalQueue", true, false) as ModalQueue


func _kok_bori(game: GameContext) -> Button:
	return game.find_child("KokBoriButton", true, false) as Button


func _state(game: GameContext) -> GameState:
	return game.get("_game_state") as GameState


func _press(button: Button) -> void:
	button.pressed.emit()


func _card(game: GameContext, index: int) -> Button:
	return _queue(game).current().find_child("Card%d" % index, true, false) as Button


# AC3: eşik aşıldığında modal kendiliğinden yalnızca tur başında açılır; HUD düğmesi görünür.
func test_dawn_offer_opens_once_at_turn_start() -> void:
	var game: GameContext = _game(30)
	assert_bool(_queue(game).is_open()).is_false()
	assert_bool(_kok_bori(game).visible).is_true()
	_press(game.find_child("EndTurnButton", true, false) as Button)
	assert_bool(_queue(game).is_open()).is_true()
	assert_object(_queue(game).current()).is_instanceof(BoonOfferModal)
	assert_int(_queue(game).current().find_child("Cards", true, false).get_child_count()).is_equal(3)


# AC15: ertelenen sunum HUD düğmesiyle aynı 3 kartla yeniden açılır; modal açıkken harita kilitli.
func test_deferred_offer_reopens_from_hud_with_same_cards() -> void:
	var game: GameContext = _game(30)
	_press(_kok_bori(game))
	var first: String = _card(game, 0).accessibility_name
	game.call("_on_region_clicked", &"otuken")
	assert_str(String(_state(game).map_state.selected_region_id)).is_empty()
	_press(_queue(game).current().find_child("DeferButton", true, false) as Button)
	assert_bool(_queue(game).is_open()).is_false()
	assert_int(_state(game).ruh).is_equal(30)
	_press(_kok_bori(game))
	assert_str(_card(game, 0).accessibility_name).is_equal(first)


# AC5 + AC15: seçim Ruh'u düşer; eşik hâlâ sağlanıyorsa kendiliğinden ikinci modal yok,
# HUD düğmesi aynı tur ikinci sunumu açar.
func test_pick_from_hud_keeps_button_for_next_offer() -> void:
	var game: GameContext = _game(80)
	_press(_kok_bori(game))
	_press(_card(game, 0))
	assert_bool(_queue(game).is_open()).is_false()
	assert_int(_state(game).ruh).is_equal(50)
	assert_array(_state(game).boons).is_equal([&"bereket"])
	assert_bool(_kok_bori(game).visible).is_true()
	_press(_kok_bori(game))
	assert_bool(_queue(game).is_open()).is_true()


# spirit AC16 / scene-flow T16–T17: zaferde sunum zorunlu (Sonra yok), seçimden sonra eşik sağlanıyorsa ikincisi hemen gelir.
func test_victory_offers_are_mandatory_and_chain() -> void:
	var game: GameContext = _game(80)
	_state(game).map_state.game_result = MapState.GameResult.WON
	var finished: Array[bool] = [false]
	game.boon_picks_finished.connect(func() -> void: finished[0] = true)
	game.start_boon_picks()
	var modal: Control = _queue(game).current()
	assert_bool((modal.find_child("DeferButton", true, false) as Button).visible).is_false()
	_press(_card(game, 0))
	assert_bool(_queue(game).is_open()).is_true()
	assert_int(_state(game).ruh).is_equal(50)
	_press(_card(game, 0))
	assert_bool(_queue(game).is_open()).is_false()
	assert_int(_state(game).boons.size()).is_equal(2)
	await await_idle_frame()
	assert_bool(finished[0]).is_true()
	assert_bool(_kok_bori(game).visible).is_false()


# ADR-0011: modal kapanınca önceki odak geri verilir.
func test_closing_modal_restores_focus() -> void:
	var game: GameContext = _game(30)
	var end_turn: Button = game.find_child("EndTurnButton", true, false) as Button
	end_turn.grab_focus()
	_press(_kok_bori(game))
	assert_object(get_viewport().gui_get_focus_owner()).is_same(_card(game, 0))
	_press(_queue(game).current().find_child("DeferButton", true, false) as Button)
	assert_object(get_viewport().gui_get_focus_owner()).is_same(end_turn)


# Lütuf seçimleri yeniden açılışta etkiyle geri gelir (AC19, GameContext yolu).
func test_saved_boons_rebuild_modifiers_on_context_start() -> void:
	var state: GameState = GameState.new()
	state.boons = [&"bereket"] as Array[StringName]
	var game: GameContext = (load("res://contexts/game_context/game_context.tscn") as PackedScene).instantiate() as GameContext
	game.bind_services(state, AccessibilitySettings.new())
	add_child(game)
	auto_free(game)
	assert_float(StatResolver.resolve(&"gold_income", 0.0, state.modifiers)).is_equal(1.0)
	assert_str((game.find_child("GoldLabel", true, false) as Label).text).is_equal("Gold: 6 %s" % NumberFormatter.ltr("(+3)"))
