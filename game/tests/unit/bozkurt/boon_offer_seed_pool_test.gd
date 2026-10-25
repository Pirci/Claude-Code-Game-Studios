extends GdUnitTestSuite
## Lütuf sunumu: kampanya tohumu + sahne havuzu (C-78; spirit §3.5, §4.5, AC4, AC25, AC26, AC29;
## scene-flow §3.10 L10). Tohumlar testte enjekte edilir.


const CATALOG: BoonCatalog = preload("res://features/bozkurt/data/boon_catalog.tres")
const CAMPAIGN_PATH: String = "res://features/campaign/data/campaign.tres"
const PROLOG_TRIO: Array[StringName] = [&"arinma_ustaligi", &"bereket", &"gok_kalkani"]
const SEED_A: int = 1_000_003
const SEED_B: int = 1_000_004


## Tüm `requires` sistemleri etkin katalog kopyası — sahne havuzu, M2 lütufları açılsa da korumalı mı?
func _all_active_catalog() -> BoonCatalog:
	var catalog: BoonCatalog = CATALOG.duplicate() as BoonCatalog
	var systems: Array[StringName] = []
	for boon: BoonDefinition in catalog.boons:
		if boon.requires != &"" and boon.requires not in systems:
			systems.append(boon.requires)
	catalog.active_systems = systems
	return catalog


func _spirit(catalog: BoonCatalog, scene_pool: Array[StringName], seed_value: int, ruh: int = 10_000) -> SpiritController:
	var state: GameState = GameState.new()
	state.ruh = ruh
	state.campaign_seed = seed_value
	var modifiers: ModifierController = ModifierController.new()
	modifiers.bind_services(state)
	var spirit: SpiritController = SpiritController.new()
	spirit.bind_services(state)
	spirit.bind_boons(catalog, modifiers, scene_pool)
	return spirit


func _ids(boons: Array[BoonDefinition]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for boon: BoonDefinition in boons:
		ids.append(boon.boon_id)
	return ids


# AC4 + AC29: tohum 0 eski çıktıyı verir (örnek: scene 1, n 0 → Bereket, Gök Kalkanı, Arınma Ustalığı).
func test_boon_offer_seed_zero_matches_legacy_output() -> void:
	var pool: Array[BoonDefinition] = BoonRules.eligible_pool(CATALOG, null, PROLOG_TRIO)
	assert_array(_ids(BoonRules.offer(pool, 1, 0, 0))).is_equal([&"bereket", &"gok_kalkani", &"arinma_ustaligi"])
	for n: int in 6:
		assert_array(_ids(BoonRules.offer(pool, 1, n, 0))).is_equal(_ids(BoonRules.offer(pool, 1, n)))


# AC29: farklı tohum farklı sunum verebilir; aynı tohum her zaman aynı sunum.
func test_boon_offer_seed_changes_rotation_and_is_stable() -> void:
	var pool: Array[BoonDefinition] = BoonRules.eligible_pool(CATALOG, null, PROLOG_TRIO)
	assert_array(_ids(BoonRules.offer(pool, 1, 0, 1))).is_not_equal(_ids(BoonRules.offer(pool, 1, 0, 0)))
	assert_array(_ids(BoonRules.offer(pool, 1, 0, SEED_A))).is_equal(_ids(BoonRules.offer(pool, 1, 0, SEED_A)))
	# Büyük tohum taşmaz (31 bit).
	assert_int(BoonRules.offer(pool, 6, 9, SaveSerializer.MAX_SEED).size()).is_equal(BoonRules.OFFER_SIZE)


# AC29: SpiritController tohumu GameState'ten (kayıttan) okur.
func test_spirit_offer_uses_campaign_seed_from_state() -> void:
	var a: SpiritController = _spirit(CATALOG, PROLOG_TRIO, SEED_A)
	var a_again: SpiritController = _spirit(CATALOG, PROLOG_TRIO, SEED_A)
	var b: SpiritController = _spirit(CATALOG, PROLOG_TRIO, SEED_B)
	assert_array(_ids(a.current_offer(1))).is_equal(_ids(a_again.current_offer(1)))
	assert_array(_ids(a.current_offer(1))).is_not_equal(_ids(b.current_offer(1)))


# AC26: sahne havuzu doluyken yalnız listedekiler — tüm sistemler etkin olsa bile; boş liste tüm katalog.
func test_scene_pool_limits_offer_and_empty_pool_uses_catalog() -> void:
	var catalog: BoonCatalog = _all_active_catalog()
	for seed_value: int in [0, 1, 2, SEED_A]:
		for n: int in 6:
			var spirit: SpiritController = _spirit(catalog, PROLOG_TRIO, seed_value)
			for boon_id: StringName in _ids(BoonRules.offer(spirit.call("_pool"), 1, n, seed_value)):
				assert_bool(boon_id in PROLOG_TRIO).override_failure_message(String(boon_id)).is_true()
	var open: Array[BoonDefinition] = BoonRules.eligible_pool(catalog, null, [] as Array[StringName])
	assert_int(open.size()).is_equal(catalog.boons.size())
	assert_array(_ids(BoonRules.eligible_pool(catalog, null, PROLOG_TRIO))).is_equal(PROLOG_TRIO)


# L10: havuz kimlikleri katalogda, tekrarsız; doluysa süzülen havuz ≥ 3; Prolog tam M1 üçlüsü.
func test_campaign_scene_pools_pass_content_lint() -> void:
	var campaign: CampaignDefinition = load(CAMPAIGN_PATH) as CampaignDefinition
	for scene: SceneDefinition in campaign.scenes:
		var seen: Dictionary = {}
		for boon_id: StringName in scene.boon_pool_ids:
			assert_object(CATALOG.get_boon(boon_id)).override_failure_message("katalogda yok: %s" % boon_id).is_not_null()
			assert_bool(seen.has(boon_id)).override_failure_message("tekrar: %s" % boon_id).is_false()
			seen[boon_id] = true
		if not scene.boon_pool_ids.is_empty():
			assert_int(BoonRules.eligible_pool(CATALOG, null, scene.boon_pool_ids).size()).is_greater_equal(BoonRules.OFFER_SIZE)
	assert_array(campaign.scene(1).boon_pool_ids).is_equal(PROLOG_TRIO)


# AC25: Yeniden Dene aynı (chapter_id, n, havuz, tohum) → birebir aynı 3'lü (gerçek akış).
func test_retry_shows_same_offer() -> void:
	var store: MemorySaveStore = MemorySaveStore.new()
	var root_ctx: RootContext = auto_free((load("res://contexts/root_context/root_context.tscn") as PackedScene).instantiate()) as RootContext
	root_ctx.save_store = store
	var config: SceneFlowConfig = SceneFlowConfig.new()
	config.screen_input_guard_s = 0.0
	config.text_reveal_cps = 0.0
	root_ctx.flow_config = config
	root_ctx.campaign_seed_source = func() -> int: return SEED_A
	add_child(root_ctx)
	for button: String in ["NewCampaignButton", "SkipButton", "SkipButton", "StartButton"]:
		(root_ctx.find_child(button, true, false) as Button).pressed.emit()
	var first: Array[StringName] = _offer_after_gaining_spirit(root_ctx)
	var game: GameContext = root_ctx.find_child("GameContext", true, false) as GameContext
	var state: GameState = root_ctx.get("_game_state") as GameState
	state.map_state.game_result = MapState.GameResult.LOST
	state.map_state.loss_reason = MapState.LossReason.ERLIK
	(game.get("_map_controller") as MapController).game_lost.emit()
	(root_ctx.find_child("RetryButton", true, false) as Button).pressed.emit()
	(root_ctx.find_child("StartButton", true, false) as Button).pressed.emit()
	assert_array(_offer_after_gaining_spirit(root_ctx)).is_equal(first)


func _offer_after_gaining_spirit(root_ctx: RootContext) -> Array[StringName]:
	var game: GameContext = root_ctx.find_child("GameContext", true, false) as GameContext
	(root_ctx.get("_game_state") as GameState).ruh = 40
	return _ids((game.get("_spirit") as SpiritController).current_offer(1))
