class_name RootContext
extends Node


signal context_changed(context_name: StringName)


## Bağlam sahneleri geçiş anında [code]load()[/code] ile yüklenir: kök bağlam ağaçtan hiç
## çıkmadığı için bir [code]preload[/code] tüm sahne zincirini bellekte tutardı (ADR-0001,
## yasak desen "kalıcı node'lardan büyük sahne preload'u").
const MENU_SCENE_PATH: String = "res://contexts/menu_context/menu_context.tscn"
const GAME_SCENE_PATH: String = "res://contexts/game_context/game_context.tscn"
## SFX kimlik → ses eşlemesi (içerik; ADR-0008).
const SFX_LIBRARY_PATH: String = "res://features/audio/data/sfx_library.tres"

## Arapça arayüz fontu (Unifont); native piksel boyutunda kullanılmalı.
@export var arabic_font: Font = null
@export var arabic_font_size: int = 16

var _current_context: Node = null
var _game_state: GameState = null
var _accessibility: AccessibilitySettings = AccessibilitySettings.new()
var _locale_fonts: LocaleFontController = null
var _audio: AudioController = null


func _ready() -> void:
	# Ses servisi kalıcıdır (bağlam değişiminde müzik/SFX kesilmesin) — ADR-0008.
	_audio = AudioController.new()
	_audio.name = "AudioController"
	_audio.bind_services(load(SFX_LIBRARY_PATH) as SfxLibrary)
	add_child(_audio)

	_locale_fonts = LocaleFontController.new(ThemeDB.get_project_theme())
	if arabic_font:
		_locale_fonts.add_override("ar", arabic_font, arabic_font_size)
	_locale_fonts.apply(TranslationServer.get_locale())
	_switch_to(&"menu")


## İlk klavye gezinme/onay tuşu gizli odağı görünür yapar (C-25, [FocusReveal]).
func _input(event: InputEvent) -> void:
	if FocusReveal.reveal_on_navigation(get_viewport(), event):
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale_fonts:
		_locale_fonts.apply(TranslationServer.get_locale())


func _switch_to(context_name: StringName) -> void:
	if _current_context:
		# Giden bağlam aynı karede ağaçtan çıkar (girdi almaz), kare sonunda serbest kalır.
		remove_child(_current_context)
		_current_context.queue_free()
		_current_context = null

	match context_name:
		&"menu":
			var menu: MenuContext = (load(MENU_SCENE_PATH) as PackedScene).instantiate() as MenuContext
			menu.bind_services(_accessibility)
			menu.new_campaign_requested.connect(_on_new_campaign)
			menu.quit_requested.connect(_on_quit)
			_current_context = menu

		&"game":
			_game_state = GameState.new()
			var game: GameContext = (load(GAME_SCENE_PATH) as PackedScene).instantiate() as GameContext
			game.bind_services(_game_state, _accessibility, _audio)
			game.return_to_menu_requested.connect(_on_return_to_menu)
			_current_context = game

	if _current_context:
		add_child(_current_context)
		context_changed.emit(context_name)


func _on_new_campaign() -> void:
	_switch_to(&"game")


func _on_return_to_menu() -> void:
	_game_state = null
	_switch_to(&"menu")


func _on_quit() -> void:
	get_tree().quit()
