extends GdUnitTestSuite
## HUD modeli M2 (C-87; hud.md §5.1–§5.5, H1–H4, H8–H10; seviye `unit/ui/hud_presenter`): yayılım sayacı,
## "Odak tehlikede", düşman bölgesi sayacı, tek kırmızı uyarı önceliği, Kağan vuruş eşiği (AI ile aynı fonksiyon).


const S := RegionData.Owner


## Perde 1 benzeri: odak `koru` (L2), komşusu `kayin` (temiz, yayılım hedefi olur), düşman `otag` + `oba`, oyuncu `yurt`.
func _state(turn: int, last_spread: int, interval: int = 3) -> GameState:
	var state: GameState = GameState.new()
	var m: MapState = MapState.new()
	m.current_turn = turn
	m.last_erlik_spread_turn = last_spread
	m.erlik_spread_interval = interval
	for spec: Array in [[&"koru", S.NEUTRAL, 0, 2], [&"kayin", S.NEUTRAL, 0, 0], [&"otag", S.ENEMY, 4, 0],
			[&"oba", S.ENEMY, 3, 0], [&"yurt", S.PLAYER, 5, 0]]:
		var r: RegionData = RegionData.new()
		r.region_id = spec[0]
		r.owner = spec[1]
		r.army_count = spec[2]
		r.corruption_level = spec[3]
		m.regions[r.region_id] = r
	m.get_region(&"koru").adjacent_regions.assign([&"kayin"])
	m.get_region(&"kayin").adjacent_regions.assign([&"koru"])
	m.enemy_region_ids_initial.assign([&"otag", &"oba"])
	state.map_state = m
	return state


func _win(foci: Array[StringName], threshold: int = 9) -> WinCondition:
	var win: WinCondition = WinCondition.new()
	win.erlik_foci = foci
	win.erlik_loss_threshold = threshold
	win.must_defeat_all_enemies = true
	return win


func _build(state: GameState, win: WinCondition, modifiers: Array[StatModifier] = []) -> HudModel:
	var spirit: SpiritController = SpiritController.new()
	spirit.bind_services(state)
	return HudPresenter.build(state, ResourceController.new(), spirit, modifiers, win)


func _shield(stacks: int) -> Array[StatModifier]:
	var modifier: StatModifier = StatModifier.new()
	modifier.source_id = &"boon:gok_kalkani"
	modifier.stat_id = ErlikSpreadController.STAT_SPREAD_INTERVAL
	modifier.value = 1.0
	modifier.stacks = stacks
	return [modifier] as Array[StatModifier]


# H1: geri sayar, yayılım turunda 0; Gök Kalkanı I_eff'i uzatınca N uzar.
func test_hud_presenter_spread_counter_counts_down_and_zero_on_spread_turn() -> void:
	var win: WinCondition = _win([] as Array[StringName])
	var counts: Array[int] = []
	for turn: int in [1, 2, 3, 4]:
		counts.append(_build(_state(turn, 0), win).spread_turns_left)
	assert_array(counts).is_equal([2, 1, 0, 0])
	assert_int(_build(_state(2, 0), win, _shield(2)).spread_turns_left).is_equal(3)  # I_eff 5
	# Tur sonu yayılımı ile aynı kaynak: N = 0 ⇔ is_spread_turn.
	var state: GameState = _state(3, 0)
	var decision: ErlikSpreadController.SpreadDecision = ErlikSpreadController.new().decide(
		state.map_state, ErlikSpreadController.effective_interval(state.map_state, [] as Array[StatModifier]))
	assert_bool(decision.is_spread_turn).is_true()


# H1: arındırma sayacı sıfırlamaz (yalnız yayılım `last_erlik_spread_turn`'ü yazar).
func test_hud_presenter_spread_counter_unchanged_by_purification() -> void:
	var state: GameState = _state(2, 0)
	var before: int = _build(state, _win([] as Array[StringName])).spread_turns_left
	state.map_state.get_region(&"koru").corruption_level = 0
	assert_int(_build(state, _win([] as Array[StringName])).spread_turns_left).is_equal(before)


# H2: eşik 0 → sayaç ve Gölge gizli.
func test_hud_presenter_spread_hidden_without_threshold() -> void:
	var model: HudModel = _build(_state(3, 0), _win([] as Array[StringName], 0))
	assert_bool(model.spread_visible).is_false()
	assert_int(model.red_warning).is_not_equal(HudModel.Warning.SPREAD_NOW)


# H3: N = 0 ve hedef odak ⇒ true; N ≥ 1, hedef yok ya da odak değil ⇒ false.
func test_hud_presenter_focus_at_risk_rules() -> void:
	# kayin odak olarak işaretli (yayılım hedefi o).
	assert_bool(_build(_state(3, 0), _win([&"kayin"] as Array[StringName])).focus_at_risk).is_true()
	assert_bool(_build(_state(2, 0), _win([&"kayin"] as Array[StringName])).focus_at_risk).is_false()  # N = 1
	assert_bool(_build(_state(3, 0), _win([&"koru"] as Array[StringName])).focus_at_risk).is_false()  # hedef odak değil
	var no_target: GameState = _state(3, 0)
	no_target.map_state.get_region(&"koru").corruption_level = 0  # bozuk bölge yok → hedef yok
	var model: HudModel = _build(no_target, _win([&"kayin"] as Array[StringName]))
	assert_str(String(model.spread_target_id)).is_empty()
	assert_bool(model.focus_at_risk).is_false()


# H8 + H10: tek kırmızı uyarı; öncelik Erlik kaybı > Odak tehlikede > Yayılım N = 0; oyun bitince yok.
func test_hud_presenter_single_red_warning_priority() -> void:
	assert_int(_build(_state(3, 0), _win([] as Array[StringName])).red_warning).is_equal(HudModel.Warning.SPREAD_NOW)
	var focus: HudModel = _build(_state(3, 0), _win([&"kayin"] as Array[StringName]))
	assert_int(focus.red_warning).is_equal(HudModel.Warning.FOCUS_AT_RISK)  # Yayılım segmentinin yerini alır
	var loss: HudModel = _build(_state(3, 0), _win([&"kayin"] as Array[StringName], 3))  # güç 2 = eşik − 1
	assert_bool(loss.erlik_warning).is_true()
	assert_int(loss.red_warning).is_equal(HudModel.Warning.ERLIK_LOSS)
	assert_int(_build(_state(1, 0), _win([] as Array[StringName])).red_warning).is_equal(HudModel.Warning.NONE)
	var over: GameState = _state(3, 0)
	over.map_state.game_result = MapState.GameResult.LOST
	assert_int(_build(over, _win([&"kayin"] as Array[StringName], 3)).red_warning).is_equal(HudModel.Warning.NONE)


# H9: payda sahne başı düşman bölgesi; alınınca pay artar, geri kaybedilince azalır, payda sabit.
func test_hud_presenter_enemy_region_counter() -> void:
	var state: GameState = _state(1, 0)
	var win: WinCondition = _win([] as Array[StringName])
	var model: HudModel = _build(state, win)
	assert_bool(model.enemy_counter_visible).is_true()
	assert_array([model.enemy_regions_taken, model.enemy_regions_initial]).is_equal([0, 2])
	state.map_state.get_region(&"oba").owner = S.PLAYER
	model = _build(state, win)
	assert_array([model.enemy_regions_taken, model.enemy_regions_initial]).is_equal([1, 2])
	state.map_state.get_region(&"yurt").owner = S.ENEMY  # düşman yeni bölge aldı: payda değişmez
	state.map_state.get_region(&"oba").owner = S.ENEMY  # oba geri kaybedildi
	model = _build(state, win)
	assert_array([model.enemy_regions_taken, model.enemy_regions_initial]).is_equal([0, 2])
	win.must_defeat_all_enemies = false
	assert_bool(_build(state, win).enemy_counter_visible).is_false()


func test_hud_presenter_enemy_counter_hidden_without_enemies() -> void:
	var prolog: ChapterMapDefinition = load("res://features/grid/data/chapter_1_map.tres") as ChapterMapDefinition
	var state: GameState = GameState.new()
	state.map_state = prolog.create_map_state()
	assert_bool(_build(state, prolog.win_condition).enemy_counter_visible).is_false()


# H4: eşik değerleri ve AI F-E1 ile çapraz tutarlılık (aynı fonksiyon).
func test_strike_threshold_values_and_cross_check_with_ai() -> void:
	var expected: Dictionary = {0: 1, 2: 3, 3: 5, 5: 8, 4: 6, 1: 2}
	for p_eff: int in expected:
		assert_int(StrikeThreshold.min_force(p_eff, 3, 2)).override_failure_message("P_eff %d" % p_eff).is_equal(expected[p_eff])
	var profile: EnemyAIProfile = EnemyAIProfile.new()
	profile.strike_enabled = true
	var ai: EnemyAIController = EnemyAIController.new()
	ai.bind_config(profile)
	for p_eff: int in range(0, 15):
		var n: int = StrikeThreshold.min_force(p_eff, 3, 2)
		for attack: int in range(0, 25):
			var by_formula: bool = attack > p_eff and 2 * attack >= 3 * p_eff
			assert_bool(ai.strike_allowed(attack, p_eff)).is_equal(by_formula)
			assert_bool(attack >= n).is_equal(by_formula)
	# Lütuf P_eff'i artırınca N artar (Demir Post ×2: 4 → 6).
	var demir: StatModifier = StatModifier.new()
	demir.source_id = &"boon:demir_post"
	demir.stat_id = MoveResolver.STAT_ARMY_DEFENSE
	demir.value = 1.0
	demir.stacks = 2
	var boosted: int = EnemyAIController.effective_defense(4, [demir] as Array[StatModifier])
	assert_int(StrikeThreshold.min_force(boosted, 3, 2)).is_greater(StrikeThreshold.min_force(4, 3, 2))


# İçerik: sahne başı düşman listesi bölüm verisinden gelir, kaydedilmez.
func test_initial_enemy_regions_come_from_chapter_data() -> void:
	var definition: ChapterMapDefinition = ChapterMapDefinition.new()
	for spec: Array in [[&"otag", S.ENEMY], [&"yurt", S.PLAYER], [&"oba", S.ENEMY]]:
		var region: RegionDefinition = RegionDefinition.new()
		region.region_id = spec[0]
		region.owner = spec[1]
		region.starting_army = 2
		definition.regions.append(region)
	assert_array(definition.create_map_state().enemy_region_ids_initial).contains_exactly_in_any_order([&"otag", &"oba"])
