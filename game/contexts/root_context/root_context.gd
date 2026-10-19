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

## Kayıt deposu; ağaca eklenmeden önce verilebilir (testler bellek içi depo verir).
## Boşsa `user://saves` üzerinde [FileSaveStore] kullanılır.
var save_store: SaveStore = null

var _current_context: Node = null
var _game_state: GameState = null
var _accessibility: AccessibilitySettings = AccessibilitySettings.new()
var _locale_fonts: LocaleFontController = null
var _audio: AudioController = null
var _save: SaveController = null


func _ready() -> void:
	# Ses servisi kalıcıdır (bağlam değişiminde müzik/SFX kesilmesin) — ADR-0008.
	_audio = AudioController.new()
	_audio.name = "AudioController"
	_audio.bind_services(load(SFX_LIBRARY_PATH) as SfxLibrary)
	add_child(_audio)
	# Kampanya kaydı (ADR-0007): RootContext sahiplenir, GameContext'e enjekte eder (C-17 D4).
	_save = SaveController.new()
	_save.bind_services(save_store if save_store != null else FileSaveStore.new(), _create_map_state)
	# Kayıtlı ayarlar UI kurulmadan önce uygulanır (dil fontu dahil) — ADR-0007, C-65.
	_apply_settings(_save.load_settings())

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
			menu.bind_services(_accessibility, _save.has_campaign())
			menu.new_campaign_requested.connect(_on_new_campaign)
			menu.continue_requested.connect(_on_continue)
			menu.settings_changed.connect(_on_settings_changed)
			menu.quit_requested.connect(_on_quit)
			_current_context = menu

		&"game":
			# Durumu çağıran hazırlar: yeni kampanya (boş) ya da yüklenen kayıt.
			var game: GameContext = (load(GAME_SCENE_PATH) as PackedScene).instantiate() as GameContext
			game.bind_services(_game_state, _accessibility, _audio, _save)
			game.return_to_menu_requested.connect(_on_return_to_menu)
			_current_context = game

	if _current_context:
		add_child(_current_context)
		context_changed.emit(context_name)


func _on_new_campaign() -> void:
	_game_state = GameState.new()
	_switch_to(&"game")


func _on_continue() -> void:
	var result: LoadResult = _save.load_campaign()
	if result.code != LoadResult.Code.OK:
		push_warning("Kayıt yüklenemedi (%s): %s" % [LoadResult.Code.keys()[result.code], result.detail])
		(_current_context as MenuContext).set_continue_available(false)
		return
	_game_state = result.state
	_switch_to(&"game")


func _on_settings_changed() -> void:
	_save.save_settings(_capture_settings())


## Şu anki ayarların anlık görüntüsü (erişilebilirlik, dil, tam ekran, bus sesleri).
func _capture_settings() -> SettingsSnapshot:
	var snapshot: SettingsSnapshot = SettingsSnapshot.new()
	snapshot.color_blind_mode = _accessibility.color_blind_mode
	snapshot.reduce_motion = _accessibility.reduce_motion
	snapshot.show_region_names = _accessibility.show_region_names
	snapshot.fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	var language: String = TranslationServer.standardize_locale(TranslationServer.get_locale()).get_slice("_", 0)
	snapshot.locale = language if language in SettingsSerializer.SUPPORTED_LOCALES else "en"
	snapshot.master_volume = AudioController.get_bus_linear(&"Master")
	snapshot.music_volume = AudioController.get_bus_linear(AudioController.MUSIC_BUS)
	snapshot.sfx_volume = AudioController.get_bus_linear(AudioController.SFX_BUS)
	return snapshot


## Kayıtlı ayarları uygular; null (yok/bozuk) → varsayılanlar kalır.
func _apply_settings(snapshot: SettingsSnapshot) -> void:
	if snapshot == null:
		return
	_accessibility.color_blind_mode = snapshot.color_blind_mode
	_accessibility.reduce_motion = snapshot.reduce_motion
	_accessibility.show_region_names = snapshot.show_region_names
	TranslationServer.set_locale(snapshot.locale)
	AudioController.set_bus_linear(&"Master", snapshot.master_volume)
	AudioController.set_bus_linear(AudioController.MUSIC_BUS, snapshot.music_volume)
	AudioController.set_bus_linear(AudioController.SFX_BUS, snapshot.sfx_volume)
	if snapshot.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


## Kayıt yüklemesi için içerikten taze bölüm haritası (ADR-0007 map_factory); yoksa null.
func _create_map_state(chapter_id: int) -> MapState:
	var path: String = GameContext.CHAPTER_MAP_PATH_FORMAT % chapter_id
	if not ResourceLoader.exists(path):
		return null
	var definition: ChapterMapDefinition = load(path) as ChapterMapDefinition
	return definition.create_map_state() if definition != null else null


func _on_return_to_menu() -> void:
	_game_state = null
	_switch_to(&"menu")


func _on_quit() -> void:
	get_tree().quit()
