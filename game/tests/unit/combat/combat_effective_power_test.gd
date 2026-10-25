extends GdUnitTestSuite
## Etkin güç (C-79; combat-system.md §4 "Etkin güç", AC7–AC8; spirit §3.2 `P_eff`): Kurt Gücü
## `army_attack`, Demir Post `army_defense`; yalnız oyuncu tarafı, `ceil`; düşman `A_eff = A`.


const COMBAT_CONFIG: String = "res://features/combat/data/combat_config.tres"


func _combat() -> CombatResolver:
	var combat: CombatResolver = CombatResolver.new()
	combat.bind_config(load(COMBAT_CONFIG) as CombatConfig)
	return combat


func _mod(stat_id: StringName, value: float, kind: StatModifier.Kind = StatModifier.Kind.FLAT, stacks: int = 1) -> StatModifier:
	var modifier: StatModifier = StatModifier.new()
	modifier.source_id = &"boon:test"
	modifier.stat_id = stat_id
	modifier.kind = kind
	modifier.value = value
	modifier.stacks = stacks
	return modifier


func _kurt_gucu(stacks: int = 1) -> Array[StatModifier]:
	return [_mod(MoveResolver.STAT_ARMY_ATTACK, 1.0, StatModifier.Kind.FLAT, stacks)] as Array[StatModifier]


func _demir_post(stacks: int = 1) -> Array[StatModifier]:
	return [_mod(MoveResolver.STAT_ARMY_DEFENSE, 1.0, StatModifier.Kind.FLAT, stacks)] as Array[StatModifier]


func _fields(r: CombatResolver.CombatResult) -> Array:
	return [r.attacker_won, r.attacker_losses, r.defender_losses, r.attacker_remaining, r.defender_remaining]


## İki bölgelik harita: kaynak `a` (sahip, ordu) → hedef `b` (sahip, ordu, bozulma).
func _map(a_owner: RegionData.Owner, a_army: int, b_owner: RegionData.Owner, b_army: int, b_corruption: int = 0) -> MapState:
	var m: MapState = MapState.new()
	m.actions_remaining = 1
	for spec: Array in [[&"a", a_owner, a_army, 0], [&"b", b_owner, b_army, b_corruption]]:
		var r: RegionData = RegionData.new()
		r.region_id = spec[0]
		r.owner = spec[1]
		r.army_count = spec[2]
		r.corruption_level = spec[3]
		m.regions[r.region_id] = r
	m.get_region(&"a").adjacent_regions.assign([&"b"])
	m.get_region(&"b").adjacent_regions.assign([&"a"])
	return m


func _resolver() -> MoveResolver:
	var resolver: MoveResolver = MoveResolver.new()
	resolver.bind_services(_combat())
	return resolver


# AC7: modifikatör yokken etkin güç yolu AC1–3 (ve geniş tablo) sonuçlarını değiştirmez.
func test_effective_power_without_modifiers_matches_plain_resolve() -> void:
	var combat: CombatResolver = _combat()
	for a: int in range(1, 13):
		for d: int in range(1, 13):
			assert_array(_fields(combat.resolve_effective(a, d, a, d))).is_equal(_fields(combat.resolve(a, d)))
	assert_array(_fields(combat.resolve(5, 3))).is_equal([true, 2, 3, 3, 0])
	assert_array(_fields(combat.resolve(3, 6))).is_equal([false, 3, 1, 0, 5])
	assert_array(_fields(combat.resolve(4, 4))).is_equal([false, 3, 2, 1, 2])


# AC8a: Kurt Gücü 1 yığın, A=4, D=4 → A_eff 5 > 4 → Dal 1, kayıp ceil(4 × 0,5) = 2.
func test_effective_power_kurt_gucu_turns_draw_into_win() -> void:
	var outcome: MoveOutcome = _resolver().resolve(_map(RegionData.Owner.PLAYER, 5, RegionData.Owner.ENEMY, 4),
		&"a", &"b", RegionData.Owner.PLAYER, _kurt_gucu())
	assert_int(outcome.combat.attacker_effective).is_equal(5)
	assert_array(_fields(outcome.combat)).is_equal([true, 2, 4, 2, 0])
	assert_int(outcome.target_owner_after).is_equal(RegionData.Owner.PLAYER)
	assert_int(outcome.target_army_after).is_equal(2)


# AC8b: Demir Post 1 yığın, oyuncu savunur, A=4, D=4 → D_eff 5, savunan kazanır; defender_losses = ceil(4 × 0,3) = 2.
func test_effective_power_demir_post_holds_enemy_attack() -> void:
	var outcome: MoveOutcome = _resolver().resolve(_map(RegionData.Owner.ENEMY, 5, RegionData.Owner.PLAYER, 4),
		&"a", &"b", RegionData.Owner.ENEMY, _demir_post())
	assert_int(outcome.combat.attacker_effective).is_equal(4)  # düşman A_eff = A (lütuf almaz)
	assert_int(outcome.combat.defender_effective).is_equal(5)
	assert_array(_fields(outcome.combat)).is_equal([false, 4, 2, 0, 2])
	assert_int(outcome.target_owner_after).is_equal(RegionData.Owner.PLAYER)


# Lütuflar yalnız oyuncu tarafına: düşman saldırırken Kurt Gücü, oyuncu saldırırken Demir Post etkisiz.
func test_effective_power_applies_only_to_player_side() -> void:
	var enemy_attack: MoveOutcome = _resolver().resolve(_map(RegionData.Owner.ENEMY, 5, RegionData.Owner.PLAYER, 4),
		&"a", &"b", RegionData.Owner.ENEMY, _kurt_gucu(3))
	assert_int(enemy_attack.combat.attacker_effective).is_equal(4)
	assert_int(enemy_attack.combat.defender_effective).is_equal(4)
	var player_attack: MoveOutcome = _resolver().resolve(_map(RegionData.Owner.PLAYER, 5, RegionData.Owner.ENEMY, 4),
		&"a", &"b", RegionData.Owner.PLAYER, _demir_post(3))
	assert_int(player_attack.combat.attacker_effective).is_equal(4)
	assert_int(player_attack.combat.defender_effective).is_equal(4)  # düşman savunması lütufsuz


# Arındırma: A = P_eff, S savunma modifikatörü almaz; P == S lütufsuz başarısız, Kurt Gücü ile başarılı.
func test_effective_power_purification_uses_p_eff() -> void:
	var resolver: MoveResolver = _resolver()
	var s: int = SpiritRules.new().corruption_strength(2)
	var map: MapState = _map(RegionData.Owner.PLAYER, s + 1, RegionData.Owner.NEUTRAL, 0, 2)
	var plain: MoveOutcome = resolver.resolve(map, &"a", &"b", RegionData.Owner.PLAYER, [] as Array[StatModifier])
	assert_bool(plain.purified).is_false()  # P == S → başarısız (eşitlik dahil)
	var boosted: Array[StatModifier] = _kurt_gucu()
	boosted.append(_mod(MoveResolver.STAT_ARMY_DEFENSE, 5.0))  # S'ye işlemez
	var with_boon: MoveOutcome = resolver.resolve(map, &"a", &"b", RegionData.Owner.PLAYER, boosted)
	assert_bool(with_boon.purified).is_true()
	assert_int(with_boon.combat.defender_effective).is_equal(s)
	assert_int(with_boon.combat.attacker_losses).is_equal(ceili(s * 0.5))  # kayıp gerçek birlikten
	assert_int(with_boon.target_army_after).is_equal(s - ceili(s * 0.5))


# ceil + kayan nokta: tam sayının hemen üstüne düşen artık (ör. yığınlı yüzde toplamı) tavanı bir üste
# taşımaz; gerçek kesir yukarı yuvarlanır (4 × 1,2 = 4,8 → 5).
func test_effective_power_ceil_ignores_float_residue() -> void:
	var residue: Array[StatModifier] = [_mod(MoveResolver.STAT_ARMY_ATTACK, 1.0 + 1e-12)] as Array[StatModifier]
	assert_int(MoveResolver.effective_power(MoveResolver.STAT_ARMY_ATTACK, 4, residue)).is_equal(5)
	var percent: Array[StatModifier] = [_mod(MoveResolver.STAT_ARMY_ATTACK, 0.2, StatModifier.Kind.PERCENT)] as Array[StatModifier]
	assert_int(MoveResolver.effective_power(MoveResolver.STAT_ARMY_ATTACK, 4, percent)).is_equal(5)
	assert_int(MoveResolver.effective_power(MoveResolver.STAT_ARMY_ATTACK, 4, [] as Array[StatModifier])).is_equal(4)


# Önizleme = uygulama: MapController düşman hamlesine de lütufları geçirir (Demir Post savunması tutar).
func test_effective_power_enemy_turn_uses_player_modifiers() -> void:
	var state: GameState = GameState.new()
	state.map_state = _map(RegionData.Owner.ENEMY, 5, RegionData.Owner.PLAYER, 4)
	state.map_state.enemy_actions_per_turn = 1
	state.boons.assign([&"demir_post"])
	var catalog: BoonCatalog = (load("res://features/bozkurt/data/boon_catalog.tres") as BoonCatalog).duplicate() as BoonCatalog
	catalog.active_systems = [&"effective_power"] as Array[StringName]
	var modifiers: ModifierController = ModifierController.new()
	modifiers.bind_services(state)
	modifiers.rebuild(catalog.sources_for(state.boons))
	var map: MapController = MapController.new()
	map.bind_services(state.map_state, state, ArmyController.new(), null, _combat(), null, EnemyAIController.new(), _resolver())
	map.bind_erlik_layer(null, null, modifiers)
	var outcomes: Array[MoveOutcome] = []
	map.combat_occurred.connect(func(o: MoveOutcome) -> void: outcomes.append(o))
	map.call("_run_enemy_ai")
	assert_int(outcomes.size()).is_equal(1)
	assert_int(outcomes[0].combat.defender_effective).is_equal(5)
	assert_int(state.map_state.get_region(&"b").owner).is_equal(RegionData.Owner.PLAYER)
	assert_int(state.map_state.get_region(&"b").army_count).is_equal(2)
