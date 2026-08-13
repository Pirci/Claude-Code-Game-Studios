class_name SettingsScreen
extends Control


signal back_requested


const LOCALES: Array[Dictionary] = [
	{"code": "en", "name": "English"},
	{"code": "tr", "name": "Türkçe"},
	{"code": "de", "name": "Deutsch"},
	{"code": "fr", "name": "Français"},
	{"code": "es", "name": "Español"},
	{"code": "zh", "name": "中文"},
	{"code": "ja", "name": "日本語"},
	{"code": "ko", "name": "한국어"},
	{"code": "ru", "name": "Русский"},
	{"code": "pt", "name": "Português"},
	{"code": "ar", "name": "العربية"},
]


@onready var _language_option: OptionButton = %LanguageOption
@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _fullscreen_check: CheckButton = %FullscreenCheck
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_setup_language_options()
	_setup_audio_sliders()
	_setup_fullscreen()

	_language_option.item_selected.connect(_on_language_selected)
	_master_slider.value_changed.connect(_on_master_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_back_button.pressed.connect(_on_back_pressed)


func _setup_language_options() -> void:
	_language_option.clear()
	var current_locale: String = TranslationServer.get_locale()
	var selected_index: int = 0

	for i: int in LOCALES.size():
		var locale: Dictionary = LOCALES[i]
		_language_option.add_item(locale["name"] as String, i)
		if current_locale.begins_with(locale["code"] as String):
			selected_index = i

	_language_option.selected = selected_index


func _setup_audio_sliders() -> void:
	_master_slider.min_value = 0.0
	_master_slider.max_value = 1.0
	_master_slider.step = 0.05
	_master_slider.value = _get_bus_volume("Master")

	_music_slider.min_value = 0.0
	_music_slider.max_value = 1.0
	_music_slider.step = 0.05
	_music_slider.value = _get_bus_volume("Music")

	_sfx_slider.min_value = 0.0
	_sfx_slider.max_value = 1.0
	_sfx_slider.step = 0.05
	_sfx_slider.value = _get_bus_volume("SFX")


func _setup_fullscreen() -> void:
	var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	_fullscreen_check.button_pressed = (mode == DisplayServer.WINDOW_MODE_FULLSCREEN)


func _get_bus_volume(bus_name: String) -> float:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return 1.0
	return db_to_linear(AudioServer.get_bus_volume_db(bus_index))


func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_value))


func _on_language_selected(index: int) -> void:
	var locale_code: String = LOCALES[index]["code"] as String
	TranslationServer.set_locale(locale_code)


func _on_master_changed(value: float) -> void:
	_set_bus_volume("Master", value)


func _on_music_changed(value: float) -> void:
	_set_bus_volume("Music", value)


func _on_sfx_changed(value: float) -> void:
	_set_bus_volume("SFX", value)


func _on_fullscreen_toggled(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_back_pressed() -> void:
	back_requested.emit()
