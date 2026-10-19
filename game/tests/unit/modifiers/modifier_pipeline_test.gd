extends GdUnitTestSuite
## Toplamsal değiştirici hattı — ADR-0006 doğrulama listesi (C-55).


const GOLD: StringName = &"gold_income"
const SPREAD_INTERVAL: StringName = &"erlik_spread_interval"
const FIXTURE_GOK_KALKANI: String = "res://tests/unit/modifiers/fixtures/fixture_gok_kalkani_source.tres"

var _state: GameState
var _controller: ModifierController


func before_test() -> void:
	_state = GameState.new()
	_controller = ModifierController.new()
	_controller.bind_services(_state)


func _effect(stat_id: StringName, kind: StatModifier.Kind, value: float) -> ModifierEffect:
	var effect: ModifierEffect = ModifierEffect.new()
	effect.stat_id = stat_id
	effect.kind = kind
	effect.value = value
	return effect


func _source(id: StringName, effects: Array[ModifierEffect], group: StringName = &"", max_stacks: int = 0) -> ModifierSource:
	var source: ModifierSource = ModifierSource.new()
	source.source_id = id
	source.exclusive_group = group
	source.max_stacks = max_stacks
	source.effects = effects
	return source


func _bereket() -> ModifierSource:
	return _source(&"boon:bereket", [_effect(GOLD, StatModifier.Kind.FLAT, 1.0)] as Array[ModifierEffect])


func _gok_kalkani() -> ModifierSource:
	return _source(&"boon:gok_kalkani", [_effect(SPREAD_INTERVAL, StatModifier.Kind.FLAT, 1.0)] as Array[ModifierEffect], &"", 3)


func _modifier(stat_id: StringName, kind: StatModifier.Kind, value: float, stacks: int = 1) -> StatModifier:
	var modifier: StatModifier = StatModifier.new()
	modifier.source_id = &"test"
	modifier.stat_id = stat_id
	modifier.kind = kind
	modifier.value = value
	modifier.stacks = stacks
	return modifier


func _snapshot() -> Array[String]:
	var rows: Array[String] = []
	for m: StatModifier in _state.modifiers:
		rows.append("%s|%s|%d|%s|%d" % [m.source_id, m.stat_id, m.kind, m.value, m.stacks])
	return rows


func test_same_source_twice_stacks_one_record() -> void:
	assert_bool(_controller.add_source(_bereket())).is_true()
	assert_bool(_controller.add_source(_bereket())).is_true()
	assert_int(_state.modifiers.size()).is_equal(1)
	assert_int(_state.modifiers[0].stacks).is_equal(2)
	assert_float(StatResolver.flat_sum(GOLD, _state.modifiers)).is_equal(2.0)


func test_boon_and_council_on_same_stat_each_count_once() -> void:
	var council: ModifierSource = _source(&"council:oguz", [_effect(GOLD, StatModifier.Kind.PERCENT, 0.1)] as Array[ModifierEffect])
	_controller.add_source(_bereket())
	_controller.add_source(council)
	assert_float(StatResolver.flat_sum(GOLD, _state.modifiers)).is_equal(1.0)
	assert_float(StatResolver.percent_sum(GOLD, _state.modifiers)).is_equal_approx(0.1, 0.0001)


func test_same_exclusive_group_under_another_source_is_rejected() -> void:
	var boon: ModifierSource = _source(&"boon:bolluk", [_effect(GOLD, StatModifier.Kind.PERCENT, 0.1)] as Array[ModifierEffect], &"gold_pct_10")
	var council: ModifierSource = _source(&"council:gun", [_effect(GOLD, StatModifier.Kind.PERCENT, 0.1)] as Array[ModifierEffect], &"gold_pct_10")
	assert_bool(_controller.add_source(boon)).is_true()
	assert_bool(_controller.can_add(council)).is_false()
	assert_bool(_controller.add_source(council)).is_false()
	assert_float(StatResolver.percent_sum(GOLD, _state.modifiers)).is_equal_approx(0.1, 0.0001)
	# Aynı kaynağın tekrarı grup çakışması sayılmaz.
	assert_bool(_controller.add_source(boon)).is_true()


func test_resolve_accepts_filtered_typed_and_assigned_untyped_arrays() -> void:
	var typed: Array[StatModifier] = [
		_modifier(GOLD, StatModifier.Kind.FLAT, 1.0),
		_modifier(&"army_attack", StatModifier.Kind.FLAT, 5.0),
	]
	var filtered: Array[StatModifier] = typed.filter(func(m: StatModifier) -> bool: return m.stat_id == GOLD)
	assert_float(StatResolver.resolve(GOLD, 5.0, filtered)).is_equal(6.0)
	var untyped: Array = [_modifier(GOLD, StatModifier.Kind.FLAT, 2.0)]
	var converted: Array[StatModifier] = []
	converted.assign(untyped)
	assert_float(StatResolver.resolve(GOLD, 5.0, converted)).is_equal(7.0)


func test_resolve_adds_flat_before_percent_and_caller_floors() -> void:
	var modifiers: Array[StatModifier] = [
		_modifier(GOLD, StatModifier.Kind.FLAT, 1.0),
		_modifier(GOLD, StatModifier.Kind.PERCENT, 0.2),
	]
	assert_float(StatResolver.resolve(GOLD, 5.0, modifiers)).is_equal_approx(7.2, 0.0001)
	# resource F2: floor((I_raw + B_add) × M_g) — I_raw 5, B_add 1, M_g 1.2 → 7.
	var m_g: float = 1.0 + StatResolver.percent_sum(GOLD, modifiers)
	assert_int(floori((5.0 + StatResolver.flat_sum(GOLD, modifiers)) * m_g)).is_equal(7)


func test_percents_combine_additively() -> void:
	var modifiers: Array[StatModifier] = [
		_modifier(GOLD, StatModifier.Kind.PERCENT, 0.25, 2),
		_modifier(GOLD, StatModifier.Kind.PERCENT, 0.5),
	]
	# (10) × (1 + 0.5 + 0.5) = 20 — çarpımsal olsaydı 10 × 1.25² × 1.5 ≈ 23.4.
	assert_float(StatResolver.resolve(GOLD, 10.0, modifiers)).is_equal(20.0)


func test_max_stacks_rejects_fourth_add() -> void:
	var source: ModifierSource = _gok_kalkani()
	for i: int in 3:
		assert_bool(_controller.add_source(source)).override_failure_message("add %d" % i).is_true()
	assert_bool(_controller.can_add(source)).is_false()
	assert_bool(_controller.add_source(source)).is_false()
	assert_int(_state.modifiers[0].stacks).is_equal(3)


func test_rebuild_twice_is_idempotent() -> void:
	var sources: Array[ModifierSource] = [_bereket(), _bereket(), _gok_kalkani()]
	_controller.rebuild(sources)
	var first: Array[String] = _snapshot()
	_controller.rebuild(sources)
	assert_array(_snapshot()).is_equal(first)


func test_rebuild_from_saved_boons_derives_effects() -> void:
	var catalog: Dictionary[StringName, ModifierSource] = {
		&"bereket": _bereket(),
		&"gok_kalkani": _gok_kalkani(),
	}
	_state.boons.assign([&"bereket", &"bereket", &"gok_kalkani"])
	var sources: Array[ModifierSource] = []
	for boon_id: StringName in _state.boons:
		sources.append(catalog[boon_id])
	_controller.rebuild(sources)
	assert_float(StatResolver.flat_sum(GOLD, _state.modifiers)).is_equal(2.0)
	assert_float(StatResolver.flat_sum(SPREAD_INTERVAL, _state.modifiers)).is_equal(1.0)


func test_rebuild_clips_picks_above_lowered_max_stacks() -> void:
	var source: ModifierSource = _gok_kalkani()
	source.max_stacks = 2
	_controller.rebuild([source, source, source] as Array[ModifierSource])
	assert_float(StatResolver.flat_sum(SPREAD_INTERVAL, _state.modifiers)).is_equal(2.0)


func test_remove_source_drops_all_stacks_and_signals() -> void:
	_controller.add_source(_bereket())
	_controller.add_source(_bereket())
	var seen: Array[StringName] = []
	_controller.modifiers_changed.connect(func(stat_id: StringName) -> void: seen.append(stat_id))
	_controller.remove_source(&"boon:bereket")
	assert_int(_state.modifiers.size()).is_equal(0)
	assert_array(seen).contains_exactly([GOLD])
	# Kaldırılan kaynak sıfırdan yeniden eklenebilir.
	assert_bool(_controller.add_source(_bereket())).is_true()
	assert_int(_state.modifiers[0].stacks).is_equal(1)


func test_add_emits_changed_per_affected_stat() -> void:
	var seen: Array[StringName] = []
	_controller.modifiers_changed.connect(func(stat_id: StringName) -> void: seen.append(stat_id))
	var two: ModifierSource = _source(&"boon:iki", [
		_effect(GOLD, StatModifier.Kind.FLAT, 1.0),
		_effect(SPREAD_INTERVAL, StatModifier.Kind.FLAT, 1.0),
	] as Array[ModifierEffect])
	_controller.add_source(two)
	assert_array(seen).contains_exactly([GOLD, SPREAD_INTERVAL])


func test_null_or_unnamed_source_is_rejected() -> void:
	assert_bool(_controller.can_add(null)).is_false()
	assert_bool(_controller.can_add(_source(&"", [] as Array[ModifierEffect]))).is_false()


func test_duplicate_effect_in_one_source_merges_into_one_record() -> void:
	var source: ModifierSource = _source(&"boon:cift", [
		_effect(GOLD, StatModifier.Kind.FLAT, 1.0),
		_effect(GOLD, StatModifier.Kind.FLAT, 2.0),
	] as Array[ModifierEffect])
	_controller.add_source(source)
	assert_int(_state.modifiers.size()).is_equal(1)
	assert_float(StatResolver.flat_sum(GOLD, _state.modifiers)).is_equal(3.0)


func test_tres_source_loads_with_typed_effects() -> void:
	var source: ModifierSource = load(FIXTURE_GOK_KALKANI) as ModifierSource
	assert_object(source).is_not_null()
	assert_int(source.max_stacks).is_equal(3)
	assert_int(source.effects.size()).is_equal(1)
	assert_str(String(source.effects[0].stat_id)).is_equal(String(SPREAD_INTERVAL))
	assert_bool(_controller.add_source(source)).is_true()
	assert_float(StatResolver.resolve(SPREAD_INTERVAL, 3.0, _state.modifiers)).is_equal(4.0)


func test_game_state_reset_clears_boons_and_modifiers() -> void:
	_controller.add_source(_bereket())
	_state.boons.append(&"bereket")
	_state.reset()
	assert_int(_state.boons.size()).is_equal(0)
	assert_int(_state.modifiers.size()).is_equal(0)
