extends GdUnitTestSuite
## Erişilebilirlik ayarları — art bible §7 "Erişilebilirlik Ayarları (zorunlu)".


const SETTINGS_SCENE: String = "res://ui/screens/settings_screen.tscn"
const CHAPTER_1: String = "res://features/grid/data/chapter_1_map.tres"
const LOCALES: PackedStringArray = ["en", "tr", "de", "fr", "es", "zh", "ja", "ko", "ru", "pt", "ar"]
const KEYS: PackedStringArray = ["COLOR_BLIND_MODE", "REDUCE_MOTION", "SHOW_REGION_NAMES"]


func _settings_screen(settings: AccessibilitySettings) -> SettingsScreen:
	var screen: SettingsScreen = (load(SETTINGS_SCENE) as PackedScene).instantiate() as SettingsScreen
	screen.bind_services(settings)
	add_child(screen)
	auto_free(screen)
	return screen


func _check(screen: SettingsScreen, name: String) -> CheckButton:
	return screen.find_child(name, true, false) as CheckButton


func test_defaults_match_art_bible() -> void:
	var s: AccessibilitySettings = AccessibilitySettings.new()
	assert_bool(s.color_blind_mode).is_false()
	assert_bool(s.reduce_motion).is_false()
	# "Bölge Adlarını Göster/Gizle — Varsayılan: göster"
	assert_bool(s.show_region_names).is_true()


func test_settings_screen_reflects_and_writes_preferences() -> void:
	var s: AccessibilitySettings = AccessibilitySettings.new()
	s.reduce_motion = true
	var screen: SettingsScreen = _settings_screen(s)
	assert_bool(_check(screen, "ReduceMotionCheck").button_pressed).is_true()
	assert_bool(_check(screen, "RegionNamesCheck").button_pressed).is_true()
	_check(screen, "ColorBlindCheck").button_pressed = true
	_check(screen, "RegionNamesCheck").button_pressed = false
	_check(screen, "ReduceMotionCheck").button_pressed = false
	assert_bool(s.color_blind_mode).is_true()
	assert_bool(s.show_region_names).is_false()
	assert_bool(s.reduce_motion).is_false()


func test_settings_screen_without_preferences_disables_toggles() -> void:
	var screen: SettingsScreen = _settings_screen(null)
	for name: String in ["ColorBlindCheck", "ReduceMotionCheck", "RegionNamesCheck"]:
		assert_bool(_check(screen, name).disabled).is_true()


func test_campaign_map_applies_preferences_to_every_region() -> void:
	var state: MapState = (load(CHAPTER_1) as ChapterMapDefinition).create_map_state()
	var map: CampaignMap = auto_free(CampaignMap.new()) as CampaignMap
	add_child(map)
	map.build_map(state)
	var s: AccessibilitySettings = AccessibilitySettings.new()
	s.color_blind_mode = true
	s.show_region_names = false
	map.apply_accessibility(s)
	var regions: int = 0
	for node: Node in map.get_children():
		var region: RegionNode = node as RegionNode
		if region == null:
			continue
		regions += 1
		assert_bool(region.color_blind_mode).is_true()
		assert_bool(region.show_name_label).is_false()
	assert_int(regions).is_equal(state.regions.size())


func test_translation_keys_exist_in_all_languages() -> void:
	for locale: String in LOCALES:
		var translation: Translation = TranslationServer.get_translation_object(locale)
		assert_object(translation).override_failure_message(locale).is_not_null()
		for key: String in KEYS:
			var text: String = String(translation.get_message(key))
			assert_str(text).override_failure_message("%s/%s" % [locale, key]).is_not_empty()
			assert_str(text).override_failure_message("%s/%s untranslated" % [locale, key]).is_not_equal(key)
