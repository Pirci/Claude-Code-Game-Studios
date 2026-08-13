extends GdUnitTestSuite
## ArmyController birim testleri — army-system.md kabul kriterleri.


func _region(id: StringName, owner: RegionData.Owner, army: int, adj: Array[StringName]) -> RegionData:
	var r: RegionData = RegionData.new()
	r.region_id = id
	r.owner = owner
	r.army_count = army
	r.adjacent_regions = adj
	return r


func _map(regions: Array[RegionData], actions: int = 1) -> MapState:
	var m: MapState = MapState.new()
	for r: RegionData in regions:
		m.regions[r.region_id] = r
	m.actions_remaining = actions
	return m


func test_cannot_move_with_single_army() -> void:
	var src: RegionData = _region(&"a", RegionData.Owner.PLAYER, 1, [&"b"] as Array[StringName])
	var dst: RegionData = _region(&"b", RegionData.Owner.NEUTRAL, 0, [&"a"] as Array[StringName])
	var m: MapState = _map([src, dst] as Array[RegionData])
	assert_bool(ArmyController.new().can_move(m, &"a", &"b")).is_false()


func test_cannot_move_to_non_adjacent() -> void:
	var src: RegionData = _region(&"a", RegionData.Owner.PLAYER, 5, [] as Array[StringName])
	var dst: RegionData = _region(&"b", RegionData.Owner.NEUTRAL, 0, [] as Array[StringName])
	var m: MapState = _map([src, dst] as Array[RegionData])
	assert_bool(ArmyController.new().can_move(m, &"a", &"b")).is_false()


func test_cannot_move_without_actions() -> void:
	var src: RegionData = _region(&"a", RegionData.Owner.PLAYER, 5, [&"b"] as Array[StringName])
	var dst: RegionData = _region(&"b", RegionData.Owner.NEUTRAL, 0, [&"a"] as Array[StringName])
	var m: MapState = _map([src, dst] as Array[RegionData], 0)
	assert_bool(ArmyController.new().can_move(m, &"a", &"b")).is_false()


func test_valid_move_leaves_garrison() -> void:
	var src: RegionData = _region(&"a", RegionData.Owner.PLAYER, 5, [&"b"] as Array[StringName])
	var dst: RegionData = _region(&"b", RegionData.Owner.NEUTRAL, 0, [&"a"] as Array[StringName])
	var m: MapState = _map([src, dst] as Array[RegionData])
	var moving: int = ArmyController.new().move_army(m, &"a", &"b")
	assert_int(moving).is_equal(4)
	assert_int(src.army_count).is_equal(1)


func test_peaceful_move_to_empty_neutral() -> void:
	var dst: RegionData = _region(&"b", RegionData.Owner.NEUTRAL, 0, [&"a"] as Array[StringName])
	var m: MapState = _map([dst] as Array[RegionData])
	ArmyController.new().apply_peaceful_move(m, &"b", 4)
	assert_int(dst.owner).is_equal(RegionData.Owner.PLAYER)
	assert_int(dst.army_count).is_equal(4)


func test_reinforce_own_region() -> void:
	var dst: RegionData = _region(&"b", RegionData.Owner.PLAYER, 2, [] as Array[StringName])
	var m: MapState = _map([dst] as Array[RegionData])
	ArmyController.new().apply_peaceful_move(m, &"b", 3)
	assert_int(dst.army_count).is_equal(5)


func test_apply_combat_result_win_captures_region() -> void:
	var dst: RegionData = _region(&"b", RegionData.Owner.ENEMY, 3, [] as Array[StringName])
	var m: MapState = _map([dst] as Array[RegionData])
	var result: CombatResolver.CombatResult = CombatResolver.new().resolve(5, 3)
	ArmyController.new().apply_combat_result(m, &"b", result, 5)
	assert_int(dst.owner).is_equal(RegionData.Owner.PLAYER)
	assert_int(dst.army_count).is_equal(result.attacker_remaining)


func test_apply_combat_result_loss_keeps_owner() -> void:
	var dst: RegionData = _region(&"b", RegionData.Owner.ENEMY, 6, [] as Array[StringName])
	var m: MapState = _map([dst] as Array[RegionData])
	var result: CombatResolver.CombatResult = CombatResolver.new().resolve(3, 6)
	ArmyController.new().apply_combat_result(m, &"b", result, 3)
	assert_int(dst.owner).is_equal(RegionData.Owner.ENEMY)
	assert_int(dst.army_count).is_equal(result.defender_remaining)
