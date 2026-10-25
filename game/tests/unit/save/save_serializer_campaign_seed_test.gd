extends GdUnitTestSuite
## Kampanya tohumu kaydı (C-77; ADR-0007 eki, scene-flow §3.2 / §3.4, AC25c, spirit AC29): şema v2
## alanı, v1 göçü (0), doğrulama ve sefer boyunca sabitlik (S1–S3, Devam Et, Yeniden Dene).


const ROOT_SCENE: String = "res://contexts/root_context/root_context.tscn"
const PROLOG_MAP: String = "res://features/grid/data/chapter_1_map.tres"
const S := SceneFlow.State
## Testte enjekte edilen tohumlar (rastgelelik yok — determinizm kuralı).
const SEED_A: int = 123_456_789
const SEED_B: int = 987_654_321

var _store: MemorySaveStore
var _seeds: Array[int] = []


func before_test() -> void:
	TranslationServer.set_locale("en")
	_store = MemorySaveStore.new()
	_seeds = [SEED_A, SEED_B]


func _map_factory(chapter_id: int) -> MapState:
	return (load(PROLOG_MAP) as ChapterMapDefinition).create_map_state() if chapter_id == 1 else null


func _state_with_seed(value: int) -> GameState:
	var s: GameState = GameState.new()
	s.campaign_seed = value
	s.map_state = _map_factory(1)
	return s


# --- Serileştirici ---

func test_campaign_seed_round_trips_in_schema_v2() -> void:
	var text: String = SaveSerializer.to_text(_state_with_seed(SEED_A))
	var data: Dictionary = JSON.parse_string(text) as Dictionary
	assert_int(int(data["schema_version"])).is_equal(2)
	assert_int(int((data["game"] as Dictionary)["campaign_seed"])).is_equal(SEED_A)
	var result: LoadResult = SaveSerializer.from_text(text, _map_factory)
	assert_int(result.code).is_equal(LoadResult.Code.OK)
	assert_int(result.state.campaign_seed).is_equal(SEED_A)


func test_campaign_seed_v1_save_migrates_to_zero() -> void:
	var data: Dictionary = SaveSerializer.to_dict(_state_with_seed(SEED_A))
	data["schema_version"] = 1
	(data["game"] as Dictionary).erase("campaign_seed")
	var copy: Dictionary = data.duplicate(true)
	var result: LoadResult = SaveSerializer.from_dict(data, _map_factory)
	assert_int(result.code).is_equal(LoadResult.Code.OK)
	assert_int(result.state.campaign_seed).is_equal(0)  # tohumsuz → eski sunum çıktısı (spirit AC4)
	assert_dict(data).is_equal(copy)  # göç girdiyi değiştirmez


func test_campaign_seed_invalid_or_missing_in_v2_is_corrupt() -> void:
	for bad: Variant in [null, -1, SaveSerializer.MAX_SEED + 1, "42", 4.5]:
		var data: Dictionary = SaveSerializer.to_dict(_state_with_seed(SEED_A))
		if bad == null:
			(data["game"] as Dictionary).erase("campaign_seed")
		else:
			(data["game"] as Dictionary)["campaign_seed"] = bad
		var result: LoadResult = SaveSerializer.from_dict(data, _map_factory)
		assert_int(result.code).override_failure_message("değer: %s" % [bad]).is_equal(LoadResult.Code.CORRUPT)


func test_default_campaign_seed_source_is_positive_31_bit() -> void:
	for i: int in 50:
		var value: int = RootContext.new_campaign_seed()
		assert_bool(value >= 1 and value <= SaveSerializer.MAX_SEED).is_true()


# --- Sahne akışı (AC25c) ---

func _root() -> RootContext:
	var root_ctx: RootContext = auto_free((load(ROOT_SCENE) as PackedScene).instantiate()) as RootContext
	root_ctx.save_store = _store
	var config: SceneFlowConfig = SceneFlowConfig.new()
	config.screen_input_guard_s = 0.0
	config.text_reveal_cps = 0.0
	root_ctx.flow_config = config
	root_ctx.campaign_seed_source = func() -> int: return _seeds.pop_front()
	add_child(root_ctx)
	return root_ctx


func _press(root_ctx: RootContext, button_name: String) -> void:
	(root_ctx.find_child(button_name, true, false) as Button).pressed.emit()


func _state(root_ctx: RootContext) -> GameState:
	return root_ctx.get("_game_state") as GameState


func _saved(slot: StringName) -> GameState:
	var texts: PackedStringArray = _store.read_candidates(slot)
	return SaveSerializer.from_text(texts[0], _map_factory).state if not texts.is_empty() else null


func _start(root_ctx: RootContext) -> void:
	_press(root_ctx, "NewCampaignButton")
	if root_ctx.find_child("YesButton", true, false) != null:  # kayıt varsa Yeni Sefer onay ister
		_press(root_ctx, "YesButton")
	for button: String in ["SkipButton", "SkipButton", "StartButton"]:
		_press(root_ctx, button)
	assert_int(root_ctx.flow_state()).is_equal(S.PLAYING)


func test_campaign_seed_constant_through_s2_s1_retry_continue_and_s3() -> void:
	var root_ctx: RootContext = _root()
	_start(root_ctx)
	assert_int(_state(root_ctx).campaign_seed).is_equal(SEED_A)
	assert_int(_saved(SaveController.CAMPAIGN_SLOT).campaign_seed).is_equal(SEED_A)  # S2
	assert_int(_saved(SaveController.SCENE_ENTRY_SLOT).campaign_seed).is_equal(SEED_A)
	(root_ctx.find_child("EndTurnButton", true, false) as Button).pressed.emit()
	assert_int(_saved(SaveController.CAMPAIGN_SLOT).campaign_seed).is_equal(SEED_A)  # S1
	# Yeniden Dene tohumu değiştirmez.
	_state(root_ctx).map_state.game_result = MapState.GameResult.LOST
	_state(root_ctx).map_state.loss_reason = MapState.LossReason.ERLIK
	((root_ctx.find_child("GameContext", true, false) as GameContext).get("_map_controller") as MapController).game_lost.emit()
	_press(root_ctx, "RetryButton")
	assert_int(_state(root_ctx).campaign_seed).is_equal(SEED_A)
	# Devam Et (yeni oturum) aynı tohumu okur.
	var resumed: RootContext = _root()
	_press(resumed, "ContinueButton")
	assert_int(_state(resumed).campaign_seed).is_equal(SEED_A)
	# S3 (sahne tamamlandı, harita yok) tohumu taşır.
	_state(resumed).map_state.game_result = MapState.GameResult.WON
	((resumed.find_child("GameContext", true, false) as GameContext).get("_map_controller") as MapController).game_won.emit()
	_press(resumed, "ContinueButton")
	assert_int(resumed.flow_state()).is_equal(S.OUTRO_NARRATIVE)
	var completed: GameState = _saved(SaveController.CAMPAIGN_SLOT)
	assert_object(completed.map_state).is_null()
	assert_int(completed.campaign_seed).is_equal(SEED_A)
	assert_int(_seeds.size()).is_equal(1)  # yalnız bir Yeni Sefer tohumu harcandı


func test_campaign_seed_regenerated_on_new_campaign() -> void:
	var first: RootContext = _root()
	_start(first)
	assert_int(_saved(SaveController.CAMPAIGN_SLOT).campaign_seed).is_equal(SEED_A)
	var second: RootContext = _root()
	_start(second)  # kayıt var → onay → yeni sefer
	assert_int(_state(second).campaign_seed).is_equal(SEED_B)
	assert_int(_saved(SaveController.CAMPAIGN_SLOT).campaign_seed).is_equal(SEED_B)
