class_name ReportModal
extends PanelContainer
## Rapor modallarının ortak çerçevesi (ux/battle-report.md §3, §5): başlık, isteğe bağlı bölge
## adı, ozan dizesi, sayı satırları ve tek [Devam]. Pasif görünüm — veriyi alt sınıf yazar;
## [Devam] / Enter / Space / Esc kapatır (ortak Esc kuralı), girdi koruması süresince pasif.


signal closed

## Ortak modal iç genişliği (scene-screens §0).
const LINE_WIDTH: int = 288

var _guard_s: float = 0.0
var _vbox: VBoxContainer
var _continue_button: Button


func _init(guard_s: float = 0.0) -> void:
	theme_type_variation = &"ModalPanel"
	_guard_s = guard_s
	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override(&"separation", 4)
	add_child(_vbox)


func _ready() -> void:
	_continue_button = Button.new()
	_continue_button.name = "ContinueButton"
	_continue_button.theme_type_variation = &"PrimaryButton"
	_continue_button.text = tr("CONTINUE")
	_continue_button.custom_minimum_size = Vector2(64, 0)
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue_button.pressed.connect(_on_continue_pressed)
	_vbox.add_child(_continue_button)
	InputGuard.arm(self, [_continue_button] as Array[BaseButton], _guard_s)


func get_focus_target() -> Control:
	return _continue_button


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and _continue_button != null and not _continue_button.disabled:
		get_viewport().set_input_as_handled()
		_on_continue_pressed()


func _add_heading(text: String) -> void:
	var label: Label = _label("Heading", text)
	label.theme_type_variation = &"HeaderLabel"


func _add_region_name(name_key: StringName) -> void:
	if name_key == &"":
		return
	var label: Label = _label("RegionName", tr(String(name_key)))
	label.theme_type_variation = &"SecondaryLabel"
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


func _add_verse(text: String) -> void:
	var label: Label = _label("Verse", text)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(LINE_WIDTH, 0)


## Sayı satırı: `tr(key) % sayı`, sayı LTR yalıtımlı (ADR-0009). [param trend] < 0 kayıp (`↓`, kırmızı),
## > 0 kazanç (`↑`, yeşil), 0 düz — renk tek başına anlam taşımaz (glif + metin).
func _add_number(node_name: String, key: String, value: int, trend: int = 0) -> void:
	var text: String = tr(key) % NumberFormatter.ltr(NumberFormatter.format_int(value))
	if trend < 0:
		text = "↓ " + text
	elif trend > 0:
		text = "↑ " + text
	var label: Label = _label(node_name, text)
	if trend != 0:
		label.add_theme_color_override(&"font_color", ValueFeedback.COLOR_LOSS if trend < 0 else ValueFeedback.COLOR_GAIN)


func _label(node_name: String, text: String) -> Label:
	var label: Label = Label.new()
	label.name = node_name
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(label)
	return label


func _on_continue_pressed() -> void:
	closed.emit()
