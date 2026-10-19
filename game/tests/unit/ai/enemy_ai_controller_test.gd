extends GdUnitTestSuite
## EnemyAIController birim testleri — saf karar servisi (ADR-0005, region-map-system.md §3.5).


func _region(id: StringName, owner: RegionData.Owner, army: int, adj: Array[StringName]) -> RegionData:
	var r: RegionData = RegionData.new()
	r.region_id = id
	r.owner = owner
	r.army_count = army
	r.adjacent_regions = adj
	return r


func _map(regions: Array[RegionData]) -> MapState:
	var m: MapState = MapState.new()
	for r: RegionData in regions:
		m.regions[r.region_id] = r
	return m


func _none() -> Array[StringName]:
	return [] as Array[StringName]


func test_decide_targets_weakest_non_enemy_neighbor() -> void:
	var m: MapState = _map([
		_region(&"e", RegionData.Owner.ENEMY, 5, [&"strong", &"weak"] as Array[StringName]),
		_region(&"strong", RegionData.Owner.PLAYER, 4, [&"e"] as Array[StringName]),
		_region(&"weak", RegionData.Owner.NEUTRAL, 2, [&"e"] as Array[StringName]),
	] as Array[RegionData])
	var intent: EnemyAIController.MoveIntent = EnemyAIController.new().decide(m, _none())
	assert_object(intent).is_not_null()
	assert_str(intent.from_id).is_equal("e")
	assert_str(intent.to_id).is_equal("weak")


func test_decide_ignores_enemy_neighbors() -> void:
	var m: MapState = _map([
		_region(&"e1", RegionData.Owner.ENEMY, 5, [&"e2", &"p"] as Array[StringName]),
		_region(&"e2", RegionData.Owner.ENEMY, 1, [&"e1"] as Array[StringName]),
		_region(&"p", RegionData.Owner.PLAYER, 3, [&"e1"] as Array[StringName]),
	] as Array[RegionData])
	var intent: EnemyAIController.MoveIntent = EnemyAIController.new().decide(m, _none())
	assert_str(intent.to_id).is_equal("p")


func test_decide_skips_regions_with_single_garrison() -> void:
	var m: MapState = _map([
		_region(&"e1", RegionData.Owner.ENEMY, 1, [&"p"] as Array[StringName]),
		_region(&"e2", RegionData.Owner.ENEMY, 3, [&"p"] as Array[StringName]),
		_region(&"p", RegionData.Owner.PLAYER, 1, [&"e1", &"e2"] as Array[StringName]),
	] as Array[RegionData])
	var intent: EnemyAIController.MoveIntent = EnemyAIController.new().decide(m, _none())
	assert_str(intent.from_id).is_equal("e2")


func test_decide_skips_acted_regions() -> void:
	var m: MapState = _map([
		_region(&"e1", RegionData.Owner.ENEMY, 5, [&"p1"] as Array[StringName]),
		_region(&"e2", RegionData.Owner.ENEMY, 5, [&"p2"] as Array[StringName]),
		_region(&"p1", RegionData.Owner.PLAYER, 1, [&"e1"] as Array[StringName]),
		_region(&"p2", RegionData.Owner.PLAYER, 1, [&"e2"] as Array[StringName]),
	] as Array[RegionData])
	var intent: EnemyAIController.MoveIntent = EnemyAIController.new().decide(m, [&"e1"] as Array[StringName])
	assert_str(intent.from_id).is_equal("e2")


func test_decide_returns_null_when_no_move_possible() -> void:
	var m: MapState = _map([
		_region(&"e", RegionData.Owner.ENEMY, 1, [&"p"] as Array[StringName]),
		_region(&"p", RegionData.Owner.PLAYER, 5, [&"e"] as Array[StringName]),
	] as Array[RegionData])
	assert_object(EnemyAIController.new().decide(m, _none())).is_null()


func test_decide_does_not_mutate_state() -> void:
	var m: MapState = _map([
		_region(&"e", RegionData.Owner.ENEMY, 5, [&"p"] as Array[StringName]),
		_region(&"p", RegionData.Owner.PLAYER, 2, [&"e"] as Array[StringName]),
	] as Array[RegionData])
	EnemyAIController.new().decide(m, _none())
	assert_int(m.get_region(&"e").army_count).is_equal(5)
	assert_int(m.get_region(&"p").owner).is_equal(RegionData.Owner.PLAYER)
	assert_int(m.get_region(&"p").army_count).is_equal(2)


# --- region-map AC6 / W6: eşitlik bozma ve işleme sırası `region_id` alfabetik (C-52) ---
func test_decide_breaks_target_ties_alphabetically() -> void:
	var m: MapState = _map([
		_region(&"e", RegionData.Owner.ENEMY, 5, [&"zeta", &"alfa"] as Array[StringName]),
		_region(&"zeta", RegionData.Owner.NEUTRAL, 2, [&"e"] as Array[StringName]),
		_region(&"alfa", RegionData.Owner.PLAYER, 2, [&"e"] as Array[StringName]),
	] as Array[RegionData])
	var intent: EnemyAIController.MoveIntent = EnemyAIController.new().decide(m, _none())
	assert_str(intent.to_id).is_equal("alfa")


func test_decide_processes_enemy_regions_in_id_order() -> void:
	# Kayıt sırası z → a olsa da ilk hamle `a_kale`'den.
	var m: MapState = _map([
		_region(&"z_kale", RegionData.Owner.ENEMY, 5, [&"p"] as Array[StringName]),
		_region(&"a_kale", RegionData.Owner.ENEMY, 5, [&"p"] as Array[StringName]),
		_region(&"p", RegionData.Owner.PLAYER, 3, [&"z_kale", &"a_kale"] as Array[StringName]),
	] as Array[RegionData])
	var intent: EnemyAIController.MoveIntent = EnemyAIController.new().decide(m, _none())
	assert_str(intent.from_id).is_equal("a_kale")
