class_name BoonOfferModal
extends PanelContainer
## Kök Böri lütuf sunumu (spirit-system.md §3.4, ADR-0011): üç kart, biri seçilir; zorunlu
## değilse "Sonra" ya da Esc ile ertelenir. Pasif görünüm — veriyi [method show_offer] alır,
## niyeti sinyalle bildirir; seçimi [SpiritController] uygular, kapanışı [ModalQueue] yönetir.
## Her sunum türünde (zorunlu, şafak, HUD, yükleme) açılışta girdi koruması: kartlar ve [Sonra]
## pasif, Esc düşer (boon-selection AC8, scene-flow §0.3).


signal boon_picked(boon_id: StringName)
signal deferred
signal closed

## Kök Böri sözünün sarma genişliği (3 kart + boşluklar — [constant BoonCard.CARD_WIDTH]).
const LINE_WIDTH: int = 288
## Panel yükseklik bütçesi (ux §5.2, AC9): 360 − üst (40) − alt (31) − 8 px pay. Aşılırsa önce figür
## (henüz yok), sonra bilgi taşımayan Kök Böri sözü gizlenir — Ruh / bedel / kartlar hep görünür.
const MAX_HEIGHT: int = 281

var _mandatory: bool = false
var _cards: Array[BoonCard] = []
var _spirit_label: Label
var _cost_label: Label
var _remaining_label: Label
var _cards_row: HBoxContainer
var _carries_label: Label
var _defer_button: Button
var _offer_line: Label
var _guard_s: float = 0.0


func _init(guard_s: float = 0.0) -> void:
	name = "BoonOfferModal"
	_guard_s = guard_s
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
	_offer_line = line
	line.name = "OfferLine"
	line.text = tr("BOON_OFFER_LINE")
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size = Vector2(LINE_WIDTH, 0)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(line)

	# Ruh / Bedel / Kalan ayrı etiketler (`→` yok, ux §6); uzun dilde satır kırılır (HFlow).
	var stats: HFlowContainer = HFlowContainer.new()
	stats.name = "Stats"
	stats.alignment = FlowContainer.ALIGNMENT_CENTER
	stats.custom_minimum_size = Vector2(LINE_WIDTH, 0)
	stats.add_theme_constant_override(&"h_separation", 12)
	vbox.add_child(stats)
	_spirit_label = Label.new()
	_spirit_label.name = "SpiritLabel"
	stats.add_child(_spirit_label)
	_cost_label = Label.new()
	_cost_label.name = "CostLabel"
	stats.add_child(_cost_label)
	_remaining_label = Label.new()
	_remaining_label.name = "RemainingLabel"
	stats.add_child(_remaining_label)

	# Sahne sonu altyazısı (scene-flow §3.6): lütuf sonraki sahnelere taşınır.
	_carries_label = Label.new()
	_carries_label.name = "CarriesOnLabel"
	_carries_label.text = tr("BOON_CARRIES_ON")
	_carries_label.theme_type_variation = &"SecondaryLabel"
	_carries_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_carries_label.custom_minimum_size = Vector2(LINE_WIDTH, 0)
	_carries_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_carries_label.hide()
	vbox.add_child(_carries_label)

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


## [param boons] sunumun 3 kartı (aynı lütuf tekrar edebilir — §5; görünüm tekrarları birleştirir),
## [param ruh] mevcut Ruh, [param cost] bu seçimin maliyeti; [param mandatory] sahne sonunda
## ertelemeyi kapatır; [param stacks] `boon_id` → şu anki yığın sayısı (yoksa 0).
func show_offer(boons: Array[BoonDefinition], ruh: int, cost: int, mandatory: bool,
		stacks: Dictionary = {}) -> void:
	_mandatory = mandatory
	_spirit_label.text = "%s: %s" % [tr("SPIRIT"), NumberFormatter.format_int(ruh)]
	_cost_label.text = tr("BOON_COST") % NumberFormatter.format_int(cost)
	_remaining_label.text = tr("BOON_REMAINING") % NumberFormatter.format_int(maxi(0, ruh - cost))
	for card: BoonCard in _cards:
		_cards_row.remove_child(card)
		card.queue_free()
	_cards.clear()
	for boon: BoonDefinition in unique_boons(boons):
		var card: BoonCard = _card(boon, _cards.size())
		var max_stacks: int = boon.modifier_source.max_stacks if boon.modifier_source != null else 0
		card.set_stack(stack_text(int(stacks.get(boon.boon_id, 0)), max_stacks))
		_cards.append(card)
	_defer_button.visible = not mandatory
	_carries_label.visible = mandatory
	_offer_line.show()
	if is_inside_tree():
		_fit_height_budget()


## AC9: bütçeyi aşan dilde (ru/ar uzun kart metinleri) Kök Böri sözü gizlenir. Kart yükseklikleri
## ağaca girdikten sonra (tema/font) oturur — bu yüzden her en küçük boyut değişiminde yeniden bakılır;
## yalnız gizler (söz yeni sunumda [method show_offer] ile geri gelir), döngü olmaz.
func _fit_height_budget() -> void:
	if _offer_line.visible and get_combined_minimum_size().y > MAX_HEIGHT:
		_offer_line.hide()


## Testler / ölçüm: bütçe nedeniyle söz gizlendi mi.
func is_offer_line_hidden() -> bool:
	return not _offer_line.visible


func _ready() -> void:
	minimum_size_changed.connect(_fit_height_budget)
	_fit_height_budget()
	var buttons: Array[BaseButton] = [_defer_button]
	for card: BoonCard in _cards:
		buttons.append(card)
	InputGuard.arm(self, buttons, _guard_s)


## [ModalQueue] açılışta odağı buraya verir: ilk kart.
func get_focus_target() -> Control:
	return _cards[0] if not _cards.is_empty() else _defer_button


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and not _mandatory:
		get_viewport().set_input_as_handled()
		if not _defer_button.disabled:  # koruma içinde Esc düşer (kuyruğa alınmaz)
			_on_defer_pressed()


## Havuz < 3'te tekrar eden slotlar tek karta iner (sıra korunur; ux §6 "Tekrarlı kartlar").
static func unique_boons(boons: Array[BoonDefinition]) -> Array[BoonDefinition]:
	var unique: Array[BoonDefinition] = []
	for boon: BoonDefinition in boons:
		if boon not in unique:
			unique.append(boon)
	return unique


## Yığın satırı (ux §6): sınırlıda bu seçimden sonraki `×N/MAX` (+ son yığında `(son)`); sınırsızda yalnız
## daha önce alınmışsa `×N`; ilk sınırsız alımda boş. Sayılı biçim LTR yalıtılır (Arapça, C-76).
static func stack_text(current_stacks: int, max_stacks: int) -> String:
	var after: int = current_stacks + 1
	if max_stacks > 0:
		var text: String = TranslationServer.translate("BOON_STACK") % [
			NumberFormatter.format_int(after), NumberFormatter.format_int(max_stacks)]
		text = NumberFormatter.ltr(text)
		if after >= max_stacks:
			text += " " + TranslationServer.translate("BOON_STACK_LAST")
		return text
	if current_stacks > 0:
		return NumberFormatter.ltr(TranslationServer.translate("BOON_STACK_COUNT") % NumberFormatter.format_int(after))
	return ""


func _card(boon: BoonDefinition, index: int) -> BoonCard:
	var card: BoonCard = BoonCard.new()
	card.name = "Card%d" % index
	card.set_texts(tr(boon.name_key), tr(boon.description_key) % NumberFormatter.format_int(boon.display_amount()))
	card.set_icon(boon.icon)
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
