extends GdUnitTestSuite
## Ortak girdi koruması + Esc kuralı (C-74; boon-selection AC8, scene-screens §0.3 / AC-E5-6 / AC-E5-8,
## hud A-4): her ModalQueue modalı ve E5 açılışta `screen_input_guard_s` boyunca düğmelerini pasif
## tutar ve Esc'i düşürür; koruma bitince Esc tablosu: rapor/zafer = Devam, ertelenebilir lütuf =
## Ertele, onay = Hayır, E5 = Ana Menü; zorunlu lütuf / E2 / E4'te Esc etkisiz.


const GUARD_S: float = 5.0  # test süresince koruma kalkmaz (gerçek değer 0,4 sn)


func _esc() -> InputEventAction:
	var esc: InputEventAction = InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	return esc


func _game(guard_s: float) -> GameContext:
	var config: SceneFlowConfig = SceneFlowConfig.new()
	config.screen_input_guard_s = guard_s
	var state: GameState = GameState.new()
	var game: GameContext = (load("res://contexts/game_context/game_context.tscn") as PackedScene).instantiate() as GameContext
	game.bind_services(state, AccessibilitySettings.new(), null, null, null, config)
	add_child(game)
	auto_free(game)
	state.ruh = 200  # her sunum türü için bekleyen sunum
	return game


func _current(game: GameContext) -> Control:
	return (game.get("_modal_queue") as ModalQueue).get("_current") as Control


func _buttons(node: Node) -> Array[BaseButton]:
	var buttons: Array[BaseButton] = []
	for child: Node in node.find_children("*", "BaseButton", true, false):
		if (child as BaseButton).visible:
			buttons.append(child as BaseButton)
	return buttons


## Modal korumalı: görünür her düğme pasif, Esc modalı kapatmaz.
func _assert_guarded(game: GameContext, expected_class: String) -> void:
	var modal: Control = _current(game)
	assert_object(modal).is_not_null()
	assert_bool(modal.is_class(expected_class) or modal.get_script().get_global_name() == expected_class).is_true()
	var buttons: Array[BaseButton] = _buttons(modal)
	assert_bool(buttons.is_empty()).is_false()
	for button: BaseButton in buttons:
		assert_bool(button.disabled).override_failure_message("korumasız: %s" % button.name).is_true()
	modal._unhandled_input(_esc())
	assert_object(_current(game)).is_same(modal)


func test_input_guard_dawn_boon_offer() -> void:
	var game: GameContext = _game(GUARD_S)
	game.call("_on_end_turn_pressed")
	_assert_guarded(game, "BoonOfferModal")


func test_input_guard_hud_boon_offer() -> void:
	var game: GameContext = _game(GUARD_S)
	game.call("_on_kok_bori_pressed")
	_assert_guarded(game, "BoonOfferModal")


func test_input_guard_load_boon_offer() -> void:
	var game: GameContext = _game(GUARD_S)
	game.offer_pending_boon()
	_assert_guarded(game, "BoonOfferModal")


func test_input_guard_mandatory_boon_offer() -> void:
	var game: GameContext = _game(GUARD_S)
	game.start_boon_picks()
	_assert_guarded(game, "BoonOfferModal")


func test_input_guard_leave_confirm() -> void:
	var game: GameContext = _game(GUARD_S)
	game.show_leave_confirm()
	_assert_guarded(game, "ConfirmDialog")


func test_input_guard_turn_summary() -> void:
	var game: GameContext = _game(GUARD_S)
	var m: MapState = (game.get("_game_state") as GameState).map_state
	m.last_erlik_spread_turn = m.current_turn - m.erlik_spread_interval
	game.call("_on_end_turn_pressed")
	_assert_guarded(game, "TurnSummaryReport")


func test_esc_after_guard_defers_boon_and_closes_confirm() -> void:
	var game: GameContext = _game(0.0)
	game.call("_on_kok_bori_pressed")
	var offer: BoonOfferModal = _current(game) as BoonOfferModal
	var deferred: Array[int] = [0]
	offer.deferred.connect(func() -> void: deferred[0] += 1)
	offer._unhandled_input(_esc())
	assert_int(deferred[0]).is_equal(1)
	await await_idle_frame()
	game.show_leave_confirm()
	var dialog: ConfirmDialog = _current(game) as ConfirmDialog
	var cancelled: Array[int] = [0]
	dialog.cancelled.connect(func() -> void: cancelled[0] += 1)
	dialog._unhandled_input(_esc())
	assert_int(cancelled[0]).is_equal(1)


func test_esc_is_inert_on_mandatory_boon_objective_and_defeat() -> void:
	var game: GameContext = _game(0.0)
	game.start_boon_picks()
	var offer: Control = _current(game)
	offer._unhandled_input(_esc())
	assert_object(_current(game)).is_same(offer)
	# E2 / E4: Esc dinleyicisi yok ya da kapatmıyor — gerçek girdi yolundan gönderilir.
	for modal: Control in [ObjectivePanel.new(&"", &""), DefeatScreen.new()] as Array[Control]:
		var closes: Array[int] = [0]
		modal.connect(&"closed", func() -> void: closes[0] += 1)
		add_child(modal)
		auto_free(modal)
		get_viewport().push_input(_esc())
		await await_idle_frame()
		assert_int(closes[0]).is_equal(0)


func test_guard_releases_buttons_after_duration() -> void:
	var game: GameContext = _game(0.05)
	game.call("_on_kok_bori_pressed")
	var offer: Control = _current(game)
	assert_bool((offer.find_child("Card0", true, false) as BaseButton).disabled).is_true()
	await get_tree().create_timer(0.15).timeout
	assert_bool((offer.find_child("Card0", true, false) as BaseButton).disabled).is_false()
	assert_bool((offer.find_child("DeferButton", true, false) as BaseButton).disabled).is_false()


func _chapter_select(guard_s: float) -> ChapterSelectContext:
	var campaign: CampaignDefinition = load("res://features/campaign/data/campaign.tres") as CampaignDefinition
	var select: ChapterSelectContext = ChapterSelectContext.new()
	select.bind_services(campaign, GameState.new(), null, guard_s)
	add_child(select)
	auto_free(select)
	return select


func test_chapter_select_guard_then_esc_returns_to_menu() -> void:
	var guarded: ChapterSelectContext = _chapter_select(GUARD_S)
	var menu_calls: Array[int] = [0]
	guarded.menu_requested.connect(func() -> void: menu_calls[0] += 1)
	assert_bool((guarded.find_child("StartButton", true, false) as BaseButton).disabled).is_true()
	assert_bool((guarded.find_child("MenuButton", true, false) as BaseButton).disabled).is_true()
	guarded._unhandled_input(_esc())
	assert_int(menu_calls[0]).is_equal(0)
	var open: ChapterSelectContext = _chapter_select(0.0)
	open.menu_requested.connect(func() -> void: menu_calls[0] += 1)
	assert_bool((open.find_child("StartButton", true, false) as BaseButton).disabled).is_false()
	open._unhandled_input(_esc())
	assert_int(menu_calls[0]).is_equal(1)
