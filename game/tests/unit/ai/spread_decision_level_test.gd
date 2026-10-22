extends GdUnitTestSuite
## Yayılım kararının önceki seviyesi — ADR-0010 eki G3 (C-71): 0 → yeni yayılım, ≥ 1 → derinleşme.


func _region(id: StringName, army: int, adj: Array[StringName], corruption: int) -> RegionData:
	var r: RegionData = RegionData.new()
	r.region_id = id
	r.owner = RegionData.Owner.NEUTRAL
	r.army_count = army
	r.adjacent_regions = adj
	r.corruption_level = corruption
	return r


func _map(regions: Array[RegionData]) -> MapState:
	var m: MapState = MapState.new()
	for r: RegionData in regions:
		m.regions[r.region_id] = r
	m.current_turn = 3
	return m


func test_spread_decision_level_before_is_zero_for_clean_target() -> void:
	var m: MapState = _map([
		_region(&"lair", 0, [&"vadi"] as Array[StringName], 3),
		_region(&"vadi", 0, [&"lair"] as Array[StringName], 0),
	] as Array[RegionData])
	var d: ErlikSpreadController.SpreadDecision = ErlikSpreadController.new().decide(m, 3)
	assert_str(String(d.target_id)).is_equal("vadi")
	assert_int(d.level_before).is_equal(0)


func test_spread_decision_level_before_reports_deepening_target() -> void:
	var m: MapState = _map([
		_region(&"lair", 5, [&"vadi"] as Array[StringName], 3),
		_region(&"vadi", 0, [&"lair"] as Array[StringName], 1),
	] as Array[RegionData])
	var d: ErlikSpreadController.SpreadDecision = ErlikSpreadController.new().decide(m, 3)
	assert_str(String(d.target_id)).is_equal("vadi")
	assert_int(d.level_before).is_equal(1)


func test_spread_decision_level_before_is_zero_without_target() -> void:
	var m: MapState = _map([_region(&"vadi", 0, [] as Array[StringName], 0)] as Array[RegionData])
	var d: ErlikSpreadController.SpreadDecision = ErlikSpreadController.new().decide(m, 3)
	assert_str(String(d.target_id)).is_empty()
	assert_int(d.level_before).is_equal(0)
