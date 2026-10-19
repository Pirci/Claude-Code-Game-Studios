extends GdUnitTestSuite
## Birincil buton + modal panel çerçeveleri — art bible §3 "UI Şekil Grameri", §7 "Panel
## Sistemi" (C-21): 5×5 koçboynuzu köşe, 2px kilim şevron bandı, 9-slice StyleBoxTexture.


const THEME_PATH: String = "res://assets/fonts/default_theme.tres"
const FRAME_DIR: String = "res://assets/art/ui/theme/"
const CORNER: float = 5.0
const BORDER: String = "8a6d4f"
const CURL: String = "b8945d"
const GOLD: String = "edc76b"
const BAND_DARK: String = "3a2817"


func _theme() -> Theme:
	return load(THEME_PATH) as Theme


func _image(name: String) -> Image:
	return (load(FRAME_DIR + name + ".png") as Texture2D).get_image()


func _hex(img: Image, x: int, y: int) -> String:
	return img.get_pixel(x, y).to_html(false)


func test_primary_button_states_are_nine_slice_textures() -> void:
	var theme: Theme = _theme()
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		var box: StyleBoxTexture = theme.get_stylebox(state, &"PrimaryButton") as StyleBoxTexture
		assert_object(box).is_not_null()
		assert_object(box.texture).is_not_null()
		assert_float(box.texture_margin_left).is_equal(CORNER)
		assert_float(box.texture_margin_top).is_equal(CORNER)
		assert_float(box.texture_margin_right).is_equal(CORNER)
		assert_float(box.texture_margin_bottom).is_equal(CORNER)
	assert_str(String(theme.get_type_variation_base(&"PrimaryButton"))).is_equal("Button")


func test_primary_button_keeps_flat_button_content_margins() -> void:
	var theme: Theme = _theme()
	var normal: StyleBoxTexture = theme.get_stylebox(&"normal", &"PrimaryButton") as StyleBoxTexture
	var pressed: StyleBoxTexture = theme.get_stylebox(&"pressed", &"PrimaryButton") as StyleBoxTexture
	assert_array([normal.content_margin_left, normal.content_margin_top, normal.content_margin_right, normal.content_margin_bottom]).is_equal([6.0, 2.0, 6.0, 2.0])
	# Basılınca içerik 1px aşağı (art bible §7 "Buton").
	assert_array([pressed.content_margin_top, pressed.content_margin_bottom]).is_equal([3.0, 1.0])


func test_modal_panel_tiles_the_chevron_band() -> void:
	var theme: Theme = _theme()
	var box: StyleBoxTexture = theme.get_stylebox(&"panel", &"ModalPanel") as StyleBoxTexture
	assert_object(box).is_not_null()
	assert_float(box.texture_margin_left).is_equal(CORNER)
	assert_int(box.axis_stretch_horizontal).is_equal(StyleBoxTexture.AXIS_STRETCH_MODE_TILE)
	assert_int(box.axis_stretch_vertical).is_equal(StyleBoxTexture.AXIS_STRETCH_MODE_TILE)
	assert_str(String(theme.get_type_variation_base(&"ModalPanel"))).is_equal("PanelContainer")


func test_primary_frame_has_border_and_horn_corner() -> void:
	var normal: Image = _image("frame_primary_normal")
	assert_str(_hex(normal, 0, 0)).is_equal(BORDER)
	assert_str(_hex(normal, 1, 1)).is_equal(CURL)
	assert_str(_hex(normal, 3, 2)).is_equal(CURL)
	assert_str(_hex(normal, 2, 3)).is_equal(CURL)
	# Köşegen simetri + aynalı köşe (sağ alt).
	assert_str(_hex(normal, 14, 14)).is_equal(CURL)
	assert_str(_hex(normal, 8, 0)).is_equal(BORDER)
	var hover: Image = _image("frame_primary_hover")
	assert_str(_hex(hover, 0, 0)).is_equal(GOLD)
	assert_str(_hex(hover, 1, 1)).is_equal(GOLD)


func test_modal_frame_chevron_band_alternates() -> void:
	var img: Image = _image("frame_modal")
	assert_str(_hex(img, 9, 0)).is_equal(BORDER)
	# Dış satır periyodun ilk yarısında, iç satır ikinci yarısında yanar.
	assert_str(_hex(img, 5, 1)).is_equal(CURL)
	assert_str(_hex(img, 7, 1)).is_equal(BAND_DARK)
	assert_str(_hex(img, 5, 2)).is_equal(BAND_DARK)
	assert_str(_hex(img, 7, 2)).is_equal(CURL)
	# Dikey kenar aynı desen (sol kenar, y ekseninde).
	assert_str(_hex(img, 1, 5)).is_equal(CURL)
	assert_str(_hex(img, 2, 7)).is_equal(CURL)


func test_primary_actions_use_primary_button() -> void:
	var game: Node = auto_free((load("res://contexts/game_context/game_context.tscn") as PackedScene).instantiate())
	assert_str(String((game.get_node("BottomBarPanel/BottomBar/EndTurnButton") as Button).theme_type_variation)).is_equal("PrimaryButton")
	assert_str(String((game.get_node("BottomBarPanel/BottomBar/MenuButton") as Button).theme_type_variation)).is_equal("")
	var menu: Node = auto_free((load("res://contexts/menu_context/menu_context.tscn") as PackedScene).instantiate())
	assert_str(String((menu.get_node("MainPanel/NewCampaignButton") as Button).theme_type_variation)).is_equal("PrimaryButton")
	assert_str(String((menu.get_node("MainPanel/SettingsButton") as Button).theme_type_variation)).is_equal("")


func test_send_army_button_is_primary() -> void:
	var panel: RegionInfoPanel = auto_free(RegionInfoPanel.new()) as RegionInfoPanel
	add_child(panel)
	var region: RegionData = RegionData.new()
	region.region_id = &"r"
	region.owner = RegionData.Owner.PLAYER
	region.army_count = 3
	panel.show_region(region)
	var send: Button = panel.get_focus_target() as Button
	assert_object(send).is_not_null()
	assert_str(String(send.theme_type_variation)).is_equal("PrimaryButton")


func test_settings_screen_sits_in_modal_panel() -> void:
	var screen: Node = auto_free((load("res://ui/screens/settings_screen.tscn") as PackedScene).instantiate())
	var frame: PanelContainer = screen.get_node("Frame") as PanelContainer
	assert_str(String(frame.theme_type_variation)).is_equal("ModalPanel")
	assert_object(screen.get_node("Frame/Panel/BackButton")).is_not_null()
