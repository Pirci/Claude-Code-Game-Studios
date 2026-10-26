class_name ChapterSelectContext
extends Control
## Sefer haritası — `CHAPTER_SELECT` (scene-flow.md §3.9; ADR-0012 karar 3; scene-screens E5): iki satırlı
## sahne düğümleri (durum ikonu + ad + eylem; açık sahnede teaser), ortak durum satırı (odaktaki sahnenin
## tam adı / kilit ipucu), taşınan güç şeridi (Ruh + lütuflar), [Başla] / [Destanı Oku] / [Ana Menü].
## Pasif: yalnızca niyet sinyalleri; geçişi SceneFlow verir. Açılışta girdi koruması (AC-E5-6): düğmeler
## pasif, Esc/Enter düşer; sonra Esc = [Ana Menü] (AC-E5-8).


signal start_requested(chapter_id: int)
signal read_requested(chapter_id: int)
signal menu_requested

const ICON_DIR: String = "res://assets/art/ui/theme/"
const ICON_COMPLETED: Texture2D = preload(ICON_DIR + "icon_chapter_completed.png")
const ICON_AVAILABLE: Texture2D = preload(ICON_DIR + "icon_chapter_available.png")
const ICON_AVAILABLE_GLOW: Texture2D = preload(ICON_DIR + "icon_chapter_available_glow.png")
const ICON_LOCKED: Texture2D = preload(ICON_DIR + "icon_chapter_locked.png")
const ICON_NEW: Texture2D = preload(ICON_DIR + "icon_chapter_new.png")
const PANEL_WIDTH: int = 400
## Yeni açılma parıltısı: 4 kare (E5.6), kare başına süre.
const GLOW_FRAMES: int = 4
const GLOW_FRAME_S: float = 0.12
## Kilitli sahne adı soluk (renk tek ipucu değil: kilit ikonu + ipucu satırı, AC-E5-4). Sahne akışı
## ekranlarında `modulate` yok (AC27) — soluklama tema renk override'ıyla, parıltı doku değişimiyle.
const LOCKED_TEXT_COLOR: Color = Color("#8A6D4F")
const SFX_CHAPTER_UNLOCK: StringName = &"chapter_unlock"
const SFX_UI_DENIED: StringName = &"ui_denied"
const NBSP: String = "\u00a0"

var _campaign: CampaignDefinition = null
var _game_state: GameState = null
var _boon_catalog: BoonCatalog = null
var _focus_target: Control = null
var _guard_s: float = 0.0
var _newly_unlocked: int = 0
var _reduce_motion: bool = false
var _audio: AudioController = null
var _menu_button: Button = null
var _status_line: Label = null
var _glow_tween: Tween = null


## [param newly_unlocked] E1 çıkışından gelişte yeni açılan sahne (parıltı + ses ziyaret başına bir kez);
## Devam Et'te 0. [param reduce_motion] parıltı yerine sabit "yeni" işareti.
func bind_services(campaign: CampaignDefinition, game_state: GameState, boon_catalog: BoonCatalog = null,
		guard_s: float = 0.0, newly_unlocked: int = 0, reduce_motion: bool = false,
		audio: AudioController = null) -> void:
	_campaign = campaign
	_game_state = game_state
	_boon_catalog = boon_catalog
	_guard_s = guard_s
	_newly_unlocked = newly_unlocked
	_reduce_motion = reduce_motion
	_audio = audio


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background: ColorRect = ColorRect.new()
	background.color = Color("#141A33")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "SelectPanel"
	panel.theme_type_variation = &"ModalPanel"
	center.add_child(panel)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 6)
	vbox.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	panel.add_child(vbox)

	var title: Label = Label.new()
	title.theme_type_variation = &"HeaderLabel"
	title.text = tr("CHAPTER_SELECT_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var completed: Array[int] = _game_state.chapters_completed
	if CampaignRules.next_chapter(completed, _campaign.scene_count()) == 0:
		var badge: Label = Label.new()
		badge.name = "CampaignCompleteBadge"
		badge.text = tr("CAMPAIGN_COMPLETE")
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(badge)
	for scene: SceneDefinition in _campaign.scenes:
		vbox.add_child(_scene_node(scene, CampaignRules.chapter_state(scene.chapter_id, completed)))
	_status_line = Label.new()
	_status_line.name = "StatusLine"
	_status_line.theme_type_variation = &"SecondaryLabel"
	_status_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_status_line.clip_text = true
	vbox.add_child(_status_line)
	vbox.add_child(_power_strip())

	_menu_button = Button.new()
	_menu_button.name = "MenuButton"
	_menu_button.text = tr("MAIN_MENU")
	_menu_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_menu_button.pressed.connect(menu_requested.emit)
	_menu_button.focus_entered.connect(_set_status.bind(""))
	vbox.add_child(_menu_button)
	var buttons: Array[BaseButton] = []
	for node: Node in find_children("*", "BaseButton", true, false):
		buttons.append(node as BaseButton)
	InputGuard.arm(self, buttons, _guard_s)
	FocusReveal.focus_quietly(_focus_target if _focus_target != null else _menu_button)
	_announce_unlock()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and _menu_button != null:
		get_viewport().set_input_as_handled()
		if not _menu_button.disabled:
			menu_requested.emit()


## Yeni açılma parıltısı oynuyor mu (Hareketi Azalt'ta hiç başlamaz; AC-E5-2).
func is_unlock_glowing() -> bool:
	return _glow_tween != null and _glow_tween.is_running()


## Sahne düğümü: üst satır ikon + ad + eylem; açık sahnede alt satır teaser (önceki sahnenin `teaser_key`'i).
func _scene_node(scene: SceneDefinition, state: CampaignRules.ChapterState) -> Control:
	var node: VBoxContainer = VBoxContainer.new()
	node.name = "Chapter%d" % scene.chapter_id
	node.add_theme_constant_override(&"separation", 0)
	var line: HBoxContainer = HBoxContainer.new()
	line.name = "Line"
	line.add_theme_constant_override(&"separation", 6)
	node.add_child(line)
	var icon: TextureRect = TextureRect.new()
	icon.name = "StateIcon"
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.texture = _state_icon(state)
	line.add_child(icon)
	var full_name: String = tr(String(scene.title_key))
	if state == CampaignRules.ChapterState.LOCKED:
		line.add_child(_locked_button(full_name))
		return node
	var name_label: Label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = full_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.clip_text = true
	line.add_child(name_label)
	var action: Button = Button.new()
	if state == CampaignRules.ChapterState.AVAILABLE:
		action.name = "StartButton"
		action.theme_type_variation = &"PrimaryButton"
		action.text = tr("START_SCENE")
		action.pressed.connect(start_requested.emit.bind(scene.chapter_id))
		_focus_target = action
		if scene.chapter_id == _newly_unlocked:
			var mark: TextureRect = TextureRect.new()
			mark.name = "NewMark"
			mark.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			mark.texture = ICON_NEW
			line.add_child(mark)
	else:
		action.name = "ReadButton"
		action.text = tr("READ_STORY")
		action.pressed.connect(read_requested.emit.bind(scene.chapter_id))
	action.focus_entered.connect(_on_action_focused.bind(name_label))  # kesilen ad odakta tam (AC-E5-5)
	line.add_child(action)
	if state == CampaignRules.ChapterState.AVAILABLE:
		var teaser_key: StringName = _teaser_key(scene.chapter_id)
		if teaser_key != &"":
			var teaser: Label = Label.new()
			teaser.name = "Teaser"
			teaser.theme_type_variation = &"SecondaryLabel"
			teaser.text = tr(String(teaser_key))
			teaser.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			teaser.max_lines_visible = 2
			node.add_child(teaser)
	return node


## Kilitli satır odaklanabilir düğmedir: soluk ad, eylem yok; odak/basış ipucunu durum satırına yazar.
func _locked_button(full_name: String) -> Button:
	var button: Button = Button.new()
	button.name = "LockedButton"
	button.flat = true
	button.text = full_name
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.clip_text = true
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for color_name: StringName in [&"font_color", &"font_hover_color", &"font_focus_color", &"font_pressed_color"]:
		button.add_theme_color_override(color_name, LOCKED_TEXT_COLOR)
	button.focus_entered.connect(_set_status.bind(tr("CHAPTER_LOCKED_HINT")))
	button.pressed.connect(_on_locked_pressed)
	return button


func _on_locked_pressed() -> void:
	_set_status(tr("CHAPTER_LOCKED_HINT"))
	if _audio != null:
		_audio.play_sfx(SFX_UI_DENIED)


## Ad kesildiyse tam adı durum satırına yazar; sığıyorsa satır boş kalır (tekrar yok).
func _on_action_focused(name_label: Label) -> void:
	await get_tree().process_frame  # açılış odağı yerleşimden önce gelir; genişlik bir kare sonra kesin
	if not is_instance_valid(name_label):
		return
	var font: Font = name_label.get_theme_font(&"font")
	var width: float = font.get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		name_label.get_theme_font_size(&"font_size")).x
	_set_status(name_label.text if width > name_label.size.x else "")


func _set_status(text: String) -> void:
	if _status_line != null:
		_status_line.text = text


## c. sahnenin teaser'ı (c − 1). sahnenin `teaser_key`'idir (E5.3); ilk sahnenin teaser'ı yok.
func _teaser_key(chapter_id: int) -> StringName:
	var previous: SceneDefinition = _campaign.scene(chapter_id - 1)
	return previous.teaser_key if previous != null else &""


static func _state_icon(state: CampaignRules.ChapterState) -> Texture2D:
	match state:
		CampaignRules.ChapterState.COMPLETED:
			return ICON_COMPLETED
		CampaignRules.ChapterState.AVAILABLE:
			return ICON_AVAILABLE
	return ICON_LOCKED


## Yeni açılan sahne: ses (kütüphanede varsa) + 4 karelik altın parıltı (ikon normal ↔ parlak, işaret
## görünür ↔ gizli); Hareketi Azalt'ta yalnız sabit işaret.
func _announce_unlock() -> void:
	var node: Node = find_child("Chapter%d" % _newly_unlocked, true, false) if _newly_unlocked > 0 else null
	var mark: TextureRect = node.find_child("NewMark", true, false) as TextureRect if node != null else null
	if mark == null:
		return
	if _audio != null:
		_audio.play_sfx(SFX_CHAPTER_UNLOCK)
	if _reduce_motion:
		return
	var icon: TextureRect = node.find_child("StateIcon", true, false) as TextureRect
	_glow_tween = create_tween()
	for frame: int in GLOW_FRAMES:
		var bright: bool = frame % 2 == 0
		_glow_tween.tween_callback(func() -> void:
			icon.texture = ICON_AVAILABLE_GLOW if bright else ICON_AVAILABLE
			mark.visible = bright)
		_glow_tween.tween_interval(GLOW_FRAME_S)
	_glow_tween.tween_callback(func() -> void:
		icon.texture = ICON_AVAILABLE
		mark.visible = true)


## Taşınan güç: Ruh bakiyesi ve lütuf başına yığın sayısı (§3.9, çapraz inceleme N1). Her parça yönüne
## göre yalıtılır (AC-E5-7: Arapçada `ad xN` bütün okunur).
func _power_strip() -> Label:
	var strip: Label = Label.new()
	strip.name = "PowerStrip"
	strip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	strip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var parts: PackedStringArray = [NumberFormatter.isolate("%s: %s" % [tr("SPIRIT"), NumberFormatter.format_int(_game_state.ruh)])]
	var counts: Dictionary[StringName, int] = {}
	for boon_id: StringName in _game_state.boons:
		counts[boon_id] = counts.get(boon_id, 0) + 1
	for boon_id: StringName in counts:
		var boon: BoonDefinition = _boon_catalog.get_boon(boon_id) if _boon_catalog != null else null
		var label: String = tr(boon.name_key) if boon != null else String(boon_id)
		# Parça içinde bölünmez boşluk: satır sonunda ad ve "xN" bölünmez, parçalar bütün sarılır (Arapça c93).
		var part: String = "%s x%s" % [label, NumberFormatter.format_int(counts[boon_id])]
		parts.append(NumberFormatter.isolate(part.replace(" ", NBSP)))
	strip.text = "  ".join(parts)
	return strip
