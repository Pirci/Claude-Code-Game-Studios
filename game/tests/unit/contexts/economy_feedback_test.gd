extends GdUnitTestSuite
## Üretim / gelir geri bildirimi GameContext ve haritada — resource-system.md §9 (C-66).


const LIBRARY_PATH: String = "res://features/audio/data/sfx_library.tres"
const GAME_SCENE: String = "res://contexts/game_context/game_context.tscn"


func before_test() -> void:
	TranslationServer.set_locale("en")


func _game(audio: AudioController = null, reduce_motion: bool = false) -> GameContext:
	var accessibility: AccessibilitySettings = AccessibilitySettings.new()
	accessibility.reduce_motion = reduce_motion
	var game: GameContext = (load(GAME_SCENE) as PackedScene).instantiate() as GameContext
	game.bind_services(GameState.new(), accessibility, audio)
	add_child(game)
	auto_free(game)
	return game


func _audio() -> AudioController:
	var audio: AudioController = AudioController.new()
	audio.bind_services(load(LIBRARY_PATH) as SfxLibrary)
	add_child(audio)
	auto_free(audio)
	return audio


func _played(audio: AudioController, id: StringName) -> bool:
	var stream: AudioStream = (load(LIBRARY_PATH) as SfxLibrary).get_stream(id)
	for player: AudioStreamPlayer in audio.get_sfx_players():
		if player.stream == stream:
			return true
	return false


func _state(game: GameContext) -> GameState:
	return game.get("_game_state") as GameState


func _player_region(game: GameContext) -> RegionData:
	return _state(game).map_state.get_player_regions()[0]


func _region_node(game: GameContext, region_id: StringName) -> RegionNode:
	for node: Node in game.find_children("*", "RegionNode", true, false):
		if (node as RegionNode).region_id == region_id:
			return node as RegionNode
	return null


func _gold_label(game: GameContext) -> Label:
	return game.find_child("GoldLabel", true, false) as Label


func test_economy_feedback_library_has_recruit_drum_and_income_coin() -> void:
	var library: SfxLibrary = load(LIBRARY_PATH) as SfxLibrary
	assert_object(library.get_stream(AudioController.SFX_RECRUIT)).is_not_null()
	assert_object(library.get_stream(AudioController.SFX_INCOME)).is_not_null()


func test_economy_feedback_context_start_shows_no_feedback() -> void:
	var game: GameContext = _game()
	assert_bool(game.get_gold_feedback().is_flashing()).is_false()
	assert_str(_gold_label(game).text).not_contains("↑")
	assert_bool(_region_node(game, _player_region(game).region_id).get_army_feedback().is_flashing()).is_false()


func test_economy_feedback_recruit_plays_drum_spends_gold_red_and_army_green() -> void:
	var audio: AudioController = _audio()
	var game: GameContext = _game(audio)
	var region: RegionData = _player_region(game)
	var gold_before: int = _state(game).gold
	var army_before: int = region.army_count
	game.call("_on_recruit_pressed", region.region_id, 1)
	assert_int(region.army_count).is_equal(army_before + 1)
	assert_bool(_played(audio, AudioController.SFX_RECRUIT)).is_true()
	var spent: int = gold_before - _state(game).gold
	assert_int(spent).is_greater(0)
	var label: Label = _gold_label(game)
	assert_str(label.text).contains(NumberFormatter.ltr("↓-%d" % spent))
	assert_object(label.get_theme_color(&"font_color")).is_equal(ValueFeedback.COLOR_LOSS)
	var node: RegionNode = _region_node(game, region.region_id)
	assert_object(node.get_army_label().get_theme_color(&"font_color")).is_equal(ValueFeedback.COLOR_GAIN)
	assert_str(node.get_army_label().text).contains(NumberFormatter.ltr("↑+1"))


func test_economy_feedback_end_turn_income_plays_coin_and_shows_gain() -> void:
	var audio: AudioController = _audio()
	var game: GameContext = _game(audio)
	var gold_before: int = _state(game).gold
	(game.get("_map_controller") as MapController).end_turn()
	var gained: int = _state(game).gold - gold_before
	assert_int(gained).is_greater(0)
	assert_bool(_played(audio, AudioController.SFX_INCOME)).is_true()
	assert_str(_gold_label(game).text).contains(NumberFormatter.ltr("↑+%d" % gained))
	assert_object(_gold_label(game).get_theme_color(&"font_color")).is_equal(ValueFeedback.COLOR_GAIN)


func test_economy_feedback_flash_expires_after_two_frames_but_text_stays_longer() -> void:
	var game: GameContext = _game()
	var region: RegionData = _player_region(game)
	game.call("_on_recruit_pressed", region.region_id, 1)
	await await_millis(int(ValueFeedback.FLASH_SEC * 1000.0) + 120)
	var label: Label = _gold_label(game)
	assert_bool(label.has_theme_color_override(&"font_color")).is_false()
	assert_str(label.text).contains("↓")
	await await_millis(int((ValueFeedback.DELTA_HOLD_SEC - ValueFeedback.FLASH_SEC) * 1000.0) + 200)
	assert_str(label.text).not_contains("↓")


func test_economy_feedback_reduce_motion_highlight_is_immediate_and_persistent() -> void:
	var game: GameContext = _game(null, true)
	var region: RegionData = _player_region(game)
	game.call("_on_recruit_pressed", region.region_id, 1)
	await await_millis(int(ValueFeedback.DELTA_HOLD_SEC * 1000.0) + 200)
	var label: Label = _gold_label(game)
	assert_object(label.get_theme_color(&"font_color")).is_equal(ValueFeedback.COLOR_LOSS)
	assert_str(label.text).contains("↓")
	var node: RegionNode = _region_node(game, region.region_id)
	assert_str(node.get_army_label().text).contains(NumberFormatter.ltr("↑+1"))


## Düşman takviyesi (F6) — Prolog'da düşman yok; harita düğümü doğrudan sınanır.
func test_economy_feedback_enemy_reinforcement_shows_plus_one_on_army_label() -> void:
	var data: RegionData = RegionData.new()
	data.region_id = &"enemy"
	data.owner = RegionData.Owner.ENEMY
	data.army_count = 3
	data.polygon_points = PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10)])
	var node: RegionNode = RegionNode.new()
	node.setup(data)
	add_child(node)
	auto_free(node)
	data.army_count = 4
	node.update_display(data)
	assert_str(node.get_army_label().text).is_equal("Army: 4 %s" % NumberFormatter.ltr("↑+1"))
	assert_object(node.get_army_label().get_theme_color(&"font_color")).is_equal(ValueFeedback.COLOR_GAIN)
	data.army_count = 2
	node.update_display(data)
	assert_str(node.get_army_label().text).is_equal("Army: 2")
