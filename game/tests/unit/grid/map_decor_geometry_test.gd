extends GdUnitTestSuite
## Perde 1 dekor yerleşim kuralları (C-89; seviye perde1 §7.2–§7.5, §13 `unit/grid/map_decor_geometry`):
## proplar bölge poligonlarının dışında; üst çubuk + 4 px altında, alt çubuğun üstünde; nehir y150'yi geçmez ve
## poligonlara girmez; körmös bağlı bölgenin içinde; her bozulma seviyesinde bölge başına ≤ 5 görünür bağlı prop.


const MAP_PATH: String = "res://features/grid/data/chapter_2_map.tres"
## Üst çubuk 38 px (C-88 ölçümü, 6 dil) + 4 px; alt çubuk 31 px → 640×360'ta y ≤ 329.
const TOP_LIMIT: float = 42.0
const BOTTOM_LIMIT: float = 329.0
const RIVER_MAX_Y: float = 150.0
const MAX_PROPS_PER_REGION: int = 5


func _definition() -> ChapterMapDefinition:
	return load(MAP_PATH) as ChapterMapDefinition


## Görünür alan (tuval − 2 px pay), ayak noktasından.
func _visible_rect(item: MapDecorItem) -> Rect2:
	var size: Vector2i = Vector2i(item.frames[0].get_size())
	var origin: Vector2 = MapDecorLayer.canvas_origin(item.position, size)
	var pad: float = MapDecorLayer.CANVAS_PAD
	return Rect2(origin + Vector2(pad, pad), Vector2(size) - Vector2(pad, pad) * 2.0)


func _rect_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
		Vector2(rect.position.x, rect.end.y)])


func _overlaps(rect: Rect2, polygon: PackedVector2Array) -> bool:
	for piece: PackedVector2Array in Geometry2D.intersect_polygons(_rect_polygon(rect), polygon):
		if absf(_area(piece)) > 0.5:
			return true
	return false


func _area(points: PackedVector2Array) -> float:
	var total: float = 0.0
	for i: int in points.size():
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % points.size()]
		total += a.x * b.y - b.x * a.y
	return total / 2.0


func test_decor_geometry_props_outside_regions_and_inside_screen() -> void:
	var d: ChapterMapDefinition = _definition()
	var problems: Array[String] = []
	for item: MapDecorItem in d.decor.items:
		if item.layer == MapDecorItem.Layer.OVERLAY:
			continue
		var rect: Rect2 = _visible_rect(item)
		var label: String = "%s@%s" % [item.frames[0].resource_path.get_file(), item.position]
		if rect.position.y < TOP_LIMIT or rect.end.y > BOTTOM_LIMIT + 1.0 or rect.position.x < 0.0 or rect.end.x > 640.0:
			problems.append("ekran dışı %s %s" % [label, rect])
		for region: RegionDefinition in d.regions:
			if _overlaps(rect, region.polygon_points):
				problems.append("poligonda %s ∩ %s" % [label, region.region_id])
	assert_array(problems).override_failure_message("\n".join(problems)).is_empty()


func test_decor_geometry_river_above_150_and_outside_regions() -> void:
	var d: ChapterMapDefinition = _definition()
	assert_int(d.decor.water_rects.size()).is_greater(0)
	for rect: Rect2 in d.decor.water_rects:
		assert_float(rect.end.y).is_less_equal(RIVER_MAX_Y)
		assert_float(rect.position.y).is_greater_equal(TOP_LIMIT)
		for region: RegionDefinition in d.regions:
			assert_bool(_overlaps(rect, region.polygon_points)).override_failure_message(
				"nehir %s ∩ %s" % [rect, region.region_id]).is_false()


func test_decor_geometry_overlay_inside_bound_region() -> void:
	var d: ChapterMapDefinition = _definition()
	var count: int = 0
	for item: MapDecorItem in d.decor.items_in_layer(MapDecorItem.Layer.OVERLAY):
		count += 1
		var region: RegionDefinition = null
		for r: RegionDefinition in d.regions:
			if r.region_id == item.bound_region_id:
				region = r
		assert_object(region).is_not_null()
		var rect: Rect2 = _visible_rect(item)
		for corner: Vector2 in _rect_polygon(rect):
			assert_bool(Geometry2D.is_point_in_polygon(corner, region.polygon_points)).override_failure_message(
				"körmös dışarıda: %s" % corner).is_true()
		assert_bool(item.is_animated()).is_true()
	assert_int(count).is_equal(2)


func test_decor_geometry_at_most_five_visible_props_per_region() -> void:
	var d: ChapterMapDefinition = _definition()
	for level: int in range(0, 4):
		var per_region: Dictionary = {}
		for item: MapDecorItem in d.decor.items_in_layer(MapDecorItem.Layer.PROP):
			if item.bound_region_id == &"" or not item.is_visible(level):
				continue
			per_region[item.bound_region_id] = int(per_region.get(item.bound_region_id, 0)) + 1
		for region_id: StringName in per_region:
			assert_int(per_region[region_id]).override_failure_message("%s seviye %d" % [region_id, level]).is_less_equal(MAX_PROPS_PER_REGION)


func test_decor_geometry_bound_regions_exist() -> void:
	var d: ChapterMapDefinition = _definition()
	var ids: Array[StringName] = []
	for r: RegionDefinition in d.regions:
		ids.append(r.region_id)
	for item: MapDecorItem in d.decor.items:
		if item.bound_region_id != &"":
			assert_bool(item.bound_region_id in ids).override_failure_message(String(item.bound_region_id)).is_true()
