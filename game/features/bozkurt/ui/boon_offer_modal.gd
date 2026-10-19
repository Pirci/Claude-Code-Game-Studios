class_name BoonOfferModal
extends PanelContainer
## Kök Böri lütuf sunumu (spirit-system.md §3.4, ADR-0011): üç kart, biri seçilir; zorunlu
## değilse "Sonra" ya da Esc ile ertelenir. Pasif görünüm — veriyi [method show_offer] alır,
## niyeti sinyalle bildirir; seçimi [SpiritController] uygular, kapanışı [ModalQueue] yönetir.


signal boon_picked(boon_id: StringName)
signal deferred
signal closed

## Kök Böri sözünün sarma genişliği (3 kart + boşluklar — [constant BoonCard.CARD_WIDTH]).
const LINE_WIDTH: int = 288

var _mandatory: bool = false
var _cards: Array[BoonCard] = []
var _spirit_label: Label
var _cost_label: Label
var _cards_row: HBoxContainer
var _defer_button: Button


func _init() -> void:
	name = "BoonOfferModal"
	# İlahi panel (art bible §7): koyu indigo zemin, 2px altın kenar.
	theme_type_variation = &"DivinePanel"
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 4)
	add_child(vbox)

	var title: Label = Label.new()
	title.theme_type_variation = &"HeaderLabel"
	title.text = tr("KOK_BORI")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var line: Label = Label.new()
	line.name = "OfferLine"
	line.text = tr("BOON_OFFER_LINE")
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size = Vector2(LINE_WIDTH, 0)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(line)

	var stats: HBoxContainer = HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override(&"separation", 12)
	vbox.add_child(stats)
	_spirit_label = Label.new()
	_spirit_label.name = "SpiritLabel"
	stats.add_child(_spirit_label)
	_cost_label = Label.new()
	_cost_label.name = "CostLabel"
	stats.add_child(_cost_label)

	_cards_row = HBoxContainer.new()
	_cards_row.name = "Cards"
	_cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_row.add_theme_constant_override(&"separation", 6)
	vbox.add_child(_cards_row)

	_defer_button = Button.new()
	_defer_button.name = "DeferButton"
	_defer_button.text = tr("BOON_DEFER")
	_defer_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_defer_button.pressed.connect(_on_defer_pressed)
	vbox.add_child(_defer_button)


## [param boons] sunumun 3 kartı (aynı lütuf tekrar edebilir — §5), [param ruh] mevcut Ruh,
## [param cost] bu seçimin maliyeti; [param mandatory] sahne sonunda ertelemeyi kapatır.
func show_offer(boons: Array[BoonDefinition], ruh: int, cost: int, mandatory: bool) -> void:
	_mandatory = mandatory
	_spirit_label.text = "%s: %s" % [tr("SPIRIT"), NumberFormatter.format_int(ruh)]
	_cost_label.text = tr("BOON_COST") % NumberFormatter.format_int(cost)
	for card: BoonCard in _cards:
		_cards_row.remove_child(card)
		card.queue_free()
	_cards.clear()
	for i: int in boons.size():
		_cards.append(_card(boons[i], i))
	_defer_button.visible = not mandatory


## [ModalQueue] açılışta odağı buraya verir: ilk kart.
func get_focus_target() -> Control:
	return _cards[0] if not _cards.is_empty() else _defer_button


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and not _mandatory:
		get_viewport().set_input_as_handled()
		_on_defer_pressed()


func _card(boon: BoonDefinition, index: int) -> BoonCard:
	var card: BoonCard = BoonCard.new()
	card.name = "Card%d" % index
	card.set_texts(tr(boon.name_key), tr(boon.description_key) % NumberFormatter.format_int(boon.display_amount()))
	card.pressed.connect(_on_card_pressed.bind(boon.boon_id))
	_cards_row.add_child(card)
	return card


func _on_card_pressed(boon_id: StringName) -> void:
	boon_picked.emit(boon_id)
	closed.emit()


func _on_defer_pressed() -> void:
	if _mandatory:
		return
	deferred.emit()
	closed.emit()
