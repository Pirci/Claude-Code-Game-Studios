extends GdUnitTestSuite
## Lütuf modalı M2 (C-81; ux/boon-selection.md §6, AC7, AC12): yığın satırı `×N/MAX` / `(son)` / `×N`,
## `Kalan` ayrı etiket, tavana ulaşmış lütuf kartta yok, havuz < 3'te tekrarlı kartlar birleşik.


const CATALOG: BoonCatalog = preload("res://features/bozkurt/data/boon_catalog.tres")
const LRI: String = "\u2066"
const PDI: String = "\u2069"


func before_test() -> void:
	TranslationServer.set_locale("en")


func _plain(text: String) -> String:
	return text.replace(LRI, "").replace(PDI, "")


func _text(node: Node, node_name: String) -> String:
	var label: Label = node.find_child(node_name, true, false) as Label
	return label.text if label != null and label.visible else ""


func _boons(ids: Array[StringName]) -> Array[BoonDefinition]:
	var boons: Array[BoonDefinition] = []
	for boon_id: StringName in ids:
		boons.append(CATALOG.get_boon(boon_id))
	return boons


func test_boon_stack_text_rules() -> void:
	assert_str(_plain(BoonOfferModal.stack_text(0, 3))).is_equal("×1/3")  # ilk alım, sonraki yığın
	assert_str(_plain(BoonOfferModal.stack_text(1, 3))).is_equal("×2/3")
	assert_str(_plain(BoonOfferModal.stack_text(2, 3))).is_equal("×3/3 (last)")
	assert_str(BoonOfferModal.stack_text(0, 0)).is_empty()  # sınırsız, ilk alım: satır yok
	assert_str(_plain(BoonOfferModal.stack_text(1, 0))).is_equal("×2")
	assert_bool(BoonOfferModal.stack_text(0, 3).begins_with(LRI)).is_true()  # Arapçada sona kaymaz
	TranslationServer.set_locale("tr")
	assert_str(_plain(BoonOfferModal.stack_text(2, 3))).is_equal("×3/3 (son)")


func test_boon_modal_stack_rows_remaining_and_merged_cards() -> void:
	var modal: BoonOfferModal = auto_free(BoonOfferModal.new()) as BoonOfferModal
	add_child(modal)
	modal.show_offer(_boons([&"gok_kalkani", &"bereket", &"arinma_ustaligi"]), 36, 30, false,
		{&"gok_kalkani": 2, &"bereket": 1})
	assert_str(_plain(_text(modal.find_child("Card0", true, false), "StackLabel"))).is_equal("×3/3 (last)")
	assert_str(_plain(_text(modal.find_child("Card1", true, false), "StackLabel"))).is_equal("×2")
	assert_str(_text(modal.find_child("Card2", true, false), "StackLabel")).is_empty()
	assert_str(_text(modal, "SpiritLabel")).is_equal("Spirit: 36")
	assert_str(_text(modal, "RemainingLabel")).is_equal("Left: 6")
	assert_str(_text(modal, "CostLabel")).not_contains("→")
	# Havuz < 3: aynı lütuf üç slotta → tek kart; Enter onu seçer.
	modal.show_offer(_boons([&"bereket", &"bereket", &"bereket"]), 40, 30, false)
	await await_idle_frame()
	assert_int(modal.find_children("Card*", "BoonCard", true, false).size()).is_equal(1)
	var picked: Array[StringName] = []
	modal.boon_picked.connect(func(boon_id: StringName) -> void: picked.append(boon_id))
	var card: BoonCard = modal.get_focus_target() as BoonCard
	card.grab_focus()
	var enter: InputEventAction = InputEventAction.new()
	enter.action = &"ui_accept"
	enter.pressed = true
	get_viewport().push_input(enter)
	var release: InputEventAction = InputEventAction.new()
	release.action = &"ui_accept"
	get_viewport().push_input(release)  # düğme bırakışta tetiklenir (BUTTON_RELEASE)
	await await_idle_frame()
	assert_array(picked).is_equal([&"bereket"])


# Gerçek yol: GameContext yığın sayısını ModifierController'dan geçirir; 3 yığındaki lütuf kartta yok.
func test_game_context_passes_stacks_and_hides_capped_boon() -> void:
	var state: GameState = GameState.new()
	var game: GameContext = (load("res://contexts/game_context/game_context.tscn") as PackedScene).instantiate() as GameContext
	game.bind_services(state, AccessibilitySettings.new())
	add_child(game)
	auto_free(game)
	var spirit: SpiritController = game.get("_spirit") as SpiritController
	state.ruh = 1000
	assert_bool(spirit.pick_boon(1, &"gok_kalkani") or spirit.pick_boon(1, &"bereket")).is_true()
	# Gök Kalkanı'nı iki yığına çıkar (sunumda yoksa doğrudan seçim listesine ekleyerek kur).
	var modifiers: ModifierController = game.get("_modifiers") as ModifierController
	state.boons.assign([&"gok_kalkani", &"gok_kalkani"])
	spirit.rebuild_boon_modifiers()
	assert_int(modifiers.stacks_of(&"boon:gok_kalkani")).is_equal(2)
	var expected: String = ""
	for boon: BoonDefinition in spirit.current_offer(1):
		if boon.boon_id == &"gok_kalkani":
			expected = "×3/3 (last)"
	game.call("_on_kok_bori_pressed")
	var modal: Node = game.find_child("BoonOfferModal", true, false)
	assert_object(modal).is_not_null()
	var found: String = ""
	for card: Node in modal.find_children("Card*", "BoonCard", true, false):
		if (card.find_child("NameLabel", true, false) as Label).text == tr("BOON_GOK_KALKANI"):
			found = _plain(_text(card, "StackLabel"))
	assert_str(found).is_equal(expected)
	# 3. yığından sonra Gök Kalkanı hiçbir kartta yok (AC7, §3.5).
	state.boons.append(&"gok_kalkani")
	spirit.rebuild_boon_modifiers()
	for boon: BoonDefinition in spirit.current_offer(1):
		assert_str(String(boon.boon_id)).is_not_equal("gok_kalkani")
	assert_int(state.ruh).is_greater(0)  # AC12: modal durum yazmadı (yalnız seçim yazar)


# AC9: en kötü durum (üç yığın satırı, uzun kart metni) ru'da bütçeyi aşar → söz gizlenir, panel ≤ 281;
# kısa dilde (zh) söz görünür kalır. Yeni sunumda söz yeniden denenir.
func test_boon_modal_hides_offer_line_only_when_over_height_budget() -> void:
	var boons: Array[BoonDefinition] = _boons([&"gok_kalkani", &"kurt_gucu", &"arinma_ustaligi"])
	var stacks: Dictionary = {&"gok_kalkani": 2, &"arinma_ustaligi": 1}
	for case: Array in [["ru", true], ["zh", false]]:
		TranslationServer.set_locale(case[0] as String)
		var modal: BoonOfferModal = auto_free(BoonOfferModal.new()) as BoonOfferModal
		modal.show_offer(boons, 136, 90, false, stacks)
		add_child(modal)
		await await_idle_frame()
		await await_idle_frame()
		assert_bool(modal.is_offer_line_hidden()).override_failure_message(case[0] as String).is_equal(case[1] as bool)
		assert_float(modal.get_combined_minimum_size().y).is_less_equal(float(BoonOfferModal.MAX_HEIGHT))
