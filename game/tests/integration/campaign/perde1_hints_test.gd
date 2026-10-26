extends GdUnitTestSuite
## Perde 1 sahne içi tetikleyiciler (C-92; seviye perde1 §2 "Anlatı tetikleyicileri", enemy-layers §3.4):
## ilk tur `HINT_ENEMY_KING` (bir kez, modal açıkken bekler — hud B2), başkentin ilk seçilişinde
## `HINT_CAPITAL` (bir kez), Çürük Koru arındırma raporunda sahnenin "şifa" anahtarları.


const ROOT_SCENE: String = "res://contexts/root_context/root_context.tscn"
const S := RegionData.Owner

var _store: MemorySaveStore


func before_test() -> void:
	TranslationServer.set_locale("en")
	_store = MemorySaveStore.new()


func _root(prolog_done: bool) -> RootContext:
	if prolog_done:
		var done: GameState = GameState.new()
		done.chapters_completed = [1] as Array[int]
		done.current_chapter = 2
		_store.write(SaveController.CAMPAIGN_SLOT, SaveSerializer.to_text(done))
	var root_ctx: RootContext = auto_free((load(ROOT_SCENE) as PackedScene).instantiate()) as RootContext
	root_ctx.save_store = _store
	var config: SceneFlowConfig = SceneFlowConfig.new()
	config.screen_input_guard_s = 0.0
	config.text_reveal_cps = 0.0
	root_ctx.flow_config = config
	root_ctx.campaign_seed_source = func() -> int: return 1
	add_child(root_ctx)
	return root_ctx


func _press(node: Node, button_name: String) -> void:
	var button: Button = node.find_child(button_name, true, false) as Button
	assert_object(button).override_failure_message("düğme yok: %s" % button_name).is_not_null()
	button.pressed.emit()


## Devam Et → sefer haritası → Perde 1 → giriş ve Kök Böri sayfaları atlanır; hedef paneli açık kalır.
func _open_perde1_objective(root_ctx: RootContext) -> void:
	await await_idle_frame()
	_press(root_ctx, "ContinueButton")
	_press(root_ctx.find_child("Chapter2", true, false), "StartButton")
	await await_idle_frame()
	_press(root_ctx, "SkipButton")
	_press(root_ctx, "SkipButton")
	await await_idle_frame()


func _game(root_ctx: RootContext) -> GameContext:
	return root_ctx.find_child("GameContext", true, false) as GameContext


func _hint_text(node: Node) -> String:
	var text: Label = node.find_child("HintText", true, false) as Label
	return text.text if text != null and not text.is_queued_for_deletion() else ""


func _dismiss_hint(game: GameContext) -> void:
	_press(game, "GotItButton")
	await await_idle_frame()
	await await_idle_frame()


func test_perde1_enemy_king_hint_waits_for_objective_then_recruit_follows() -> void:
	var root_ctx: RootContext = _root(true)
	await _open_perde1_objective(root_ctx)
	var game: GameContext = _game(root_ctx)
	assert_int((game.get("_game_state") as GameState).map_state.chapter_id).is_equal(2)
	assert_str(_hint_text(game)).is_empty()  # hedef paneli açık: ipucu bekler (B2)
	_press(root_ctx, "StartButton")
	await await_idle_frame()
	assert_str(_hint_text(game)).is_equal(tr("HINT_ENEMY_KING"))
	await _dismiss_hint(game)
	assert_str(_hint_text(game)).is_equal(tr("HINT_RECRUIT"))  # aynı tur başında sıradaki ipucu


func test_perde1_capital_hint_once_on_capital_only() -> void:
	var root_ctx: RootContext = _root(true)
	await _open_perde1_objective(root_ctx)
	_press(root_ctx, "StartButton")
	await await_idle_frame()
	var game: GameContext = _game(root_ctx)
	await _dismiss_hint(game)  # düşman kağanı
	await _dismiss_hint(game)  # üret
	game.call("_on_region_clicked", &"curcet_oba")  # düşman ama başkent değil
	assert_str(_hint_text(game)).is_empty()
	game.call("_on_controller_region_deselected")
	game.call("_on_region_clicked", &"curcet_otagi")
	assert_str(_hint_text(game)).is_equal(tr("HINT_CAPITAL"))
	await _dismiss_hint(game)
	game.call("_on_controller_region_deselected")
	game.call("_on_region_clicked", &"curcet_otagi")
	assert_str(_hint_text(game)).is_empty()


func test_prolog_first_turn_has_no_enemy_king_hint() -> void:
	var root_ctx: RootContext = _root(false)
	await await_idle_frame()
	_press(root_ctx, "NewCampaignButton")
	_press(root_ctx, "SkipButton")
	_press(root_ctx, "SkipButton")
	_press(root_ctx, "StartButton")
	await await_idle_frame()
	assert_str(_hint_text(_game(root_ctx))).is_equal(tr("HINT_RECRUIT"))


## Kayın Koruluk'tan (komşu) Çürük Koru'ya [param army] − 1 kuvvetle arındırma; rapor döner.
func _purify_grove(army: int) -> Node:
	var root_ctx: RootContext = _root(true)
	await _open_perde1_objective(root_ctx)
	_press(root_ctx, "StartButton")
	await await_idle_frame()
	var game: GameContext = _game(root_ctx)
	(game.get("_tutorial") as TutorialProgress).load_seen(TutorialRules.ALL)
	var source: RegionData = (game.get("_game_state") as GameState).map_state.get_region(&"kayin_koruluk")
	source.owner = S.PLAYER
	source.army_count = army
	game.call("_on_controller_region_deselected")
	game.call("_on_region_clicked", &"kayin_koruluk")
	_press(game, "SendArmyButton")
	game.call("_on_region_clicked", &"curuk_koru")
	return game.find_child("PurificationReport", true, false)


func test_perde1_grove_purification_report_uses_healing_keys() -> void:
	var report: Node = await _purify_grove(20)  # 19 > S = 12
	assert_object(report).is_not_null()
	assert_str((report.find_child("Heading", true, false) as Label).text).is_equal(tr("CHAPTER_2_CLEANSED_HEADING"))
	assert_str((report.find_child("Verse", true, false) as Label).text).is_equal(tr("CHAPTER_2_CLEANSED_LINE"))


func test_perde1_grove_failed_purification_uses_failed_line() -> void:
	var report: Node = await _purify_grove(6)  # 5 ≤ 12
	assert_object(report).is_not_null()
	assert_str((report.find_child("Heading", true, false) as Label).text).is_equal(tr("PURIFY_REPORT_HEADING"))
	assert_str((report.find_child("Verse", true, false) as Label).text).is_equal(tr("CHAPTER_2_HUNT_FAILED"))
