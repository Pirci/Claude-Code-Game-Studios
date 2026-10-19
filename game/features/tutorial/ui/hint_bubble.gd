class_name HintBubble
extends PanelContainer
## Bağlamsal öğretici ipucu balonu (design/ux/prolog-tutorial.md): haritayı ve girdiyi
## kilitlemez; metin + [Anladım]. Pasif görünüm — yalnızca `dismissed(hint_id)` bildirir.


signal dismissed(hint_id: StringName)

const TEXT_WIDTH: int = 216

var hint_id: StringName = &""
var _got_it: Button


func _init(id: StringName = &"") -> void:
	hint_id = id
	name = "HintBubble"
	theme_type_variation = &"HudPanel"
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 4)
	add_child(vbox)
	var text: Label = Label.new()
	text.name = "HintText"
	text.text = tr(TutorialRules.text_key(id))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(TEXT_WIDTH, 0)
	vbox.add_child(text)
	_got_it = Button.new()
	_got_it.name = "GotItButton"
	_got_it.text = tr("TUTORIAL_GOT_IT")
	_got_it.size_flags_horizontal = Control.SIZE_SHRINK_END
	_got_it.pressed.connect(func() -> void: dismissed.emit(hint_id))
	vbox.add_child(_got_it)
