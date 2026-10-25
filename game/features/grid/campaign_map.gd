class_name CampaignMap
extends Node2D
## Bölüm haritasının görsel kök node'u. RegionNode'ları ve çizgileri yönetir.


signal region_clicked(region_id: StringName)
## Bölge klavyeyle seçildi (K4).
signal region_accepted(region_id: StringName)

var _region_nodes: Dictionary = {}  # StringName -> RegionNode
var _line_drawer: AdjacencyLineDrawer
var _line_color: Color = AdjacencyLineDrawer.DEFAULT_LINE_COLOR
var _tamgas: TamgaLibrary = TamgaLibrary.new()
## Bölüm dekoru (null → yok, Prolog); katmanlar [method build_map]'te kurulur.
var _decor: MapDecor = null
var _decor_layers: Array[MapDecorLayer] = []
var _reduce_motion: bool = false


## Dekor [method build_map]'ten önce verilir (seviye perde1 §7.6).
func set_decor(decor: MapDecor) -> void:
	_decor = decor


func build_map(map_state: MapState) -> void:
	_clear()

	# Çizim sırası (§7.6): GROUND (nehir) → çizgiler → PROP → bölgeler → OVERLAY.
	_add_decor_layer(MapDecorItem.Layer.GROUND, "DecorGround")
	_line_drawer = AdjacencyLineDrawer.new()
	_line_drawer.line_color = _line_color
	add_child(_line_drawer)
	_line_drawer.build_connections(map_state)
	_add_decor_layer(MapDecorItem.Layer.PROP, "DecorProp")

	for region: RegionData in map_state.regions.values():
		var node: RegionNode = RegionNode.new()
		node.setup(region)
		node.set_tamga(_tamgas.get_texture(map_state.get_owner_tamga_id(region.owner)))
		node.clicked.connect(_on_region_clicked)
		node.accepted.connect(region_accepted.emit)
		add_child(node)
		_region_nodes[region.region_id] = node
	_add_decor_layer(MapDecorItem.Layer.OVERLAY, "DecorOverlay")
	_apply_decor_corruption(map_state)
	_link_focus_neighbors(map_state)


## Dekor katmanları (testler ve ölçüm için; dekor yoksa boş).
func decor_layers() -> Array[MapDecorLayer]:
	return _decor_layers


func _add_decor_layer(layer: MapDecorItem.Layer, node_name: String) -> void:
	if _decor == null:
		return
	var decor_layer: MapDecorLayer = MapDecorLayer.new()
	decor_layer.name = node_name
	decor_layer.setup(_decor, layer, layer == MapDecorItem.Layer.GROUND)
	decor_layer.reduce_motion = _reduce_motion
	add_child(decor_layer)
	_decor_layers.append(decor_layer)


## Bozulma bağlı görünürlük (§7.6): her yenilemede bölge seviyeleri katmanlara geçer.
func _apply_decor_corruption(map_state: MapState) -> void:
	if _decor_layers.is_empty():
		return
	var levels: Dictionary = {}
	for region: RegionData in map_state.regions.values():
		levels[region.region_id] = region.corruption_level
	for decor_layer: MapDecorLayer in _decor_layers:
		decor_layer.apply_corruption(levels)


## Bölgenin klavye odak kontrolü (yoksa null).
func focus_target(region_id: StringName) -> Control:
	var node: RegionNode = _region_nodes.get(region_id) as RegionNode
	return node.get_focus_target() if node != null else null


## Tab sırası: okuma sırası (yukarıdan aşağı, soldan sağa; eşitlikte kimlik). Harita LTR.
func focus_order() -> Array[Control]:
	var nodes: Array = _region_nodes.values()
	nodes.sort_custom(func(a: RegionNode, b: RegionNode) -> bool:
		var pa: Vector2 = a.bounds_rect().get_center()
		var pb: Vector2 = b.bounds_rect().get_center()
		if not is_equal_approx(pa.y, pb.y):
			return pa.y < pb.y
		if not is_equal_approx(pa.x, pb.x):
			return pa.x < pb.x
		return String(a.region_id) < String(b.region_id))
	var order: Array[Control] = []
	for node: RegionNode in nodes:
		order.append(node.get_focus_target())
	return order


## Ok tuşları komşuluğa göre (RegionFocusRules); o yönde komşu yoksa odak yerinde kalır —
## boş bırakılırsa Godot geometrik olarak en yakın kontrole (HUD düğmeleri) atlardı.
func _link_focus_neighbors(map_state: MapState) -> void:
	var centers: Dictionary = {}
	var adjacency: Dictionary = {}
	for region: RegionData in map_state.regions.values():
		centers[region.region_id] = region.position
		adjacency[region.region_id] = region.adjacent_regions
	var links: Dictionary = RegionFocusRules.neighbors(centers, adjacency)
	for region_id: StringName in links:
		var target: Control = focus_target(region_id)
		var sides: Dictionary = links[region_id]
		for side: RegionFocusRules.Side in RegionFocusRules.DIRECTIONS:
			var other: Control = focus_target(sides[side]) if sides.has(side) else target
			var path: NodePath = target.get_path_to(other)
			match side:
				RegionFocusRules.Side.LEFT:
					target.focus_neighbor_left = path
				RegionFocusRules.Side.RIGHT:
					target.focus_neighbor_right = path
				RegionFocusRules.Side.UP:
					target.focus_neighbor_top = path
				RegionFocusRules.Side.DOWN:
					target.focus_neighbor_bottom = path
	# Node2D altındaki kontroller Godot'nun Tab gezinmesine kendiliğinden girmez: zinciri kur.
	# Uçlar (haritaya giriş / çıkış) GameContext tarafından HUD'a bağlanır.
	var order: Array[Control] = focus_order()
	for i: int in order.size() - 1:
		order[i].focus_next = order[i].get_path_to(order[i + 1])
		order[i + 1].focus_previous = order[i + 1].get_path_to(order[i])


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
	_apply_decor_corruption(map_state)


func set_selected(region_id: StringName) -> void:
	for id: StringName in _region_nodes:
		var node: RegionNode = _region_nodes[id] as RegionNode
		node.is_selected = (id == region_id)


## Erişilebilirlik tercihlerini tüm bölgelere uygular (null = varsayılanlar).
func apply_accessibility(settings: AccessibilitySettings) -> void:
	if settings == null:
		return
	_reduce_motion = settings.reduce_motion
	for decor_layer: MapDecorLayer in _decor_layers:
		decor_layer.reduce_motion = settings.reduce_motion
	for node: RegionNode in _region_nodes.values():
		node.color_blind_mode = settings.color_blind_mode
		node.show_name_label = settings.show_region_names
		node.reduce_motion = settings.reduce_motion


## Hedef işaretleri (F7 `V`): listedeki bölgeler işaretlenir, diğerlerinin işareti kalkar.
func set_objective_markers(region_ids: Array[StringName]) -> void:
	for id: StringName in _region_nodes:
		(_region_nodes[id] as RegionNode).is_objective_marked = id in region_ids


## İşaretli bölgelerin işaret alanları (harita koordinatı, 2px pay) — paneller bunları örtmez.
func objective_marker_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for node: RegionNode in _region_nodes.values():
		if node.is_objective_marked:
			rects.append(node.objective_mark_rect().grow(2.0))
	return rects


## Bölgenin harita koordinatlarında sınır kutusu (yoksa boş Rect2).
func region_rect(region_id: StringName) -> Rect2:
	var node: RegionNode = _region_nodes.get(region_id) as RegionNode
	return node.bounds_rect() if node != null else Rect2()


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
	_decor_layers.clear()
