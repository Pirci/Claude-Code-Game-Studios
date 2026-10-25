extends GdUnitTestSuite
## Kurt Gücü / Demir Post etkinleştirme (C-80; spirit §3.5, AC26–AC28; cross-review D2): katalog
## `active_systems += effective_power`, ikisi de en çok 3 yığın; sınırdan sonra havuz dışı; eski kayıtta
## `rebuild()` sınır kadar kurar, `n = boons.size()` değişmez. Prolog havuzu korumalı kalır.


const CATALOG: BoonCatalog = preload("res://features/bozkurt/data/boon_catalog.tres")
const CAMPAIGN_PATH: String = "res://features/campaign/data/campaign.tres"
const CAPPED: Array[StringName] = [&"kurt_gucu", &"demir_post"]
const STAT_FOR: Dictionary = {&"kurt_gucu": &"army_attack", &"demir_post": &"army_defense"}


func _ids(boons: Array[BoonDefinition]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for boon: BoonDefinition in boons:
		ids.append(boon.boon_id)
	return ids


func _controllers() -> Array:
	var state: GameState = GameState.new()
	var modifiers: ModifierController = ModifierController.new()
	modifiers.bind_services(state)
	return [state, modifiers]


func test_boon_stack_caps_catalog_enables_effective_power_with_cap_three() -> void:
	assert_bool(&"effective_power" in CATALOG.active_systems).is_true()
	for boon_id: StringName in CAPPED:
		var boon: BoonDefinition = CATALOG.get_boon(boon_id)
		assert_str(String(boon.requires)).is_equal("effective_power")
		assert_bool(CATALOG.is_available(boon)).is_true()
		assert_int(boon.modifier_source.max_stacks).override_failure_message(String(boon_id)).is_equal(3)


# AC27 / AC28: 3 yığından sonra uygun havuzdan çıkar; etki +3'te durur.
func test_boon_stack_caps_leave_pool_after_three_stacks() -> void:
	for boon_id: StringName in CAPPED:
		var c: Array = _controllers()
		var state: GameState = c[0]
		var modifiers: ModifierController = c[1]
		var source: ModifierSource = CATALOG.get_boon(boon_id).modifier_source
		for i: int in 3:
			assert_bool(_ids(BoonRules.eligible_pool(CATALOG, modifiers)).has(boon_id)).is_true()
			assert_bool(modifiers.add_source(source)).is_true()
		assert_bool(modifiers.can_add(source)).is_false()
		assert_array(_ids(BoonRules.eligible_pool(CATALOG, modifiers))).not_contains([boon_id])
		assert_int(MoveResolver.effective_power(STAT_FOR[boon_id], 4, state.modifiers)).is_equal(7)


# AC27 / AC28: sınır düşürülmüş eski kayıt (5 seçim) → rebuild en çok 3 yığın; n = boons.size() = 5.
func test_boon_stack_caps_rebuild_old_save_caps_effect_but_keeps_n() -> void:
	for boon_id: StringName in CAPPED:
		var c: Array = _controllers()
		var state: GameState = c[0]
		var modifiers: ModifierController = c[1]
		for i: int in 5:
			state.boons.append(boon_id)
		var spirit: SpiritController = SpiritController.new()
		spirit.bind_services(state)
		spirit.bind_boons(CATALOG, modifiers)
		spirit.rebuild_boon_modifiers()
		assert_int(MoveResolver.effective_power(STAT_FOR[boon_id], 4, state.modifiers)).is_equal(7)
		assert_int(state.boons.size()).is_equal(5)
		var config: SpiritConfig = load("res://features/bozkurt/data/spirit_config.tres") as SpiritConfig
		assert_int(spirit.next_boon_cost()).is_equal(BoonRules.boon_cost(5, config))


# M2 sahneleri (boş havuz = tüm katalog) Kurt Gücü / Demir Post'u sunabilir; Prolog hiçbir tohumda sunmaz (AC26).
func test_boon_stack_caps_offered_outside_prolog_only() -> void:
	var c: Array = _controllers()
	var modifiers: ModifierController = c[1]
	var open_pool: Array[BoonDefinition] = BoonRules.eligible_pool(CATALOG, modifiers)
	var seen: Dictionary = {}
	for n: int in 5:
		for boon_id: StringName in _ids(BoonRules.offer(open_pool, 2, n)):
			seen[boon_id] = true
	for boon_id: StringName in CAPPED:
		assert_bool(seen.has(boon_id)).override_failure_message("sunulmadı: %s" % boon_id).is_true()
	var prolog: Array[StringName] = (load(CAMPAIGN_PATH) as CampaignDefinition).scene(1).boon_pool_ids
	var prolog_pool: Array[BoonDefinition] = BoonRules.eligible_pool(CATALOG, modifiers, prolog)
	for seed_value: int in [0, 1, 7, 123_456_789]:
		for n: int in 6:
			for boon_id: StringName in _ids(BoonRules.offer(prolog_pool, 1, n, seed_value)):
				assert_bool(boon_id in CAPPED).override_failure_message("Prolog'da: %s" % boon_id).is_false()
