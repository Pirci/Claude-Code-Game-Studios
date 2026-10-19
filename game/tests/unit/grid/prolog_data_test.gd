extends GdUnitTestSuite
## Prolog veri kabul kriteri — region-map AC1 / AC14 (C-49 değerleri, C-36) ve spirit AC23.


const PROLOG_MAP: String = "res://features/grid/data/chapter_1_map.tres"
## Kaynak: design/balance/prolog-balance-2026-10-19.md §3 (bölge | sahip | garnizon | altın | bozulma).
const EXPECTED: Dictionary = {
	&"otuken": [RegionData.Owner.PLAYER, 5, 2, 0],
	&"bati_bozkir": [RegionData.Owner.NEUTRAL, 3, 1, 0],
	&"dogu_bozkir": [RegionData.Owner.NEUTRAL, 0, 1, 1],
	&"altai": [RegionData.Owner.NEUTRAL, 2, 2, 0],
	&"guney_vadi": [RegionData.Owner.NEUTRAL, 0, 3, 0],
	&"sinir_bolge": [RegionData.Owner.NEUTRAL, 0, 1, 3],
}

var _definition: ChapterMapDefinition


func before_test() -> void:
	_definition = load(PROLOG_MAP) as ChapterMapDefinition


func test_regions_match_balance_report() -> void:
	var m: MapState = _definition.create_map_state()
	assert_int(m.regions.size()).is_equal(EXPECTED.size())
	for id: StringName in EXPECTED:
		var r: RegionData = m.get_region(id)
		var row: Array = EXPECTED[id]
		assert_int(r.owner).override_failure_message(String(id)).is_equal(row[0])
		assert_int(r.army_count).override_failure_message(String(id)).is_equal(row[1])
		assert_int(r.gold_per_turn).override_failure_message(String(id)).is_equal(row[2])
		assert_int(r.corruption_level).override_failure_message(String(id)).is_equal(row[3])
	assert_int(m.get_enemy_regions().size()).is_equal(0)


func test_scene_values_match_balance_report() -> void:
	var win: WinCondition = _definition.win_condition
	assert_array(win.erlik_foci).contains_exactly([&"sinir_bolge"])
	assert_int(win.erlik_loss_threshold).is_equal(9)
	assert_int(win.required_neutral_conquests).is_equal(3)
	assert_int(_definition.erlik_spread_interval).is_equal(3)
	assert_int(_definition.starting_gold).is_equal(6)
	assert_str(String(_definition.enemy_tamga_id)).is_empty()


## Genel kural (her bölüm): eşik açıksa başlangıç Erlik gücü eşiğin altında; odaklar nötr,
## garnizonsuz ve bozuk (S1-e — garnizonlu odak son hamleyi savaşa çevirirdi).
func test_foci_and_threshold_rules() -> void:
	var m: MapState = _definition.create_map_state()
	var win: WinCondition = _definition.win_condition
	assert_int(WinCondition.erlik_power(m)).is_equal(4)
	assert_bool(win.erlik_loss_threshold == 0 or WinCondition.erlik_power(m) < win.erlik_loss_threshold).is_true()
	for focus_id: StringName in win.erlik_foci:
		var focus: RegionData = m.get_region(focus_id)
		assert_int(focus.owner).is_equal(RegionData.Owner.NEUTRAL)
		assert_int(focus.army_count).is_equal(0)
		assert_int(focus.corruption_level).is_greater_equal(1)


## spirit AC23 (veri ile): Otağ'dan 4'lük hamle Doğu L1'i arındıramaz (4 ≤ 4), 6'lık arındırır.
func test_first_purification_trap_on_real_data() -> void:
	var m: MapState = _definition.create_map_state()
	var fail: MoveOutcome = MoveResolver.new().resolve(m, &"otuken", &"dogu_bozkir")
	assert_int(fail.branch).is_equal(MoveOutcome.Branch.PURIFICATION)
	assert_bool(fail.purified).is_false()
	m.get_region(&"otuken").army_count = 7
	var ok: MoveOutcome = MoveResolver.new().resolve(m, &"otuken", &"dogu_bozkir")
	assert_bool(ok.purified).is_true()
	assert_int(ok.target_army_after).is_equal(4)
	assert_int(ok.ruh_gain).is_equal(10)
