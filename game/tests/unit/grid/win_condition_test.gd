extends GdUnitTestSuite
## WinCondition birim testleri — region-map-system.md kazanma kriterleri.


func _region(id: StringName, owner: RegionData.Owner, initial: RegionData.Owner = RegionData.Owner.NEUTRAL) -> RegionData:
	var r: RegionData = RegionData.new()
	r.region_id = id
	r.owner = owner
	r.initial_owner = initial
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
	# Başlangıç bölgesi + 3 başlangıçta-nötr bölge → conquered_neutral_count = 3
	var m: MapState = _map([
		_region(&"a", RegionData.Owner.PLAYER, RegionData.Owner.PLAYER),
		_region(&"b", RegionData.Owner.PLAYER),
		_region(&"c", RegionData.Owner.PLAYER),
		_region(&"d", RegionData.Owner.PLAYER),
	] as Array[RegionData])
	assert_bool(_win(3, true).is_met(m)).is_true()


func test_not_met_when_conquests_insufficient() -> void:
	# Başlangıç bölgesi + 1 nötr → conquered_neutral_count = 1 < 3
	var m: MapState = _map([
		_region(&"a", RegionData.Owner.PLAYER, RegionData.Owner.PLAYER),
		_region(&"b", RegionData.Owner.PLAYER),
	] as Array[RegionData])
	assert_bool(_win(3, true).is_met(m)).is_false()


# --- region-map AC10 / §4: sayım başlangıçta nötr ve odak olmayan bölgelere göre (C-51) ---
func test_lost_start_region_does_not_block_expansion() -> void:
	var m: MapState = _map([
		_region(&"otag", RegionData.Owner.NEUTRAL, RegionData.Owner.PLAYER),
		_region(&"n1", RegionData.Owner.PLAYER),
		_region(&"n2", RegionData.Owner.PLAYER),
		_region(&"n3", RegionData.Owner.PLAYER),
	] as Array[RegionData])
	assert_int(_win(3, true).conquered_neutral_count(m)).is_equal(3)
	assert_bool(_win(3, true).is_met(m)).is_true()


func test_captured_enemy_regions_and_foci_do_not_count() -> void:
	var w: WinCondition = _win(2, true)
	w.erlik_foci.assign([&"lair"])
	var m: MapState = _map([
		_region(&"otag", RegionData.Owner.PLAYER, RegionData.Owner.PLAYER),
		_region(&"kale", RegionData.Owner.PLAYER, RegionData.Owner.ENEMY),
		_region(&"lair", RegionData.Owner.PLAYER),
		_region(&"n1", RegionData.Owner.PLAYER),
	] as Array[RegionData])
	assert_int(w.conquered_neutral_count(m)).is_equal(1)
	assert_bool(w.is_met(m)).is_false()


func test_corrupted_focus_blocks_victory_until_cleansed() -> void:
	var w: WinCondition = _win(1, true)
	w.erlik_foci.assign([&"lair"])
	var lair: RegionData = _region(&"lair", RegionData.Owner.NEUTRAL)
	lair.corruption_level = 3
	var m: MapState = _map([
		_region(&"otag", RegionData.Owner.PLAYER, RegionData.Owner.PLAYER),
		_region(&"n1", RegionData.Owner.PLAYER),
		lair,
	] as Array[RegionData])
	assert_bool(w.is_met(m)).is_false()
	lair.corruption_level = 0
	assert_bool(w.is_met(m)).is_true()


func test_no_player_region_is_never_a_win() -> void:
	var m: MapState = _map([_region(&"n1", RegionData.Owner.NEUTRAL)] as Array[RegionData])
	assert_bool(_win(0, false).is_met(m)).is_false()


func test_region_definition_sets_initial_owner() -> void:
	var definition: RegionDefinition = RegionDefinition.new()
	definition.region_id = &"otag"
	definition.owner = RegionData.Owner.PLAYER
	assert_int(definition.create_region_data().initial_owner).is_equal(RegionData.Owner.PLAYER)
