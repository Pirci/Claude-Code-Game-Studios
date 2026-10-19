extends GdUnitTestSuite
## Başlangıç klavye odağı — C-25: ekran açılışında birincil kontrol gizli odak alır;
## ilk gezinme/onay tuşu odağı taşımadan ve butona basmadan görünür yapar.


const MENU_SCENE: String = "res://contexts/menu_context/menu_context.tscn"
const GAME_SCENE: String = "res://contexts/game_context/game_context.tscn"
const SETTINGS_SCENE: String = "res://ui/screens/settings_screen.tscn"
const ROOT_SCENE: String = "res://contexts/root_context/root_context.tscn"


func _action(action: StringName) -> InputEventAction:
	var ev: InputEventAction = InputEventAction.new()
	ev.action = action
	ev.pressed = true
	return ev


func _two_buttons() -> Array[Button]:
	var box: VBoxContainer = auto_free(VBoxContainer.new()) as VBoxContainer
	add_child(box)
	var a: Button = Button.new()
	var b: Button = Button.new()
	box.add_child(a)
	box.add_child(b)
	return [a, b] as Array[Button]


func _is_hidden_focus(control: Control) -> bool:
	return control.has_focus() and not control.has_focus(true)


func test_focus_quietly_gives_hidden_focus() -> void:
	var buttons: Array[Button] = _two_buttons()
	FocusReveal.focus_quietly(buttons[0])
	assert_bool(_is_hidden_focus(buttons[0])).is_true()


func test_first_navigation_reveals_without_moving() -> void:
	var buttons: Array[Button] = _two_buttons()
	FocusReveal.focus_quietly(buttons[0])
	assert_bool(FocusReveal.reveal_on_navigation(get_viewport(), _action(&"ui_down"))).is_true()
	assert_bool(buttons[0].has_focus(true)).is_true()
	assert_bool(buttons[1].has_focus()).is_false()


func test_visible_focus_navigates_normally() -> void:
	var buttons: Array[Button] = _two_buttons()
	buttons[0].grab_focus()
	assert_bool(FocusReveal.reveal_on_navigation(get_viewport(), _action(&"ui_down"))).is_false()


func test_non_navigation_input_is_ignored() -> void:
	var buttons: Array[Button] = _two_buttons()
	FocusReveal.focus_quietly(buttons[0])
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_A
	key.pressed = true
	assert_bool(FocusReveal.reveal_on_navigation(get_viewport(), key)).is_false()


func test_menu_opens_with_hidden_focus_on_new_campaign() -> void:
	var menu: MenuContext = auto_free((load(MENU_SCENE) as PackedScene).instantiate()) as MenuContext
	add_child(menu)
	assert_bool(_is_hidden_focus(menu.find_child("NewCampaignButton", true, false) as Control)).is_true()


func test_game_opens_with_hidden_focus_on_end_turn() -> void:
	var game: GameContext = (load(GAME_SCENE) as PackedScene).instantiate() as GameContext
	game.bind_services(GameState.new(), AccessibilitySettings.new())
	add_child(game)
	auto_free(game)
	assert_bool(_is_hidden_focus(game.find_child("EndTurnButton", true, false) as Control)).is_true()


func test_settings_opens_with_hidden_focus_on_language() -> void:
	var screen: SettingsScreen = auto_free((load(SETTINGS_SCENE) as PackedScene).instantiate()) as SettingsScreen
	add_child(screen)
	assert_bool(_is_hidden_focus(screen.find_child("LanguageOption", true, false) as Control)).is_true()


func test_root_context_accept_reveals_instead_of_pressing() -> void:
	var root_ctx: RootContext = auto_free((load(ROOT_SCENE) as PackedScene).instantiate()) as RootContext
	add_child(root_ctx)
	var started: Array[bool] = [false]
	root_ctx.context_changed.connect(func(name: StringName) -> void: started[0] = started[0] or name == &"game")
	var new_campaign: Control = root_ctx.find_child("NewCampaignButton", true, false) as Control
	get_viewport().push_input(_action(&"ui_accept"))
	assert_bool(started[0]).is_false()
	assert_bool(new_campaign.has_focus(true)).is_true()
