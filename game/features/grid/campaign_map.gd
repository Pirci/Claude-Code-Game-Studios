class_name CampaignMap
extends Node2D
## Bölüm haritasının görsel kök node'u. RegionNode'ları ve çizgileri yönetir.


signal region_clicked(region_id: StringName)

var _region_nodes: Dictionary = {}  # StringName -> RegionNode
var _line_drawer: AdjacencyLineDrawer


func build_map(map_state: MapState) -> void:
	_clear()

	_line_drawer = AdjacencyLineDrawer.new()
	add_child(_line_drawer)
	_line_drawer.build_connections(map_state)

	for region: RegionData in map_state.regions.values():
		var node: RegionNode = RegionNode.new()
		node.setup(region)
		node.clicked.connect(_on_region_clicked)
		add_child(node)
		_region_nodes[region.region_id] = node


func refresh(map_state: MapState) -> void:
	for region: RegionData in map_state.regions.values():
		var node: RegionNode = _region_nodes.get(region.region_id) as RegionNode
		if node:
			node.update_display(region)


func set_selected(region_id: StringName) -> void:
	for id: StringName in _region_nodes:
		var node: RegionNode = _region_nodes[id] as RegionNode
		node.is_selected = (id == region_id)


func clear_selection() -> void:
	for node: RegionNode in _region_nodes.values():
		node.is_selected = false


func _on_region_clicked(region_id: StringName) -> void:
	region_clicked.emit(region_id)


func _clear() -> void:
	for child: Node in get_children():
		child.queue_free()
	_region_nodes.clear()
