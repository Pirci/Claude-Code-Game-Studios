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
## Her dilin adı kendi pixel fontuyla önceden çizilmiş görsel olarak gösterilir
## (tools/asset-pipeline/generate_language_name_icons.gd). Tek tema fontu tüm
## alfabeleri native boyutta çizemez (ör. "العربية" Unifont 16px, liste 12px).
const LOCALE_NAME_ICON_PATH: String = "res://assets/art/ui/theme/lang_name_%s.png"


var _accessibility: AccessibilitySettings = null

@onready var _language_option: OptionButton = %LanguageOption
@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _fullscreen_check: CheckButton = %FullscreenCheck
@onready var _color_blind_check: CheckButton = %ColorBlindCheck
@onready var _reduce_motion_check: CheckButton = %ReduceMotionCheck
@onready var _region_names_check: CheckButton = %RegionNamesCheck
@onready var _back_button: Button = %BackButton


## Erişilebilirlik anahtarlarının okuyup yazacağı tercihler (null ise anahtarlar gizlenir).
func bind_services(accessibility: AccessibilitySettings) -> void:
	_accessibility = accessibility


func _ready() -> void:
	_setup_language_options()
	_setup_audio_sliders()
	_setup_fullscreen()
	_setup_accessibility()

	_language_option.item_selected.connect(_on_language_selected)
	_master_slider.value_changed.connect(_on_master_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_color_blind_check.toggled.connect(_on_color_blind_toggled)
	_reduce_motion_check.toggled.connect(_on_reduce_motion_toggled)
	_region_names_check.toggled.connect(_on_region_names_toggled)
	_back_button.pressed.connect(_on_back_pressed)


func _setup_language_options() -> void:
	_language_option.clear()
	var current_locale: String = TranslationServer.get_locale()
	var selected_index: int = 0

	for i: int in LOCALES.size():
		var locale: Dictionary = LOCALES[i]
		var code: String = locale["code"] as String
		var icon_path: String = LOCALE_NAME_ICON_PATH % code
		if ResourceLoader.exists(icon_path):
			_language_option.add_icon_item(load(icon_path) as Texture2D, "", i)
		else:
			_language_option.add_item(locale["name"] as String, i)
		if current_locale.begins_with(code):
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


func _setup_accessibility() -> void:
	var enabled: bool = _accessibility != null
	for check: CheckButton in [_color_blind_check, _reduce_motion_check, _region_names_check]:
		check.disabled = not enabled
	if not enabled:
		return
	_color_blind_check.button_pressed = _accessibility.color_blind_mode
	_reduce_motion_check.button_pressed = _accessibility.reduce_motion
	_region_names_check.button_pressed = _accessibility.show_region_names


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


func _on_color_blind_toggled(enabled: bool) -> void:
	_accessibility.color_blind_mode = enabled


func _on_reduce_motion_toggled(enabled: bool) -> void:
	_accessibility.reduce_motion = enabled


func _on_region_names_toggled(enabled: bool) -> void:
	_accessibility.show_region_names = enabled


func _on_back_pressed() -> void:
	back_requested.emit()
