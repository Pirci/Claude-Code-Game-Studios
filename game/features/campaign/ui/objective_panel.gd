class_name ObjectivePanel
extends PanelContainer
## Hedef işareti paneli — `KOK_BORI_MARK` B (scene-flow §3.5): Kök Böri sözü + hedef metni +
## [Başla]. Mekanik hedef metni kazanma koşulundan okunur (tek doğruluk kaynağı). Esc paneli
## kapatmaz; yalnız [Başla] / Enter / Space.


signal dismissed
signal closed

const TEXT_WIDTH: int = 280

var _guard_s: float = 0.0
var _start_button: Button


## [param line_key] sahnenin Kök Böri sözü, [param objective_key] `WinCondition.description_key`.
func _init(line_key: StringName = &"", objective_key: StringName = &"", guard_s: float = 0.0) -> void:
	name = "ObjectivePanel"
	theme_type_variation = &"DivinePanel"
	_guard_s = guard_s
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 6)
	add_child(vbox)
	var title: Label = Label.new()
	title.theme_type_variation = &"HeaderLabel"
	title.text = tr("KOK_BORI")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(_wrapped("KokBoriLine", tr(String(line_key))))
	vbox.add_child(_wrapped("ObjectiveText", "%s: %s" % [tr("OBJECTIVE_LABEL"), tr(String(objective_key))]))
	_start_button = Button.new()
	_start_button.name = "StartButton"
	_start_button.theme_type_variation = &"PrimaryButton"
	_start_button.text = tr("START_SCENE")
	_start_button.custom_minimum_size = Vector2(64, 0)
	_start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_start_button.pressed.connect(_on_start_pressed)
	vbox.add_child(_start_button)


func _ready() -> void:
	InputGuard.arm(self, [_start_button] as Array[BaseButton], _guard_s)


func get_focus_target() -> Control:
	return _start_button


func _wrapped(node_name: String, text: String) -> Label:
	var label: Label = Label.new()
	label.name = node_name
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(TEXT_WIDTH, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _on_start_pressed() -> void:
	dismissed.emit()
	closed.emit()
