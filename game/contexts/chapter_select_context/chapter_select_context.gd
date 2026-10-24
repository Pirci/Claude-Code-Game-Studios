class_name ChapterSelectContext
extends Control
## Sefer haritası — `CHAPTER_SELECT` (scene-flow.md §3.9; ADR-0012 karar 3): sahne düğümleri
## (F1: tamamlandı / açık / kilitli), taşınan güç şeridi (Ruh + lütuflar), [Başla] /
## [Destanı Oku] / [Ana Menü]. Pasif: yalnızca niyet sinyalleri; geçişi SceneFlow verir.
## Açılışta girdi koruması (AC-E5-6): düğmeler pasif, Esc/Enter düşer; sonra Esc = [Ana Menü] (AC-E5-8).


signal start_requested(chapter_id: int)
signal read_requested(chapter_id: int)
signal menu_requested

var _campaign: CampaignDefinition = null
var _game_state: GameState = null
var _boon_catalog: BoonCatalog = null
var _focus_target: Control = null
var _guard_s: float = 0.0
var _menu_button: Button = null


func bind_services(campaign: CampaignDefinition, game_state: GameState, boon_catalog: BoonCatalog = null,
		guard_s: float = 0.0) -> void:
	_campaign = campaign
	_game_state = game_state
	_boon_catalog = boon_catalog
	_guard_s = guard_s


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
	panel.theme_type_variation = &"ModalPanel"
	center.add_child(panel)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 6)
	vbox.custom_minimum_size = Vector2(300, 0)
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
		vbox.add_child(_scene_row(scene, CampaignRules.chapter_state(scene.chapter_id, completed)))
	vbox.add_child(_power_strip())

	_menu_button = Button.new()
	_menu_button.name = "MenuButton"
	_menu_button.text = tr("MAIN_MENU")
	_menu_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_menu_button.pressed.connect(menu_requested.emit)
	vbox.add_child(_menu_button)
	var buttons: Array[BaseButton] = []
	for node: Node in find_children("*", "BaseButton", true, false):
		buttons.append(node as BaseButton)
	InputGuard.arm(self, buttons, _guard_s)
	FocusReveal.focus_quietly(_focus_target if _focus_target != null else _menu_button)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and _menu_button != null:
		get_viewport().set_input_as_handled()
		if not _menu_button.disabled:
			menu_requested.emit()


func _scene_row(scene: SceneDefinition, state: CampaignRules.ChapterState) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "Chapter%d" % scene.chapter_id
	row.add_theme_constant_override(&"separation", 8)
	var name_label: Label = Label.new()
	name_label.text = tr(String(scene.title_key))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.clip_text = true
	row.add_child(name_label)
	match state:
		CampaignRules.ChapterState.AVAILABLE:
			var start: Button = Button.new()
			start.name = "StartButton"
			start.theme_type_variation = &"PrimaryButton"
			start.text = tr("START_SCENE")
			start.pressed.connect(start_requested.emit.bind(scene.chapter_id))
			row.add_child(start)
			_focus_target = start
		CampaignRules.ChapterState.COMPLETED:
			var read: Button = Button.new()
			read.name = "ReadButton"
			read.text = tr("READ_STORY")
			read.pressed.connect(read_requested.emit.bind(scene.chapter_id))
			row.add_child(read)
		_:
			var hint: Label = Label.new()
			hint.name = "LockedHint"
			hint.text = tr("CHAPTER_LOCKED_HINT")
			hint.theme_type_variation = &"SecondaryLabel"
			row.add_child(hint)
	return row


## Taşınan güç: Ruh bakiyesi ve lütuf başına yığın sayısı (§3.9, çapraz inceleme N1).
func _power_strip() -> Label:
	var strip: Label = Label.new()
	strip.name = "PowerStrip"
	strip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	strip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var parts: PackedStringArray = ["%s: %s" % [tr("SPIRIT"), NumberFormatter.format_int(_game_state.ruh)]]
	var counts: Dictionary[StringName, int] = {}
	for boon_id: StringName in _game_state.boons:
		counts[boon_id] = counts.get(boon_id, 0) + 1
	for boon_id: StringName in counts:
		var boon: BoonDefinition = _boon_catalog.get_boon(boon_id) if _boon_catalog != null else null
		var label: String = tr(boon.name_key) if boon != null else String(boon_id)
		parts.append("%s x%s" % [label, NumberFormatter.format_int(counts[boon_id])])
	strip.text = "  ".join(parts)
	return strip
