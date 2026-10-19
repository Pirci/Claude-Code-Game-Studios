class_name RegionInfoPanel
extends PanelContainer
## Seçili bölgenin bilgilerini gösteren UI paneli.


signal send_army_pressed(from_id: StringName)
signal recruit_pressed(region_id: StringName, count: int)

## UI paleti (art bible §4): Erlik bilgisi değeri ve kayıp (↓-X) rengi.
const COLOR_ERLIK_INFO := Color("#A86BC4")
const COLOR_LOSS := Color("#E87A7A")
## Etiket ile değer arası (satır içi) boşluk, piksel.
const ROW_SEPARATION: int = 4

var _region_id: StringName = &""
## Seçici değeri yalnızca başka bölgeye geçince 1'e döner (aynı bölge yenilenince korunur).
var _shown_region_id: StringName = &""

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
var _recruit_box: VBoxContainer
var _recruit_minus: Button
var _recruit_count_label: Label
var _recruit_plus: Button
var _recruit_confirm: Button
var _recruit_cost_label: Label
var _recruit_cap_label: Label
var _recruit_hint_label: Label
var _reinforcement_row: HBoxContainer
var _reinforcement_value: Label
var _recruit_count: int = 1
var _recruit_max: int = 0
var _recruit_cost: int = 0


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

	_build_recruit_section(vbox)

	# Düşman bölgesi: tur başına takviye bilgisi (resource-system §10).
	_reinforcement_row = _row(vbox)
	_reinforcement_row.name = "ReinforcementRow"
	_name_cell(_reinforcement_row, "ENEMY_REINFORCEMENT")
	_reinforcement_value = _value_label(_reinforcement_row, "ReinforcementValue", COLOR_LOSS)

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
	if data.region_id != _shown_region_id:
		_recruit_count = 1
	_shown_region_id = data.region_id
	_recruit_box.hide()
	_reinforcement_row.hide()
	show()


## Ordu Topla bölümü (resource-system §10, AC17): [param used] / [param cap] bu turun sayacı,
## [param max_count] seçicinin üst sınırı (0 → pasif), [param missing_gold] tek birlik için
## eksik altın. Değerler [ResourceController]'dan; panel yalnızca gösterir (ADR-0011).
func show_recruit(used: int, cap: int, max_count: int, cost: int, missing_gold: int) -> void:
	_recruit_max = max_count
	_recruit_cost = cost
	_recruit_count = clampi(_recruit_count, 1, maxi(1, max_count))
	_recruit_cap_label.text = tr("RECRUIT_CAP") % _fraction(used, cap)
	var blocked: bool = max_count < 1
	_recruit_hint_label.visible = blocked
	if used >= cap:
		_recruit_hint_label.text = tr("RECRUIT_CAP_REACHED") % _fraction(used, cap)
	else:
		_recruit_hint_label.text = tr("RECRUIT_NOT_ENOUGH_GOLD") % NumberFormatter.format_int(missing_gold)
	_recruit_box.show()
	_update_recruit_selector()


## Düşman bölgesinin tur sonu takviyesi (F6) — bilgi satırı.
func show_reinforcement(per_turn: int) -> void:
	_reinforcement_value.text = tr("PER_TURN") % ("+" + NumberFormatter.format_int(per_turn))
	_reinforcement_row.show()


## Klavye odak zincirine bağlanacak en alttaki kontrol (Ordu Topla onayı, yoksa Ordu
## Gönder) — görünür değilse null. Panel kardeşlerini bilmez; zinciri ebeveyn kurar.
func get_focus_target() -> Control:
	if not visible:
		return null
	if _recruit_box.visible:
		return _recruit_confirm
	if _send_button.visible:
		return _send_button
	return null


func hide_panel() -> void:
	_region_id = &""
	_shown_region_id = &""
	hide()


func _build_recruit_section(parent: VBoxContainer) -> void:
	_recruit_box = VBoxContainer.new()
	_recruit_box.name = "RecruitBox"
	_recruit_box.add_theme_constant_override(&"separation", 2)
	parent.add_child(_recruit_box)

	var header: Label = Label.new()
	header.text = tr("RECRUIT")
	_recruit_box.add_child(header)

	# −/+ seçici ve onay: [-] k [+] [Topla]. Eksi ASCII "-" (U+2212 Fusion'da yok — ADR-0009).
	var selector: HBoxContainer = _row(_recruit_box)
	selector.name = "RecruitSelector"
	_recruit_minus = _small_button(selector, "RecruitMinus", "-")
	_recruit_minus.pressed.connect(_on_recruit_step.bind(-1))
	_recruit_count_label = Label.new()
	_recruit_count_label.name = "RecruitCount"
	_recruit_count_label.custom_minimum_size = Vector2(12, 0)
	_recruit_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selector.add_child(_recruit_count_label)
	_recruit_plus = _small_button(selector, "RecruitPlus", "+")
	_recruit_plus.pressed.connect(_on_recruit_step.bind(1))
	_recruit_confirm = Button.new()
	_recruit_confirm.name = "RecruitConfirm"
	_recruit_confirm.text = tr("RECRUIT_CONFIRM")
	_recruit_confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_recruit_confirm.pressed.connect(_on_recruit_confirm)
	selector.add_child(_recruit_confirm)

	_recruit_cost_label = Label.new()
	_recruit_cost_label.name = "RecruitCost"
	_recruit_box.add_child(_recruit_cost_label)
	_recruit_cap_label = Label.new()
	_recruit_cap_label.name = "RecruitCap"
	_recruit_box.add_child(_recruit_cap_label)
	# İpucu uzun dillerde sarar (panel 136px sabit — §10 Yerleşim).
	_recruit_hint_label = Label.new()
	_recruit_hint_label.name = "RecruitHint"
	_recruit_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_recruit_hint_label.add_theme_color_override(&"font_color", COLOR_LOSS)
	_recruit_box.add_child(_recruit_hint_label)
	_recruit_box.hide()


func _small_button(row: HBoxContainer, node_name: String, text: String) -> Button:
	var button: Button = Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = Vector2(14, 0)
	row.add_child(button)
	return button


func _update_recruit_selector() -> void:
	var blocked: bool = _recruit_max < 1
	_recruit_count_label.text = NumberFormatter.format_int(_recruit_count)
	_recruit_minus.disabled = blocked or _recruit_count <= 1
	_recruit_plus.disabled = blocked or _recruit_count >= _recruit_max
	_recruit_confirm.disabled = blocked
	_recruit_cost_label.text = tr("RECRUIT_COST") % NumberFormatter.format_int(_recruit_count * _recruit_cost)


func _fraction(used: int, cap: int) -> String:
	return "%s / %s" % [NumberFormatter.format_int(used), NumberFormatter.format_int(cap)]


func _on_recruit_step(delta: int) -> void:
	_recruit_count = clampi(_recruit_count + delta, 1, maxi(1, _recruit_max))
	_update_recruit_selector()


func _on_recruit_confirm() -> void:
	if _recruit_max >= 1:
		recruit_pressed.emit(_region_id, _recruit_count)


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
