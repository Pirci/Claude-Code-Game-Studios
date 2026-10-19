class_name NarrativeContext
extends Control
## Tam ekran anlatı sayfaları (scene-flow.md §3.8; ADR-0012 karar 3): giriş, Kök Böri (A),
## çıkış, kampanya sonu, "Destanı Oku". İllüstrasyon üstte, alt koyu panelde metin; metin
## karakter karakter belirir. Enter/Space/tık: ilk basış metni tamamlar, ikincisi ilerler;
## Esc/[Atla]: kalan sayfaları atlar. Her sayfada ilk `screen_input_guard_s` girdi yok sayılır.


## Son sayfa geçildi ya da atlandı (aynı olay — SceneFlow `pages_finished`).
signal pages_finished

## İllüstrasyon yüklenemezse düz indigo zemin (§3.8, art bible `#141A33`).
const FALLBACK_COLOR := Color("#141A33")
const PANEL_HEIGHT: int = 92

var _pages: Array[NarrativePage] = []
var _config: SceneFlowConfig = SceneFlowConfig.new()
var _accessibility: AccessibilitySettings = null
var _index: int = -1
var _shown_at_ms: int = 0
var _reveal_chars: float = 0.0
var _finished: bool = false
var _illustration_path: String = ""
var _pending_path: String = ""
var _pending_since_ms: int = 0

var _illustration: TextureRect
var _title_label: Label
var _text_label: Label
var _counter_label: Label
var _continue_button: Button
var _skip_button: Button


func bind_services(pages: Array[NarrativePage], config: SceneFlowConfig, accessibility: AccessibilitySettings) -> void:
	_pages = pages
	if config != null:
		_config = config
	_accessibility = accessibility


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background: ColorRect = ColorRect.new()
	background.color = FALLBACK_COLOR
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	_illustration = TextureRect.new()
	_illustration.name = "Illustration"
	_illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_illustration.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_illustration.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_illustration)
	_build_panel()
	if _pages.is_empty():
		_finish.call_deferred()
		return
	_show_page(0)


func _process(_delta: float) -> void:
	_poll_illustration()
	if _index < 0 or _text_revealed():
		return
	_reveal_chars += _config.text_reveal_cps * get_process_delta_time()
	_text_label.visible_characters = int(_reveal_chars)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_skip_pressed()
	elif event.is_action_pressed(&"ui_accept") or _is_left_click(event):
		get_viewport().set_input_as_handled()
		advance()


## Enter/Space/tık ve [Devam]: metin yazılıyorsa tamamlar, yoksa sonraki sayfa (F6).
func advance() -> void:
	if _finished or not _guard_passed():
		return
	if not _text_revealed():
		_text_label.visible_characters = -1
		return
	if _index + 1 >= _pages.size():
		_finish()
	else:
		_show_page(_index + 1)


## Şu anki sayfa sırası (testler ve sayaç için).
func current_page() -> int:
	return _index


func _build_panel() -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "TextPanel"
	panel.theme_type_variation = &"HudPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -PANEL_HEIGHT
	add_child(panel)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 2)
	panel.add_child(vbox)
	var header: HBoxContainer = HBoxContainer.new()
	vbox.add_child(header)
	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.theme_type_variation = &"HeaderLabel"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)
	_counter_label = Label.new()
	_counter_label.name = "PageCounter"
	_counter_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	header.add_child(_counter_label)
	_text_label = Label.new()
	_text_label.name = "TextLabel"
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_text_label)
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override(&"separation", 8)
	vbox.add_child(buttons)
	_skip_button = Button.new()
	_skip_button.name = "SkipButton"
	_skip_button.text = tr("SKIP")
	_skip_button.pressed.connect(_on_skip_pressed)
	buttons.add_child(_skip_button)
	_continue_button = Button.new()
	_continue_button.name = "ContinueButton"
	_continue_button.theme_type_variation = &"PrimaryButton"
	_continue_button.text = tr("CONTINUE")
	_continue_button.pressed.connect(advance)
	buttons.add_child(_continue_button)


func _show_page(index: int) -> void:
	_index = index
	var page: NarrativePage = _pages[index]
	_title_label.text = tr(String(page.title_key)) if page.title_key != &"" else ""
	_title_label.visible = page.title_key != &""
	_text_label.text = tr(String(page.text_key))
	_counter_label.text = "%d/%d" % [index + 1, _pages.size()]
	_reveal_chars = 0.0
	var instant: bool = _config.text_reveal_cps <= 0.0 or (_accessibility != null and _accessibility.reduce_motion)
	_text_label.visible_characters = -1 if instant else 0
	_shown_at_ms = Time.get_ticks_msec()
	if not page.illustration_path.is_empty():
		_request_illustration(page.illustration_path)
	if index + 1 < _pages.size() and not _pages[index + 1].illustration_path.is_empty():
		_prefetch(_pages[index + 1].illustration_path)
	FocusReveal.focus_quietly(_continue_button)


## Asenkron yükleme (§3.8): geçerli + sonraki; dosya yoksa ya da süre aşılırsa düz zemin.
func _request_illustration(path: String) -> void:
	if path == _illustration_path:
		return
	_illustration_path = path
	_illustration.texture = null
	if not ResourceLoader.exists(path):
		push_warning("NarrativeContext: illüstrasyon yok, düz zemin: %s" % path)
		_pending_path = ""
		return
	if ResourceLoader.load_threaded_request(path) != OK and ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		push_warning("NarrativeContext: illüstrasyon istenemedi: %s" % path)
		return
	_pending_path = path
	_pending_since_ms = Time.get_ticks_msec()


func _prefetch(path: String) -> void:
	if ResourceLoader.exists(path):
		ResourceLoader.load_threaded_request(path)


func _poll_illustration() -> void:
	if _pending_path.is_empty():
		return
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(_pending_path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_illustration.texture = ResourceLoader.load_threaded_get(_pending_path) as Texture2D
		_pending_path = ""
	elif status != ResourceLoader.THREAD_LOAD_IN_PROGRESS or \
			Time.get_ticks_msec() - _pending_since_ms > int(_config.illustration_load_timeout_s * 1000.0):
		push_warning("NarrativeContext: illüstrasyon yüklenemedi: %s" % _pending_path)
		_pending_path = ""


func _text_revealed() -> bool:
	return _text_label.visible_characters < 0 or _text_label.visible_characters >= _text_label.get_total_character_count()


func _guard_passed() -> bool:
	return Time.get_ticks_msec() - _shown_at_ms >= int(_config.screen_input_guard_s * 1000.0)


func _is_left_click(event: InputEvent) -> bool:
	var click: InputEventMouseButton = event as InputEventMouseButton
	return click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT


func _on_skip_pressed() -> void:
	if _finished or not _guard_passed():
		return
	_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	pages_finished.emit()
