extends GdUnitTestSuite
## ResourceController birim testleri — tur başı gelir toplama.


func _region(id: StringName, owner: RegionData.Owner, gold: int) -> RegionData:
	var r: RegionData = RegionData.new()
	r.region_id = id
	r.owner = owner
	r.gold_per_turn = gold
	return r


func _map(regions: Array[RegionData]) -> MapState:
	var m: MapState = MapState.new()
	for r: RegionData in regions:
		m.regions[r.region_id] = r
	return m


func test_income_sums_only_player_regions() -> void:
	var m: MapState = _map([
		_region(&"a", RegionData.Owner.PLAYER, 2),
		_region(&"b", RegionData.Owner.PLAYER, 3),
		_region(&"e", RegionData.Owner.ENEMY, 10),
		_region(&"n", RegionData.Owner.NEUTRAL, 5),
	] as Array[RegionData])
	var gs: GameState = GameState.new()
	gs.gold = 0
	var income: int = ResourceController.new().collect_turn_income(m, gs)
	assert_int(income).is_equal(5)
	assert_int(gs.gold).is_equal(5)


func test_income_accumulates() -> void:
	var m: MapState = _map([_region(&"a", RegionData.Owner.PLAYER, 4)] as Array[RegionData])
	var gs: GameState = GameState.new()
	gs.gold = 100
	ResourceController.new().collect_turn_income(m, gs)
	assert_int(gs.gold).is_equal(104)
