extends GdUnitTestSuite
## Ordu üretimi ve ekonomi adımı — resource-system.md AC1–AC24 (C-37).


func _region(id: StringName, owner: RegionData.Owner, army: int, gold: int = 0, adj: Array[StringName] = []) -> RegionData:
	var r: RegionData = RegionData.new()
	r.region_id = id
	r.owner = owner
	r.initial_owner = owner
	r.army_count = army
	r.gold_per_turn = gold
	r.adjacent_regions = adj
	return r


func _map(regions: Array[RegionData]) -> MapState:
	var m: MapState = MapState.new()
	for r: RegionData in regions:
		m.regions[r.region_id] = r
	m.actions_remaining = 1
	m.actions_per_turn = 1
	return m


func _state(gold: int) -> GameState:
	var s: GameState = GameState.new()
	s.gold = gold
	return s


func _modifier(kind: StatModifier.Kind, value: float) -> StatModifier:
	var m: StatModifier = StatModifier.new()
	m.source_id = &"test"
	m.stat_id = IncomeRules.STAT_GOLD_INCOME
	m.kind = kind
	m.value = value
	return m


func _controller(m: MapState, s: GameState) -> MapController:
	var c: MapController = MapController.new()
	var win: WinCondition = WinCondition.new()
	win.required_neutral_conquests = 99
	c.bind_services(m, s, ArmyController.new(), ResourceController.new(), CombatResolver.new(), win, EnemyAIController.new())
	return c


# AC2 / AC22: gelir yalnızca oyuncu bölgelerinden; nötrler değişmez.
func test_income_sums_player_regions_only() -> void:
	var m: MapState = _map([
		_region(&"otag", RegionData.Owner.PLAYER, 5, 2),
		_region(&"vadi", RegionData.Owner.PLAYER, 1, 3),
		_region(&"n1", RegionData.Owner.NEUTRAL, 2, 4),
		_region(&"n2", RegionData.Owner.NEUTRAL, 4, 4),
	] as Array[RegionData])
	var s: GameState = _state(0)
	assert_int(ResourceController.new().collect_turn_income(m, s)).is_equal(5)
	assert_int(s.gold).is_equal(5)
	assert_int(m.get_region(&"n1").army_count).is_equal(2)
	assert_int(m.get_region(&"n2").army_count).is_equal(4)


# AC3 / AC24: bozulma çarpanı.
func test_corruption_multiplier_reduces_income() -> void:
	var r: RegionData = _region(&"a", RegionData.Owner.PLAYER, 1, 2)
	assert_int(IncomeRules.region_income(r, 0.75)).is_equal(1)
	var vadi: RegionData = _region(&"vadi", RegionData.Owner.PLAYER, 1, 3)
	vadi.corruption_level = 2
	assert_int(ResourceController.new().forecast_income(_map([vadi] as Array[RegionData]))).is_equal(1)


# AC4 / AC23: F2 lütuf terimleri, taban ve bölgesiz durum.
func test_turn_income_formula() -> void:
	var config: EconomyConfig = EconomyConfig.new()
	var flat: Array[StatModifier] = [_modifier(StatModifier.Kind.FLAT, 1.0)]
	assert_int(IncomeRules.turn_income(5, true, flat, config)).is_equal(6)
	var both: Array[StatModifier] = [_modifier(StatModifier.Kind.FLAT, 1.0), _modifier(StatModifier.Kind.PERCENT, 0.2)]
	assert_int(IncomeRules.turn_income(5, true, both, config)).is_equal(7)
	config.income_floor = 1
	assert_int(IncomeRules.turn_income(0, true, [] as Array[StatModifier], config)).is_equal(1)
	assert_int(IncomeRules.turn_income(0, false, [] as Array[StatModifier], config)).is_equal(0)


# AC5 / AC6 / AC7: üretim, tavan, kısmi üretim yok.
func test_recruit_spends_gold_and_respects_cap() -> void:
	var m: MapState = _map([_region(&"otag", RegionData.Owner.PLAYER, 5, 2)] as Array[RegionData])
	var s: GameState = _state(6)
	var rc: ResourceController = ResourceController.new()
	assert_bool(rc.recruit(m, s, &"otag", 2)).is_true()
	assert_int(s.gold).is_equal(2)
	assert_int(m.get_region(&"otag").army_count).is_equal(7)
	assert_bool(rc.recruit(m, s, &"otag", 1)).is_false()
	assert_int(s.gold).is_equal(2)


func test_no_partial_recruit_when_gold_is_short() -> void:
	var m: MapState = _map([_region(&"vadi", RegionData.Owner.PLAYER, 1, 3)] as Array[RegionData])
	var s: GameState = _state(3)
	assert_bool(ResourceController.new().recruit(m, s, &"vadi", 2)).is_false()
	assert_int(s.gold).is_equal(3)
	assert_int(m.get_region(&"vadi").army_count).is_equal(1)


# AC9: etkin geliri 0 olan bölgenin tavanı R_min = 1.
func test_zero_income_region_still_recruits_one() -> void:
	var lair: RegionData = _region(&"lair", RegionData.Owner.PLAYER, 1, 1)
	lair.corruption_level = 3
	var rc: ResourceController = ResourceController.new()
	assert_int(rc.remaining_cap(lair)).is_equal(1)
	assert_int(rc.remaining_cap(_region(&"z", RegionData.Owner.PLAYER, 1, 0))).is_equal(1)


# AC14: nötr ya da düşman bölgede üretim yok.
func test_cannot_recruit_in_foreign_regions() -> void:
	var m: MapState = _map([
		_region(&"n", RegionData.Owner.NEUTRAL, 1, 3),
		_region(&"e", RegionData.Owner.ENEMY, 1, 3),
	] as Array[RegionData])
	var s: GameState = _state(10)
	var rc: ResourceController = ResourceController.new()
	assert_bool(rc.recruit(m, s, &"n", 1)).is_false()
	assert_bool(rc.recruit(m, s, &"e", 1)).is_false()
	assert_int(s.gold).is_equal(10)


# AC20: tavan birden çok üretimde birikir.
func test_cap_accumulates_over_several_recruits() -> void:
	var m: MapState = _map([_region(&"vadi", RegionData.Owner.PLAYER, 1, 3)] as Array[RegionData])
	var s: GameState = _state(10)
	var rc: ResourceController = ResourceController.new()
	assert_bool(rc.recruit(m, s, &"vadi", 1)).is_true()
	assert_bool(rc.recruit(m, s, &"vadi", 2)).is_true()
	assert_int(m.get_region(&"vadi").army_count).is_equal(4)
	assert_int(s.gold).is_equal(4)
	assert_bool(rc.recruit(m, s, &"vadi", 1)).is_false()


# AC10 / AC12: takviye ve bakım.
func test_enemy_reinforcement_and_upkeep() -> void:
	var m: MapState = _map([
		_region(&"e1", RegionData.Owner.ENEMY, 1),
		_region(&"e2", RegionData.Owner.ENEMY, 3),
		_region(&"p", RegionData.Owner.PLAYER, 13),
	] as Array[RegionData])
	var rc: ResourceController = ResourceController.new()
	rc.reinforce_enemies(m)
	assert_int(m.get_region(&"e1").army_count).is_equal(2)
	assert_int(m.get_region(&"e2").army_count).is_equal(4)
	var s: GameState = _state(2)
	assert_int(rc.pay_upkeep(m, s)).is_equal(0)
	var config: EconomyConfig = EconomyConfig.new()
	config.upkeep_per_army = 1
	rc.bind_services(null, config)
	assert_int(rc.pay_upkeep(m, s)).is_equal(2)
	assert_int(s.gold).is_equal(0)
	assert_int(m.get_region(&"p").army_count).is_equal(13)


# AC8 / AC18 / AC13 / AC19 (MapController ile).
func test_recruit_costs_no_action_and_counters_reset_next_turn() -> void:
	var m: MapState = _map([
		_region(&"otag", RegionData.Owner.PLAYER, 5, 2, [&"n"] as Array[StringName]),
		_region(&"n", RegionData.Owner.NEUTRAL, 0, 1, [&"otag"] as Array[StringName]),
	] as Array[RegionData])
	var s: GameState = _state(6)
	var c: MapController = _controller(m, s)
	var recruited: Array[int] = [0]
	c.army_recruited.connect(func(_id: StringName, count: int) -> void: recruited[0] += count)
	assert_bool(c.recruit(&"otag", 2)).is_true()
	assert_int(m.actions_remaining).is_equal(1)
	assert_int(recruited[0]).is_equal(2)
	# AC13: üretilenler aynı tur hareket eder (7 − 1 = 6 taşınır).
	c.select_region(&"otag")
	c.attempt_move(&"n")
	assert_int(m.get_region(&"n").army_count).is_equal(6)
	# AC19: yeni ele geçirilen bölgede sayaç 0'dan.
	assert_int(m.get_region(&"n").recruited_this_turn).is_equal(0)
	c.end_turn()
	# AC8: yeni turda sayaçlar 0.
	assert_int(m.get_region(&"otag").recruited_this_turn).is_equal(0)


func test_recruit_is_refused_after_game_over() -> void:
	var m: MapState = _map([_region(&"otag", RegionData.Owner.PLAYER, 5, 2)] as Array[RegionData])
	m.game_result = MapState.GameResult.WON
	assert_bool(_controller(m, _state(6)).recruit(&"otag", 1)).is_false()


# AC1: Prolog sahnesi `starting_gold` ile açılır.
func test_prolog_scene_starts_with_six_gold() -> void:
	var state: GameState = GameState.new()
	var game: GameContext = (load("res://contexts/game_context/game_context.tscn") as PackedScene).instantiate() as GameContext
	game.bind_services(state, AccessibilitySettings.new())
	add_child(game)
	auto_free(game)
	assert_int(state.gold).is_equal(6)
