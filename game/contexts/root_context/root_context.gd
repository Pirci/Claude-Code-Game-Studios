class_name RootContext
extends Node
## Kök bağlam: kalıcı servisler (ses, kayıt, ayarlar) ve kampanya akışı. Akışın kuralları saf
## [SceneFlow]'dadır; burası yalnızca dönen eylemleri sırayla uygular ve bağlam değiştirir
## (ADR-0012 karar 2). Sinyaller yukarı: ses ve öğretici bunlara bağlanır.


signal context_changed(context_name: StringName)
signal scene_started(chapter_id: int, first_entry: bool)
signal scene_completed(chapter_id: int)
signal scene_failed(chapter_id: int)
signal campaign_completed


## Bağlam sahneleri geçiş anında [code]load()[/code] ile yüklenir: kök bağlam ağaçtan hiç
## çıkmadığı için bir [code]preload[/code] tüm sahne zincirini bellekte tutardı (ADR-0001,
## yasak desen "kalıcı node'lardan büyük sahne preload'u").
const MENU_SCENE_PATH: String = "res://contexts/menu_context/menu_context.tscn"
const GAME_SCENE_PATH: String = "res://contexts/game_context/game_context.tscn"
## SFX kimlik → ses eşlemesi (içerik; ADR-0008).
const SFX_LIBRARY_PATH: String = "res://features/audio/data/sfx_library.tres"
## Kampanya içeriği ve akış ayarları — küçük kaynaklar, açılışta bir kez `load()`.
const CAMPAIGN_PATH: String = "res://features/campaign/data/campaign.tres"
const SCENE_FLOW_CONFIG_PATH: String = "res://features/campaign/data/scene_flow_config.tres"
const BOON_CATALOG_PATH: String = "res://features/bozkurt/data/boon_catalog.tres"

## Arapça arayüz fontu (Unifont); native piksel boyutunda kullanılmalı.
@export var arabic_font: Font = null
@export var arabic_font_size: int = 16

## Kayıt deposu; ağaca eklenmeden önce verilebilir (testler bellek içi depo verir).
## Boşsa `user://saves` üzerinde [FileSaveStore] kullanılır.
var save_store: SaveStore = null
## Akış ayarları; ağaca eklenmeden önce verilebilir (testler girdi korumasını kapatır).
var flow_config: SceneFlowConfig = null

var _current_context: Node = null
var _game_state: GameState = null
var _accessibility: AccessibilitySettings = AccessibilitySettings.new()
var _locale_fonts: LocaleFontController = null
var _audio: AudioController = null
var _save: SaveController = null
## Görülen öğretici ipuçları: ayarlarla kalıcı, GameContext'e enjekte edilir (C-41).
var _tutorial: TutorialProgress = TutorialProgress.new()
var _flow: SceneFlow = SceneFlow.new()
var _flow_state: SceneFlow.State = SceneFlow.State.MAIN_MENU
var _chapter_id: int = 1
var _campaign: CampaignDefinition = null
## "Devam Et" denemesinin sonucu (T3/T4 `adopt_state` eylemi okur).
var _loaded: LoadResult = null
## Sahne girişi anlık görüntüsü (T11) — Yeniden Dene ve F3 için; kayıt yuvası yoksa yedek.
var _entry: Dictionary = {}


func _ready() -> void:
	# Ses servisi kalıcıdır (bağlam değişiminde müzik/SFX kesilmesin) — ADR-0008.
	_audio = AudioController.new()
	_audio.name = "AudioController"
	_audio.bind_services(load(SFX_LIBRARY_PATH) as SfxLibrary)
	add_child(_audio)
	_campaign = load(CAMPAIGN_PATH) as CampaignDefinition
	if flow_config == null:
		flow_config = load(SCENE_FLOW_CONFIG_PATH) as SceneFlowConfig
	# Kampanya kaydı (ADR-0007): RootContext sahiplenir, GameContext'e enjekte eder (C-17 D4).
	_save = SaveController.new()
	_save.bind_services(save_store if save_store != null else FileSaveStore.new(), _create_map_state)
	# Kayıtlı ayarlar UI kurulmadan önce uygulanır (dil fontu dahil) — ADR-0007, C-65.
	_apply_settings(_save.load_settings())
	_tutorial.changed.connect(_on_settings_changed)

	_locale_fonts = LocaleFontController.new(ThemeDB.get_project_theme())
	if arabic_font:
		_locale_fonts.add_override("ar", arabic_font, arabic_font_size)
	_locale_fonts.apply(TranslationServer.get_locale())
	_enter_state(SceneFlow.State.MAIN_MENU, SceneFlow.State.MAIN_MENU)


## Şu anki akış durumu (testler ve hata ayıklama).
func flow_state() -> SceneFlow.State:
	return _flow_state


## İlk klavye gezinme/onay tuşu gizli odağı görünür yapar (C-25, [FocusReveal]).
func _input(event: InputEvent) -> void:
	if FocusReveal.reveal_on_navigation(get_viewport(), event):
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale_fonts:
		_locale_fonts.apply(TranslationServer.get_locale())


func _switch_to(context: Node, context_name: StringName) -> void:
	if _current_context:
		# Giden bağlam aynı karede ağaçtan çıkar (girdi almaz), kare sonunda serbest kalır.
		remove_child(_current_context)
		_current_context.queue_free()
		_current_context = null
	_current_context = context
	add_child(_current_context)
	context_changed.emit(context_name)


# --- Akış: olay → SceneFlow → eylemler → yeni durumun ekranı ---

func _dispatch(event: StringName, extra: Dictionary = {}) -> void:
	var facts: Dictionary = {SceneFlow.FACT_CHAPTER_ID: _chapter_id}
	facts.merge(extra, true)
	var step: SceneFlow.FlowStep = _flow.transition(_flow_state, event, facts)
	if step.ignored:
		return
	var previous: SceneFlow.State = _flow_state
	_chapter_id = step.chapter_id
	for action: StringName in step.actions:
		_run_action(action)
	_flow_state = step.next_state
	if step.next_state != previous:
		_enter_state(step.next_state, previous)


func _run_action(action: StringName) -> void:
	match action:
		SceneFlow.ACTION_CONFIRM_NEW_CAMPAIGN:
			(_current_context as MenuContext).show_confirm_new_campaign()
		SceneFlow.ACTION_NEW_STATE:
			_game_state = GameState.new()
			_entry = {}
		SceneFlow.ACTION_ADOPT_STATE:
			_game_state = _loaded.state
			_entry = {}
		SceneFlow.ACTION_SHOW_LOAD_ERROR:
			push_warning("Kayıt yüklenemedi (%s): %s" % [LoadResult.Code.keys()[_loaded.code], _loaded.detail])
			(_current_context as MenuContext).set_continue_available(false)
		SceneFlow.ACTION_BUILD_MAP:
			var definition: ChapterMapDefinition = _scene().load_map_definition()
			_game_state.current_chapter = _chapter_id
			_game_state.map_state = definition.create_map_state()
			_game_state.gold = definition.starting_gold
		SceneFlow.ACTION_REBUILD_MODIFIERS:
			# Türetilmiş kayıtlar `boons`'tan yeniden kurulur (ADR-0006); tek yazar ModifierController.
			var modifiers: ModifierController = ModifierController.new()
			modifiers.bind_services(_game_state)
			var spirit: SpiritController = SpiritController.new()
			spirit.bind_services(_game_state)
			spirit.bind_boons(load(BOON_CATALOG_PATH) as BoonCatalog, modifiers)
			spirit.rebuild_boon_modifiers()
		SceneFlow.ACTION_CAPTURE_ENTRY:
			_entry = _snapshot(_game_state)
		SceneFlow.ACTION_SAVE_ENTRY:
			_save.save_scene_entry(_game_state)
		SceneFlow.ACTION_CONFIRM_LEAVE:
			(_current_context as GameContext).show_leave_confirm()
		SceneFlow.ACTION_START_BOON_PICKS:
			(_current_context as GameContext).start_boon_picks()
		SceneFlow.ACTION_COMMIT_SCENE:
			CampaignRules.commit_scene(_game_state, _chapter_id, _campaign.scene_count())
			scene_completed.emit(_chapter_id)
		SceneFlow.ACTION_SAVE_COMPLETED:
			_save.save_completed(_game_state)
		SceneFlow.ACTION_RESTORE_ENTRY:
			_restore_entry()


func _enter_state(state: SceneFlow.State, previous: SceneFlow.State) -> void:
	match state:
		SceneFlow.State.MAIN_MENU:
			_game_state = null
			var menu: MenuContext = (load(MENU_SCENE_PATH) as PackedScene).instantiate() as MenuContext
			menu.bind_services(_accessibility, _save.has_campaign())
			menu.new_campaign_requested.connect(_on_new_campaign)
			menu.new_campaign_confirmed.connect(_dispatch.bind(SceneFlow.EVENT_NEW_CAMPAIGN_CONFIRMED))
			menu.continue_requested.connect(_on_continue)
			menu.settings_changed.connect(_on_settings_changed)
			menu.tutorial_reset_requested.connect(_tutorial.reset)
			menu.quit_requested.connect(_on_quit)
			_switch_to(menu, &"menu")
		SceneFlow.State.CHAPTER_SELECT:
			var select: ChapterSelectContext = ChapterSelectContext.new()
			select.name = "ChapterSelectContext"
			select.bind_services(_campaign, _game_state, load(BOON_CATALOG_PATH) as BoonCatalog)
			select.start_requested.connect(_on_chapter_start)
			select.read_requested.connect(_on_chapter_read)
			select.menu_requested.connect(_dispatch.bind(SceneFlow.EVENT_MENU))
			_switch_to(select, &"chapter_select")
		SceneFlow.State.INTRO_NARRATIVE:
			scene_started.emit(_chapter_id, true)
			_show_pages(_scene().intro_pages)
		SceneFlow.State.KOK_BORI_MARK_PAGES:
			_show_pages(_scene().kok_bori_pages)
		SceneFlow.State.KOK_BORI_MARK_PANEL:
			if previous == SceneFlow.State.DEFEAT:
				scene_started.emit(_chapter_id, false)
			_show_game().show_objective()
		SceneFlow.State.PLAYING:
			if previous == SceneFlow.State.MAIN_MENU:
				# Devam Et (T3): kayıtlı tur başı, giriş anlatısı/hedef paneli yok.
				_show_game().offer_pending_boon()
		SceneFlow.State.VICTORY_BEAT:
			(_current_context as GameContext).show_victory(_ruh_gained())
		SceneFlow.State.DEFEAT:
			scene_failed.emit(_chapter_id)
			(_current_context as GameContext).show_defeat()
		SceneFlow.State.OUTRO_NARRATIVE:
			_show_pages(_scene().outro_pages)
		SceneFlow.State.CAMPAIGN_END:
			campaign_completed.emit()
			_show_pages(_campaign.end_pages)
		SceneFlow.State.STORY_REPLAY:
			var scene: SceneDefinition = _scene()
			var pages: Array[NarrativePage] = []
			pages.append_array(scene.intro_pages)
			pages.append_array(scene.kok_bori_pages)
			pages.append_array(scene.outro_pages)
			_show_pages(pages)


func _show_pages(pages: Array[NarrativePage]) -> void:
	var narrative: NarrativeContext = NarrativeContext.new()
	narrative.name = "NarrativeContext"
	narrative.bind_services(pages, flow_config, _accessibility)
	narrative.pages_finished.connect(_on_pages_finished)
	_switch_to(narrative, &"narrative")


func _show_game() -> GameContext:
	var game: GameContext = (load(GAME_SCENE_PATH) as PackedScene).instantiate() as GameContext
	game.bind_services(_game_state, _accessibility, _audio, _save, _scene(), flow_config, _tutorial)
	game.menu_requested.connect(_dispatch.bind(SceneFlow.EVENT_MENU))
	game.leave_confirmed.connect(_dispatch.bind(SceneFlow.EVENT_LEAVE_CONFIRMED))
	game.objective_dismissed.connect(_dispatch.bind(SceneFlow.EVENT_OBJECTIVE_DISMISSED))
	game.scene_won.connect(_dispatch.bind(SceneFlow.EVENT_GAME_WON))
	game.scene_lost.connect(_dispatch.bind(SceneFlow.EVENT_GAME_LOST))
	game.victory_acknowledged.connect(_on_victory_acknowledged)
	game.boon_picks_finished.connect(_dispatch.bind(SceneFlow.EVENT_BOON_PICKS_FINISHED))
	game.retry_requested.connect(_dispatch.bind(SceneFlow.EVENT_RETRY))
	_switch_to(game, &"game")
	return game


func _scene() -> SceneDefinition:
	return _campaign.scene(_chapter_id)


func _on_new_campaign() -> void:
	_dispatch(SceneFlow.EVENT_NEW_CAMPAIGN, {SceneFlow.FACT_HAS_SAVE: _save.has_campaign()})


func _on_continue() -> void:
	_loaded = _save.load_campaign()
	var ok: bool = _loaded.code == LoadResult.Code.OK
	var facts: Dictionary = {SceneFlow.FACT_LOAD_OK: ok}
	if ok:
		facts[SceneFlow.FACT_MAP_PRESENT] = _loaded.state.map_state != null
		facts[SceneFlow.FACT_CHAPTER_ID] = _loaded.state.current_chapter
	_dispatch(SceneFlow.EVENT_CONTINUE, facts)


func _on_chapter_start(chapter_id: int) -> void:
	_dispatch(SceneFlow.EVENT_START, {
		SceneFlow.FACT_CHAPTER_ID: chapter_id,
		SceneFlow.FACT_CHAPTER_STATE: CampaignRules.chapter_state(chapter_id, _game_state.chapters_completed),
	})


func _on_chapter_read(chapter_id: int) -> void:
	_dispatch(SceneFlow.EVENT_READ, {
		SceneFlow.FACT_CHAPTER_ID: chapter_id,
		SceneFlow.FACT_CHAPTER_STATE: CampaignRules.chapter_state(chapter_id, _game_state.chapters_completed),
	})


func _on_pages_finished() -> void:
	var scene: SceneDefinition = _scene()
	_dispatch(SceneFlow.EVENT_PAGES_FINISHED, {
		SceneFlow.FACT_HAS_KOK_BORI_PAGES: scene != null and not scene.kok_bori_pages.is_empty(),
		SceneFlow.FACT_IS_LAST_SCENE: _chapter_id >= _campaign.scene_count(),
	})


func _on_victory_acknowledged() -> void:
	_dispatch(SceneFlow.EVENT_VICTORY_ACKNOWLEDGED, {
		SceneFlow.FACT_PICKS_PENDING: (_current_context as GameContext).has_pending_offer(),
	})


## Yeniden Dene anlık görüntüsü (§3.4 R3): kayıt yuvası → bellekteki kopya → mevcut değerler.
func _restore_entry() -> void:
	if not flow_config.retry_restores_entry_snapshot:
		return
	var entry: Dictionary = _entry
	var slot: LoadResult = _save.load_scene_entry()
	if slot.code == LoadResult.Code.OK and slot.state.current_chapter == _chapter_id:
		entry = _snapshot(slot.state)
	if entry.get(&"chapter_id", 0) != _chapter_id:
		push_warning("Yeniden Dene: sahne girişi kaydı yok, mevcut Ruh/lütuflarla devam")
		return
	_game_state.ruh = entry[&"ruh"]
	_game_state.boons = (entry[&"boons"] as Array[StringName]).duplicate()
	_game_state.chapters_completed = (entry[&"chapters_completed"] as Array[int]).duplicate()
	_entry = entry


func _snapshot(state: GameState) -> Dictionary:
	return {
		&"chapter_id": state.current_chapter,
		&"ruh": state.ruh,
		&"boons": state.boons.duplicate(),
		&"chapters_completed": state.chapters_completed.duplicate(),
	}


## F3: sahnede kazanılan Ruh — giriş görüntüsü yoksa (Devam Et) kayıt yuvasından okunur.
func _ruh_gained() -> int:
	if _entry.get(&"chapter_id", 0) != _chapter_id:
		var slot: LoadResult = _save.load_scene_entry()
		if slot.code == LoadResult.Code.OK and slot.state.current_chapter == _chapter_id:
			_entry = _snapshot(slot.state)
	var config: SpiritConfig = load("res://features/bozkurt/data/spirit_config.tres") as SpiritConfig
	return CampaignRules.ruh_gained(_game_state.ruh, _game_state.boons.size(),
		int(_entry.get(&"ruh", 0)), (_entry.get(&"boons", []) as Array).size(), config)


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
	snapshot.seen_hints = _tutorial.seen_ids()
	return snapshot


## Kayıtlı ayarları uygular; null (yok/bozuk) → varsayılanlar kalır.
func _apply_settings(snapshot: SettingsSnapshot) -> void:
	if snapshot == null:
		return
	_accessibility.color_blind_mode = snapshot.color_blind_mode
	_accessibility.reduce_motion = snapshot.reduce_motion
	_accessibility.show_region_names = snapshot.show_region_names
	_tutorial.load_seen(snapshot.seen_hints)
	TranslationServer.set_locale(snapshot.locale)
	AudioController.set_bus_linear(&"Master", snapshot.master_volume)
	AudioController.set_bus_linear(AudioController.MUSIC_BUS, snapshot.music_volume)
	AudioController.set_bus_linear(AudioController.SFX_BUS, snapshot.sfx_volume)
	if snapshot.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


## Kayıt yüklemesi için içerikten taze bölüm haritası (ADR-0007 map_factory); sahne yoksa
## null → `CONTENT_MISSING`. Yol `SceneDefinition.map_path`'ten (ADR-0012 karar 4).
func _create_map_state(chapter_id: int) -> MapState:
	var scene: SceneDefinition = _campaign.scene(chapter_id) if _campaign != null else null
	var definition: ChapterMapDefinition = scene.load_map_definition() if scene != null else null
	return definition.create_map_state() if definition != null else null


func _on_quit() -> void:
	get_tree().quit()
