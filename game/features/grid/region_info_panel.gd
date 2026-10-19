class_name RegionInfoPanel
extends PanelContainer
## Seçili bölgenin bilgilerini gösteren UI paneli.


signal send_army_pressed(from_id: StringName)

## UI paleti (art bible §4): Erlik bilgisi değeri ve kayıp (↓-X) rengi.
const COLOR_ERLIK_INFO := Color("#A86BC4")
const COLOR_LOSS := Color("#E87A7A")
## Etiket ile değer arası (satır içi) boşluk, piksel.
const ROW_SEPARATION: int = 4

var _region_id: StringName = &""

var _name_label: Label
var _owner_label: Label
var _army_label: Label
var _gold_label: Label
var _gold_penalty_label: Label
var _corruption_row: HBoxContainer
var _corruption_value: Label
var _hold_row: HBoxContainer
var _hold_value: Label
var _send_button: Button


func _ready() -> void:
	# Yükseklik içerikten gelir (dil bazlı font boyutu değişebilir).
	custom_minimum_size = Vector2(136, 0)
	# HUD paneli: yarı opak zemin + 1px kenarlık (art bible §7 Panel Sistemi).
	theme_type_variation = &"HudPanel"
	# Panel her dilde haritanın boş kalan sağ şeridinde durur (harita aynalanmaz);
	# içerik ise dile göre (Arapça → RTL) hizalanır.
	layout_direction = Control.LAYOUT_DIRECTION_LTR

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.layout_direction = Control.LAYOUT_DIRECTION_APPLICATION_LOCALE
	vbox.add_theme_constant_override(&"separation", 2)
	add_child(vbox)

	# Başlık vurgusu boyutla değil renkle (HeaderLabel tema varyasyonu) —
	# pixel font sadece native boyutunda keskin kalır.
	_name_label = Label.new()
	_name_label.theme_type_variation = &"HeaderLabel"
	vbox.add_child(_name_label)

	_owner_label = Label.new()
	vbox.add_child(_owner_label)

	_army_label = Label.new()
	vbox.add_child(_army_label)

	var gold_row: HBoxContainer = _row(vbox)
	_gold_label = Label.new()
	_gold_label.name = "GoldLabel"
	gold_row.add_child(_gold_label)
	_gold_penalty_label = _value_label(gold_row, "GoldPenaltyLabel", COLOR_LOSS)

	# Bozulma satırları yalnızca bozuk bölgede (art bible §7, C-50): ad birincil metin,
	# değer "Erlik bilgisi" rengi.
	_corruption_row = _row(vbox)
	_corruption_row.name = "CorruptionRow"
	_name_cell(_corruption_row, "CORRUPTION")
	_corruption_value = _value_label(_corruption_row, "CorruptionValue", COLOR_ERLIK_INFO)
	_hold_row = _row(vbox)
	_hold_row.name = "ErlikHoldRow"
	_name_cell(_hold_row, "ERLIK_HOLD")
	_hold_value = _value_label(_hold_row, "ErlikHoldValue", COLOR_ERLIK_INFO)

	_send_button = Button.new()
	_send_button.theme_type_variation = &"PrimaryButton"  # birincil aksiyon (art bible §7)
	_send_button.text = tr("SEND_ARMY")
	_send_button.pressed.connect(_on_send_pressed)
	vbox.add_child(_send_button)

	hide()


## [param corruption_strength] arınma direnci `S`, [param max_corruption] seviye üst sınırı,
## [param effective_gold] bozulma cezası sonrası gelir (−1 = taban gelir) — kurallar
## çağıranda hesaplanır (SpiritRules / IncomeRules), panel yalnızca gösterir (ADR-0011).
func show_region(
	data: RegionData,
	corruption_strength: int = 0,
	max_corruption: int = 3,
	effective_gold: int = -1,
) -> void:
	_region_id = data.region_id
	_name_label.text = tr(String(data.display_name_key))

	var owner_text: String = ""
	match data.owner:
		RegionData.Owner.PLAYER:
			owner_text = tr("OWNER_PLAYER")
		RegionData.Owner.ENEMY:
			owner_text = tr("OWNER_ENEMY")
		RegionData.Owner.NEUTRAL:
			owner_text = tr("OWNER_NEUTRAL")
	_owner_label.text = owner_text

	_army_label.text = "%s: %s" % [tr("ARMY"), NumberFormatter.format_int(data.army_count)]
	# "/ tur" birimi ayrı key: dile göre büyük harf ve sıra çeviride (bible: programatik harf dönüşümü yok).
	var gold: int = data.gold_per_turn if effective_gold < 0 else effective_gold
	_gold_label.text = "%s: %s" % [tr("GOLD"), tr("PER_TURN") % NumberFormatter.format_int(gold)]
	# Kayıp gösterimi: ↓ + ASCII "-" (U+2212 Fusion'da yok — ADR-0009).
	var penalty: int = data.gold_per_turn - gold
	_gold_penalty_label.text = "↓-%s" % NumberFormatter.format_int(penalty)
	_gold_penalty_label.visible = penalty > 0

	var corrupted: bool = data.corruption_level >= 1
	_corruption_row.visible = corrupted
	_hold_row.visible = corrupted
	_corruption_value.text = "%s / %s" % [
		NumberFormatter.format_int(data.corruption_level), NumberFormatter.format_int(max_corruption)]
	_hold_value.text = NumberFormatter.format_int(corruption_strength)

	_send_button.visible = data.owner == RegionData.Owner.PLAYER and data.army_count > 1
	show()


## Klavye/gamepad odak zincirine bağlanacak buton (Ordu Gönder) — görünür değilse null.
## Panel kardeşlerini bilmez; zinciri ebeveyn kurar.
func get_focus_target() -> Control:
	if visible and _send_button.visible:
		return _send_button
	return null


func hide_panel() -> void:
	_region_id = &""
	hide()


func _row(parent: Control) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", ROW_SEPARATION)
	parent.add_child(row)
	return row


func _name_cell(row: HBoxContainer, key: String) -> void:
	var label: Label = Label.new()
	label.text = "%s:" % tr(key)
	row.add_child(label)


func _value_label(row: HBoxContainer, node_name: String, color: Color) -> Label:
	var label: Label = Label.new()
	label.name = node_name
	label.add_theme_color_override(&"font_color", color)
	row.add_child(label)
	return label


func _on_send_pressed() -> void:
	send_army_pressed.emit(_region_id)
