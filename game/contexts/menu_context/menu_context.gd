class_name MenuContext
extends Control


signal new_campaign_requested
signal quit_requested


const SETTINGS_SCENE: PackedScene = preload("res://ui/screens/settings_screen.tscn")

@onready var _main_panel: VBoxContainer = %MainPanel
@onready var _new_campaign_button: Button = %NewCampaignButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton

var _settings_screen: SettingsScreen = null


func _ready() -> void:
	_new_campaign_button.pressed.connect(_on_new_campaign_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _on_new_campaign_pressed() -> void:
	new_campaign_requested.emit()


func _on_settings_pressed() -> void:
	_main_panel.visible = false
	_settings_screen = SETTINGS_SCENE.instantiate() as SettingsScreen
	_settings_screen.back_requested.connect(_on_settings_back)
	add_child(_settings_screen)


func _on_settings_back() -> void:
	if _settings_screen:
		_settings_screen.queue_free()
		_settings_screen = null
	_main_panel.visible = true


func _on_quit_pressed() -> void:
	quit_requested.emit()
