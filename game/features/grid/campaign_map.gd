class_name CampaignMap
extends Node2D
## Bölüm haritasının görsel kök node'u. RegionNode'ları ve çizgileri yönetir.


signal region_clicked(region_id: StringName)

var _region_nodes: Dictionary = {}  # StringName -> RegionNode
var _line_drawer: AdjacencyLineDrawer
var _line_color: Color = AdjacencyLineDrawer.DEFAULT_LINE_COLOR
var _tamgas: TamgaLibrary = TamgaLibrary.new()


func build_map(map_state: MapState) -> void:
	_clear()

	_line_drawer = AdjacencyLineDrawer.new()
	_line_drawer.line_color = _line_color
	add_child(_line_drawer)
	_line_drawer.build_connections(map_state)

	for region: RegionData in map_state.regions.values():
		var node: RegionNode = RegionNode.new()
		node.setup(region)
		node.set_tamga(_tamgas.get_texture(map_state.get_owner_tamga_id(region.owner)))
		node.clicked.connect(_on_region_clicked)
		add_child(node)
		_region_nodes[region.region_id] = node


## Bölümün komşuluk çizgisi rengi (ChapterMapDefinition.adjacency_line_color).
func set_line_color(color: Color) -> void:
	_line_color = color
	if _line_drawer != null:
		_line_drawer.line_color = color


func refresh(map_state: MapState) -> void:
	for region: RegionData in map_state.regions.values():
		var node: RegionNode = _region_nodes.get(region.region_id) as RegionNode
		if node:
			node.update_display(region)
			node.set_tamga(_tamgas.get_texture(map_state.get_owner_tamga_id(region.owner)))


func set_selected(region_id: StringName) -> void:
	for id: StringName in _region_nodes:
		var node: RegionNode = _region_nodes[id] as RegionNode
		node.is_selected = (id == region_id)


## Erişilebilirlik tercihlerini tüm bölgelere uygular (null = varsayılanlar).
func apply_accessibility(settings: AccessibilitySettings) -> void:
	if settings == null:
		return
	for node: RegionNode in _region_nodes.values():
		node.color_blind_mode = settings.color_blind_mode
		node.show_name_label = settings.show_region_names
		node.reduce_motion = settings.reduce_motion


## Hedef işaretleri (F7 `V`): listedeki bölgeler işaretlenir, diğerlerinin işareti kalkar.
func set_objective_markers(region_ids: Array[StringName]) -> void:
	for id: StringName in _region_nodes:
		(_region_nodes[id] as RegionNode).is_objective_marked = id in region_ids


## Testler için: bölge işaretli mi.
func is_region_marked(region_id: StringName) -> bool:
	var node: RegionNode = _region_nodes.get(region_id) as RegionNode
	return node != null and node.is_objective_marked


func clear_selection() -> void:
	for node: RegionNode in _region_nodes.values():
		node.is_selected = false


func _on_region_clicked(region_id: StringName) -> void:
	region_clicked.emit(region_id)


func _clear() -> void:
	for child: Node in get_children():
		child.queue_free()
	_region_nodes.clear()
