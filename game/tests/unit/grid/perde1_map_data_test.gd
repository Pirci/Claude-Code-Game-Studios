extends GdUnitTestSuite
## Perde 1 harita verisi (C-89; seviye perde1 §3, §4, §6, §7.1; §13 `unit/grid/win_condition` adları).


const MAP_PATH: String = "res://features/grid/data/chapter_2_map.tres"
const S := RegionData.Owner


func _definition() -> ChapterMapDefinition:
	return load(MAP_PATH) as ChapterMapDefinition


func _state() -> MapState:
	return _definition().create_map_state()


func test_perde1_regions_owners_garrisons_and_economy() -> void:
	var m: MapState = _state()
	assert_int(m.regions.size()).is_equal(8)
	var expected: Dictionary = {
		&"orman_agzi": [S.PLAYER, 6, 2, 0], &"kayin_koruluk": [S.NEUTRAL, 2, 1, 0], &"kuzey_aksu": [S.NEUTRAL, 3, 2, 0],
		&"tahta_kopru": [S.NEUTRAL, 2, 1, 0], &"kurt_ini_ormani": [S.ENEMY, 2, 1, 1], &"curuk_koru": [S.NEUTRAL, 0, 2, 3],
		&"curcet_oba": [S.ENEMY, 4, 2, 0], &"curcet_otagi": [S.ENEMY, 4, 3, 0],
	}
	for region_id: StringName in expected:
		var r: RegionData = m.get_region(region_id)
		assert_object(r).override_failure_message(String(region_id)).is_not_null()
		assert_array([r.owner, r.army_count, r.gold_per_turn, r.corruption_level]).override_failure_message(
			String(region_id)).is_equal(expected[region_id])
	assert_int(WinCondition.erlik_power(m)).is_equal(4)  # §4.4 başlangıç
	assert_array(m.enemy_region_ids_initial).contains_exactly_in_any_order([&"kurt_ini_ormani", &"curcet_oba", &"curcet_otagi"])


func test_perde1_adjacency_is_nine_symmetric_edges() -> void:
	var m: MapState = _state()
	var edges: Dictionary = {}
	for r: RegionData in m.regions.values():
		for other: StringName in r.adjacent_regions:
			assert_bool(m.get_region(other).adjacent_regions.has(r.region_id)).override_failure_message(
				"tek yönlü: %s → %s" % [r.region_id, other]).is_true()
			var key: Array = [String(r.region_id), String(other)]
			key.sort()
			edges["%s|%s" % key] = true
	assert_int(edges.size()).is_equal(9)
	assert_bool(edges.has("curuk_koru|kurt_ini_ormani")).is_true()  # kiriş
	assert_bool(edges.has("curcet_oba|curcet_otagi")).is_true()


func test_perde1_chapter_settings() -> void:
	var d: ChapterMapDefinition = _definition()
	assert_int(d.chapter_id).is_equal(2)
	assert_int(d.starting_gold).is_equal(6)
	assert_int(d.erlik_spread_interval).is_equal(3)
	assert_int(d.actions_per_turn).is_equal(1)
	assert_int(d.enemy_actions_per_turn).is_equal(1)
	assert_int(d.enemy_reinforcement_per_turn).is_equal(1)
	assert_array(d.enemy_reinforcement_region_ids).is_equal([&"curcet_otagi"])
	assert_str(String(d.enemy_tamga_id)).is_equal("curcet")
	assert_str(d.ground_color.to_html(false)).is_equal("0f1a0d")
	assert_str(d.adjacency_line_color.to_html(false)).is_equal("5c8f5c")
	var p: EnemyAIProfile = d.enemy_ai_profile
	assert_array([p.attack_start_turn, p.strike_ratio_num, p.strike_ratio_den, p.strike_enabled]).is_equal([5, 3, 2, true])
	var w: WinCondition = d.win_condition
	assert_array([w.required_neutral_conquests, w.must_defeat_all_enemies, w.erlik_loss_threshold]).is_equal([2, true, 9])
	assert_array(w.erlik_foci).is_equal([&"curuk_koru"])
	assert_str(String(w.foci_label_key)).is_equal("OBJECTIVE_FOCI_CH2")  # C-91: "koru şifası", Prolog "in" değil
	assert_object(d.decor).is_not_null()


# UD (§4.4): çürük koruyu arındırmak için P ≥ 13 (S = 3 × 4 = 12; başarı P > S).
func test_perde1_rotting_grove_needs_thirteen() -> void:
	var rules: SpiritRules = SpiritRules.new()
	rules.bind_config(load("res://features/bozkurt/data/spirit_config.tres") as SpiritConfig)
	var s: int = rules.corruption_strength(_state().get_region(&"curuk_koru").corruption_level)
	assert_int(s).is_equal(12)
	assert_int(s + 1).is_equal(13)


func _won_state() -> MapState:
	var m: MapState = _state()
	for region_id: StringName in [&"kayin_koruluk", &"kuzey_aksu", &"kurt_ini_ormani", &"curcet_oba", &"curcet_otagi"]:
		m.get_region(region_id).owner = S.PLAYER
		m.get_region(region_id).army_count = 1
	m.get_region(&"curuk_koru").corruption_level = 0
	return m


func test_perde1_victory_requires_two_neutral_conquests_and_capital_cleared() -> void:
	var win: WinCondition = _definition().win_condition
	var m: MapState = _won_state()
	assert_bool(win.is_met(m)).is_true()
	m.get_region(&"kuzey_aksu").owner = S.NEUTRAL  # yalnız 1 nötr fetih
	assert_bool(win.is_met(m)).is_false()


func test_perde1_victory_not_met_with_two_conquests_and_enemy_alive() -> void:
	var m: MapState = _won_state()
	m.get_region(&"curcet_otagi").owner = S.ENEMY  # başkent hâlâ düşmanda
	assert_bool(_definition().win_condition.is_met(m)).is_false()


func test_perde1_victory_not_met_when_focus_corrupted() -> void:
	var m: MapState = _won_state()
	m.get_region(&"curuk_koru").corruption_level = 1
	assert_bool(_definition().win_condition.is_met(m)).is_false()


func test_perde1_erlik_threshold_nine_is_loss_at_nine_not_eight() -> void:
	var win: WinCondition = _definition().win_condition
	var m: MapState = _state()  # güç 4
	m.get_region(&"kayin_koruluk").corruption_level = 3
	m.get_region(&"tahta_kopru").corruption_level = 1  # 8
	assert_int(WinCondition.erlik_power(m)).is_equal(8)
	assert_int(win.loss_reason(m)).is_equal(MapState.LossReason.NONE)
	m.get_region(&"kuzey_aksu").corruption_level = 1  # 9
	assert_int(win.loss_reason(m)).is_equal(MapState.LossReason.ERLIK)
