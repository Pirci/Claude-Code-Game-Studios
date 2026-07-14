extends GdUnitTestSuite
## CombatResolver birim testleri — combat-system.md kabul kriterleri.


func _resolver() -> CombatResolver:
	return CombatResolver.new()


func test_attacker_stronger_attacker_wins() -> void:
	var r: CombatResolver.CombatResult = _resolver().resolve(5, 3)
	assert_bool(r.attacker_won).is_true()
	assert_int(r.attacker_remaining).is_equal(3)
	assert_int(r.defender_remaining).is_equal(0)


func test_defender_stronger_defender_wins() -> void:
	var r: CombatResolver.CombatResult = _resolver().resolve(3, 6)
	assert_bool(r.attacker_won).is_false()
	assert_int(r.attacker_remaining).is_equal(0)
	assert_int(r.defender_remaining).is_equal(5)


func test_draw_defender_wins() -> void:
	var r: CombatResolver.CombatResult = _resolver().resolve(4, 4)
	assert_bool(r.attacker_won).is_false()
	assert_int(r.attacker_remaining).is_equal(1)
	assert_int(r.defender_remaining).is_equal(2)


func test_remaining_never_negative() -> void:
	var r: CombatResolver.CombatResult = _resolver().resolve(1, 1)
	assert_int(r.attacker_remaining).is_greater_equal(0)
	assert_int(r.defender_remaining).is_greater_equal(0)


func test_losses_use_ceil() -> void:
	# A=5, D=3 → attacker_losses = ceil(3 * 0.5) = 2
	var r: CombatResolver.CombatResult = _resolver().resolve(5, 3)
	assert_int(r.attacker_losses).is_equal(2)
	assert_int(r.defender_losses).is_equal(3)


func test_deterministic() -> void:
	var a: CombatResolver.CombatResult = _resolver().resolve(7, 4)
	var b: CombatResolver.CombatResult = _resolver().resolve(7, 4)
	assert_int(a.attacker_remaining).is_equal(b.attacker_remaining)
	assert_int(a.defender_remaining).is_equal(b.defender_remaining)
	assert_bool(a.attacker_won).is_equal(b.attacker_won)


func test_config_injection_changes_result() -> void:
	# Eşitlikte savunan avantajını kapatınca saldıran kazanmalı.
	var config: CombatConfig = CombatConfig.new()
	config.draw_favors_defender = false
	var resolver: CombatResolver = CombatResolver.new()
	resolver.bind_config(config)
	var r: CombatResolver.CombatResult = resolver.resolve(4, 4)
	assert_bool(r.attacker_won).is_true()


func test_null_config_uses_defaults() -> void:
	var resolver: CombatResolver = CombatResolver.new()
	resolver.bind_config(null)
	var r: CombatResolver.CombatResult = resolver.resolve(5, 3)
	assert_bool(r.attacker_won).is_true()
	assert_int(r.attacker_remaining).is_equal(3)
