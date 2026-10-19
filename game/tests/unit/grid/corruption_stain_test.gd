extends GdUnitTestSuite
## Erlik lekesi görseli — art bible §4 "Bozulma Seviyeleri" (C-50 kuralı, C-38 uygulaması).


## 40×24'lük dikdörtgen bölge (yerel koordinat).
const RECT: PackedVector2Array = [Vector2(0, 0), Vector2(40, 0), Vector2(40, 24), Vector2(0, 24)]
const PALETTE: Array[String] = ["33173d", "1a1719", "522961"]


func _counts(image: Image) -> Dictionary:
	var counts: Dictionary = {"body": 0, "glint": 0, "edge": 0, "clear": 0, "other": 0}
	for y: int in image.get_height():
		for x: int in image.get_width():
			var c: Color = image.get_pixel(x, y)
			if c.a == 0.0:
				counts["clear"] += 1
			elif c.a < 1.0:
				counts["other"] += 1
			else:
				match c.to_html(false):
					"33173d": counts["body"] += 1
					"522961": counts["glint"] += 1
					"1a1719": counts["edge"] += 1
					_: counts["other"] += 1
	return counts


func test_level_zero_has_no_frames() -> void:
	assert_int(CorruptionStain.new(RECT, 0).frames.size()).is_equal(0)


func test_each_level_has_four_frames_inside_clean_band() -> void:
	var stain: CorruptionStain = CorruptionStain.new(RECT, 2)
	assert_int(stain.frames.size()).is_equal(CorruptionStain.FRAME_COUNT)
	# 1px kontur + 2px temiz bant → leke 3px içeriden başlar.
	assert_vector(Vector2(stain.origin)).is_equal(Vector2(3, 3))
	assert_int(stain.frames[0].get_width()).is_equal(34)
	assert_int(stain.frames[0].get_height()).is_equal(18)


func test_density_grows_with_level() -> void:
	var ratios: Array[float] = []
	for level: int in [1, 2, 3]:
		var counts: Dictionary = _counts(CorruptionStain.new(RECT, level).frames[0])
		var stained: int = counts["body"] + counts["glint"]
		var interior: int = stained + counts["clear"]
		ratios.append(float(stained) / interior)
	# Kenar pikselleri hariç iç alanda yaklaşık %25 / %50 / %75.
	assert_float(ratios[0]).is_between(0.18, 0.32)
	assert_float(ratios[1]).is_between(0.42, 0.58)
	assert_float(ratios[2]).is_between(0.65, 0.85)


func test_only_palette_colours_and_binary_alpha() -> void:
	for level: int in [1, 2, 3]:
		for image: Image in CorruptionStain.new(RECT, level).frames:
			assert_int(_counts(image)["other"]).is_equal(0)


func test_frames_shift_the_pattern() -> void:
	var stain: CorruptionStain = CorruptionStain.new(RECT, 2)
	assert_bool(stain.frames[0].get_data() == stain.frames[1].get_data()).is_false()


func test_glint_is_a_subset_of_stain() -> void:
	for frame: int in CorruptionStain.FRAME_COUNT:
		for y: int in 4:
			for x: int in 4:
				if CorruptionStain.is_glint(x, y, frame):
					assert_bool(CorruptionStain.is_stained(x, y, 1, frame)).is_true()


func test_dashed_outline_draws_two_skips_one() -> void:
	var line: PackedVector2Array = [Vector2(0, 0), Vector2(9, 0), Vector2(9, 1), Vector2(0, 1)]
	var pixels: Array[Vector2i] = CorruptionStain.dashed_outline(line)
	# İlk kenar 9 adım: 0,1 çiz, 2 boş, 3,4 çiz, 5 boş, 6,7 çiz, 8 boş.
	assert_bool(Vector2i(2, 0) in pixels).is_false()
	assert_bool(Vector2i(0, 0) in pixels and Vector2i(1, 0) in pixels and Vector2i(3, 0) in pixels).is_true()


func test_region_node_draws_stain_for_corrupted_region() -> void:
	var data: RegionData = RegionData.new()
	data.region_id = &"r"
	data.polygon_points = RECT
	data.position = Vector2(20, 12)
	data.corruption_level = 3
	var node: RegionNode = auto_free(RegionNode.new()) as RegionNode
	node.setup(data)
	add_child(node)
	assert_int(node.get_corruption_level()).is_equal(3)
	assert_object(node.get_stain_image()).is_not_null()
	data.corruption_level = 0
	node.update_display(data)
	assert_int(node.get_corruption_level()).is_equal(0)
	assert_object(node.get_stain_image()).is_null()
	assert_bool(node.is_processing()).is_false()


func test_reduce_motion_freezes_on_static_frame() -> void:
	var data: RegionData = RegionData.new()
	data.region_id = &"r"
	data.polygon_points = RECT
	data.corruption_level = 2
	var node: RegionNode = auto_free(RegionNode.new()) as RegionNode
	node.setup(data)
	add_child(node)
	assert_bool(node.is_processing()).is_true()
	node.reduce_motion = true
	assert_bool(node.is_processing()).is_false()
	var expected: Image = CorruptionStain.new(RECT, 2).frames[CorruptionStain.STATIC_FRAME]
	assert_bool(node.get_stain_image().get_data() == expected.get_data()).is_true()
