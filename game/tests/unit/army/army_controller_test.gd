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


func _apply(m: MapState, from_id: StringName, to_id: StringName, mover: RegionData.Owner = RegionData.Owner.PLAYER) -> MoveOutcome:
	var outcome: MoveOutcome = MoveResolver.new().resolve(m, from_id, to_id, mover)
	ArmyController.new().apply_outcome(m, outcome)
	return outcome


func test_valid_move_leaves_garrison() -> void:
	var src: RegionData = _region(&"a", RegionData.Owner.PLAYER, 5, [&"b"] as Array[StringName])
	var dst: RegionData = _region(&"b", RegionData.Owner.NEUTRAL, 0, [&"a"] as Array[StringName])
	var m: MapState = _map([src, dst] as Array[RegionData])
	var outcome: MoveOutcome = _apply(m, &"a", &"b")
	assert_int(outcome.moving).is_equal(4)
	assert_int(src.army_count).is_equal(1)


func test_peaceful_move_to_empty_neutral() -> void:
	var src: RegionData = _region(&"a", RegionData.Owner.PLAYER, 5, [&"b"] as Array[StringName])
	var dst: RegionData = _region(&"b", RegionData.Owner.NEUTRAL, 0, [&"a"] as Array[StringName])
	var m: MapState = _map([src, dst] as Array[RegionData])
	_apply(m, &"a", &"b")
	assert_int(dst.owner).is_equal(RegionData.Owner.PLAYER)
	assert_int(dst.army_count).is_equal(4)


func test_reinforce_own_region() -> void:
	var src: RegionData = _region(&"a", RegionData.Owner.PLAYER, 4, [&"b"] as Array[StringName])
	var dst: RegionData = _region(&"b", RegionData.Owner.PLAYER, 2, [&"a"] as Array[StringName])
	var m: MapState = _map([src, dst] as Array[RegionData])
	_apply(m, &"a", &"b")
	assert_int(dst.army_count).is_equal(5)


func test_combat_win_captures_region() -> void:
	var src: RegionData = _region(&"a", RegionData.Owner.PLAYER, 6, [&"b"] as Array[StringName])
	var dst: RegionData = _region(&"b", RegionData.Owner.ENEMY, 3, [&"a"] as Array[StringName])
	var m: MapState = _map([src, dst] as Array[RegionData])
	var outcome: MoveOutcome = _apply(m, &"a", &"b")
	assert_int(dst.owner).is_equal(RegionData.Owner.PLAYER)
	assert_int(dst.army_count).is_equal(outcome.combat.attacker_remaining)


func test_combat_loss_keeps_owner() -> void:
	var src: RegionData = _region(&"a", RegionData.Owner.PLAYER, 4, [&"b"] as Array[StringName])
	var dst: RegionData = _region(&"b", RegionData.Owner.ENEMY, 6, [&"a"] as Array[StringName])
	var m: MapState = _map([src, dst] as Array[RegionData])
	var outcome: MoveOutcome = _apply(m, &"a", &"b")
	assert_int(dst.owner).is_equal(RegionData.Owner.ENEMY)
	assert_int(dst.army_count).is_equal(outcome.combat.defender_remaining)


func test_invalid_outcome_changes_nothing() -> void:
	var src: RegionData = _region(&"a", RegionData.Owner.PLAYER, 1, [&"b"] as Array[StringName])
	var dst: RegionData = _region(&"b", RegionData.Owner.NEUTRAL, 0, [&"a"] as Array[StringName])
	var m: MapState = _map([src, dst] as Array[RegionData])
	var outcome: MoveOutcome = _apply(m, &"a", &"b")
	assert_bool(outcome.is_valid()).is_false()
	assert_int(src.army_count).is_equal(1)
	assert_int(dst.owner).is_equal(RegionData.Owner.NEUTRAL)


# --- Sahip-bağımsız kurallar (army-system.md §3.1, C-19 / ADR-0005) ---
func test_enemy_mover_can_move_from_enemy_region_without_player_actions() -> void:
	var src: RegionData = _region(&"e", RegionData.Owner.ENEMY, 3, [&"p"] as Array[StringName])
	var dst: RegionData = _region(&"p", RegionData.Owner.PLAYER, 1, [&"e"] as Array[StringName])
	var m: MapState = _map([src, dst] as Array[RegionData], 0)
	assert_bool(ArmyController.new().can_move(m, &"e", &"p", RegionData.Owner.ENEMY)).is_true()


func test_enemy_mover_cannot_move_player_region() -> void:
	var src: RegionData = _region(&"p", RegionData.Owner.PLAYER, 3, [&"e"] as Array[StringName])
	var dst: RegionData = _region(&"e", RegionData.Owner.ENEMY, 1, [&"p"] as Array[StringName])
	var m: MapState = _map([src, dst] as Array[RegionData])
	assert_bool(ArmyController.new().can_move(m, &"p", &"e", RegionData.Owner.ENEMY)).is_false()


func test_enemy_peaceful_move_takes_region_for_enemy() -> void:
	var src: RegionData = _region(&"e", RegionData.Owner.ENEMY, 5, [&"n"] as Array[StringName])
	var dst: RegionData = _region(&"n", RegionData.Owner.NEUTRAL, 0, [&"e"] as Array[StringName])
	var m: MapState = _map([src, dst] as Array[RegionData])
	_apply(m, &"e", &"n", RegionData.Owner.ENEMY)
	assert_int(dst.owner).is_equal(RegionData.Owner.ENEMY)
	assert_int(dst.army_count).is_equal(4)


func test_enemy_combat_win_captures_for_enemy() -> void:
	var src: RegionData = _region(&"e", RegionData.Owner.ENEMY, 6, [&"p"] as Array[StringName])
	var dst: RegionData = _region(&"p", RegionData.Owner.PLAYER, 3, [&"e"] as Array[StringName])
	var m: MapState = _map([src, dst] as Array[RegionData])
	_apply(m, &"e", &"p", RegionData.Owner.ENEMY)
	assert_int(dst.owner).is_equal(RegionData.Owner.ENEMY)
	assert_int(dst.army_count).is_equal(3)


# --- army AC13 / W3: savaştan sonra boş kalan bölge sahipsiz olur (C-52) ---
func test_one_on_one_draw_leaves_target_neutral_and_empty() -> void:
	var src: RegionData = _region(&"a", RegionData.Owner.PLAYER, 2, [&"e"] as Array[StringName])
	var target: RegionData = _region(&"e", RegionData.Owner.ENEMY, 1, [&"a"] as Array[StringName])
	target.corruption_level = 2
	var m: MapState = _map([src, target] as Array[RegionData])
	var outcome: MoveOutcome = _apply(m, &"a", &"e")
	assert_int(target.owner).is_equal(RegionData.Owner.NEUTRAL)
	assert_int(target.army_count).is_equal(0)
	assert_int(target.corruption_level).is_equal(2)
	assert_int(outcome.dispersed).is_equal(0)


func test_draw_won_by_attacker_with_no_survivors_stays_neutral() -> void:
	# draw_favors_defender = false, A = D = 1 → saldıran "kazanır" ama kimse kalmaz.
	var config: CombatConfig = CombatConfig.new()
	config.draw_favors_defender = false
	var combat: CombatResolver = CombatResolver.new()
	combat.bind_config(config)
	var resolver: MoveResolver = MoveResolver.new()
	resolver.bind_services(combat)
	var src: RegionData = _region(&"a", RegionData.Owner.PLAYER, 2, [&"e"] as Array[StringName])
	var target: RegionData = _region(&"e", RegionData.Owner.ENEMY, 1, [&"a"] as Array[StringName])
	var m: MapState = _map([src, target] as Array[RegionData])
	ArmyController.new().apply_outcome(m, resolver.resolve(m, &"a", &"e"))
	assert_int(target.owner).is_equal(RegionData.Owner.NEUTRAL)
	assert_int(target.army_count).is_equal(0)


func test_enemy_draw_on_player_region_leaves_it_neutral() -> void:
	var src: RegionData = _region(&"e", RegionData.Owner.ENEMY, 2, [&"p"] as Array[StringName])
	var target: RegionData = _region(&"p", RegionData.Owner.PLAYER, 1, [&"e"] as Array[StringName])
	var m: MapState = _map([src, target] as Array[RegionData])
	_apply(m, &"e", &"p", RegionData.Owner.ENEMY)
	assert_int(target.owner).is_equal(RegionData.Owner.NEUTRAL)
	assert_int(target.army_count).is_equal(0)


func test_defender_with_survivors_keeps_region_and_attackers_disperse() -> void:
	var src: RegionData = _region(&"a", RegionData.Owner.PLAYER, 5, [&"e"] as Array[StringName])
	var target: RegionData = _region(&"e", RegionData.Owner.ENEMY, 4, [&"a"] as Array[StringName])
	var m: MapState = _map([src, target] as Array[RegionData])
	var outcome: MoveOutcome = _apply(m, &"a", &"e")
	assert_int(target.owner).is_equal(RegionData.Owner.ENEMY)
	assert_int(target.army_count).is_equal(outcome.combat.defender_remaining)
	assert_int(outcome.dispersed).is_equal(outcome.combat.attacker_remaining)
	assert_int(src.army_count).is_equal(1)
