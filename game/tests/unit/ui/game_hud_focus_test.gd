extends GdUnitTestSuite
## Oyun HUD'u buton taban genişlikleri ve dinamik odak zinciri — art bible §7.


const GAME_SCENE: String = "res://contexts/game_context/game_context.tscn"
const BAR_BUTTON_MIN_WIDTH: float = 64.0


func _game() -> GameContext:
	var game: GameContext = (load(GAME_SCENE) as PackedScene).instantiate() as GameContext
	game.bind_services(GameState.new(), AccessibilitySettings.new())
	add_child(game)
	auto_free(game)
	return game


func _end_turn(game: GameContext) -> Button:
	return game.find_child("EndTurnButton", true, false) as Button


func _player_region_id(game: GameContext) -> StringName:
	var state: GameState = game.get("_game_state") as GameState
	return state.map_state.get_player_regions()[0].region_id


func test_bar_buttons_have_base_width() -> void:
	var game: GameContext = _game()
	for name: String in ["EndTurnButton", "MenuButton"]:
		var button: Button = game.find_child(name, true, false) as Button
		assert_float(button.custom_minimum_size.x).is_greater_equal(BAR_BUTTON_MIN_WIDTH)


func test_send_army_joins_focus_chain_when_visible() -> void:
	var game: GameContext = _game()
	var controller: MapController = game.get("_map_controller") as MapController
	controller.select_region(_player_region_id(game))
	var panel: RegionInfoPanel = game.get("_info_panel") as RegionInfoPanel
	var send: Control = panel.get_focus_target()
	assert_object(send).is_not_null()
	var end_turn: Button = _end_turn(game)
	assert_object(end_turn.get_node(end_turn.focus_neighbor_top)).is_same(send)
	assert_object(send.get_node(send.focus_neighbor_bottom)).is_same(end_turn)


func test_focus_link_removed_when_panel_hidden() -> void:
	var game: GameContext = _game()
	var controller: MapController = game.get("_map_controller") as MapController
	var region_id: StringName = _player_region_id(game)
	controller.select_region(region_id)
	controller.select_region(region_id)  # tekrar tıklama seçimi kaldırır
	assert_object((game.get("_info_panel") as RegionInfoPanel).get_focus_target()).is_null()
	assert_bool(_end_turn(game).focus_neighbor_top.is_empty()).is_true()
