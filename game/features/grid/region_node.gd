class_name RegionNode
extends Node2D
## Haritada tıklanabilir bölge görsel temsili.


signal clicked(region_id: StringName)

const COLOR_PLAYER := Color(0.2, 0.5, 0.9, 0.6)
const COLOR_ENEMY := Color(0.9, 0.2, 0.2, 0.6)
const COLOR_NEUTRAL := Color(0.6, 0.6, 0.6, 0.4)
const COLOR_SELECTED := Color(1.0, 0.9, 0.3, 0.7)
const COLOR_HOVER := Color(1.0, 1.0, 1.0, 0.15)

var region_id: StringName = &""
var is_selected: bool = false

var _polygon: Polygon2D
var _area: Area2D
var _collision: CollisionPolygon2D
var _label: Label
var _army_label: Label
var _is_hovered: bool = false
var _base_color: Color = COLOR_NEUTRAL


func setup(data: RegionData) -> void:
	region_id = data.region_id
	position = Vector2.ZERO

	_polygon = Polygon2D.new()
	_polygon.polygon = data.polygon_points
	_polygon.color = _get_owner_color(data.owner)
	add_child(_polygon)

	_area = Area2D.new()
	_area.input_pickable = true
	_collision = CollisionPolygon2D.new()
	_collision.polygon = data.polygon_points
	_area.add_child(_collision)
	add_child(_area)

	_area.input_event.connect(_on_input_event)
	_area.mouse_entered.connect(_on_mouse_entered)
	_area.mouse_exited.connect(_on_mouse_exited)

	_label = Label.new()
	_label.text = tr(String(data.display_name_key))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = data.position - Vector2(80, 30)
	_label.size = Vector2(160, 30)
	_label.add_theme_font_size_override(&"font_size", 16)
	add_child(_label)

	_army_label = Label.new()
	_army_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_army_label.position = data.position - Vector2(40, 5)
	_army_label.size = Vector2(80, 25)
	_army_label.add_theme_font_size_override(&"font_size", 14)
	add_child(_army_label)
	update_display(data)


func update_display(data: RegionData) -> void:
	_base_color = _get_owner_color(data.owner)
	if _polygon:
		if is_selected:
			_polygon.color = COLOR_SELECTED
		else:
			_polygon.color = _base_color
	if _army_label:
		_army_label.text = "%s: %d" % [tr("ARMY"), data.army_count]
	if _label:
		_label.text = tr(String(data.display_name_key))


func _get_owner_color(owner: RegionData.Owner) -> Color:
	match owner:
		RegionData.Owner.PLAYER:
			return COLOR_PLAYER
		RegionData.Owner.ENEMY:
			return COLOR_ENEMY
		_:
			return COLOR_NEUTRAL


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(region_id)


func _on_mouse_entered() -> void:
	_is_hovered = true
	if _polygon and not is_selected:
		_polygon.color = _polygon.color.lightened(0.15)


func _on_mouse_exited() -> void:
	_is_hovered = false
	if _polygon and not is_selected:
		_polygon.color = _base_color
