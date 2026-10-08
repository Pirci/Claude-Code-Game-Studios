extends GdUnitTestSuite
## HUD panel stilleri — art bible §7 "Panel Sistemi" (HUD: #1C150D ~%70 opak, 1px #8A6D4F).


const THEME_PATH: String = "res://assets/fonts/default_theme.tres"
const GAME_SCENE_PATH: String = "res://contexts/game_context/game_context.tscn"
const HUD_ALPHA: float = 0.7


func _style(variation: StringName) -> StyleBoxFlat:
	var theme: Theme = load(THEME_PATH) as Theme
	return theme.get_stylebox(&"panel", variation) as StyleBoxFlat


func test_hud_variations_use_panel_colour_at_70_percent() -> void:
	for v: StringName in [&"HudBarTop", &"HudBarBottom", &"HudPanel"]:
		var box: StyleBoxFlat = _style(v)
		assert_object(box).is_not_null()
		assert_str(box.bg_color.to_html(false)).is_equal("1c150d")
		assert_float(box.bg_color.a).is_equal_approx(HUD_ALPHA, 0.001)
		assert_str(box.border_color.to_html(false)).is_equal("8a6d4f")
		assert_bool(box.anti_aliasing).is_false()


func test_bars_have_1px_border_only_on_map_side() -> void:
	var top: StyleBoxFlat = _style(&"HudBarTop")
	assert_array([top.border_width_left, top.border_width_top, top.border_width_right, top.border_width_bottom]).is_equal([0, 0, 0, 1])
	var bottom: StyleBoxFlat = _style(&"HudBarBottom")
	assert_array([bottom.border_width_left, bottom.border_width_top, bottom.border_width_right, bottom.border_width_bottom]).is_equal([0, 1, 0, 0])


func test_hud_panel_has_1px_border_all_sides() -> void:
	var box: StyleBoxFlat = _style(&"HudPanel")
	assert_array([box.border_width_left, box.border_width_top, box.border_width_right, box.border_width_bottom]).is_equal([1, 1, 1, 1])


func test_game_context_bars_use_hud_variations() -> void:
	var scene: Node = auto_free((load(GAME_SCENE_PATH) as PackedScene).instantiate())
	var top: PanelContainer = scene.get_node("TopBarPanel") as PanelContainer
	var bottom: PanelContainer = scene.get_node("BottomBarPanel") as PanelContainer
	assert_str(String(top.theme_type_variation)).is_equal("HudBarTop")
	assert_str(String(bottom.theme_type_variation)).is_equal("HudBarBottom")


func test_region_info_panel_uses_hud_panel() -> void:
	var panel: RegionInfoPanel = auto_free(RegionInfoPanel.new()) as RegionInfoPanel
	add_child(panel)
	assert_str(String(panel.theme_type_variation)).is_equal("HudPanel")
