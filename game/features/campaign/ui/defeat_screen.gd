class_name DefeatScreen
extends PanelContainer
## Yenilgi ekranı — `DEFEAT` (scene-flow §3.7): neden metni (sahneye özel → `DEFEAT_REASON_*`
## → genel), Erlik kaybında `erlik_power / eşik`, ilerleme güvencesi; [Sahneyi Yeniden Dene]
## (birincil) ve [Ana Menü]. Kayıt yazılmaz — yalnızca niyet sinyalleri.


signal retry_requested
signal menu_requested
signal closed

const TEXT_WIDTH: int = 260

var _guard_s: float = 0.0
var _retry_button: Button
var _menu_button: Button


## [param erlik_threshold] > 0 ise "Erlik'in Gölgesi: güç / eşik" satırı gösterilir (Erlik kaybı).
func _init(reason_key: StringName = &"", erlik_power: int = 0, erlik_threshold: int = 0, guard_s: float = 0.0) -> void:
	name = "DefeatScreen"
	theme_type_variation = &"ModalPanel"
	_guard_s = guard_s
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 6)
	add_child(vbox)
	var title: Label = Label.new()
	title.theme_type_variation = &"HeaderLabel"
	title.text = tr("DEFEAT")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(_wrapped("ReasonText", tr(String(reason_key))))
	if erlik_threshold > 0:
		vbox.add_child(_wrapped("ErlikValue", tr("ERLIK_SHADOW_VALUE") % [
			NumberFormatter.format_int(erlik_power), NumberFormatter.format_int(erlik_threshold)]))
	vbox.add_child(_wrapped("ProgressKept", tr("DEFEAT_PROGRESS_KEPT")))
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override(&"separation", 12)
	vbox.add_child(buttons)
	_retry_button = Button.new()
	_retry_button.name = "RetryButton"
	_retry_button.theme_type_variation = &"PrimaryButton"
	_retry_button.text = tr("RETRY_SCENE")
	_retry_button.pressed.connect(_answer.bind(true))
	buttons.add_child(_retry_button)
	_menu_button = Button.new()
	_menu_button.name = "MenuButton"
	_menu_button.text = tr("MAIN_MENU")
	_menu_button.pressed.connect(_answer.bind(false))
	buttons.add_child(_menu_button)


func _ready() -> void:
	InputGuard.arm(self, [_retry_button, _menu_button] as Array[BaseButton], _guard_s)


func get_focus_target() -> Control:
	return _retry_button


func _wrapped(node_name: String, text: String) -> Label:
	var label: Label = Label.new()
	label.name = node_name
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(TEXT_WIDTH, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _answer(retry: bool) -> void:
	if retry:
		retry_requested.emit()
	else:
		menu_requested.emit()
	closed.emit()
