class_name VictoryCard
extends PanelContainer
## Zafer sonuç kartı — `VICTORY_BEAT` (scene-flow §3.6): tur, tutulan topraklar, sahnede
## kazanılan Ruh (F3). Tek düğme [Devam] (Enter/Space/Esc); girdi koruması süresince pasif.


signal acknowledged
signal closed

var _guard_s: float = 0.0
var _continue_button: Button


func _init(turns: int = 0, regions_held: int = 0, regions_total: int = 0, ruh_gained: int = 0, guard_s: float = 0.0) -> void:
	name = "VictoryCard"
	theme_type_variation = &"ModalPanel"
	_guard_s = guard_s
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 4)
	vbox.custom_minimum_size = Vector2(180, 0)
	add_child(vbox)
	var title: Label = Label.new()
	title.theme_type_variation = &"HeaderLabel"
	title.text = tr("VICTORY")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(_line("TurnsLine", tr("RESULT_TURNS") % NumberFormatter.format_int(turns)))
	vbox.add_child(_line("RegionsLine", tr("RESULT_REGIONS") % NumberFormatter.fraction(regions_held, regions_total)))
	vbox.add_child(_line("RuhLine", tr("RESULT_RUH_GAINED") % NumberFormatter.format_int(ruh_gained)))
	_continue_button = Button.new()
	_continue_button.name = "ContinueButton"
	_continue_button.theme_type_variation = &"PrimaryButton"
	_continue_button.text = tr("CONTINUE")
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue_button.pressed.connect(_on_continue_pressed)
	vbox.add_child(_continue_button)


func _ready() -> void:
	InputGuard.arm(self, [_continue_button] as Array[BaseButton], _guard_s)


func get_focus_target() -> Control:
	return _continue_button


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and not _continue_button.disabled:
		get_viewport().set_input_as_handled()
		_on_continue_pressed()


func _line(node_name: String, text: String) -> Label:
	var label: Label = Label.new()
	label.name = node_name
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _on_continue_pressed() -> void:
	acknowledged.emit()
	closed.emit()
