extends GdUnitTestSuite
## Kök Böri lütuf kuralları — spirit-system.md §3.4–3.5, §4.4–4.5 (C-39).


const CATALOG: BoonCatalog = preload("res://features/bozkurt/data/boon_catalog.tres")
const PROLOG_POOL: Array[StringName] = [&"arinma_ustaligi", &"bereket", &"gok_kalkani"]


func _setup(ruh: int = 0) -> Array:
	var state: GameState = GameState.new()
	state.ruh = ruh
	var modifiers: ModifierController = ModifierController.new()
	modifiers.bind_services(state)
	var spirit: SpiritController = SpiritController.new()
	spirit.bind_services(state)
	# Prolog sahne havuzu (M1 üçlüsü): etkin güç açıkken (C-80) bu testler Prolog sunumunu modeller.
	spirit.bind_boons(CATALOG, modifiers, PROLOG_POOL)
	return [state, modifiers, spirit]


func _ids(boons: Array[BoonDefinition]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for boon: BoonDefinition in boons:
		ids.append(boon.boon_id)
	return ids


# §4.4: 0→30, 1→50, 2→70, 3→90.
func test_boon_cost_grows_linearly() -> void:
	var config: SpiritConfig = load("res://features/bozkurt/data/spirit_config.tres") as SpiritConfig
	assert_array([0, 1, 2, 3].map(func(n: int) -> int: return BoonRules.boon_cost(n, config))).is_equal([30, 50, 70, 90])


# AC4 + AC18 (M2'de AC26 ile güncellendi, C-80): etkin güç açık — katalog havuzu Kurt Gücü / Demir Post'u
# içerir, sistemi kapalı lütuflar (sürü, yiğitler) dışarıda; Prolog sahne havuzu M1 üçlüsü ve eski sunum.
func test_m1_offer_is_deterministic_and_excludes_locked_boons() -> void:
	var modifiers: ModifierController = _setup()[1]
	assert_array(_ids(BoonRules.eligible_pool(CATALOG, modifiers))).is_equal(
		[&"arinma_ustaligi", &"bereket", &"demir_post", &"gok_kalkani", &"kurt_gucu"])
	var prolog: Array[StringName] = [&"arinma_ustaligi", &"bereket", &"gok_kalkani"]
	var pool: Array[BoonDefinition] = BoonRules.eligible_pool(CATALOG, modifiers, prolog)
	assert_array(_ids(pool)).is_equal(prolog)
	var offer: Array[BoonDefinition] = BoonRules.offer(pool, 1, 0)
	assert_array(_ids(offer)).is_equal([&"bereket", &"gok_kalkani", &"arinma_ustaligi"])
	assert_array(_ids(BoonRules.offer(pool, 1, 0))).is_equal(_ids(offer))


# §5: havuz 3'ten küçükse slotlar tekrar eder; boşsa sunum yok.
func test_small_pool_repeats_and_empty_pool_offers_nothing() -> void:
	var pool: Array[BoonDefinition] = [CATALOG.get_boon(&"bereket")]
	assert_array(_ids(BoonRules.offer(pool, 1, 0))).is_equal([&"bereket", &"bereket", &"bereket"])
	assert_array(BoonRules.offer([] as Array[BoonDefinition], 1, 0)).is_empty()


# AC3 (koşul): eşik `ruh ≥ boon_cost(n)`.
func test_offer_pending_only_at_threshold() -> void:
	var low: Array = _setup(29)
	assert_bool((low[2] as SpiritController).is_offer_pending()).is_false()
	var spirit: SpiritController = _setup(30)[2]
	assert_bool(spirit.is_offer_pending()).is_true()
	assert_int(spirit.current_offer(1).size()).is_equal(3)


# AC5: maliyet düşer, seçilmeyenler kaybolur, sunumda olmayan kart reddedilir.
func test_pick_deducts_cost_and_records_choice() -> void:
	var setup: Array = _setup(45)
	var state: GameState = setup[0]
	var spirit: SpiritController = setup[2]
	assert_bool(spirit.pick_boon(1, &"kurt_gucu")).is_false()
	assert_bool(spirit.pick_boon(1, &"bereket")).is_true()
	assert_int(state.ruh).is_equal(15)
	assert_array(state.boons).is_equal([&"bereket"])
	assert_bool(spirit.is_offer_pending()).is_false()
	assert_bool(spirit.pick_boon(1, &"bereket")).is_false()


# AC17: Bereket sonraki ekonomi adımında geliri tam +1 artırır (I_raw 5 → 6).
func test_bereket_adds_one_gold_to_turn_income() -> void:
	var setup: Array = _setup(30)
	var modifiers: ModifierController = setup[1]
	(setup[2] as SpiritController).pick_boon(1, &"bereket")
	var config: EconomyConfig = EconomyConfig.new()
	assert_int(IncomeRules.turn_income(5, true, modifiers.get_modifiers(), config)).is_equal(6)


# AC2: Arınma Ustalığı ile seviye 2 arındırma 24 Ruh.
func test_arinma_ustaligi_raises_ruh_gain() -> void:
	var setup: Array = _setup(30)
	var modifiers: ModifierController = setup[1]
	(setup[2] as SpiritController).pick_boon(1, &"arinma_ustaligi")
	assert_int(SpiritRules.new().ruh_gain(2, modifiers.get_modifiers())).is_equal(24)


# AC9: Gök Kalkanı 1 yığın → aralık 4, 3 yığın → 6; sonra havuzdan çıkar.
func test_gok_kalkani_stacks_to_cap_then_leaves_pool() -> void:
	var setup: Array = _setup()
	var state: GameState = setup[0]
	var modifiers: ModifierController = setup[1]
	var shield: ModifierSource = CATALOG.get_boon(&"gok_kalkani").modifier_source
	assert_bool(modifiers.add_source(shield)).is_true()
	assert_int(roundi(StatResolver.resolve(&"erlik_spread_interval", 3.0, state.modifiers))).is_equal(4)
	modifiers.add_source(shield)
	modifiers.add_source(shield)
	assert_int(roundi(StatResolver.resolve(&"erlik_spread_interval", 3.0, state.modifiers))).is_equal(6)
	assert_array(_ids(BoonRules.eligible_pool(CATALOG, modifiers))).not_contains([&"gok_kalkani"])


# AC19: kayıttaki `ruh` + `boons`'tan aynı sunum ve aynı kayıtlar yeniden kurulur.
func test_offer_and_modifiers_rebuild_from_saved_choices() -> void:
	var setup: Array = _setup(130)
	var spirit: SpiritController = setup[2]
	spirit.pick_boon(1, &"bereket")
	var before: Array[StringName] = _ids(spirit.current_offer(1))
	var loaded: LoadResult = SaveSerializer.from_text(SaveSerializer.to_text(setup[0]), Callable())
	assert_int(loaded.code).is_equal(LoadResult.Code.OK)
	var restored: GameState = loaded.state
	var modifiers: ModifierController = ModifierController.new()
	modifiers.bind_services(restored)
	var spirit2: SpiritController = SpiritController.new()
	spirit2.bind_services(restored)
	spirit2.bind_boons(CATALOG, modifiers, PROLOG_POOL)
	spirit2.rebuild_boon_modifiers()
	assert_int(restored.ruh).is_equal(100)
	assert_array(_ids(spirit2.current_offer(1))).is_equal(before)
	assert_float(StatResolver.resolve(&"gold_income", 0.0, restored.modifiers)).is_equal(1.0)


# Kart metni: yüzde lütfu büyüklüğü ×100 gösterir.
func test_display_amount_formats_percent_and_flat() -> void:
	assert_int(CATALOG.get_boon(&"arinma_ustaligi").display_amount()).is_equal(20)
	assert_int(CATALOG.get_boon(&"bereket").display_amount()).is_equal(1)
