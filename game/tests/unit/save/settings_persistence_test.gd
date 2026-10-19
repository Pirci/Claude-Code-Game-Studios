extends GdUnitTestSuite
## Ayar kalıcılığı — ADR-0007 "Settings persistence" (C-65).


const ROOT_SCENE: String = "res://contexts/root_context/root_context.tscn"

var _saved_locale: String = ""


func before_test() -> void:
	_saved_locale = TranslationServer.get_locale()


func after_test() -> void:
	TranslationServer.set_locale(_saved_locale)


func _snapshot() -> SettingsSnapshot:
	var s: SettingsSnapshot = SettingsSnapshot.new()
	s.color_blind_mode = true
	s.reduce_motion = true
	s.show_region_names = false
	s.locale = "de"
	s.master_volume = 0.5
	s.music_volume = 0.25
	s.sfx_volume = 0.75
	return s


func test_round_trip() -> void:
	var loaded: SettingsSnapshot = SettingsSerializer.from_text(SettingsSerializer.to_text(_snapshot()))
	assert_object(loaded).is_not_null()
	assert_bool(loaded.color_blind_mode).is_true()
	assert_bool(loaded.reduce_motion).is_true()
	assert_bool(loaded.show_region_names).is_false()
	assert_str(loaded.locale).is_equal("de")
	assert_float(loaded.music_volume).is_equal_approx(0.25, 0.0001)


func test_invalid_settings_fall_back_to_defaults() -> void:
	var good: String = SettingsSerializer.to_text(_snapshot())
	for bad: String in ["", "{", "[]", good.replace("\"de\"", "\"xx\""), good.replace("0.25", "7"),
			good.replace("\"schema_version\": 1", "\"schema_version\": 99")]:
		assert_object(SettingsSerializer.from_text(bad)).override_failure_message(bad.left(40)).is_null()


func test_controller_prefers_first_valid_candidate() -> void:
	var store: MemorySaveStore = MemorySaveStore.new()
	store.set_candidates(SaveController.SETTINGS_SLOT, PackedStringArray(["{", SettingsSerializer.to_text(_snapshot())]))
	var c: SaveController = SaveController.new()
	c.bind_services(store, Callable())
	assert_str(c.load_settings().locale).is_equal("de")


func test_root_applies_saved_settings_before_ui() -> void:
	var store: MemorySaveStore = MemorySaveStore.new()
	store.write(SaveController.SETTINGS_SLOT, SettingsSerializer.to_text(_snapshot()))
	var root_ctx: RootContext = auto_free((load(ROOT_SCENE) as PackedScene).instantiate()) as RootContext
	root_ctx.save_store = store
	add_child(root_ctx)
	var accessibility: AccessibilitySettings = root_ctx.get("_accessibility") as AccessibilitySettings
	assert_bool(accessibility.color_blind_mode).is_true()
	assert_bool(accessibility.reduce_motion).is_true()
	assert_str(TranslationServer.get_locale()).starts_with("de")
	assert_float(AudioController.get_bus_linear(AudioController.MUSIC_BUS)).is_equal_approx(0.25, 0.01)
	# Diğer testleri etkilememek için sesleri geri al.
	for bus: StringName in [&"Master", AudioController.MUSIC_BUS, AudioController.SFX_BUS]:
		AudioController.set_bus_linear(bus, 1.0)


func test_changing_a_setting_writes_the_settings_file() -> void:
	var store: MemorySaveStore = MemorySaveStore.new()
	var root_ctx: RootContext = auto_free((load(ROOT_SCENE) as PackedScene).instantiate()) as RootContext
	root_ctx.save_store = store
	add_child(root_ctx)
	(root_ctx.find_child("SettingsButton", true, false) as Button).pressed.emit()
	var check: CheckButton = root_ctx.find_child("ColorBlindCheck", true, false) as CheckButton
	check.button_pressed = true
	var saved: PackedStringArray = store.read_candidates(SaveController.SETTINGS_SLOT)
	assert_int(saved.size()).is_greater(0)
	assert_bool(SettingsSerializer.from_text(saved[0]).color_blind_mode).is_true()
