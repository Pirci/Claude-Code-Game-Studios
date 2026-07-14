extends GdUnitTestSuite
## MapController birim testleri — region-map-system.md tur akışı, AI, kazanma/kaybetme.


const PROLOG_MAP: String = "res://features/grid/data/chapter_1_map.tres"


func _region(id: StringName, owner: RegionData.Owner, army: int, adj: Array[StringName], gold: int = 0) -> RegionData:
	var r: RegionData = RegionData.new()
	r.region_id = id
	r.owner = owner
	r.army_count = army
	r.adjacent_regions = adj
	r.gold_per_turn = gold
	return r


func _map(regions: Array[RegionData], actions: int = 1, enemy_actions: int = 1) -> MapState:
	var m: MapState = MapState.new()
	for r: RegionData in regions:
		m.regions[r.region_id] = r
	m.actions_remaining = actions
	m.actions_per_turn = actions
	m.enemy_actions_per_turn = enemy_actions
	return m


func _controller(m: MapState, win: WinCondition) -> MapController:
	var c: MapController = MapController.new()
	c.bind_services(
		m,
		GameState.new(),
		ArmyController.new(),
		ResourceController.new(),
		CombatResolver.new(),
		win,
	)
	return c


func _win(required: int, must_defeat: bool) -> WinCondition:
	var w: WinCondition = WinCondition.new()
	w.required_neutral_conquests = required
	w.must_defeat_all_enemies = must_defeat
	return w


# --- Kabul kriteri 1: Prolog haritası doğru yüklenir ---
func test_prolog_map_loads_six_regions() -> void:
	var def: ChapterMapDefinition = load(PROLOG_MAP) as ChapterMapDefinition
	var m: MapState = def.create_map_state()
	assert_int(m.regions.size()).is_equal(6)
	assert_int(m.get_region(&"otuken").owner).is_equal(RegionData.Owner.PLAYER)
	assert_int(m.get_region(&"sinir_bolge").owner).is_equal(RegionData.Owner.ENEMY)
	# 4 nötr bölge
	var neutral_count: int = 0
	for r: RegionData in m.regions.values():
		if r.owner == RegionData.Owner.NEUTRAL:
			neutral_count += 1
	assert_int(neutral_count).is_equal(4)


# --- Kabul kriteri 2: seçim toggle ---
func test_select_region_toggles() -> void:
	var m: MapState = _map([_region(&"a", RegionData.Owner.PLAYER, 5, [] as Array[StringName])] as Array[RegionData])
	var c: MapController = _controller(m, _win(99, true))
	c.select_region(&"a")
	assert_str(m.selected_region_id).is_equal("a")
	c.select_region(&"a")
	assert_str(m.selected_region_id).is_equal("")


# --- Kabul kriteri 3: geçerli hareket aksiyonu azaltır ---
func test_valid_move_decrements_actions() -> void:
	var m: MapState = _map([
		_region(&"a", RegionData.Owner.PLAYER, 5, [&"b"] as Array[StringName]),
		_region(&"b", RegionData.Owner.NEUTRAL, 0, [&"a"] as Array[StringName]),
	] as Array[RegionData])
	var c: MapController = _controller(m, _win(99, true))
	c.select_region(&"a")
	var ok: bool = c.attempt_move(&"b")
	assert_bool(ok).is_true()
	assert_int(m.actions_remaining).is_equal(0)


# --- Kabul kriteri 5: gelir = oyuncu bölgeleri gold_per_turn toplamı ---
func test_end_turn_collects_income_and_advances() -> void:
	var m: MapState = _map([_region(&"a", RegionData.Owner.PLAYER, 5, [] as Array[StringName], 3)] as Array[RegionData])
	var c: MapController = _controller(m, _win(99, true))
	var income_seen: Dictionary = {"v": -1}
	c.income_collected.connect(func(amount: int) -> void: income_seen["v"] = amount)
	c.end_turn()
	assert_int(income_seen["v"]).is_equal(3)
	assert_int(m.current_turn).is_equal(2)
	assert_int(m.actions_remaining).is_equal(m.actions_per_turn)


# --- Kabul kriteri 6: düşman AI en düşük ordulu düşman-olmayan komşuya saldırır ---
func test_enemy_ai_targets_weakest_neighbor() -> void:
	var m: MapState = _map([
		_region(&"e", RegionData.Owner.ENEMY, 5, [&"weak", &"strong"] as Array[StringName]),
		_region(&"weak", RegionData.Owner.PLAYER, 2, [&"e"] as Array[StringName]),
		_region(&"strong", RegionData.Owner.PLAYER, 4, [&"e"] as Array[StringName]),
	] as Array[RegionData])
	var c: MapController = _controller(m, _win(99, true))
	c.end_turn()
	assert_int(m.get_region(&"weak").owner).is_equal(RegionData.Owner.ENEMY)
	assert_int(m.get_region(&"strong").owner).is_equal(RegionData.Owner.PLAYER)


# --- enemy_actions_per_turn data-driven limiti ---
func test_enemy_actions_limit_one() -> void:
	var m: MapState = _map([
		_region(&"e1", RegionData.Owner.ENEMY, 5, [&"p1"] as Array[StringName]),
		_region(&"e2", RegionData.Owner.ENEMY, 5, [&"p2"] as Array[StringName]),
		_region(&"p1", RegionData.Owner.PLAYER, 1, [&"e1"] as Array[StringName]),
		_region(&"p2", RegionData.Owner.PLAYER, 1, [&"e2"] as Array[StringName]),
	] as Array[RegionData], 1, 1)
	var c: MapController = _controller(m, _win(99, true))
	c.end_turn()
	assert_int(m.get_player_regions().size()).is_equal(1)


func test_enemy_actions_limit_two() -> void:
	var m: MapState = _map([
		_region(&"e1", RegionData.Owner.ENEMY, 5, [&"p1"] as Array[StringName]),
		_region(&"e2", RegionData.Owner.ENEMY, 5, [&"p2"] as Array[StringName]),
		_region(&"p1", RegionData.Owner.PLAYER, 1, [&"e1"] as Array[StringName]),
		_region(&"p2", RegionData.Owner.PLAYER, 1, [&"e2"] as Array[StringName]),
	] as Array[RegionData], 1, 2)
	var c: MapController = _controller(m, _win(99, true))
	c.end_turn()
	assert_int(m.get_player_regions().size()).is_equal(0)


# --- Kabul kriteri 7: kazanma sinyali ---
func test_game_won_emitted() -> void:
	var m: MapState = _map([
		_region(&"a", RegionData.Owner.PLAYER, 5, [] as Array[StringName]),
		_region(&"b", RegionData.Owner.PLAYER, 1, [] as Array[StringName]),
		_region(&"c", RegionData.Owner.PLAYER, 1, [] as Array[StringName]),
		_region(&"d", RegionData.Owner.PLAYER, 1, [] as Array[StringName]),
	] as Array[RegionData])
	var c: MapController = _controller(m, _win(3, true))
	var won: Dictionary = {"v": false}
	c.game_won.connect(func() -> void: won["v"] = true)
	c.end_turn()
	assert_bool(won["v"]).is_true()


# --- Kabul kriteri 8: kaybetme sinyali ---
func test_game_lost_emitted() -> void:
	var m: MapState = _map([
		_region(&"n1", RegionData.Owner.NEUTRAL, 0, [] as Array[StringName]),
		_region(&"n2", RegionData.Owner.NEUTRAL, 0, [] as Array[StringName]),
	] as Array[RegionData])
	var c: MapController = _controller(m, _win(3, true))
	var lost: Dictionary = {"v": false}
	c.game_lost.connect(func() -> void: lost["v"] = true)
	c.end_turn()
	assert_bool(lost["v"]).is_true()
