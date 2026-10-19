class_name ConfirmDialog
extends PanelContainer
## Evet / Hayır onay modalı (scene-flow §10: `CONFIRM_NEW_CAMPAIGN`, `CONFIRM_LEAVE_SCENE`).
## Varsayılan odak Hayır; Esc = Hayır. [ModalQueue] sözleşmesi: kapanınca `closed`.


signal confirmed
signal cancelled
signal closed

## Mesajın sarma genişliği (640×360 içinde ortalı modal).
const MESSAGE_WIDTH: int = 260

var _no_button: Button


func _init(message_key: String = "") -> void:
	name = "ConfirmDialog"
	theme_type_variation = &"ModalPanel"
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 8)
	add_child(vbox)
	var message: Label = Label.new()
	message.name = "Message"
	message.text = tr(message_key)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size = Vector2(MESSAGE_WIDTH, 0)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(message)
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override(&"separation", 12)
	vbox.add_child(buttons)
	var yes: Button = Button.new()
	yes.name = "YesButton"
	yes.text = tr("YES")
	yes.custom_minimum_size = Vector2(48, 0)
	yes.pressed.connect(_answer.bind(true))
	buttons.add_child(yes)
	_no_button = Button.new()
	_no_button.name = "NoButton"
	_no_button.text = tr("NO")
	_no_button.custom_minimum_size = Vector2(48, 0)
	_no_button.pressed.connect(_answer.bind(false))
	buttons.add_child(_no_button)


func get_focus_target() -> Control:
	return _no_button


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_answer(false)


func _answer(yes: bool) -> void:
	if yes:
		confirmed.emit()
	else:
		cancelled.emit()
	closed.emit()
