class_name MenuContext
extends Control


signal new_campaign_requested
## "Devam Et": RootContext kaydı yükler (ADR-0007, C-17 D4).
signal continue_requested
signal quit_requested


const SETTINGS_SCENE: PackedScene = preload("res://ui/screens/settings_screen.tscn")

@onready var _main_panel: VBoxContainer = %MainPanel
@onready var _continue_button: Button = %ContinueButton
@onready var _new_campaign_button: Button = %NewCampaignButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton

var _settings_screen: SettingsScreen = null
var _accessibility: AccessibilitySettings = null
var _can_continue: bool = false


## Ayarlar ekranına aktarılacak erişilebilirlik tercihleri; [param can_continue] yüklenebilir
## bir kampanya kaydı var mı (Devam Et etkin ve birincil aksiyon olur).
func bind_services(accessibility: AccessibilitySettings, can_continue: bool = false) -> void:
	_accessibility = accessibility
	_can_continue = can_continue


func _ready() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)
	_new_campaign_button.pressed.connect(_on_new_campaign_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_apply_continue_state()


## Yükleme başarısız olunca RootContext Devam Et'i kapatır.
func set_continue_available(available: bool) -> void:
	_can_continue = available
	_apply_continue_state()


func _apply_continue_state() -> void:
	_continue_button.disabled = not _can_continue
	# Birincil aksiyon (art bible §7): kayıt varsa Devam Et, yoksa Yeni Kampanya.
	_continue_button.theme_type_variation = &"PrimaryButton" if _can_continue else &""
	_new_campaign_button.theme_type_variation = &"" if _can_continue else &"PrimaryButton"
	FocusReveal.focus_quietly(_continue_button if _can_continue else _new_campaign_button)


func _on_continue_pressed() -> void:
	continue_requested.emit()


func _on_new_campaign_pressed() -> void:
	new_campaign_requested.emit()


func _on_settings_pressed() -> void:
	_main_panel.visible = false
	_settings_screen = SETTINGS_SCENE.instantiate() as SettingsScreen
	_settings_screen.bind_services(_accessibility)
	_settings_screen.back_requested.connect(_on_settings_back)
	add_child(_settings_screen)


func _on_settings_back() -> void:
	if _settings_screen:
		_settings_screen.queue_free()
		_settings_screen = null
	_main_panel.visible = true
	FocusReveal.focus_quietly(_settings_button)


func _on_quit_pressed() -> void:
	quit_requested.emit()
