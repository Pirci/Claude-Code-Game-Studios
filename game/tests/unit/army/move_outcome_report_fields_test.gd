extends GdUnitTestSuite
## Rapor verisi — ADR-0010 eki G1/G2 (C-71): outcome hedefin önceki sahibini ve hamle nedenini taşır;
## savaş sinyali outcome'u olduğu gibi yayar.


## Her zaman ilk düşman bölgesinden ilk komşuya `&"strike"` nedeniyle saldıran sahte AI.
class StrikeAI extends EnemyAIController:
	func decide(map_state: MapState, acted: Array[StringName]) -> MoveIntent:
		for region: RegionData in map_state.get_enemy_regions():
			if region.region_id in acted or region.army_count <= 1:
				continue
			return MoveIntent.new(region.region_id, region.adjacent_regions[0], &"strike")
		return null


func _region(id: StringName, owner: RegionData.Owner, army: int, adj: Array[StringName]) -> RegionData:
	var r: RegionData = RegionData.new()
	r.region_id = id
	r.owner = owner
	r.initial_owner = owner
	r.army_count = army
	r.adjacent_regions = adj
	return r


func _map() -> MapState:
	var m: MapState = MapState.new()
	for r: RegionData in [
		_region(&"camp", RegionData.Owner.PLAYER, 2, [&"oba"] as Array[StringName]),
		_region(&"oba", RegionData.Owner.ENEMY, 6, [&"camp", &"boy"] as Array[StringName]),
		_region(&"boy", RegionData.Owner.NEUTRAL, 1, [&"oba"] as Array[StringName]),
	]:
		m.regions[r.region_id] = r
	m.actions_remaining = 1
	m.actions_per_turn = 1
	m.erlik_spread_interval = 99
	return m


func _controller(m: MapState, ai: EnemyAIController) -> MapController:
	var win: WinCondition = WinCondition.new()
	win.required_neutral_conquests = 99
	var c: MapController = MapController.new()
	c.bind_services(m, GameState.new(), ArmyController.new(), ResourceController.new(), CombatResolver.new(), win, ai)
	return c


func test_move_outcome_records_target_owner_before_and_empty_reason_for_player() -> void:
	var outcome: MoveOutcome = MoveResolver.new().resolve(_map(), &"camp", &"oba")
	assert_int(outcome.branch).is_equal(MoveOutcome.Branch.COMBAT)
	assert_int(outcome.target_owner_before).is_equal(RegionData.Owner.ENEMY)
	assert_str(String(outcome.reason)).is_empty()


func test_move_outcome_enemy_strike_carries_reason_and_previous_owner_in_signal() -> void:
	var m: MapState = _map()
	var c: MapController = _controller(m, StrikeAI.new())
	var seen: Array[MoveOutcome] = []
	c.combat_occurred.connect(func(o: MoveOutcome) -> void: seen.append(o))
	c.end_turn()
	assert_int(seen.size()).is_equal(1)
	assert_int(seen[0].mover).is_equal(RegionData.Owner.ENEMY)
	assert_str(String(seen[0].to_id)).is_equal("camp")
	assert_int(seen[0].target_owner_before).is_equal(RegionData.Owner.PLAYER)
	assert_str(String(seen[0].reason)).is_equal("strike")


func test_move_outcome_preview_and_apply_still_match_with_new_fields() -> void:
	var m: MapState = _map()
	var preview: MoveOutcome = MoveResolver.new().resolve(m, &"camp", &"oba")
	var again: MoveOutcome = MoveResolver.new().resolve(m, &"camp", &"oba")
	assert_int(again.target_owner_before).is_equal(preview.target_owner_before)
	assert_int(m.get_region(&"oba").owner).is_equal(RegionData.Owner.ENEMY)  # önizleme haritayı değiştirmez
