extends GdUnitTestSuite
## Dekor katmanı çizimi (C-85; seviye perde1 §7.3, §7.6, §10; kabul #6 null dekor → Prolog aynı, #7 kayıt /
## yükleme sonrası dekor eşit). Gerçek CampaignMap + Prolog harita durumu + test dekoru.


const PROLOG_MAP: String = "res://features/grid/data/chapter_1_map.tres"
const ENV: String = "res://assets/art/maps/env/"
const UNITS: String = "res://assets/art/units/"


func _state() -> MapState:
	return (load(PROLOG_MAP) as ChapterMapDefinition).create_map_state()


func _item(texture_names: Array[String], foot: Vector2, layer: MapDecorItem.Layer, bound: StringName = &"",
		min_level: int = 0, max_level: int = -1, fps: float = 0.0, folder: String = ENV) -> MapDecorItem:
	var item: MapDecorItem = MapDecorItem.new()
	for texture_name: String in texture_names:
		item.frames.append(load(folder + texture_name + ".png") as Texture2D)
	item.position = foot
	item.layer = layer
	item.bound_region_id = bound
	item.min_corruption = min_level
	item.max_corruption = max_level
	item.fps = fps
	return item


## Sinir bölgesine (Prolog'un bozuk ini) bağlı çürük / sağlıklı ağaç çifti, bağımsız köprü, körmös, L nehir.
func _decor() -> MapDecor:
	var decor: MapDecor = MapDecor.new()
	decor.items = [
		_item(["env_tree_healthy_01"], Vector2(380, 210), MapDecorItem.Layer.PROP, &"sinir_bolge", 0, 0),
		_item(["env_tree_rotten_01"], Vector2(380, 210), MapDecorItem.Layer.PROP, &"sinir_bolge", 1),
		_item(["env_bridge_wood_01"], Vector2(386, 98), MapDecorItem.Layer.PROP),
		_item(["unit_kormos_forest_idle_0", "unit_kormos_forest_idle_1"], Vector2(395, 250),
			MapDecorItem.Layer.OVERLAY, &"sinir_bolge", 1, -1, 2.0, UNITS),
	] as Array[MapDecorItem]
	decor.water_rects = [Rect2(0, 45, 386, 15), Rect2(382, 45, 8, 95)] as Array[Rect2]
	return decor


func _map(decor: MapDecor, state: MapState) -> CampaignMap:
	var map: CampaignMap = auto_free(CampaignMap.new()) as CampaignMap
	map.set_decor(decor)
	add_child(map)
	map.build_map(state)
	return map


func _layer(map: CampaignMap, node_name: String) -> MapDecorLayer:
	return map.find_child(node_name, false, false) as MapDecorLayer


func test_decor_layers_follow_draw_order() -> void:
	var map: CampaignMap = _map(_decor(), _state())
	var names: Array[String] = []
	for child: Node in map.get_children():
		names.append("Line" if child is AdjacencyLineDrawer else "Region" if child is RegionNode else String(child.name))
	var ground: int = names.find("DecorGround")
	var line: int = names.find("Line")
	var prop: int = names.find("DecorProp")
	var first_region: int = names.find("Region")
	var overlay: int = names.find("DecorOverlay")
	assert_bool(ground < line and line < prop and prop < first_region and first_region < overlay).is_true()
	assert_int(names.rfind("Region")).is_less(overlay)


func test_decor_visibility_follows_corruption_through_refresh() -> void:
	var state: MapState = _state()
	state.get_region(&"sinir_bolge").corruption_level = 0
	var map: CampaignMap = _map(_decor(), state)
	var prop: MapDecorLayer = _layer(map, "DecorProp")
	var overlay: MapDecorLayer = _layer(map, "DecorOverlay")
	assert_int(prop.visible_items().size()).is_equal(2)  # sağlıklı ağaç + köprü
	assert_int(overlay.visible_items().size()).is_equal(0)
	assert_bool(overlay.is_processing()).is_false()  # görünür animasyon yok → _process kapalı
	state.get_region(&"sinir_bolge").corruption_level = 2
	map.refresh(state)
	var names: Array[String] = []
	for item: MapDecorItem in prop.visible_items():
		names.append(item.frames[0].resource_path.get_file())
	assert_array(names).contains_exactly(["env_bridge_wood_01.png", "env_tree_rotten_01.png"])
	assert_int(overlay.visible_items().size()).is_equal(1)
	assert_bool(overlay.is_processing()).is_true()
	state.get_region(&"sinir_bolge").corruption_level = 0  # arınınca çürük ağaç kalkar
	map.refresh(state)
	assert_int(overlay.visible_items().size()).is_equal(0)


func test_decor_reduce_motion_stops_animation_on_frame_zero() -> void:
	var state: MapState = _state()
	state.get_region(&"sinir_bolge").corruption_level = 3
	var map: CampaignMap = _map(_decor(), state)
	var overlay: MapDecorLayer = _layer(map, "DecorOverlay")
	var kormos: MapDecorItem = overlay.visible_items()[0]
	overlay._process(0.6)  # 2 fps → 1. kare
	assert_int(overlay.frame_index(kormos)).is_equal(1)
	var settings: AccessibilitySettings = AccessibilitySettings.new()
	settings.reduce_motion = true
	map.apply_accessibility(settings)
	assert_bool(overlay.is_processing()).is_false()
	assert_int(overlay.frame_index(kormos)).is_equal(0)


func test_decor_river_shore_has_no_inner_seam() -> void:
	var segments: Array[Rect2] = MapDecorLayer.shore_segments(_decor().water_rects)
	var shore: Dictionary = {}
	for segment: Rect2 in segments:
		for x: int in range(int(segment.position.x), int(segment.end.x)):
			shore[Vector2i(x, int(segment.position.y))] = true
	# L-dönüşünün iç birleşimi (yatay bandın alt kenarı dikey kolun üstünde) kıyı değildir.
	assert_bool(shore.has(Vector2i(385, 59))).is_false()
	# Dış kenarlar kıyıdır: üst kenar, yatay bandın sol ucu, dikey kolun alt ucu.
	assert_bool(shore.has(Vector2i(100, 45))).is_true()
	assert_bool(shore.has(Vector2i(0, 50))).is_true()
	assert_bool(shore.has(Vector2i(385, 139))).is_true()
	assert_bool(shore.has(Vector2i(100, 59))).is_true()  # dikey kolun solunda kalan alt kenar


func test_decor_foot_point_maps_to_canvas_origin() -> void:
	# 16×14 tuval (12×10 görünür + 2 px pay): ayak (100, 50) → görünür alt satır y = 50, orta sütun x = 100.
	assert_that(MapDecorLayer.canvas_origin(Vector2(100, 50), Vector2i(16, 14))).is_equal(Vector2(92, 39))


# Kabul #6: dekor yoksa (Prolog) katman yok, çocuklar eskisiyle aynı.
func test_decor_null_keeps_prolog_map_unchanged() -> void:
	var map: CampaignMap = _map(null, _state())
	assert_array(map.decor_layers()).is_empty()
	for child: Node in map.get_children():
		assert_bool(child is MapDecorLayer).is_false()


# Kabul #7: dekor türetilir — kayıt/yükleme sonrası aynı görünür küme.
func test_decor_equal_after_save_and_load() -> void:
	var state: GameState = GameState.new()
	state.map_state = _state()
	state.map_state.get_region(&"sinir_bolge").corruption_level = 2
	var before: Array[MapDecorItem] = _layer(_map(_decor(), state.map_state), "DecorProp").visible_items()
	var loaded: LoadResult = SaveSerializer.from_text(SaveSerializer.to_text(state), func(_c: int) -> MapState: return _state())
	assert_int(loaded.code).is_equal(LoadResult.Code.OK)
	var decor: MapDecor = _decor()
	var after: Array[MapDecorItem] = _layer(_map(decor, loaded.state.map_state), "DecorProp").visible_items()
	assert_int(after.size()).is_equal(before.size())
	for i: int in after.size():
		assert_that(after[i].position).is_equal(before[i].position)
		assert_str(after[i].frames[0].resource_path).is_equal(before[i].frames[0].resource_path)
