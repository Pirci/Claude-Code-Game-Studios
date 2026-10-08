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


func test_hover_changes_outline_not_fill() -> void:
	var node: RegionNode = _node(RegionData.Owner.PLAYER)
	node._on_mouse_entered()
	assert_object(node.get_outline_color()).is_equal(RegionNode.COLOR_HOVER_OUTLINE)
	assert_str(node.get_fill_color().to_html(false)).is_equal("47a3e8")
	node._on_mouse_exited()
	assert_str(node.get_outline_color().to_html(false)).is_equal("2e7ab8")


func test_selected_outline_is_gold_and_overrides_hover() -> void:
	var node: RegionNode = _node(RegionData.Owner.NEUTRAL)
	node._on_mouse_entered()
	node.is_selected = true
	assert_str(node.get_outline_color().to_html(false)).is_equal("edc76b")
	assert_str(node.get_fill_color().to_html(false)).is_equal("6b655a")


func test_owner_change_updates_fill() -> void:
	var node: RegionNode = _node(RegionData.Owner.NEUTRAL)
	var data: RegionData = RegionData.new()
	data.owner = RegionData.Owner.PLAYER
	node.update_display(data)
	assert_str(node.get_fill_color().to_html(false)).is_equal("47a3e8")
