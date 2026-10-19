extends GdUnitTestSuite
## Prolog denge regresyonu (C-64; resource-system AC15, design/balance/prolog-balance-2026-10-19.md):
## referans çizgileri gerçek kontrolcülerle oynatılır ve tools/balance/prolog_sim.py'nin (kural
## tekrarı, 12/12) sonuçlarıyla karşılaştırılır; "T4'te zafer yok" budamalı aramayla kanıtlanır.


const PrologReplay := preload("res://tests/integration/balance/prolog_replay.gd")

## P(w) çizgilerinin pasif bekleme sonrası ortak hamleleri (prolog_sim.py ile aynı).
const P_TAIL: Array = [
	[["rec", "O", 1], ["mv", "O", "A"]],
	[["rec", "O", 2], ["mv", "A", "B"]],
	[["rec", "O", 2], ["mv", "B", "G"]],
	[["rec", "G", 3], ["rec", "O", 1], ["mv", "O", "G"]],
	[["rec", "G", 3], ["mv", "G", "L"]],
]

## Ad → [çizgi, pasif tur, boşta üretim bölgesi, beklenen (sonuç, tur, Ruh)] — prolog_sim.py LINES.
var LINES: Dictionary = {
	"A fastest": [[
		[["rec", "O", 2], ["mv", "O", "A"]],
		[["rec", "O", 2], ["mv", "O", "G"], ["rec", "G", 1]],
		[["rec", "G", 3], ["mv", "A", "B"]],
		[["rec", "G", 3], ["rec", "B", 1], ["mv", "B", "G"]],
		[["rec", "G", 3], ["mv", "G", "L"]]], 0, "O", ["WON", 5, 30]],
	"E1 engaged-light": [[
		[["rec", "O", 2], ["mv", "O", "D"]],
		[["rec", "O", 2], ["mv", "O", "G"]],
		[["rec", "G", 3], ["mv", "G", "B"]],
		[["rec", "O", 2], ["rec", "D", 1], ["mv", "D", "O"]],
		[["rec", "O", 2], ["mv", "O", "G"], ["rec", "G", 1]],
		[["rec", "G", 3], ["rec", "O", 1], ["mv", "B", "G"]],
		[["rec", "G", 3], ["mv", "G", "L"]]], 0, "O", ["WON", 7, 50]],
	"E3 engaged mid-scene boon": [[
		[["rec", "O", 2], ["mv", "O", "G"]],
		[["rec", "G", 3], ["mv", "G", "B"]],
		[["rec", "O", 2], ["rec", "G", 1], ["mv", "B", "A"]],
		[["rec", "O", 2], ["rec", "G", 2], ["mv", "A", "O"]],
		[["rec", "O", 2], ["rec", "G", 2], ["mv", "O", "D"]],
		[["rec", "G", 3], ["rec", "O", 2], ["mv", "D", "O"]],
		[["rec", "O", 2], ["rec", "G", 2], ["mv", "O", "D"], ["boon", "arinma_ustaligi"]],
		[["rec", "G", 3], ["mv", "G", "L"]]], 0, "O", ["WON", 8, 36]],
	"C greedy conquest": [[
		[["rec", "O", 2], ["mv", "O", "A"]],
		[["rec", "O", 2], ["mv", "O", "G"], ["rec", "G", 1]],
		[["rec", "G", 3], ["mv", "A", "B"]]], 0, "G", ["LOST", 15, 0]],
	"P inf passive": [[], 0, "O", ["LOST", 15, 0]],
	"P w=3": [P_TAIL, 3, "O", ["WON", 8, 30]],
	"P w=6": [P_TAIL, 6, "O", ["WON", 11, 30]],
	"P w=8": [P_TAIL, 8, "O", ["WON", 13, 40]],
	"P w=9": [P_TAIL, 9, "O", ["WON", 14, 40]],
	"P w=12": [P_TAIL, 12, "O", ["WON", 17, 50]],
	"P w=13 ignores warning": [[
		[["rec", "O", 1], ["mv", "O", "A"]],
		[["rec", "O", 2], ["mv", "A", "B"]]], 13, "O", ["LOST", 15, 0]],
	"P w=13 purify-first": [[
		[["rec", "O", 1], ["mv", "O", "G"]],
		[["rec", "G", 2], ["mv", "G", "B"]],
		[["rec", "G", 2], ["rec", "B", 1], ["mv", "B", "A"]],
		[["rec", "G", 2], ["rec", "A", 1], ["mv", "A", "B"]],
		[["rec", "G", 2], ["rec", "B", 1], ["mv", "B", "G"]],
		[["rec", "G", 3], ["mv", "G", "L"]]], 13, "O", ["WON", 19, 60]],
}


func _play(name: String) -> PrologReplay:
	var line: Array = LINES[name]
	var replay: PrologReplay = PrologReplay.new()
	assert_bool(replay.run_line(line[0], line[1], line[2])).override_failure_message(name).is_true()
	return replay


func _outcome(replay: PrologReplay) -> Array:
	match replay.game_state.map_state.game_result:
		MapState.GameResult.WON:
			return ["WON", replay.finished_turn, replay.game_state.ruh]
		MapState.GameResult.LOST:
			return ["LOST", replay.finished_turn, 0]
	return ["ONGOING", replay.game_state.map_state.current_turn, replay.game_state.ruh]


# Rapor tablosu (12 çizgi) gerçek kodla birebir; her çizgide sonuç sinyali tek kez.
func test_reference_lines_match_rule_replay() -> void:
	for name: String in LINES:
		var replay: PrologReplay = _play(name)
		var expected: Array = LINES[name][3]
		assert_array(_outcome(replay)).override_failure_message("%s: %s" % [name, _outcome(replay)]).is_equal(expected)
		assert_int(replay.won_signals + replay.lost_signals).override_failure_message(name).is_equal(1)


# AC15 (A): zafer 5. turun hamlesinde, Ruh 30, sahne sonu sunumu bekler.
func test_line_a_wins_on_turn_five_with_offer_pending() -> void:
	var replay: PrologReplay = _play("A fastest")
	assert_int(replay.finished_turn).is_equal(5)
	assert_int(replay.game_state.ruh).is_equal(30)
	assert_bool(replay.spirit.is_offer_pending()).is_true()


# AC15 (C): erlik_power T3/T6/T9/T12/T15 sonlarında 5/6/7/8/9; 15. turda tek kayıp.
func test_line_c_erlik_shadow_climbs_to_loss_on_turn_fifteen() -> void:
	var replay: PrologReplay = _play("C greedy conquest")
	var powers: Array = [3, 6, 9, 12, 15].map(func(t: int) -> int: return replay.power_by_turn[t])
	assert_array(powers).is_equal([5, 6, 7, 8, 9])
	assert_int(replay.lost_signals).is_equal(1)
	assert_int(replay.game_state.map_state.loss_reason).is_equal(MapState.LossReason.ERLIK)


# AC15 (P8): zafer 13. turda; hiçbir tur sonunda erlik_power 8'i aşmaz.
func test_passive_eight_wins_on_thirteen_without_exceeding_eight() -> void:
	var replay: PrologReplay = _play("P w=8")
	assert_int(replay.finished_turn).is_equal(13)
	for turn: int in replay.power_by_turn:
		assert_int(replay.power_by_turn[turn]).override_failure_message("T%d" % turn).is_less_equal(8)


# AC15 (E3): 7. turda, inden önce Ruh ≥ 30 ve lütuf sunumu sahne ortasında bekler.
func test_line_e3_has_mid_scene_offer_on_turn_seven() -> void:
	var line: Array = LINES["E3 engaged mid-scene boon"][0]
	var replay: PrologReplay = PrologReplay.new()
	for i: int in 6:
		replay.play_turn(line[i])
	# 7. tur, lütuf seçiminden önce: O+2, G+2, O→D arındırma.
	replay.recruit("O", 2)
	replay.recruit("G", 2)
	replay.move("O", "D")
	assert_int(replay.game_state.map_state.current_turn).is_equal(7)
	assert_int(replay.game_state.ruh).is_greater_equal(30)
	assert_bool(replay.spirit.is_offer_pending()).is_true()
	assert_int(replay.region("L").corruption_level).is_equal(3)


# AC15 (A): hiçbir hamle dizisi 4. turda zafer üretmez — budamalı arama, gerçek kontrolcüler.
func test_no_move_sequence_wins_by_turn_four() -> void:
	var search: Dictionary = {"nodes": 0, "wins": []}
	var start: PrologReplay = PrologReplay.new()
	_search(start.game_state, 1, [], search)
	assert_array(search["wins"]).override_failure_message("T4 zafer: %s" % [search["wins"]]).is_empty()
	assert_int(search["nodes"]).is_greater(0)


## Tur başı durumundan [param turn]. turun tüm verimli planlarını dener (en çok 4. tura dek):
## hamle öncesi kaynakta üretim × verimli hamle × hamle sonrası tüm tükenmiş üretim dağılımları.
func _search(state: GameState, turn: int, path: Array, search: Dictionary) -> void:
	if turn > 4:
		return
	var probe: PrologReplay = PrologReplay.new(_clone(state))
	if _moves_needed(probe) > 5 - turn:
		return
	for plan: Array in _plans(probe):
		var moved: PrologReplay = PrologReplay.new(_clone(state))
		if not _apply_move(moved, plan):
			continue
		search["nodes"] += 1
		if moved.game_state.map_state.game_result == MapState.GameResult.WON:
			search["wins"].append(path + [plan])
			continue
		for allocation: Dictionary in _allocations(moved):
			var replay: PrologReplay = PrologReplay.new(_clone(moved.game_state))
			for region_id: StringName in allocation:
				replay.map.recruit(region_id, allocation[region_id])
			replay.end_turn()
			if replay.ongoing():
				_search(replay.game_state, turn + 1, path + [plan + [allocation]], search)


## Kalan verimli hamle: fethedilecek nötr (gereken − fethedilen) + bozuk odak sayısı.
func _moves_needed(replay: PrologReplay) -> int:
	var win: WinCondition = replay.definition.win_condition
	var needed: int = maxi(0, win.required_neutral_conquests - win.conquered_neutral_count(replay.game_state.map_state))
	for focus: StringName in win.erlik_foci:
		if replay.game_state.map_state.get_region(focus).corruption_level > 0:
			needed += 1
	return needed


## Plan = [kaynak, hedef, hamle öncesi kaynakta üretim k] — yalnızca oyuncuya ait olmayan komşuya.
func _plans(replay: PrologReplay) -> Array:
	var plans: Array = []
	var map_state: MapState = replay.game_state.map_state
	for source: RegionData in map_state.get_player_regions():
		for target_id: StringName in source.adjacent_regions:
			if map_state.get_region(target_id).owner == RegionData.Owner.PLAYER:
				continue
			for pre: int in range(replay.resources.max_recruit(replay.game_state, source) + 1):
				plans.append([source.region_id, target_id, pre])
	return plans


## Hamle verimli olmalı (fetih ya da arındırma başarılı); değilse dal T4 zaferine götüremez.
func _apply_move(replay: PrologReplay, plan: Array) -> bool:
	var source: StringName = plan[0]
	var target: StringName = plan[1]
	if plan[2] > 0 and not replay.map.recruit(source, plan[2]):
		return false
	if replay.game_state.map_state.get_region(source).army_count <= 1:
		return false
	replay.map.select_region(source)
	if not replay.map.attempt_move(target):
		return false
	var region: RegionData = replay.game_state.map_state.get_region(target)
	return region.owner == RegionData.Owner.PLAYER and region.corruption_level == 0


## Hamle sonrası üretim: altın ya da tavan bitene dek yapılan tüm dağılımlar (tükenmiş olanlar —
## eksik harcama hiçbir dalı güçlendirmez; birlik yer değiştirmez, bakım yok).
func _allocations(replay: PrologReplay) -> Array[Dictionary]:
	var regions: Array[RegionData] = replay.game_state.map_state.get_player_regions()
	var caps: Array[int] = []
	for region: RegionData in regions:
		caps.append(replay.resources.remaining_cap(region))
	var cost: int = replay.resources.recruit_cost()
	var result: Array[Dictionary] = []
	_allocate(regions, caps, 0, replay.game_state.gold, cost, {}, result)
	return result


func _allocate(regions: Array[RegionData], caps: Array[int], index: int, gold: int, cost: int,
		current: Dictionary, result: Array[Dictionary]) -> void:
	if index == regions.size():
		# Tükenmiş: altın yetmiyor ya da hiçbir bölgede tavan kalmadı.
		var exhausted: bool = gold < cost
		if not exhausted:
			exhausted = true
			for i: int in regions.size():
				if current.get(regions[i].region_id, 0) < caps[i]:
					exhausted = false
		if exhausted:
			result.append(current.duplicate())
		return
	for count: int in range(mini(caps[index], gold / cost) + 1):
		if count > 0:
			current[regions[index].region_id] = count
		else:
			current.erase(regions[index].region_id)
		_allocate(regions, caps, index + 1, gold - count * cost, cost, current, result)
	current.erase(regions[index].region_id)


## Kayıt kopyası + tur içi üretim sayaçları (kayda girmez, tur ortası kopya için taşınır).
func _clone(state: GameState) -> GameState:
	var definition: ChapterMapDefinition = load(PrologReplay.PROLOG_MAP) as ChapterMapDefinition
	var copy: GameState = SaveSerializer.from_dict(SaveSerializer.to_dict(state),
		func(_chapter: int) -> MapState: return definition.create_map_state()).state
	for region: RegionData in state.map_state.regions.values():
		copy.map_state.get_region(region.region_id).recruited_this_turn = region.recruited_this_turn
	return copy
