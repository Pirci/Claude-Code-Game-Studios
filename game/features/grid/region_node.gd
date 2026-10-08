class_name RegionNode
extends Node2D
## Haritada tıklanabilir bölge görsel temsili.
##
## Renkler art bible §4 "Sahiplik Renkleri"nden gelir: dolgu opak ana renk,
## kenar 1px rampanın koyu tonu; hover/seçim 1px Ülgen altını kontur (dolgu değişmez).


signal clicked(region_id: StringName)

## Sahiplik mini rampaları (koyu / ana / açık) — art bible §4. Opak; yarı saydam yasak.
const RAMP_PLAYER: PackedColorArray = [Color("#2E7AB8"), Color("#47A3E8"), Color("#87C4F5")]
const RAMP_ENEMY: PackedColorArray = [Color("#9A4220"), Color("#C45A2A"), Color("#E07E45")]
const RAMP_NEUTRAL: PackedColorArray = [Color("#4A453C"), Color("#6B655A"), Color("#8F897D")]
const RAMP_DARK: int = 0
const RAMP_MAIN: int = 1
const RAMP_LIGHT: int = 2
## Seçim konturu — Ülgen altını rampası.
const COLOR_SELECTED_OUTLINE := Color("#EDC76B")
## Hover konturu — aynı rampanın bir alt tonu; seçimden ayırt edilsin diye.
const COLOR_HOVER_OUTLINE := Color("#C99A3D")
## Bölge adı / ordu etiket kutusu (640×360 base, piksel).
const LABEL_WIDTH: int = 96
const LABEL_HEIGHT: int = 16

var region_id: StringName = &""
var is_selected: bool = false:
	set(value):
		if is_selected == value:
			return
		is_selected = value
		queue_redraw()

var _points: PackedVector2Array = PackedVector2Array()
var _owner: RegionData.Owner = RegionData.Owner.NEUTRAL
var _area: Area2D
var _collision: CollisionPolygon2D
var _label: Label
var _army_label: Label
var _is_hovered: bool = false


func _draw() -> void:
	if _points.size() < 3:
		return
	draw_colored_polygon(_points, get_fill_color())
	var outline: PackedVector2Array = _points.duplicate()
	outline.append(_points[0])
	# Negatif genişlik = 1px primitive çizgi (pixel grid'de keskin, ölçekten bağımsız).
	draw_polyline(outline, get_outline_color(), -1.0)


func setup(data: RegionData) -> void:
	region_id = data.region_id
	position = Vector2.ZERO
	_points = data.polygon_points

	_area = Area2D.new()
	_area.input_pickable = true
	_collision = CollisionPolygon2D.new()
	_collision.polygon = data.polygon_points
	_area.add_child(_collision)
	add_child(_area)

	_area.input_event.connect(_on_input_event)
	_area.mouse_entered.connect(_on_mouse_entered)
	_area.mouse_exited.connect(_on_mouse_exited)

	# Font boyutu override edilmez: tema dil bazlı pixel font boyutunu belirler
	# (Fusion 12 / Arapça Unifont 16). Ara boyutlar pixel fontu bozar.
	# Konumlar harita (dünya) koordinatıdır: RTL dillerde aynalanmamalı → LTR yerleşim;
	# metnin kendisi text_direction=AUTO ile yine doğru yönde çizilir.
	# Metin kutudan genişse (ör. Unifont 16) iki yana eşit büyüsün → GROW_DIRECTION_BOTH.
	_label = Label.new()
	_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_label.text = tr(String(data.display_name_key))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_label.position = data.position - Vector2(LABEL_WIDTH / 2.0, LABEL_HEIGHT)
	_label.size = Vector2(LABEL_WIDTH, LABEL_HEIGHT)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

	_army_label = Label.new()
	_army_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_army_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_army_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_army_label.position = data.position - Vector2(LABEL_WIDTH / 2.0, 0)
	_army_label.size = Vector2(LABEL_WIDTH, LABEL_HEIGHT)
	_army_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_army_label)
	update_display(data)


func update_display(data: RegionData) -> void:
	_owner = data.owner
	queue_redraw()
	if _army_label:
		_army_label.text = "%s: %d" % [tr("ARMY"), data.army_count]
	if _label:
		_label.text = tr(String(data.display_name_key))


## Sahibin 3 tonluk mini rampası (koyu / ana / açık).
static func get_owner_ramp(owner: RegionData.Owner) -> PackedColorArray:
	match owner:
		RegionData.Owner.PLAYER:
			return RAMP_PLAYER
		RegionData.Owner.ENEMY:
			return RAMP_ENEMY
		_:
			return RAMP_NEUTRAL


## Opak dolgu rengi — sahibin ana tonu; hover/seçim dolguyu değiştirmez.
func get_fill_color() -> Color:
	return get_owner_ramp(_owner)[RAMP_MAIN]


## 1px kontur rengi: seçim > hover > rampanın koyu tonu.
func get_outline_color() -> Color:
	if is_selected:
		return COLOR_SELECTED_OUTLINE
	if _is_hovered:
		return COLOR_HOVER_OUTLINE
	return get_owner_ramp(_owner)[RAMP_DARK]


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(region_id)


func _on_mouse_entered() -> void:
	_is_hovered = true
	queue_redraw()


func _on_mouse_exited() -> void:
	_is_hovered = false
	queue_redraw()
