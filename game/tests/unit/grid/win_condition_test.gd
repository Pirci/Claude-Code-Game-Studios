extends GdUnitTestSuite
## WinCondition birim testleri — region-map-system.md kazanma kriterleri.


func _region(id: StringName, owner: RegionData.Owner) -> RegionData:
	var r: RegionData = RegionData.new()
	r.region_id = id
	r.owner = owner
	return r


func _map(regions: Array[RegionData]) -> MapState:
	var m: MapState = MapState.new()
	for r: RegionData in regions:
		m.regions[r.region_id] = r
	return m


func _win(required: int, must_defeat: bool) -> WinCondition:
	var w: WinCondition = WinCondition.new()
	w.required_neutral_conquests = required
	w.must_defeat_all_enemies = must_defeat
	return w


func test_not_met_while_enemy_alive() -> void:
	var m: MapState = _map([
		_region(&"a", RegionData.Owner.PLAYER),
		_region(&"e", RegionData.Owner.ENEMY),
	] as Array[RegionData])
	assert_bool(_win(0, true).is_met(m)).is_false()


func test_met_when_conquests_reached_and_no_enemy() -> void:
	# 4 oyuncu bölgesi → conquered_count = 3
	var m: MapState = _map([
		_region(&"a", RegionData.Owner.PLAYER),
		_region(&"b", RegionData.Owner.PLAYER),
		_region(&"c", RegionData.Owner.PLAYER),
		_region(&"d", RegionData.Owner.PLAYER),
	] as Array[RegionData])
	assert_bool(_win(3, true).is_met(m)).is_true()


func test_not_met_when_conquests_insufficient() -> void:
	# 2 oyuncu bölgesi → conquered_count = 1 < 3
	var m: MapState = _map([
		_region(&"a", RegionData.Owner.PLAYER),
		_region(&"b", RegionData.Owner.PLAYER),
	] as Array[RegionData])
	assert_bool(_win(3, true).is_met(m)).is_false()
