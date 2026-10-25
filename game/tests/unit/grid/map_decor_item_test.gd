extends GdUnitTestSuite
## Dekor veri modeli (C-84; seviye belgesi perde1 §7.6, §13 `unit/grid/map_decor_item`): bozulma bağlı
## görünürlük, sınırsız üst sınır, katman çizim sırası; Prolog dekorsuz.


func _item(min_level: int, max_level: int, foot: Vector2 = Vector2.ZERO,
		layer: MapDecorItem.Layer = MapDecorItem.Layer.PROP) -> MapDecorItem:
	var item: MapDecorItem = MapDecorItem.new()
	item.min_corruption = min_level
	item.max_corruption = max_level
	item.position = foot
	item.layer = layer
	return item


func test_map_decor_item_rotten_tree_hidden_at_zero_visible_from_one() -> void:
	var rotten: MapDecorItem = _item(1, -1)
	assert_bool(rotten.is_visible(0)).is_false()
	for level: int in [1, 2, 3]:
		assert_bool(rotten.is_visible(level)).is_true()


func test_map_decor_item_healthy_tree_hidden_once_corrupted() -> void:
	var healthy: MapDecorItem = _item(0, 0)
	assert_bool(healthy.is_visible(0)).is_true()
	assert_bool(healthy.is_visible(1)).is_false()
	# Aynı noktadaki çürük/sağlıklı çift: her seviyede tam biri görünür.
	var rotten: MapDecorItem = _item(1, -1)
	for level: int in range(0, 4):
		assert_bool(healthy.is_visible(level) != rotten.is_visible(level)).is_true()


func test_map_decor_item_unbounded_max_is_always_visible() -> void:
	var always: MapDecorItem = _item(0, -1)
	for level: int in range(0, 4):
		assert_bool(always.is_visible(level)).is_true()
	assert_bool(_item(2, 2).is_visible(3)).is_false()  # aralık dışı


func test_map_decor_item_animated_only_with_frames_and_fps() -> void:
	var item: MapDecorItem = _item(0, -1)
	item.frames = [PlaceholderTexture2D.new()] as Array[Texture2D]
	item.fps = 2.0
	assert_bool(item.is_animated()).is_false()  # tek kare
	item.frames.append(PlaceholderTexture2D.new())
	assert_bool(item.is_animated()).is_true()
	item.fps = 0.0
	assert_bool(item.is_animated()).is_false()


func test_map_decor_layer_order_is_foot_y_then_x() -> void:
	var decor: MapDecor = MapDecor.new()
	var low: MapDecorItem = _item(0, -1, Vector2(10, 200))
	var high_right: MapDecorItem = _item(0, -1, Vector2(50, 100))
	var high_left: MapDecorItem = _item(0, -1, Vector2(20, 100))
	var overlay: MapDecorItem = _item(0, -1, Vector2(0, 0), MapDecorItem.Layer.OVERLAY)
	decor.items = [low, high_right, overlay, high_left] as Array[MapDecorItem]
	assert_array(decor.items_in_layer(MapDecorItem.Layer.PROP)).is_equal([high_left, high_right, low])
	assert_array(decor.items_in_layer(MapDecorItem.Layer.OVERLAY)).is_equal([overlay])
	assert_array(decor.items_in_layer(MapDecorItem.Layer.GROUND)).is_empty()


func test_map_decor_defaults_to_none_and_prolog_has_none() -> void:
	assert_object(ChapterMapDefinition.new().decor).is_null()
	var prolog: ChapterMapDefinition = load("res://features/grid/data/chapter_1_map.tres") as ChapterMapDefinition
	assert_object(prolog.decor).is_null()
