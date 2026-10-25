extends GdUnitTestSuite
## Düşman AI R1 karşı vuruş + EnemyAIProfile (C-82; enemy-layers.md §3.2–3.4, F-E1, F-E2, AC1–AC10,
## AC19, AC20; ADR-0005 ekleri). Test adları seviye belgesi §13'ten (`test_counterattack_*`).


const S := RegionData.Owner


## Perde 1 profili: tur 5, oran 3/2, R1 açık.
func _perde1_ai() -> EnemyAIController:
	var profile: EnemyAIProfile = EnemyAIProfile.new()
	profile.attack_start_turn = 5
	profile.strike_ratio_num = 3
	profile.strike_ratio_den = 2
	profile.strike_enabled = true
	var ai: EnemyAIController = EnemyAIController.new()
	ai.bind_config(profile)
	return ai


## [param specs]: [id, owner, army, corruption]; [param links]: [[a, b], …] (iki yönlü komşuluk).
func _map(specs: Array, links: Array, turn: int = 5) -> MapState:
	var m: MapState = MapState.new()
	m.current_turn = turn
	for spec: Array in specs:
		var r: RegionData = RegionData.new()
		r.region_id = spec[0]
		r.owner = spec[1]
		r.army_count = spec[2]
		r.corruption_level = spec[3] if spec.size() > 3 else 0
		m.regions[r.region_id] = r
	for link: Array in links:
		m.get_region(link[0]).adjacent_regions.append(link[1])
		m.get_region(link[1]).adjacent_regions.append(link[0])
	return m


func _demir_post(stacks: int) -> Array[StatModifier]:
	var modifier: StatModifier = StatModifier.new()
	modifier.source_id = &"boon:demir_post"
	modifier.stat_id = MoveResolver.STAT_ARMY_DEFENSE
	modifier.value = 1.0
	modifier.stacks = stacks
	return [modifier] as Array[StatModifier]


func _pair(e_army: int, p_army: int, turn: int = 5) -> MapState:
	return _map([[&"e", S.ENEMY, e_army], [&"p", S.PLAYER, p_army]], [[&"e", &"p"]], turn)


func _intent_str(intent: EnemyAIController.MoveIntent) -> String:
	return "null" if intent == null else "%s>%s:%s" % [intent.from_id, intent.to_id, intent.reason]


# AC1
func test_counterattack_before_turn_five_never_strikes() -> void:
	assert_object(_perde1_ai().decide(_pair(8, 4, 4), [] as Array[StringName])).is_null()


# AC2
func test_counterattack_at_turn_five_strikes_when_ratio_met() -> void:
	assert_str(_intent_str(_perde1_ai().decide(_pair(8, 4), [] as Array[StringName]))).is_equal("e>p:strike")


# AC3 (2A = 3P sınırda vurur)
func test_counterattack_ratio_exactly_one_and_half_strikes() -> void:
	assert_str(_intent_str(_perde1_ai().decide(_pair(7, 4), [] as Array[StringName]))).is_equal("e>p:strike")


# AC3 (2A < 3P)
func test_counterattack_ratio_just_below_threshold_holds() -> void:
	assert_object(_perde1_ai().decide(_pair(6, 4), [] as Array[StringName])).is_null()


# AC4: oran 1/1'e düşse bile A ≤ P_eff vurmaz.
func test_counterattack_requires_attacker_greater_than_defender() -> void:
	var profile: EnemyAIProfile = EnemyAIProfile.new()
	profile.strike_enabled = true
	profile.strike_ratio_num = 1
	profile.strike_ratio_den = 1
	var ai: EnemyAIController = EnemyAIController.new()
	ai.bind_config(profile)
	assert_object(ai.decide(_pair(5, 4), [] as Array[StringName])).is_null()  # A = 4 = P
	assert_object(ai.decide(_pair(6, 4), [] as Array[StringName])).is_not_null()  # A = 5 > P


# AC5 (F-E2): iki oyuncu komşusu ve A ≥ 2 → tutar; A = 1 iken tutma yok (ama F-E1 yine engelleyebilir).
func test_counterattack_holds_when_source_defends_other_player_neighbor() -> void:
	var two_fronts: MapState = _map([[&"e", S.ENEMY, 9], [&"p1", S.PLAYER, 1], [&"p2", S.PLAYER, 5]],
		[[&"e", &"p1"], [&"e", &"p2"]])
	assert_object(_perde1_ai().decide(two_fronts, [] as Array[StringName])).is_null()
	# Aynı zayıf hedef, ikinci cephe yokken vurulur.
	var one_front: MapState = _map([[&"e", S.ENEMY, 9], [&"p1", S.PLAYER, 1]], [[&"e", &"p1"]])
	assert_str(_intent_str(_perde1_ai().decide(one_front, [] as Array[StringName]))).is_equal("e>p1:strike")
	# A = 1: tutma kuralı uygulanmaz (yalnız F-E1 karar verir — P = 0 boş hedef ulaşılamaz, burada vuramaz).
	var weak: MapState = _map([[&"e", S.ENEMY, 2], [&"p1", S.PLAYER, 1], [&"p2", S.PLAYER, 1]],
		[[&"e", &"p1"], [&"e", &"p2"]])
	assert_object(_perde1_ai().decide(weak, [] as Array[StringName])).is_null()


# AC6: yalnız nötr komşular (çürük koru dahil) → bekler.
func test_counterattack_never_enters_neutral_region() -> void:
	var m: MapState = _map([[&"e", S.ENEMY, 12], [&"n", S.NEUTRAL, 0], [&"koru", S.NEUTRAL, 0, 3]],
		[[&"e", &"n"], [&"e", &"koru"]])
	assert_object(_perde1_ai().decide(m, [] as Array[StringName])).is_null()


# AC7
func test_counterattack_ignores_corruption_level() -> void:
	var clean: MapState = _map([[&"e", S.ENEMY, 8], [&"a", S.PLAYER, 4, 0], [&"n", S.NEUTRAL, 0, 0]],
		[[&"e", &"a"], [&"e", &"n"]])
	var corrupt: MapState = _map([[&"e", S.ENEMY, 8], [&"a", S.PLAYER, 4, 3], [&"n", S.NEUTRAL, 0, 3]],
		[[&"e", &"a"], [&"e", &"n"]])
	var ai: EnemyAIController = _perde1_ai()
	assert_str(_intent_str(ai.decide(corrupt, [] as Array[StringName]))).is_equal(
		_intent_str(ai.decide(clean, [] as Array[StringName])))


# AC8: en küçük P_eff → en büyük A → alfabetik from → alfabetik to (küresel).
func test_counterattack_weakest_target_largest_attacker_alphabetical_ties() -> void:
	var ai: EnemyAIController = _perde1_ai()
	# Zayıf hedef kazanır (z_e'nin hedefi P_eff 2, a_e'ninki 3 — kimlik sırası değil P_eff).
	var weakest: MapState = _map([[&"a_e", S.ENEMY, 9], [&"z_e", S.ENEMY, 5], [&"p3", S.PLAYER, 3], [&"p2", S.PLAYER, 2]],
		[[&"a_e", &"p3"], [&"z_e", &"p2"]])
	assert_str(_intent_str(ai.decide(weakest, [] as Array[StringName]))).is_equal("z_e>p2:strike")
	# Eşit P_eff: büyük A kazanır.
	var largest: MapState = _map([[&"a_e", S.ENEMY, 5], [&"z_e", S.ENEMY, 9], [&"p", S.PLAYER, 2], [&"q", S.PLAYER, 2]],
		[[&"a_e", &"p"], [&"z_e", &"q"]])
	assert_str(_intent_str(ai.decide(largest, [] as Array[StringName]))).is_equal("z_e>q:strike")
	# Eşit P_eff ve A: alfabetik from, sonra alfabetik to.
	var ties: MapState = _map([[&"b_e", S.ENEMY, 6], [&"a_e", S.ENEMY, 6], [&"y", S.PLAYER, 2], [&"x", S.PLAYER, 2]],
		[[&"b_e", &"x"], [&"a_e", &"y"]])
	assert_str(_intent_str(ai.decide(ties, [] as Array[StringName]))).is_equal("a_e>y:strike")
	# P_eff ile sıralama (AC19 notu): Demir Post ×2 → p2 P_eff 4 (z_e A = 4 vuramaz), p3 P_eff 5 (a_e A = 8 vurur).
	assert_str(_intent_str(ai.decide(weakest, [] as Array[StringName], _demir_post(2)))).is_equal("a_e>p3:strike")


# AC9
func test_counterattack_is_deterministic_across_runs() -> void:
	var m: MapState = _map([[&"b_e", S.ENEMY, 6], [&"a_e", S.ENEMY, 6], [&"y", S.PLAYER, 2], [&"x", S.PLAYER, 2]],
		[[&"b_e", &"x"], [&"a_e", &"y"]])
	var ai: EnemyAIController = _perde1_ai()
	var first: String = _intent_str(ai.decide(m, [] as Array[StringName]))
	for i: int in 100:
		assert_str(_intent_str(ai.decide(m, [] as Array[StringName]))).is_equal(first)


# AC19: etkin savunma okunur; boş hedefte modifikatör yok sayılır (P_eff = 0).
func test_counterattack_reads_effective_defense_from_modifiers() -> void:
	var ai: EnemyAIController = _perde1_ai()
	assert_object(ai.decide(_pair(8, 4), [] as Array[StringName], _demir_post(2))).is_null()  # 14 < 18
	assert_str(_intent_str(ai.decide(_pair(8, 4), [] as Array[StringName]))).is_equal("e>p:strike")


func test_counterattack_empty_target_ignores_modifiers() -> void:
	assert_int(EnemyAIController.effective_defense(0, _demir_post(3))).is_equal(0)
	assert_int(EnemyAIController.effective_defense(4, _demir_post(2))).is_equal(6)


# AC20: girdiler değişmez.
func test_counterattack_does_not_mutate_inputs() -> void:
	var m: MapState = _pair(8, 4)
	var mods: Array[StatModifier] = _demir_post(1)
	var acted: Array[StringName] = []
	var before: String = SaveSerializer.to_text(_state(m))
	_perde1_ai().decide(m, acted, mods)
	assert_str(SaveSerializer.to_text(_state(m))).is_equal(before)
	assert_int(mods.size()).is_equal(1)
	assert_int(mods[0].stacks).is_equal(1)
	assert_array(acted).is_empty()


func _state(m: MapState) -> GameState:
	var s: GameState = GameState.new()
	s.map_state = m
	return s


# acted: aynı tur hamle yapmış kaynak yeniden vurmaz.
func test_counterattack_skips_acted_sources() -> void:
	assert_object(_perde1_ai().decide(_pair(8, 4), [&"e"] as Array[StringName])).is_null()


# AC10: varsayılan profil (ve profilsiz) eski "en düşük ordulu düşman-olmayan komşu" davranışı; nötre girer, reason boş.
func test_counterattack_default_profile_keeps_legacy_behaviour() -> void:
	var m: MapState = _map([[&"e", S.ENEMY, 3], [&"p", S.PLAYER, 5], [&"n", S.NEUTRAL, 0]], [[&"e", &"p"], [&"e", &"n"]], 1)
	for ai: EnemyAIController in [EnemyAIController.new(), _with_default_profile()]:
		assert_str(_intent_str(ai.decide(m, [] as Array[StringName], _demir_post(3)))).is_equal("e>n:")


func _with_default_profile() -> EnemyAIController:
	var ai: EnemyAIController = EnemyAIController.new()
	ai.bind_config(null)
	return ai
