extends GdUnitTestSuite
## Lütuf kartı ikonu ve İlahi panel çerçevesi — ux/boon-selection.md §6, art bible §7 "İlahi" (C-46 / C-67).


const CATALOG: BoonCatalog = preload("res://features/bozkurt/data/boon_catalog.tres")
## M1 + M2 havuzundaki lütufların hepsinin ikonu var (Sürü Kutsaması / Yiğit Ruhu kilitli, sonra).
const ICONED_BOONS: Array[StringName] = [&"arinma_ustaligi", &"bereket", &"gok_kalkani", &"kurt_gucu", &"demir_post"]


func _boon(boon_id: StringName) -> BoonDefinition:
	for boon: BoonDefinition in CATALOG.boons:
		if boon.boon_id == boon_id:
			return boon
	return null


func _card(icon: Texture2D) -> BoonCard:
	var card: BoonCard = auto_free(BoonCard.new()) as BoonCard
	add_child(card)
	card.set_texts("Bereket", "Turn income +1 gold.")
	card.set_icon(icon)
	return card


func test_boon_icons_m1_m2_boons_have_24px_icons() -> void:
	for boon_id: StringName in ICONED_BOONS:
		var boon: BoonDefinition = _boon(boon_id)
		assert_object(boon).is_not_null()
		assert_object(boon.icon).override_failure_message("%s ikonsuz" % boon_id).is_not_null()
		assert_object(boon.icon.get_size()).is_equal(Vector2(BoonCard.ICON_SIZE, BoonCard.ICON_SIZE))


func test_boon_icons_card_shows_icon_left_of_name_and_narrows_name() -> void:
	var card: BoonCard = _card(_boon(&"bereket").icon)
	var icon: TextureRect = card.find_child("Icon", true, false) as TextureRect
	var name_label: Label = card.find_child("NameLabel", true, false) as Label
	assert_bool(icon.visible).is_true()
	assert_int(icon.get_index()).is_less(name_label.get_index())
	assert_float(name_label.custom_minimum_size.x).is_equal(
		float(BoonCard.CARD_WIDTH - 2 * BoonCard.PADDING - BoonCard.ICON_SIZE - BoonCard.ICON_GAP))


func test_boon_icons_long_single_word_stacks_icon_above_full_width_name() -> void:
	var card: BoonCard = auto_free(BoonCard.new()) as BoonCard
	add_child(card)
	card.set_icon(_boon(&"gok_kalkani").icon)
	card.set_texts("Himmelsschild", "Erlik breitet sich langsamer aus.")
	assert_bool(card.is_icon_stacked()).is_true()
	assert_float((card.find_child("NameLabel", true, false) as Label).custom_minimum_size.x).is_equal(
		float(BoonCard.CARD_WIDTH - 2 * BoonCard.PADDING))


func test_boon_icons_card_without_icon_uses_full_name_width() -> void:
	var card: BoonCard = _card(null)
	assert_bool((card.find_child("Icon", true, false) as TextureRect).visible).is_false()
	assert_float((card.find_child("NameLabel", true, false) as Label).custom_minimum_size.x).is_equal(
		float(BoonCard.CARD_WIDTH - 2 * BoonCard.PADDING))


func test_boon_icons_divine_panel_uses_tunduk_frame_texture() -> void:
	var style: StyleBoxTexture = ThemeDB.get_project_theme().get_stylebox(&"panel", &"DivinePanel") as StyleBoxTexture
	assert_object(style).is_not_null()
	assert_str(style.texture.resource_path).is_equal("res://assets/art/ui/theme/frame_divine.png")
	assert_float(style.texture_margin_left).is_equal(7.0)
