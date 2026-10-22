extends GdUnitTestSuite
## Arındırma ve Erlik yayılımı — spirit-system.md §3.2, §3.6, §4.1–4.3, §4.6 (C-38).


func _region(id: StringName, owner: RegionData.Owner, army: int, adj: Array[StringName], corruption: int = 0, gold: int = 0) -> RegionData:
	var r: RegionData = RegionData.new()
	r.region_id = id
	r.owner = owner
	r.initial_owner = owner
	r.army_count = army
	r.adjacent_regions = adj
	r.corruption_level = corruption
	r.gold_per_turn = gold
	return r


func _map(regions: Array[RegionData], actions: int = 1) -> MapState:
	var m: MapState = MapState.new()
	for r: RegionData in regions:
		m.regions[r.region_id] = r
	m.actions_remaining = actions
	m.actions_per_turn = actions
	m.erlik_spread_interval = 3
	return m


func _controller(m: MapState, state: GameState, win: WinCondition = null) -> MapController:
	if win == null:
		win = WinCondition.new()
		win.required_neutral_conquests = 99
	var c: MapController = MapController.new()
	c.bind_services(m, state, ArmyController.new(), ResourceController.new(), CombatResolver.new(),
		win, EnemyAIController.new())
	return c


func _purify_map(source_army: int, level: int) -> MapState:
	return _map([
		_region(&"otag", RegionData.Owner.PLAYER, source_army, [&"dogu"] as Array[StringName]),
		_region(&"dogu", RegionData.Owner.NEUTRAL, 0, [&"otag"] as Array[StringName], level),
	] as Array[RegionData])


# --- spirit AC11: seviye 2, P = 9 başarılı; P = 8 kuvvet kaybolur ---
func test_level_two_purification_succeeds_with_nine() -> void:
	var m: MapState = _purify_map(10, 2)
	var o: MoveOutcome = MoveResolver.new().resolve(m, &"otag", &"dogu")
	assert_int(o.branch).is_equal(MoveOutcome.Branch.PURIFICATION)
	assert_int(o.corruption_strength).is_equal(8)
	assert_bool(o.purified).is_true()
	assert_int(o.target_army_after).is_equal(5)
	assert_int(o.target_owner_after).is_equal(RegionData.Owner.PLAYER)
	assert_int(o.target_corruption_after).is_equal(0)
	assert_int(o.ruh_gain).is_equal(20)


func test_level_two_purification_fails_with_eight_and_force_is_lost() -> void:
	var m: MapState = _purify_map(9, 2)
	var o: MoveOutcome = MoveResolver.new().resolve(m, &"otag", &"dogu")
	assert_bool(o.purified).is_false()
	assert_int(o.dispersed).is_equal(8)
	assert_int(o.target_owner_after).is_equal(RegionData.Owner.NEUTRAL)
	assert_int(o.target_army_after).is_equal(0)
	assert_int(o.target_corruption_after).is_equal(2)
	assert_int(o.ruh_gain).is_equal(0)


func test_purification_applies_through_map_controller() -> void:
	var m: MapState = _purify_map(10, 2)
	var state: GameState = GameState.new()
	var c: MapController = _controller(m, state)
	var seen: Array[MoveOutcome] = []
	c.purification_resolved.connect(func(o: MoveOutcome) -> void: seen.append(o))
	c.select_region(&"otag")
	var preview: MoveOutcome = c.preview_move(&"dogu")
	assert_bool(c.attempt_move(&"dogu")).is_true()
	var dogu: RegionData = m.get_region(&"dogu")
	assert_int(dogu.corruption_level).is_equal(0)
	assert_int(dogu.owner).is_equal(RegionData.Owner.PLAYER)
	assert_int(dogu.army_count).is_equal(preview.target_army_after)
	assert_int(state.ruh).is_equal(20)
	assert_int(seen.size()).is_equal(1)
	assert_int(m.get_region(&"otag").army_count).is_equal(1)


func test_failed_purification_changes_only_the_source() -> void:
	var m: MapState = _purify_map(9, 2)
	var state: GameState = GameState.new()
	var c: MapController = _controller(m, state)
	c.select_region(&"otag")
	assert_bool(c.attempt_move(&"dogu")).is_true()
	var dogu: RegionData = m.get_region(&"dogu")
	assert_int(dogu.corruption_level).is_equal(2)
	assert_int(dogu.owner).is_equal(RegionData.Owner.NEUTRAL)
	assert_int(state.ruh).is_equal(0)
	assert_int(m.get_region(&"otag").army_count).is_equal(1)
	assert_int(m.actions_remaining).is_equal(0)


# --- spirit AC23 (veri bağımsız kısmı): 4'e 4 tuzağı, 6'yla başarı ---
func test_four_against_level_one_fails_six_succeeds() -> void:
	var fail: MoveOutcome = MoveResolver.new().resolve(_purify_map(5, 1), &"otag", &"dogu")
	assert_bool(fail.purified).is_false()
	assert_int(fail.dispersed).is_equal(4)
	var m: MapState = _purify_map(7, 1)
	assert_int(WinCondition.erlik_power(m)).is_equal(1)
	var state: GameState = GameState.new()
	var c: MapController = _controller(m, state)
	c.select_region(&"otag")
	c.attempt_move(&"dogu")
	assert_int(m.get_region(&"dogu").army_count).is_equal(4)
	assert_int(state.ruh).is_equal(10)
	assert_int(WinCondition.erlik_power(m)).is_equal(0)


func test_reinforcing_own_corrupted_region_is_a_purification_attempt() -> void:
	var m: MapState = _map([
		_region(&"a", RegionData.Owner.PLAYER, 10, [&"b"] as Array[StringName]),
		_region(&"b", RegionData.Owner.PLAYER, 3, [&"a"] as Array[StringName], 1),
	] as Array[RegionData])
	var o: MoveOutcome = MoveResolver.new().resolve(m, &"a", &"b")
	assert_int(o.branch).is_equal(MoveOutcome.Branch.PURIFICATION)
	# Garnizon katılmaz; başarıda kalanlar garnizona eklenir: 3 + (9 − 2).
	assert_int(o.target_army_after).is_equal(10)


func test_arinma_ustaligi_raises_ruh_gain() -> void:
	var bonus: StatModifier = StatModifier.new()
	bonus.source_id = &"boon:arinma_ustaligi"
	bonus.stat_id = SpiritRules.STAT_RUH_GAIN
	bonus.kind = StatModifier.Kind.PERCENT
	bonus.value = 0.2
	var o: MoveOutcome = MoveResolver.new().resolve(_purify_map(10, 2), &"otag", &"dogu",
		RegionData.Owner.PLAYER, [bonus] as Array[StatModifier])
	assert_int(o.ruh_gain).is_equal(24)


# --- army AC12 / spirit AC12: düşman ve fetih arındırmaz ---
func test_enemy_never_purifies() -> void:
	var m: MapState = _map([
		_region(&"e", RegionData.Owner.ENEMY, 6, [&"c"] as Array[StringName]),
		_region(&"c", RegionData.Owner.NEUTRAL, 0, [&"e"] as Array[StringName], 2),
	] as Array[RegionData])
	var o: MoveOutcome = MoveResolver.new().resolve(m, &"e", &"c", RegionData.Owner.ENEMY)
	assert_int(o.branch).is_equal(MoveOutcome.Branch.PEACEFUL)
	assert_int(o.target_corruption_after).is_equal(2)


func test_conquering_corrupted_garrison_keeps_corruption() -> void:
	var m: MapState = _map([
		_region(&"a", RegionData.Owner.PLAYER, 9, [&"e"] as Array[StringName]),
		_region(&"e", RegionData.Owner.ENEMY, 2, [&"a"] as Array[StringName], 2),
	] as Array[RegionData])
	var state: GameState = GameState.new()
	var c: MapController = _controller(m, state)
	c.select_region(&"a")
	c.attempt_move(&"e")
	assert_int(m.get_region(&"e").owner).is_equal(RegionData.Owner.PLAYER)
	assert_int(m.get_region(&"e").corruption_level).is_equal(2)
	assert_int(state.ruh).is_equal(0)


# --- spirit §3.6 / §4.6: yayılım 2. adımda, aralık 3 ---
func _spread_map() -> MapState:
	return _map([
		_region(&"otag", RegionData.Owner.PLAYER, 5, [&"lair"] as Array[StringName]),
		_region(&"lair", RegionData.Owner.NEUTRAL, 0, [&"otag", &"vadi"] as Array[StringName], 3),
		_region(&"vadi", RegionData.Owner.NEUTRAL, 0, [&"lair"] as Array[StringName]),
	] as Array[RegionData])


func test_spread_happens_every_interval_on_weakest_neighbor() -> void:
	var m: MapState = _spread_map()
	var c: MapController = _controller(m, GameState.new())
	var spreads: Array[StringName] = []
	c.corruption_spread.connect(func(d: ErlikSpreadController.SpreadDecision) -> void: spreads.append(d.target_id))
	c.end_turn()
	c.end_turn()
	assert_array(spreads).is_empty()
	c.end_turn()
	# T3 sonu: en az ordulu aday vadi (0) — otag (5) değil.
	assert_array(spreads).contains_exactly([&"vadi"])
	assert_int(m.get_region(&"vadi").corruption_level).is_equal(1)
	assert_int(m.last_erlik_spread_turn).is_equal(3)


func test_spread_reaching_threshold_loses_in_same_end_turn() -> void:
	# spirit AC22: erlik_power 8 → yayılım +1 = 9 ≥ eşik → aynı end_turn'ün 5. adımında kayıp.
	var m: MapState = _spread_map()
	m.get_region(&"otag").corruption_level = 2
	m.get_region(&"vadi").corruption_level = 3
	m.current_turn = 3
	var extra: RegionData = _region(&"kale", RegionData.Owner.NEUTRAL, 0, [&"vadi"] as Array[StringName])
	m.regions[&"kale"] = extra
	m.get_region(&"vadi").adjacent_regions.append(&"kale")
	assert_int(WinCondition.erlik_power(m)).is_equal(8)
	var win: WinCondition = WinCondition.new()
	win.required_neutral_conquests = 99
	win.erlik_loss_threshold = 9
	var c: MapController = _controller(m, GameState.new(), win)
	var events: Array[String] = []
	c.game_lost.connect(func() -> void: events.append("lost"))
	c.turn_ended.connect(func(_t: int) -> void: events.append("turn"))
	c.end_turn()
	assert_int(WinCondition.erlik_power(m)).is_equal(9)
	assert_array(events).contains_exactly(["lost"])
	assert_int(m.loss_reason).is_equal(MapState.LossReason.ERLIK)


# --- spirit §4.3: üretim cezası M_c ---
func test_corruption_reduces_income() -> void:
	var m: MapState = _map([
		_region(&"a", RegionData.Owner.PLAYER, 1, [] as Array[StringName], 0, 2),
		_region(&"b", RegionData.Owner.PLAYER, 1, [] as Array[StringName], 2, 3),
		_region(&"c", RegionData.Owner.PLAYER, 1, [] as Array[StringName], 3, 5),
	] as Array[RegionData])
	# 2 + floor(3 × 0.5) + floor(5 × 0) = 3
	assert_int(ResourceController.new().forecast_income(m)).is_equal(3)


func test_spirit_controller_caps_level_and_moves_counter_without_target() -> void:
	var m: MapState = _spread_map()
	m.current_turn = 6
	var spirit: SpiritController = SpiritController.new()
	spirit.bind_services(GameState.new())
	var none: ErlikSpreadController.SpreadDecision = ErlikSpreadController.SpreadDecision.new()
	none.is_spread_turn = true
	spirit.apply_spread(m, none)
	assert_int(m.last_erlik_spread_turn).is_equal(6)
	var on_lair: ErlikSpreadController.SpreadDecision = ErlikSpreadController.SpreadDecision.new()
	on_lair.is_spread_turn = true
	on_lair.target_id = &"lair"
	spirit.apply_spread(m, on_lair)
	assert_int(m.get_region(&"lair").corruption_level).is_equal(3)


# --- spirit §3.2 Prolog canavarı: seviye 3, garnizon 0, S = 12 → 13 başarı, 12 başarısız ---
func test_beast_lair_needs_thirteen_and_pays_thirty_ruh() -> void:
	var fail: MoveOutcome = MoveResolver.new().resolve(_purify_map(13, 3), &"otag", &"dogu")
	assert_int(fail.corruption_strength).is_equal(12)
	assert_bool(fail.purified).is_false()
	var m: MapState = _purify_map(14, 3)
	var state: GameState = GameState.new()
	var win: WinCondition = WinCondition.new()
	win.must_defeat_all_enemies = true
	win.erlik_foci.assign([&"dogu"])
	var c: MapController = _controller(m, state, win)
	var won: Array[int] = [0]
	c.game_won.connect(func() -> void: won[0] += 1)
	c.select_region(&"otag")
	c.attempt_move(&"dogu")
	assert_int(m.get_region(&"dogu").corruption_level).is_equal(0)
	assert_int(state.ruh).is_equal(30)
	# Odak temizlenince aynı hamlenin sonunda zafer; Ruh zaferden önce hazinede (S1-a).
	assert_int(won[0]).is_equal(1)
