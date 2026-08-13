class_name RegionInfoPanel
extends PanelContainer
## Seçili bölgenin bilgilerini gösteren UI paneli.


signal send_army_pressed(from_id: StringName)

var _region_id: StringName = &""

var _name_label: Label
var _owner_label: Label
var _army_label: Label
var _gold_label: Label
var _send_button: Button


func _ready() -> void:
	custom_minimum_size = Vector2(280, 200)
	size = Vector2(280, 200)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 8)
	add_child(vbox)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override(&"font_size", 22)
	vbox.add_child(_name_label)

	_owner_label = Label.new()
	vbox.add_child(_owner_label)

	_army_label = Label.new()
	vbox.add_child(_army_label)

	_gold_label = Label.new()
	vbox.add_child(_gold_label)

	_send_button = Button.new()
	_send_button.text = tr("SEND_ARMY")
	_send_button.pressed.connect(_on_send_pressed)
	vbox.add_child(_send_button)

	hide()


func show_region(data: RegionData) -> void:
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

	_army_label.text = "%s: %d" % [tr("ARMY"), data.army_count]
	_gold_label.text = "%s: %d / %s" % [tr("GOLD"), data.gold_per_turn, tr("TURN").to_lower()]

	_send_button.visible = data.owner == RegionData.Owner.PLAYER and data.army_count > 1
	show()


func hide_panel() -> void:
	_region_id = &""
	hide()


func _on_send_pressed() -> void:
	send_army_pressed.emit(_region_id)
