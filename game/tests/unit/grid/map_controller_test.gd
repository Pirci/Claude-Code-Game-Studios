extends GdUnitTestSuite
## MapController birim testleri — region-map-system.md tur akışı, AI, kazanma/kaybetme.


const PROLOG_MAP: String = "res://features/grid/data/chapter_1_map.tres"


func _region(id: StringName, owner: RegionData.Owner, army: int, adj: Array[StringName], gold: int = 0) -> RegionData:
	var r: RegionData = RegionData.new()
	r.region_id = id
	r.owner = owner
	r.initial_owner = owner
	r.army_count = army
	r.adjacent_regions = adj
	r.gold_per_turn = gold
	return r


## Başlangıçta nötr olup şimdi oyuncunun olan bölge (fethedilmiş nötr, region-map §4).
func _conquered(id: StringName, army: int) -> RegionData:
	var r: RegionData = _region(id, RegionData.Owner.PLAYER, army, [] as Array[StringName])
	r.initial_owner = RegionData.Owner.NEUTRAL
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
		EnemyAIController.new(),
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
		_conquered(&"b", 1),
		_conquered(&"c", 1),
		_conquered(&"d", 1),
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


# --- ADR-0005 karar → uygula döngüsü: davranış korunur (C-19) ---
func test_region_conquered_by_enemy_does_not_act_same_turn() -> void:
	# e1 p1'i alır; bütçe 2 olsa da p1 (yeni düşman bölgesi) bu tur hareket etmez,
	# ikinci aksiyon e2'nindir — eski satır içi AI'ın anlık görüntü davranışı.
	var m: MapState = _map([
		_region(&"e1", RegionData.Owner.ENEMY, 9, [&"p1"] as Array[StringName]),
		_region(&"p1", RegionData.Owner.PLAYER, 1, [&"e1", &"p3"] as Array[StringName]),
		_region(&"e2", RegionData.Owner.ENEMY, 5, [&"p2"] as Array[StringName]),
		_region(&"p2", RegionData.Owner.PLAYER, 1, [&"e2"] as Array[StringName]),
		_region(&"p3", RegionData.Owner.PLAYER, 1, [&"p1"] as Array[StringName]),
	] as Array[RegionData], 1, 2)
	var c: MapController = _controller(m, _win(99, true))
	c.end_turn()
	assert_int(m.get_region(&"p1").owner).is_equal(RegionData.Owner.ENEMY)
	assert_int(m.get_region(&"p2").owner).is_equal(RegionData.Owner.ENEMY)
	assert_int(m.get_region(&"p3").owner).is_equal(RegionData.Owner.PLAYER)


func test_enemy_moves_emit_existing_signals() -> void:
	var m: MapState = _map([
		_region(&"e", RegionData.Owner.ENEMY, 5, [&"n"] as Array[StringName]),
		_region(&"n", RegionData.Owner.NEUTRAL, 0, [&"e"] as Array[StringName]),
		_region(&"p", RegionData.Owner.PLAYER, 3, [] as Array[StringName]),
	] as Array[RegionData])
	var c: MapController = _controller(m, _win(99, false))
	var moved: Dictionary = {"to": &""}
	c.army_moved.connect(func(_from: StringName, to: StringName, _n: int) -> void: moved["to"] = to)
	c.end_turn()
	assert_str(moved["to"]).is_equal("n")
	assert_int(m.get_region(&"e").army_count).is_equal(1)
	assert_int(m.get_region(&"n").army_count).is_equal(4)


# --- army AC13 (uçtan uca): 1'e 1 beraberlik → hedef NEUTRAL, kaynak 1, kimse eklenmez (C-52) ---
func test_draw_attack_empties_target_to_neutral() -> void:
	var m: MapState = _map([
		_region(&"a", RegionData.Owner.PLAYER, 2, [&"b"] as Array[StringName]),
		_region(&"b", RegionData.Owner.ENEMY, 1, [&"a"] as Array[StringName]),
	] as Array[RegionData])
	var c: MapController = _controller(m, _win(99, true))
	c.select_region(&"a")
	assert_bool(c.attempt_move(&"b")).is_true()
	assert_int(m.get_region(&"b").owner).is_equal(RegionData.Owner.NEUTRAL)
	assert_int(m.get_region(&"b").army_count).is_equal(0)
	assert_int(m.get_region(&"a").army_count).is_equal(1)


# --- region-map AC7 / §3.7: tur ortası zafer bir kez, sonra oyun kilitli (C-51) ---
func test_mid_turn_victory_locks_game() -> void:
	var m: MapState = _map([
		_region(&"a", RegionData.Owner.PLAYER, 5, [&"b"] as Array[StringName], 2),
		_region(&"b", RegionData.Owner.NEUTRAL, 0, [&"a"] as Array[StringName]),
		_region(&"e", RegionData.Owner.ENEMY, 0, [] as Array[StringName]),
	] as Array[RegionData], 2)
	m.get_region(&"e").owner = RegionData.Owner.NEUTRAL
	var c: MapController = _controller(m, _win(1, true))
	var wins: Array[int] = [0]
	var incomes: Array[int] = [0]
	c.game_won.connect(func() -> void: wins[0] += 1)
	c.income_collected.connect(func(_amount: int) -> void: incomes[0] += 1)
	c.select_region(&"a")
	assert_bool(c.attempt_move(&"b")).is_true()
	assert_int(wins[0]).is_equal(1)
	assert_int(m.game_result).is_equal(MapState.GameResult.WON)
	# Kilit: kalan aksiyon ve tur sonu çalışmaz, zafer tekrar yayılmaz.
	c.select_region(&"b")
	assert_bool(c.attempt_move(&"a")).is_false()
	c.end_turn()
	assert_int(m.current_turn).is_equal(1)
	assert_int(incomes[0]).is_equal(0)
	assert_int(wins[0]).is_equal(1)


# --- region-map AC8 / §3.4 erken çıkış: AI son bölgeyi 1. adımda alırsa 2–4 çalışmaz (C-51) ---
func test_enemy_taking_last_region_ends_game_before_economy() -> void:
	var m: MapState = _map([
		_region(&"e", RegionData.Owner.ENEMY, 9, [&"p"] as Array[StringName]),
		_region(&"p", RegionData.Owner.PLAYER, 1, [&"e"] as Array[StringName], 3),
	] as Array[RegionData])
	var c: MapController = _controller(m, _win(99, true))
	var events: Array[String] = []
	c.game_lost.connect(func() -> void: events.append("lost"))
	c.income_collected.connect(func(_amount: int) -> void: events.append("income"))
	c.turn_ended.connect(func(_turn: int) -> void: events.append("turn"))
	c.end_turn()
	assert_array(events).contains_exactly(["lost"])
	assert_int(m.current_turn).is_equal(1)
	assert_int(m.game_result).is_equal(MapState.GameResult.LOST)
	c.select_region(&"e")
	assert_bool(c.attempt_move(&"p")).is_false()


# --- region-map AC12: turn_ended kontrolden sonra ve yalnızca ONGOING iken (C-51) ---
func test_turn_ended_follows_end_of_turn_check() -> void:
	var m: MapState = _map([
		_region(&"a", RegionData.Owner.PLAYER, 5, [] as Array[StringName], 2),
	] as Array[RegionData])
	var c: MapController = _controller(m, _win(99, true))
	var seen: Array = []
	c.turn_ended.connect(func(turn: int) -> void: seen.append([turn, m.current_turn, m.game_result, m.actions_remaining]))
	c.end_turn()
	assert_array(seen).contains_exactly([[2, 2, MapState.GameResult.ONGOING, m.actions_per_turn]])


func test_end_of_turn_victory_emits_no_turn_ended() -> void:
	var m: MapState = _map([
		_region(&"a", RegionData.Owner.PLAYER, 5, [] as Array[StringName]),
		_conquered(&"b", 1),
	] as Array[RegionData])
	var c: MapController = _controller(m, _win(1, true))
	var events: Array[String] = []
	c.game_won.connect(func() -> void: events.append("won"))
	c.turn_ended.connect(func(_turn: int) -> void: events.append("turn"))
	c.end_turn()
	assert_array(events).contains_exactly(["won"])
