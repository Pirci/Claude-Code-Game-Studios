class_name AdjacencyLineDrawer
extends Node2D
## Bölgeler arası bağlantı çizgilerini çizer.


const LINE_COLOR := Color(0.8, 0.8, 0.8, 0.3)
const LINE_WIDTH := 2.0

var _connections: Array[Vector2] = []


func build_connections(map_state: MapState) -> void:
	_connections.clear()
	var drawn: Dictionary = {}
	for region: RegionData in map_state.regions.values():
		for adj_id: StringName in region.adjacent_regions:
			var key_a: String = "%s-%s" % [region.region_id, adj_id]
			var key_b: String = "%s-%s" % [adj_id, region.region_id]
			if drawn.has(key_a) or drawn.has(key_b):
				continue
			drawn[key_a] = true
			var adj: RegionData = map_state.get_region(adj_id)
			if adj == null:
				continue
			_connections.append(region.position)
			_connections.append(adj.position)
	queue_redraw()


func _draw() -> void:
	var i: int = 0
	while i < _connections.size():
		draw_line(_connections[i], _connections[i + 1], LINE_COLOR, LINE_WIDTH, true)
		i += 2
