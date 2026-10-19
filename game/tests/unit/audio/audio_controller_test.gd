extends GdUnitTestSuite
## AudioController + bus düzeni — ADR-0008, C-23 (bölge seçimi "tık"ı, SFX bus'ı ile ölçeklenir).


const LIBRARY_PATH: String = "res://features/audio/data/sfx_library.tres"
const GAME_SCENE: String = "res://contexts/game_context/game_context.tscn"
const SETTINGS_SCENE: String = "res://ui/screens/settings_screen.tscn"


func _controller(with_library: bool = true) -> AudioController:
	var audio: AudioController = AudioController.new()
	if with_library:
		audio.bind_services(load(LIBRARY_PATH) as SfxLibrary)
	add_child(audio)
	auto_free(audio)
	return audio


func _players_with_stream(audio: AudioController) -> int:
	var count: int = 0
	for player: AudioStreamPlayer in audio.get_sfx_players():
		if player.stream != null:
			count += 1
	return count


func test_bus_layout_has_music_and_sfx_sending_to_master() -> void:
	for bus: StringName in [AudioController.MUSIC_BUS, AudioController.SFX_BUS]:
		var index: int = AudioServer.get_bus_index(bus)
		assert_int(index).is_greater(0)
		assert_str(String(AudioServer.get_bus_send(index))).is_equal("Master")


func test_library_maps_region_select_to_a_stream() -> void:
	var library: SfxLibrary = load(LIBRARY_PATH) as SfxLibrary
	assert_object(library.get_stream(AudioController.SFX_REGION_SELECT)).is_not_null()
	assert_object(library.get_stream(&"does_not_exist")).is_null()


func test_play_known_sfx_uses_sfx_bus_player() -> void:
	var audio: AudioController = _controller()
	assert_bool(audio.play_sfx(AudioController.SFX_REGION_SELECT)).is_true()
	var player: AudioStreamPlayer = audio.get_sfx_players()[0]
	assert_object(player.stream).is_not_null()
	assert_str(String(player.bus)).is_equal("SFX")


func test_unknown_sfx_or_missing_library_does_not_play() -> void:
	assert_bool(_controller().play_sfx(&"does_not_exist")).is_false()
	assert_bool(_controller(false).play_sfx(AudioController.SFX_REGION_SELECT)).is_false()


func test_pool_reuses_players_round_robin() -> void:
	var audio: AudioController = _controller()
	for i: int in AudioController.SFX_POOL_SIZE + 1:
		audio.play_sfx(AudioController.SFX_REGION_SELECT)
	assert_int(audio.get_sfx_players().size()).is_equal(AudioController.SFX_POOL_SIZE)


func test_selecting_a_region_plays_the_click() -> void:
	var audio: AudioController = _controller()
	var game: GameContext = (load(GAME_SCENE) as PackedScene).instantiate() as GameContext
	game.bind_services(GameState.new(), AccessibilitySettings.new(), audio)
	add_child(game)
	auto_free(game)
	var controller: MapController = game.get("_map_controller") as MapController
	var state: GameState = game.get("_game_state") as GameState
	controller.select_region(state.map_state.get_player_regions()[0].region_id)
	assert_int(_players_with_stream(audio)).is_equal(1)


func test_sfx_slider_scales_the_sfx_bus() -> void:
	var index: int = AudioServer.get_bus_index(AudioController.SFX_BUS)
	var before: float = AudioServer.get_bus_volume_db(index)
	var screen: SettingsScreen = (load(SETTINGS_SCENE) as PackedScene).instantiate() as SettingsScreen
	add_child(screen)
	auto_free(screen)
	screen.call("_on_sfx_changed", 0.5)
	assert_float(AudioServer.get_bus_volume_db(index)).is_equal_approx(linear_to_db(0.5), 0.01)
	AudioServer.set_bus_volume_db(index, before)
