extends GdUnitTestSuite
## C-26: bölge panelindeki "/ tur" birimi ayrı çeviri key'i (PER_TURN) — programatik
## büyük/küçük harf dönüşümü yok (Almancada isim büyük harf: "Runde").


const LOCALES: Array[String] = ["en", "tr", "de", "fr", "es", "zh", "ja", "ko", "ru", "pt", "ar"]

var _saved_locale: String = ""


func before_test() -> void:
	_saved_locale = TranslationServer.get_locale()


func after_test() -> void:
	TranslationServer.set_locale(_saved_locale)


func _player_region() -> RegionData:
	var region: RegionData = RegionData.new()
	region.region_id = &"otuken"
	region.display_name_key = &"REGION_OTUKEN"
	region.owner = RegionData.Owner.PLAYER
	region.army_count = 3
	region.gold_per_turn = 2
	return region


func test_per_turn_is_translated_with_one_placeholder_in_every_locale() -> void:
	for locale: String in LOCALES:
		TranslationServer.set_locale(locale)
		var text: String = tr("PER_TURN")
		assert_str(text).override_failure_message(locale).is_not_equal("PER_TURN")
		assert_int(text.count("%s")).override_failure_message(locale).is_equal(1)


func test_german_panel_keeps_noun_capitalised() -> void:
	TranslationServer.set_locale("de")
	var panel: RegionInfoPanel = auto_free(RegionInfoPanel.new()) as RegionInfoPanel
	add_child(panel)
	panel.show_region(_player_region())
	var gold_label: Label = panel.find_child("GoldLabel", true, false) as Label
	assert_str(gold_label.text).is_equal("Gold: 2 / Runde")


func test_english_panel_reads_per_turn() -> void:
	TranslationServer.set_locale("en")
	var panel: RegionInfoPanel = auto_free(RegionInfoPanel.new()) as RegionInfoPanel
	add_child(panel)
	panel.show_region(_player_region())
	var gold_label: Label = panel.find_child("GoldLabel", true, false) as Label
	assert_str(gold_label.text).is_equal("Gold: 2 / turn")
