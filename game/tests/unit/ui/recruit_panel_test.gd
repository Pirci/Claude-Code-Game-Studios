extends GdUnitTestSuite
## Bilgi paneli "Ordu Topla" bölümü — resource-system §10, AC17 (C-37).


func before_test() -> void:
	TranslationServer.set_locale("en")


func _region(owner: RegionData.Owner) -> RegionData:
	var r: RegionData = RegionData.new()
	r.region_id = &"otag"
	r.display_name_key = &"REGION_OTAG"
	r.owner = owner
	r.army_count = 5
	r.gold_per_turn = 2
	return r


func _panel() -> RegionInfoPanel:
	var panel: RegionInfoPanel = auto_free(RegionInfoPanel.new()) as RegionInfoPanel
	add_child(panel)
	panel.show_region(_region(RegionData.Owner.PLAYER))
	return panel


func _node(panel: RegionInfoPanel, node_name: String) -> Control:
	return panel.find_child(node_name, true, false) as Control


func test_recruit_panel_enabled_selector_emits_chosen_count() -> void:
	var panel: RegionInfoPanel = _panel()
	panel.show_recruit(0, 2, 2, 2, 0)
	var confirm: Button = _node(panel, "RecruitConfirm") as Button
	var plus: Button = _node(panel, "RecruitPlus") as Button
	assert_bool(confirm.disabled).is_false()
	assert_bool((_node(panel, "RecruitMinus") as Button).disabled).is_true()
	assert_bool(_node(panel, "RecruitHint").visible).is_false()
	plus.pressed.emit()
	assert_bool(plus.disabled).is_true()
	assert_str((_node(panel, "RecruitCost") as Label).text).is_equal("Cost: 4 gold")
	assert_str((_node(panel, "RecruitCap") as Label).text).is_equal("Raised: %s" % NumberFormatter.fraction(0, 2))
	var emitted: Array[int] = [0]
	panel.recruit_pressed.connect(func(_id: StringName, count: int) -> void: emitted[0] = count)
	confirm.pressed.emit()
	assert_int(emitted[0]).is_equal(2)


func test_recruit_panel_short_of_gold_shows_missing_amount() -> void:
	var panel: RegionInfoPanel = _panel()
	panel.show_recruit(0, 2, 0, 2, 1)
	assert_bool((_node(panel, "RecruitConfirm") as Button).disabled).is_true()
	var hint: Label = _node(panel, "RecruitHint") as Label
	assert_bool(hint.visible).is_true()
	assert_str(hint.text).is_equal("Need 1 more gold")


func test_recruit_panel_cap_reached_shows_cap() -> void:
	var panel: RegionInfoPanel = _panel()
	panel.show_recruit(2, 2, 0, 2, 0)
	assert_bool((_node(panel, "RecruitConfirm") as Button).disabled).is_true()
	assert_str((_node(panel, "RecruitHint") as Label).text).is_equal("Limit reached: %s" % NumberFormatter.fraction(2, 2))


func test_recruit_panel_hidden_for_foreign_region_and_focus_falls_back() -> void:
	var panel: RegionInfoPanel = _panel()
	panel.show_recruit(0, 2, 2, 2, 0)
	assert_object(panel.get_focus_target()).is_same(_node(panel, "RecruitConfirm"))
	panel.show_region(_region(RegionData.Owner.ENEMY))
	assert_bool(_node(panel, "RecruitBox").visible).is_false()
	panel.show_reinforcement(1)
	assert_str((_node(panel, "ReinforcementValue") as Label).text).is_equal("%s / turn" % NumberFormatter.ltr("+1"))
	assert_object(panel.get_focus_target()).is_null()
