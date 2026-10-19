extends GdUnitTestSuite
## MoveResolver — saf hamle çözümü ve önizleme sözleşmesi (ADR-0010, C-38 1. adım).


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
	m.actions_per_turn = actions
	return m


func _controller(m: MapState) -> MapController:
	var c: MapController = MapController.new()
	var win: WinCondition = WinCondition.new()
	win.required_neutral_conquests = 99
	c.bind_services(m, GameState.new(), ArmyController.new(), ResourceController.new(),
		CombatResolver.new(), win, EnemyAIController.new())
	return c


func _snapshot(m: MapState) -> Array[String]:
	var rows: Array[String] = []
	for r: RegionData in m.regions.values():
		rows.append("%s|%d|%d|%d" % [r.region_id, r.owner, r.army_count, r.corruption_level])
	rows.append("actions|%d|sel|%s" % [m.actions_remaining, m.selected_region_id])
	return rows


func _fields(o: MoveOutcome) -> Array:
	return [o.branch, o.from_id, o.to_id, o.moving, o.dispersed, o.source_army_after,
		o.target_owner_after, o.target_army_after, o.target_corruption_after]


func _fixture() -> MapState:
	return _map([
		_region(&"a", RegionData.Owner.PLAYER, 6, [&"n", &"e", &"p"] as Array[StringName]),
		_region(&"n", RegionData.Owner.NEUTRAL, 0, [&"a"] as Array[StringName]),
		_region(&"e", RegionData.Owner.ENEMY, 3, [&"a"] as Array[StringName]),
		_region(&"p", RegionData.Owner.PLAYER, 2, [&"a"] as Array[StringName]),
	] as Array[RegionData])


func test_branches_follow_target_state() -> void:
	var m: MapState = _fixture()
	var r: MoveResolver = MoveResolver.new()
	assert_int(r.resolve(m, &"a", &"e").branch).is_equal(MoveOutcome.Branch.COMBAT)
	assert_int(r.resolve(m, &"a", &"n").branch).is_equal(MoveOutcome.Branch.PEACEFUL)
	var merge: MoveOutcome = r.resolve(m, &"a", &"p")
	assert_int(merge.branch).is_equal(MoveOutcome.Branch.PEACEFUL)
	assert_int(merge.target_army_after).is_equal(7)


func test_invalid_moves_report_reasons() -> void:
	var m: MapState = _fixture()
	var r: MoveResolver = MoveResolver.new()
	assert_str(String(r.resolve(m, &"x", &"n").invalid_reason)).is_equal(String(MoveResolver.REASON_NO_SOURCE))
	assert_str(String(r.resolve(m, &"a", &"x").invalid_reason)).is_equal(String(MoveResolver.REASON_NO_TARGET))
	assert_str(String(r.resolve(m, &"e", &"a").invalid_reason)).is_equal(String(MoveResolver.REASON_NOT_OWNER))
	assert_str(String(r.resolve(m, &"p", &"n").invalid_reason)).is_equal(String(MoveResolver.REASON_NOT_ADJACENT))
	m.get_region(&"p").army_count = 1
	assert_str(String(r.resolve(m, &"p", &"a").invalid_reason)).is_equal(String(MoveResolver.REASON_SINGLE_GARRISON))
	m.actions_remaining = 0
	assert_str(String(r.resolve(m, &"a", &"n").invalid_reason)).is_equal(String(MoveResolver.REASON_NO_ACTIONS))
	# Düşmanın bütçesi burada denetlenmez.
	assert_bool(r.resolve(m, &"e", &"a", RegionData.Owner.ENEMY).is_valid()).is_true()


func test_preview_does_not_change_state() -> void:
	var m: MapState = _fixture()
	var c: MapController = _controller(m)
	c.select_region(&"a")
	var before: Array[String] = _snapshot(m)
	for target: StringName in [&"n", &"e", &"p", &"x"]:
		c.preview_move(target)
	assert_array(_snapshot(m)).is_equal(before)


func test_preview_equals_applied_outcome_for_each_branch() -> void:
	for target: StringName in [&"e", &"n", &"p"]:
		var m: MapState = _fixture()
		var c: MapController = _controller(m)
		c.select_region(&"a")
		var preview: MoveOutcome = c.preview_move(target)
		var target_region: RegionData = m.get_region(target)
		assert_bool(c.attempt_move(target)).is_true()
		assert_int(target_region.owner).override_failure_message(String(target)).is_equal(preview.target_owner_after)
		assert_int(target_region.army_count).override_failure_message(String(target)).is_equal(preview.target_army_after)
		assert_int(m.get_region(&"a").army_count).is_equal(preview.source_army_after)


func test_resolve_is_deterministic() -> void:
	var m: MapState = _fixture()
	var r: MoveResolver = MoveResolver.new()
	assert_array(_fields(r.resolve(m, &"a", &"e"))).is_equal(_fields(r.resolve(m, &"a", &"e")))


func test_enemy_into_own_region_merges_peacefully() -> void:
	var m: MapState = _map([
		_region(&"e1", RegionData.Owner.ENEMY, 4, [&"e2"] as Array[StringName]),
		_region(&"e2", RegionData.Owner.ENEMY, 2, [&"e1"] as Array[StringName]),
	] as Array[RegionData])
	var o: MoveOutcome = MoveResolver.new().resolve(m, &"e1", &"e2", RegionData.Owner.ENEMY)
	assert_int(o.branch).is_equal(MoveOutcome.Branch.PEACEFUL)
	assert_int(o.target_army_after).is_equal(5)


func test_corrupted_target_keeps_corruption_in_outcome() -> void:
	var m: MapState = _fixture()
	m.get_region(&"e").corruption_level = 2
	var o: MoveOutcome = MoveResolver.new().resolve(m, &"a", &"e", RegionData.Owner.PLAYER)
	assert_int(o.target_corruption_after).is_equal(2)
