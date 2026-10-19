extends GdUnitTestSuite
## ErlikSpreadController birim testleri — spirit-system.md §3.6/§4.6, ADR-0005.


func _region(id: StringName, army: int, corruption: int, adj: Array[StringName]) -> RegionData:
	var r: RegionData = RegionData.new()
	r.region_id = id
	r.army_count = army
	r.corruption_level = corruption
	r.adjacent_regions = adj
	return r


func _map(regions: Array[RegionData], turn: int = 1, last_spread: int = 0) -> MapState:
	var m: MapState = MapState.new()
	for r: RegionData in regions:
		m.regions[r.region_id] = r
	m.current_turn = turn
	m.last_erlik_spread_turn = last_spread
	return m


func _lair_map(turn: int, last_spread: int = 0) -> MapState:
	# Canavarın İni (seviye 3) iki komşulu: doğu (3 ordu) ve güney (0 ordu).
	return _map([
		_region(&"lair", 0, 3, [&"dogu", &"guney"] as Array[StringName]),
		_region(&"dogu", 3, 0, [&"lair"] as Array[StringName]),
		_region(&"guney", 0, 0, [&"lair"] as Array[StringName]),
	] as Array[RegionData], turn, last_spread)


func test_not_a_spread_turn_before_interval() -> void:
	var d: ErlikSpreadController.SpreadDecision = ErlikSpreadController.new().decide(_lair_map(2), 3)
	assert_bool(d.is_spread_turn).is_false()


func test_spread_turn_when_interval_elapsed() -> void:
	var d: ErlikSpreadController.SpreadDecision = ErlikSpreadController.new().decide(_lair_map(3), 3)
	assert_bool(d.is_spread_turn).is_true()
	assert_str(d.target_id).is_equal("guney")


func test_counter_based_interval_after_extension() -> void:
	# Son yayılım 3. turda; aralık Gök Kalkanı ile 4'e çıktı → 6. turda değil, 7. turda yayılır.
	var spread: ErlikSpreadController = ErlikSpreadController.new()
	assert_bool(spread.decide(_lair_map(6, 3), 4).is_spread_turn).is_false()
	assert_bool(spread.decide(_lair_map(7, 3), 4).is_spread_turn).is_true()


func test_target_is_lowest_army_candidate() -> void:
	var m: MapState = _lair_map(3)
	m.get_region(&"guney").army_count = 5
	assert_str(ErlikSpreadController.new().decide(m, 3).target_id).is_equal("dogu")


func test_tie_breaks_alphabetically() -> void:
	var m: MapState = _map([
		_region(&"src", 9, 1, [&"zeta", &"alfa"] as Array[StringName]),
		_region(&"zeta", 2, 0, [&"src"] as Array[StringName]),
		_region(&"alfa", 2, 0, [&"src"] as Array[StringName]),
	] as Array[RegionData], 4)
	assert_str(ErlikSpreadController.new().decide(m, 4).target_id).is_equal("alfa")


func test_level_three_regions_are_not_candidates() -> void:
	var m: MapState = _map([
		_region(&"a", 0, 3, [&"b"] as Array[StringName]),
		_region(&"b", 0, 3, [&"a"] as Array[StringName]),
	] as Array[RegionData], 4)
	var d: ErlikSpreadController.SpreadDecision = ErlikSpreadController.new().decide(m, 4)
	assert_bool(d.is_spread_turn).is_true()
	assert_str(d.target_id).is_equal("")


func test_corrupted_region_with_corrupted_neighbor_deepens() -> void:
	# Seviye 1 bölge, seviye 3 komşusu olduğu için adaydır (en az ordulu).
	var m: MapState = _map([
		_region(&"lair", 9, 3, [&"edge"] as Array[StringName]),
		_region(&"edge", 1, 1, [&"lair", &"far"] as Array[StringName]),
		_region(&"far", 4, 0, [&"edge"] as Array[StringName]),
	] as Array[RegionData], 4)
	assert_str(ErlikSpreadController.new().decide(m, 4).target_id).is_equal("edge")


func test_no_corruption_means_no_target() -> void:
	var m: MapState = _map([
		_region(&"a", 0, 0, [&"b"] as Array[StringName]),
		_region(&"b", 0, 0, [&"a"] as Array[StringName]),
	] as Array[RegionData], 4)
	assert_str(ErlikSpreadController.new().decide(m, 4).target_id).is_equal("")


func test_target_computed_on_non_spread_turns() -> void:
	var d: ErlikSpreadController.SpreadDecision = ErlikSpreadController.new().decide(_lair_map(1), 3)
	assert_bool(d.is_spread_turn).is_false()
	assert_str(d.target_id).is_equal("guney")


func test_interval_below_one_is_treated_as_one() -> void:
	assert_bool(ErlikSpreadController.new().decide(_lair_map(1), 0).is_spread_turn).is_true()


func test_decide_does_not_mutate_state() -> void:
	var m: MapState = _lair_map(3)
	ErlikSpreadController.new().decide(m, 3)
	assert_int(m.get_region(&"guney").corruption_level).is_equal(0)
	assert_int(m.last_erlik_spread_turn).is_equal(0)
