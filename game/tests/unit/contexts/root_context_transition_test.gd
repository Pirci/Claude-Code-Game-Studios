extends GdUnitTestSuite
## RootContext bağlam geçişleri — ADR-0001 (C-57): sahneler geçişte load() edilir, giden
## bağlam aynı karede ağaçtan çıkar; bölüm haritası chapter_id ile yüklenir.


const ROOT_SCENE: String = "res://contexts/root_context/root_context.tscn"
const GAME_SCENE: String = "res://contexts/game_context/game_context.tscn"


func _root() -> RootContext:
	var root_ctx: RootContext = auto_free((load(ROOT_SCENE) as PackedScene).instantiate()) as RootContext
	add_child(root_ctx)
	return root_ctx


func _contexts(root_ctx: RootContext) -> Array[Node]:
	var found: Array[Node] = []
	for child: Node in root_ctx.get_children():
		if child is MenuContext or child is GameContext:
			found.append(child)
	return found


func _accept(pressed: bool) -> InputEventAction:
	var ev: InputEventAction = InputEventAction.new()
	ev.action = &"ui_accept"
	ev.pressed = pressed
	return ev


func test_new_campaign_press_swaps_menu_for_game_in_same_frame() -> void:
	var root_ctx: RootContext = _root()
	var menu: Node = _contexts(root_ctx)[0]
	var button: Button = root_ctx.find_child("NewCampaignButton", true, false) as Button
	button.grab_focus()  # görünür odak → ui_accept butona basar (bırakmada tetiklenir)
	get_viewport().push_input(_accept(true))
	get_viewport().push_input(_accept(false))
	var contexts: Array[Node] = _contexts(root_ctx)
	assert_int(contexts.size()).is_equal(1)
	assert_bool(contexts[0] is GameContext).is_true()
	assert_bool(menu.is_inside_tree()).is_false()
	assert_bool(menu.is_queued_for_deletion()).is_true()


func test_return_to_menu_round_trip_keeps_single_context() -> void:
	var root_ctx: RootContext = _root()
	var names: Array[StringName] = []
	root_ctx.context_changed.connect(func(context_name: StringName) -> void: names.append(context_name))
	(root_ctx.find_child("NewCampaignButton", true, false) as Button).pressed.emit()
	(root_ctx.find_child("MenuButton", true, false) as Button).pressed.emit()
	assert_array(names).contains_exactly([&"game", &"menu"])
	var contexts: Array[Node] = _contexts(root_ctx)
	assert_int(contexts.size()).is_equal(1)
	assert_bool(contexts[0] is MenuContext).is_true()


func test_game_context_loads_chapter_map_by_current_chapter() -> void:
	var state: GameState = GameState.new()
	state.current_chapter = 1
	var game: GameContext = (load(GAME_SCENE) as PackedScene).instantiate() as GameContext
	game.bind_services(state, AccessibilitySettings.new())
	add_child(game)
	auto_free(game)
	assert_int(state.map_state.regions.size()).is_equal(6)
	assert_object(state.map_state.get_region(&"otuken")).is_not_null()


func test_chapter_map_path_follows_chapter_id() -> void:
	assert_str(GameContext.CHAPTER_MAP_PATH_FORMAT % 1).is_equal("res://features/grid/data/chapter_1_map.tres")
	assert_bool(ResourceLoader.exists(GameContext.CHAPTER_MAP_PATH_FORMAT % 1)).is_true()
