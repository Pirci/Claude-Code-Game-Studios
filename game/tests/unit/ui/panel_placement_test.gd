extends GdUnitTestSuite
## Harita üstü panel yerleşimi ve hedef işareti ikonu (C-69; scene-flow §3.5/§9).


func test_first_clear_candidate_wins() -> void:
	var candidates: Array[Rect2] = [Rect2(0, 200, 100, 50), Rect2(0, 40, 100, 50)]
	assert_int(PanelPlacement.choose(candidates, [Rect2(500, 10, 9, 9)] as Array[Rect2])).is_equal(0)
	assert_int(PanelPlacement.choose(candidates, [Rect2(10, 210, 9, 9)] as Array[Rect2])).is_equal(1)


func test_least_overlap_when_all_candidates_collide() -> void:
	var candidates: Array[Rect2] = [Rect2(0, 0, 100, 100), Rect2(200, 0, 100, 100)]
	var obstacles: Array[Rect2] = [Rect2(50, 50, 60, 60), Rect2(200, 0, 10, 10)]
	assert_int(PanelPlacement.choose(candidates, obstacles)).is_equal(1)


func _marked_node(reduce_motion: bool) -> RegionNode:
	var data: RegionData = RegionData.new()
	data.region_id = &"lair"
	data.position = Vector2(100, 100)
	data.polygon_points = PackedVector2Array([Vector2(60, 80), Vector2(140, 80), Vector2(140, 120), Vector2(60, 120)])
	var node: RegionNode = auto_free(RegionNode.new()) as RegionNode
	add_child(node)
	node.setup(data)
	node.reduce_motion = reduce_motion
	node.is_objective_marked = true
	return node


func test_objective_marker_animates_unless_reduce_motion() -> void:
	var moving: RegionNode = _marked_node(false)
	assert_bool(moving.is_processing()).is_true()
	assert_int(moving.get_objective_mark_frame()).is_equal(0)
	moving._process(1.1)
	assert_int(moving.get_objective_mark_frame()).is_equal(1)
	var still: RegionNode = _marked_node(true)
	assert_bool(still.is_processing()).is_false()
	assert_int(still.get_objective_mark_frame()).is_equal(0)
	assert_object(still.objective_mark_rect()).is_equal(Rect2(96, 66, 9, 9))
