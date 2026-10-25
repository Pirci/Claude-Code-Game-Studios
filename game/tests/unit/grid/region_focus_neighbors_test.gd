extends GdUnitTestSuite
## Klavyeyle bölge seçimi (C-75; hud §10.3 kural 5, A-7, B6, §5.6): ok tuşu komşulukları saf
## kuraldan, bölge odak kontrolleri, `ui_accept` ile seçim → panel, hedef seçim modu ve Esc.


const PROLOG_MAP: String = "res://features/grid/data/chapter_1_map.tres"
const R: Dictionary = {
	"left": RegionFocusRules.Side.LEFT, "right": RegionFocusRules.Side.RIGHT,
	"up": RegionFocusRules.Side.UP, "down": RegionFocusRules.Side.DOWN,
}


func before_test() -> void:
	TranslationServer.set_locale("en")


func _action(action: StringName) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


# --- Saf kural ---

func test_region_focus_rules_follow_adjacency_and_geometry() -> void:
	var centers: Dictionary = {&"c": Vector2(100, 100), &"w": Vector2(0, 100), &"e": Vector2(200, 100),
		&"n": Vector2(100, 0), &"far_e": Vector2(400, 100)}
	var adjacency: Dictionary = {&"c": [&"w", &"e", &"n"], &"w": [&"c"], &"e": [&"c"], &"n": [&"c"], &"far_e": []}
	var links: Dictionary = RegionFocusRules.neighbors(centers, adjacency)
	assert_str(String(links[&"c"][R.left])).is_equal("w")
	assert_str(String(links[&"c"][R.right])).is_equal("e")
	assert_str(String(links[&"c"][R.up])).is_equal("n")
	assert_bool((links[&"c"] as Dictionary).has(R.down)).is_false()  # aşağıda komşu yok → giriş yok
	assert_bool((links[&"far_e"] as Dictionary).is_empty()).is_true()  # komşusuz bölge (komşu olmayan yakın bölgeye gitmez)


func test_region_focus_rules_prefer_alignment_then_distance_then_id() -> void:
	var centers: Dictionary = {&"o": Vector2.ZERO, &"diag": Vector2(100, -100), &"straight": Vector2(300, 0),
		&"b": Vector2(0, 50), &"a": Vector2(0, 50)}
	var adjacency: Dictionary = {&"o": [&"diag", &"straight", &"b", &"a"]}
	var links: Dictionary = RegionFocusRules.neighbors(centers, adjacency)
	assert_str(String(links[&"o"][R.right])).is_equal("straight")  # uzak ama tam hizalı > yakın çapraz
	assert_str(String(links[&"o"][R.down])).is_equal("a")  # aynı konum → kimlik sırası


func test_region_focus_rules_prolog_map() -> void:
	var definition: ChapterMapDefinition = load(PROLOG_MAP) as ChapterMapDefinition
	var state: MapState = definition.create_map_state()
	var centers: Dictionary = {}
	var adjacency: Dictionary = {}
	for region: RegionData in state.regions.values():
		centers[region.region_id] = region.position
		adjacency[region.region_id] = region.adjacent_regions
	var links: Dictionary = RegionFocusRules.neighbors(centers, adjacency)
	var otuken: Dictionary = links[&"otuken"]
	assert_str(String(otuken[R.left])).is_equal("bati_bozkir")
	assert_str(String(otuken[R.right])).is_equal("dogu_bozkir")
	assert_str(String(otuken[R.up])).is_equal("altai")
	assert_str(String(otuken[R.down])).is_equal("guney_vadi")
	# Her bölgeye oklarla erişilebilir (bağlı çizge).
	var seen: Dictionary = {&"otuken": true}
	var frontier: Array[StringName] = [&"otuken"]
	while not frontier.is_empty():
		var current: StringName = frontier.pop_back()
		for other: StringName in (links[current] as Dictionary).values():
			if not seen.has(other):
				seen[other] = true
				frontier.append(other)
	assert_int(seen.size()).is_equal(state.regions.size())


# --- Gerçek oyun ekranı ---

func _game() -> GameContext:
	var game: GameContext = (load("res://contexts/game_context/game_context.tscn") as PackedScene).instantiate() as GameContext
	game.bind_services(GameState.new(), AccessibilitySettings.new())
	add_child(game)
	auto_free(game)
	var m: MapState = (game.get("_game_state") as GameState).map_state
	m.get_region(&"otuken").army_count = 6
	return game


func _map(game: GameContext) -> CampaignMap:
	return game.get("_campaign_map") as CampaignMap


func _focus_owner() -> Control:
	return get_viewport().gui_get_focus_owner()


func test_region_focus_arrow_keys_move_between_neighbors() -> void:
	var game: GameContext = _game()
	var otuken: Control = _map(game).focus_target(&"otuken")
	otuken.grab_focus()
	get_viewport().push_input(_action(&"ui_right"))
	await await_idle_frame()
	assert_object(_focus_owner()).is_same(_map(game).focus_target(&"dogu_bozkir"))
	# Doğu Bozkır'ın sağında komşu yok: odak yerinde kalır (HUD'a atlamaz).
	get_viewport().push_input(_action(&"ui_right"))
	await await_idle_frame()
	assert_object(_focus_owner()).is_same(_map(game).focus_target(&"dogu_bozkir"))


func test_keyboard_turn_select_send_target_and_cancel() -> void:
	var game: GameContext = _game()
	var map: CampaignMap = _map(game)
	var m: MapState = (game.get("_game_state") as GameState).map_state
	var panel: RegionInfoPanel = game.get("_info_panel") as RegionInfoPanel
	var send: Button = panel.get_send_button()
	# Seç: odaktaki bölgede ui_accept → seçim, odak panelin ilk etkin düğmesine (Ordu Gönder).
	map.focus_target(&"otuken").grab_focus()
	map.focus_target(&"otuken")._gui_input(_action(&"ui_accept"))
	assert_str(String(m.selected_region_id)).is_equal("otuken")
	assert_object(_focus_owner()).is_same(send)
	# Panelden Esc → seçili bölgeye dön.
	game._unhandled_input(_action(&"ui_cancel"))
	assert_object(_focus_owner()).is_same(map.focus_target(&"otuken"))
	# Ordu Gönder (klavye) → hedef modu: basılı + ipucu, odak kaynak bölgede.
	send.grab_focus()
	send.pressed.emit()
	assert_bool(send.button_pressed).is_true()
	assert_bool((panel.find_child("PickTargetHint", true, false) as Label).visible).is_true()
	assert_object(_focus_owner()).is_same(map.focus_target(&"otuken"))
	# Esc → iptal: düğme normal, ipucu gizli, odak Ordu Gönder'de.
	game._unhandled_input(_action(&"ui_cancel"))
	assert_bool(game.get("_awaiting_target") as bool).is_false()
	assert_bool(send.button_pressed).is_false()
	assert_bool((panel.find_child("PickTargetHint", true, false) as Label).visible).is_false()
	assert_object(_focus_owner()).is_same(send)
	# Yeniden gönder, hedefte ui_accept → hamle (Altai'ye 5 kişi), mod kapanır.
	send.pressed.emit()
	var altai: Control = map.focus_target(&"altai")
	altai.grab_focus()
	altai._gui_input(_action(&"ui_accept"))
	assert_int(m.get_region(&"altai").owner).is_equal(RegionData.Owner.PLAYER)
	assert_bool(game.get("_awaiting_target") as bool).is_false()
	assert_bool(send.button_pressed).is_false()


func test_region_focus_outline_only_when_focus_visible() -> void:
	var game: GameContext = _game()
	var target: RegionFocusTarget = _map(game).focus_target(&"otuken") as RegionFocusTarget
	assert_int(target.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)  # tıklama Area2D'de kalır
	target.grab_focus(true)
	assert_bool(target.has_focus(true)).is_false()  # gizli odak: kontur yok (FocusReveal)
	target.grab_focus()
	assert_bool(target.has_focus(true)).is_true()


## Godot Node2D altındaki kontrolleri Tab'a kendiliğinden katmaz: Tur Bitir → bölgeler (okuma sırası).
func test_tab_enters_map_from_end_turn_in_reading_order() -> void:
	var game: GameContext = _game()
	var map: CampaignMap = _map(game)
	var end_turn: Button = game.find_child("EndTurnButton", true, false) as Button
	end_turn.grab_focus()
	var visited: Array[StringName] = []
	for i: int in 6:
		get_viewport().push_input(_action(&"ui_focus_next"))
		await await_idle_frame()
		var owner: Control = _focus_owner()
		if owner is RegionFocusTarget:
			visited.append((owner.get_parent() as RegionNode).region_id)
	assert_array(visited).contains_exactly([&"altai", &"bati_bozkir", &"otuken", &"dogu_bozkir",
		&"guney_vadi", &"sinir_bolge"])
	get_viewport().push_input(_action(&"ui_focus_next"))
	await await_idle_frame()
	assert_bool(_focus_owner() is RegionFocusTarget).is_false()  # haritadan HUD'a çıkar
	assert_object(map.focus_order()[0]).is_same(map.focus_target(&"altai"))
