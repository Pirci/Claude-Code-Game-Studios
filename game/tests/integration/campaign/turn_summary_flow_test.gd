extends GdUnitTestSuite
## Gece özeti akışı (C-73; ux/battle-report.md §2, §4.3, §9): tek özet → en çok bir şafak lütfu,
## olaysız gecede modal yok, son bölge düşmanla düşerse özet yok (doğrudan yenilgi), yayılım
## ipucu özet kapanınca (Q9). Gerçek RootContext akışı ve gerçek `end_turn`.


const ROOT_SCENE: String = "res://contexts/root_context/root_context.tscn"


func before_test() -> void:
	TranslationServer.set_locale("en")


func _start() -> GameContext:
	var root_ctx: RootContext = auto_free((load(ROOT_SCENE) as PackedScene).instantiate()) as RootContext
	root_ctx.save_store = MemorySaveStore.new()
	var config: SceneFlowConfig = SceneFlowConfig.new()
	config.screen_input_guard_s = 0.0
	config.text_reveal_cps = 0.0
	root_ctx.flow_config = config
	add_child(root_ctx)
	for button: String in ["NewCampaignButton", "SkipButton", "SkipButton", "StartButton"]:
		(root_ctx.find_child(button, true, false) as Button).pressed.emit()
	var game: GameContext = root_ctx.find_child("GameContext", true, false) as GameContext
	var got_it: Button = game.find_child("GotItButton", true, false) as Button
	if got_it != null:
		got_it.pressed.emit()
	return game


func _map(game: GameContext) -> MapState:
	return (game.get("_game_state") as GameState).map_state


func _own(map_state: MapState, region_id: StringName, owner: RegionData.Owner, army: int) -> void:
	var region: RegionData = map_state.get_region(region_id)
	region.owner = owner
	region.army_count = army


func _current(game: GameContext) -> Control:
	return (game.get("_modal_queue") as ModalQueue).get("_current") as Control


func _continue(modal: Control) -> void:
	(modal.find_child("ContinueButton", true, false) as Button).pressed.emit()


func _text(modal: Node, node_name: String) -> String:
	var label: Label = modal.find_child(node_name, true, false) as Label
	return label.text if label != null else ""


## Altai'nin saldırısı Ötüken'de kırılır (HELD), Batı Bozkır Güney Vadi'yi alır (LOST); aynı gece yayılım.
func _two_attacks_and_spread(game: GameContext) -> MapState:
	var m: MapState = _map(game)
	m.enemy_actions_per_turn = 2
	_own(m, &"otuken", RegionData.Owner.PLAYER, 40)
	_own(m, &"altai", RegionData.Owner.ENEMY, 6)
	_own(m, &"bati_bozkir", RegionData.Owner.ENEMY, 8)
	_own(m, &"guney_vadi", RegionData.Owner.PLAYER, 1)
	m.last_erlik_spread_turn = m.current_turn - m.erlik_spread_interval
	return m


func test_turn_summary_two_attacks_and_spread_then_single_boon() -> void:
	var game: GameContext = _start()
	_two_attacks_and_spread(game)
	(game.get("_game_state") as GameState).ruh = 200  # şafakta lütuf sunumu bekler
	game.call("_on_end_turn_pressed")
	var summary: Control = _current(game)
	assert_str(summary.name).is_equal("TurnSummaryReport")
	assert_int(game.find_children("TurnSummaryReport", "", true, false).size()).is_equal(1)
	assert_str(_text(summary, "Attack0Verse")).is_equal(tr("BATTLE_HELD_DEFENSE"))
	assert_str(_text(summary, "Attack0Region")).is_equal(tr("REGION_OTUKEN"))
	assert_str(_text(summary, "Attack1Verse")).is_equal(tr("BATTLE_LOST_DEFENSE"))
	assert_str(_text(summary, "Attack1Region")).is_equal(tr("REGION_GUNEY_VADI"))
	assert_str(_text(summary, "Spread")).is_not_empty()
	# Sayılar outcome alanından (görünüm yeniden hesaplamaz).
	var lost: MoveOutcome = game.night_outcomes()[1]
	assert_str(_text(summary, "Attack1TheirStanding")).contains(str(lost.combat.attacker_remaining))
	_continue(summary)
	await await_idle_frame()
	var boon: Control = _current(game)
	assert_object(boon).is_instanceof(BoonOfferModal)
	assert_int(game.find_children("*", "BoonOfferModal", true, false).size()).is_equal(1)


func test_turn_summary_quiet_night_opens_no_modal() -> void:
	var game: GameContext = _start()
	# 1. tur sonu: düşman yok, yayılım aralığı dolmadı.
	game.call("_on_end_turn_pressed")
	assert_object(_current(game)).is_null()
	assert_object(game.find_child("TurnSummaryReport", true, false)).is_null()


func test_turn_summary_skipped_when_last_region_falls_to_enemy() -> void:
	var game: GameContext = _start()
	var m: MapState = _map(game)
	for region_id: StringName in m.regions:
		_own(m, region_id, RegionData.Owner.NEUTRAL, 0)
	_own(m, &"guney_vadi", RegionData.Owner.PLAYER, 1)
	_own(m, &"bati_bozkir", RegionData.Owner.ENEMY, 8)
	_own(m, &"otuken", RegionData.Owner.ENEMY, 1)  # tek garnizon: hareket etmez, hedef de olmaz
	_own(m, &"altai", RegionData.Owner.ENEMY, 1)
	game.call("_on_end_turn_pressed")
	assert_int(m.game_result).is_equal(MapState.GameResult.LOST)
	assert_int(m.loss_reason).is_equal(MapState.LossReason.NO_REGIONS)
	assert_object(game.find_child("TurnSummaryReport", true, false)).is_null()
	await await_idle_frame()
	assert_object(_current(game)).is_instanceof(DefeatScreen)  # doğrudan yenilgi, ara modal yok


func test_turn_summary_spread_hint_waits_until_summary_closed() -> void:
	var game: GameContext = _start()
	_two_attacks_and_spread(game)
	game.call("_on_end_turn_pressed")
	assert_object(game.find_child("HintText", true, false)).is_null()  # özet açıkken balon yok (Q9)
	_continue(_current(game))
	await await_idle_frame()
	assert_str((game.find_child("HintText", true, false) as Label).text).is_equal(tr("HINT_SPREAD"))
