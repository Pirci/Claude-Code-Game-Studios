extends GdUnitTestSuite
## RegionNode renk testleri — art bible §4 "Sahiplik Renkleri".


func _node(owner: RegionData.Owner) -> RegionNode:
	var data: RegionData = RegionData.new()
	data.region_id = &"r"
	data.owner = owner
	data.polygon_points = PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10)])
	var node: RegionNode = auto_free(RegionNode.new()) as RegionNode
	node.setup(data)
	return node


func test_owner_fill_matches_art_bible_main_tone() -> void:
	assert_str(_node(RegionData.Owner.PLAYER).get_fill_color().to_html(false)).is_equal("47a3e8")
	assert_str(_node(RegionData.Owner.ENEMY).get_fill_color().to_html(false)).is_equal("c45a2a")
	assert_str(_node(RegionData.Owner.NEUTRAL).get_fill_color().to_html(false)).is_equal("6b655a")


func test_all_ramp_tones_are_opaque() -> void:
	for owner: RegionData.Owner in [RegionData.Owner.PLAYER, RegionData.Owner.ENEMY, RegionData.Owner.NEUTRAL]:
		var ramp: PackedColorArray = RegionNode.get_owner_ramp(owner)
		assert_int(ramp.size()).is_equal(3)
		for c: Color in ramp:
			assert_float(c.a).is_equal(1.0)


func test_default_outline_is_dark_ramp_tone() -> void:
	var node: RegionNode = _node(RegionData.Owner.ENEMY)
	assert_str(node.get_outline_color().to_html(false)).is_equal("9a4220")


func test_hover_outline_is_gold_and_fill_unchanged() -> void:
	var node: RegionNode = _node(RegionData.Owner.PLAYER)
	node._on_mouse_entered()
	assert_str(node.get_outline_color().to_html(false)).is_equal("edc76b")
	assert_str(node.get_fill_color().to_html(false)).is_equal("47a3e8")
	node._on_mouse_exited()
	assert_str(node.get_outline_color().to_html(false)).is_equal("2e7ab8")


func test_selected_outline_is_gold_and_fill_unchanged() -> void:
	var node: RegionNode = _node(RegionData.Owner.NEUTRAL)
	node.is_selected = true
	assert_str(node.get_outline_color().to_html(false)).is_equal("edc76b")
	assert_str(node.get_fill_color().to_html(false)).is_equal("6b655a")


func test_owner_change_updates_fill() -> void:
	var node: RegionNode = _node(RegionData.Owner.NEUTRAL)
	var data: RegionData = RegionData.new()
	data.owner = RegionData.Owner.PLAYER
	node.update_display(data)
	assert_str(node.get_fill_color().to_html(false)).is_equal("47a3e8")


func test_map_labels_use_map_label_variation_and_ellipsis() -> void:
	var labels: Array[Node] = _node(RegionData.Owner.PLAYER).find_children("*", "Label", false, false)
	assert_int(labels.size()).is_equal(2)
	for node: Node in labels:
		var label: Label = node as Label
		assert_str(String(label.theme_type_variation)).is_equal(String(RegionNode.MAP_LABEL_VARIATION))
		assert_int(label.text_overrun_behavior).is_equal(TextServer.OVERRUN_TRIM_ELLIPSIS)


func test_map_label_theme_is_cream_with_dark_1px_outline() -> void:
	var theme: Theme = load("res://assets/fonts/default_theme.tres") as Theme
	var v: StringName = RegionNode.MAP_LABEL_VARIATION
	assert_str(theme.get_color(&"font_color", v).to_html(false)).is_equal("f2e6c7")
	assert_str(theme.get_color(&"font_outline_color", v).to_html(false)).is_equal("1c170f")
	# outline_size çap gibi davranır: 2 → her yönde 1px.
	assert_int(theme.get_constant(&"outline_size", v)).is_equal(2)


func test_diamond_rows_form_5x5_diamond_for_radius_2() -> void:
	var rows: Array[Rect2i] = RegionNode.diamond_rows(Vector2i(10, 20), 2)
	assert_array(rows).is_equal([
		Rect2i(10, 18, 1, 1), Rect2i(9, 19, 3, 1), Rect2i(8, 20, 5, 1),
		Rect2i(9, 21, 3, 1), Rect2i(10, 22, 1, 1),
	] as Array[Rect2i])


func test_selection_mark_is_2px_radius() -> void:
	# Art bible §4: "köşelerde 2px ◆".
	assert_int(RegionNode.SELECTION_MARK_RADIUS).is_equal(2)


func _tamga_texture() -> Texture2D:
	return load(TamgaLibrary.texture_path(&"oguz")) as Texture2D


func test_tamga_hidden_until_selected() -> void:
	var node: RegionNode = _node(RegionData.Owner.PLAYER)
	node.set_tamga(_tamga_texture())
	assert_bool(node.is_tamga_visible()).is_false()
	node._on_mouse_entered()
	assert_bool(node.is_tamga_visible()).is_false()
	node.is_selected = true
	assert_bool(node.is_tamga_visible()).is_true()


func test_colour_blind_mode_always_shows_tamga() -> void:
	var node: RegionNode = _node(RegionData.Owner.ENEMY)
	node.set_tamga(_tamga_texture())
	node.show_tamga_always = true
	assert_bool(node.is_tamga_visible()).is_true()


func test_region_without_tamga_never_shows_one() -> void:
	var node: RegionNode = _node(RegionData.Owner.NEUTRAL)
	node.set_tamga(null)
	node.is_selected = true
	node.show_tamga_always = true
	assert_bool(node.is_tamga_visible()).is_false()


func test_tamga_sits_centred_below_army_label() -> void:
	var data: RegionData = RegionData.new()
	data.owner = RegionData.Owner.PLAYER
	data.position = Vector2(288, 150)
	data.polygon_points = PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10)])
	var node: RegionNode = auto_free(RegionNode.new()) as RegionNode
	node.setup(data)
	node.set_tamga(_tamga_texture())
	var sprite: Sprite2D = node.find_children("*", "Sprite2D", false, false)[0] as Sprite2D
	# 9×9: sütun 284..292 → merkez 288; üst = 150 + 16 + TAMGA_GAP(0).
	assert_vector(sprite.position).is_equal(Vector2(284, 166))
