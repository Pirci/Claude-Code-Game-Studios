class_name BoonCard
extends Button
## Lütuf kartı (art bible §7 "Lütuf ekranı"): tıklanabilir/odaklanabilir tek düğme; içinde
## altın başlık (HeaderLabel) ve sarmalı açıklama. Düğme çocuklarından boyut almadığı için
## yükseklik içerik değiştikçe içeriğin en küçük boyutuna eşitlenir.


## Kart genişliği — 3 kart + boşluklar 640px'te ortalı (en uzun tek sözcük de sığar).
const CARD_WIDTH: int = 92
const PADDING: int = 4
const MIN_HEIGHT: int = 92
## Lütuf ikonu adın solunda aynı satırda (ux/boon-selection.md §6, C-46/C-67); adın en uzun
## sözcüğü daralan alana sığmıyorsa (sözcük ortasından bölünmesin diye) ikon adın üstüne geçer.
const ICON_SIZE: int = 24
const ICON_GAP: int = 2

var _content: VBoxContainer
var _name_row: BoxContainer
var _icon: TextureRect
var _name_label: Label
var _description_label: Label
var _stack_label: Label


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
	_name_row = BoxContainer.new()
	_name_row.name = "NameRow"
	_name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_name_row.add_theme_constant_override(&"separation", ICON_GAP)
	_content.add_child(_name_row)
	_icon = TextureRect.new()
	_icon.name = "Icon"
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_icon.hide()
	_name_row.add_child(_icon)
	_name_label = _label(&"HeaderLabel", _name_row)
	_name_label.name = "NameLabel"
	_description_label = _label(&"")
	_description_label.name = "DescriptionLabel"
	_stack_label = _label(&"SecondaryLabel")
	_stack_label.name = "StackLabel"
	_stack_label.hide()
	_content.minimum_size_changed.connect(_fit_height)


## Ağaca girişte / dil fontu değişince (Arapça Unifont) ölçüm yeniden yapılır.
func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and _name_label != null:
		_layout_name_row()


## Kart ikonu; null → ikon gizlenir ve ad tam genişliği kullanır.
func set_icon(texture: Texture2D) -> void:
	_icon.texture = texture
	_icon.visible = texture != null
	_layout_name_row()


## Testler için: ikon adın üstünde mi (dar alana sığmayan uzun sözcük).
func is_icon_stacked() -> bool:
	return _name_row.vertical


## Metinler çağıranda çevrilmiş gelir; erişilebilirlik adı ikisini birleştirir (AccessKit, 4.5+).
func set_texts(title: String, description: String) -> void:
	_name_label.text = title
	_description_label.text = description
	accessibility_name = title
	accessibility_description = description
	_layout_name_row()


## Yığın satırı (`×1/3`, `×3/3 (son)`, `×2`); boş → gizli. Metin çağıranda biçimlenir ve LTR yalıtılır.
func set_stack(text: String) -> void:
	_stack_label.text = text
	_stack_label.visible = not text.is_empty()
	accessibility_description = _description_label.text if text.is_empty() \
		else "%s %s" % [_description_label.text, text]
	_fit_height()


func _label(variation: StringName, parent: Container = null) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(_text_width(), 0)
	(parent if parent != null else _content).add_child(label)
	return label


func _text_width() -> int:
	return CARD_WIDTH - 2 * PADDING


## İkon varken ad solunda (dar) ya da üstünde (tam genişlik); sözcük ortasından bölünme olmaz.
func _layout_name_row() -> void:
	var inline_width: int = _text_width() - ICON_SIZE - ICON_GAP
	var stacked: bool = _icon.visible and _longest_word_width(_name_label.text) > inline_width
	_name_row.vertical = stacked
	_name_label.custom_minimum_size.x = inline_width if _icon.visible and not stacked else _text_width()
	_fit_height()


func _longest_word_width(text: String) -> float:
	var font: Font = _name_label.get_theme_font(&"font")
	var font_size: int = _name_label.get_theme_font_size(&"font_size")
	var widest: float = 0.0
	for word: String in text.split(" ", false):
		widest = maxf(widest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	return widest


func _fit_height() -> void:
	var needed: int = ceili(_content.get_combined_minimum_size().y) + 2 * PADDING
	custom_minimum_size = Vector2(CARD_WIDTH, maxi(MIN_HEIGHT, needed))
