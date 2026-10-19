class_name BoonCard
extends Button
## Lütuf kartı (art bible §7 "Lütuf ekranı"): tıklanabilir/odaklanabilir tek düğme; içinde
## altın başlık (HeaderLabel) ve sarmalı açıklama. Düğme çocuklarından boyut almadığı için
## yükseklik içerik değiştikçe içeriğin en küçük boyutuna eşitlenir.


## Kart genişliği — 3 kart + boşluklar 640px'te ortalı (en uzun tek sözcük de sığar).
const CARD_WIDTH: int = 92
const PADDING: int = 4
const MIN_HEIGHT: int = 92

var _content: VBoxContainer
var _name_label: Label
var _description_label: Label


func _init() -> void:
	custom_minimum_size = Vector2(CARD_WIDTH, MIN_HEIGHT)
	_content = VBoxContainer.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_theme_constant_override(&"separation", 4)
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.offset_left = PADDING
	_content.offset_top = PADDING
	_content.offset_right = -PADDING
	_content.offset_bottom = -PADDING
	add_child(_content)
	_name_label = _label(&"HeaderLabel")
	_name_label.name = "NameLabel"
	_description_label = _label(&"")
	_description_label.name = "DescriptionLabel"
	_content.minimum_size_changed.connect(_fit_height)


## Metinler çağıranda çevrilmiş gelir; erişilebilirlik adı ikisini birleştirir (AccessKit, 4.5+).
func set_texts(title: String, description: String) -> void:
	_name_label.text = title
	_description_label.text = description
	accessibility_name = title
	accessibility_description = description
	_fit_height()


func _label(variation: StringName) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(CARD_WIDTH - 2 * PADDING, 0)
	_content.add_child(label)
	return label


func _fit_height() -> void:
	var needed: int = ceili(_content.get_combined_minimum_size().y) + 2 * PADDING
	custom_minimum_size = Vector2(CARD_WIDTH, maxi(MIN_HEIGHT, needed))
