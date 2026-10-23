extends GdUnitTestSuite
## TurnSummaryReport içerik kuralları (C-73; ux/battle-report.md §4.3): blok seçimi, R1 vuruşu,
## Gölge uyarısı yalnız yayılım gecesinde, ilgisiz düşman hamleleri yok, en çok 3 saldırı.


func before_test() -> void:
	TranslationServer.set_locale("en")


func _attack(won: bool, attacker_remaining: int, defender_remaining: int, target_before: RegionData.Owner = RegionData.Owner.PLAYER) -> MoveOutcome:
	var o: MoveOutcome = MoveOutcome.new()
	o.branch = MoveOutcome.Branch.COMBAT
	o.mover = RegionData.Owner.ENEMY
	o.to_id = &"otuken"
	o.target_owner_before = target_before
	var c: CombatResolver.CombatResult = CombatResolver.CombatResult.new()
	c.attacker_won = won
	c.attacker_losses = 2
	c.defender_losses = 3
	c.attacker_remaining = attacker_remaining
	c.defender_remaining = defender_remaining
	o.combat = c
	return o


func _spread(level_before: int) -> ErlikSpreadController.SpreadDecision:
	var d: ErlikSpreadController.SpreadDecision = ErlikSpreadController.SpreadDecision.new()
	d.is_spread_turn = true
	d.target_id = &"altai"
	d.level_before = level_before
	return d


func _report(outcomes: Array[MoveOutcome], spread: ErlikSpreadController.SpreadDecision, warning: bool = false) -> TurnSummaryReport:
	var names: Dictionary = {&"otuken": &"REGION_OTUKEN", &"altai": &"REGION_ALTAI"}
	var r: TurnSummaryReport = auto_free(TurnSummaryReport.new(outcomes, spread, names, warning)) as TurnSummaryReport
	return r


func _text(r: Node, node_name: String) -> String:
	var label: Label = r.find_child(node_name, true, false) as Label
	return label.text if label != null else ""


func test_turn_summary_strike_win_reads_lost_defense() -> void:
	var strike: MoveOutcome = _attack(true, 4, 0)
	strike.reason = &"strike"  # enemy-layers AC13: R1 vuruşu her zaman LOST_DEFENSE
	var r: TurnSummaryReport = _report([strike] as Array[MoveOutcome], null)
	assert_bool(r.has_events()).is_true()
	assert_str(_text(r, "Attack0Verse")).is_equal(tr("BATTLE_LOST_DEFENSE"))
	assert_str(_text(r, "Attack0Region")).is_equal(tr("REGION_OTUKEN"))
	assert_str(_text(r, "Attack0OurFallen")).contains("3")
	assert_str(_text(r, "Attack0TheirStanding")).contains("4")


func test_turn_summary_held_and_both_fell_verses() -> void:
	var r: TurnSummaryReport = _report([_attack(false, 1, 2), _attack(false, 0, 0)] as Array[MoveOutcome], null)
	assert_str(_text(r, "Attack0Verse")).is_equal(tr("BATTLE_HELD_DEFENSE"))
	assert_str(_text(r, "Attack0TheirFallen")).contains("2")
	assert_str(_text(r, "Attack1Verse")).is_equal(tr("BATTLE_BOTH_FELL"))


func test_turn_summary_ignores_enemy_moves_not_against_player() -> void:
	var neutral_hit: MoveOutcome = _attack(true, 3, 0, RegionData.Owner.NEUTRAL)
	var peaceful: MoveOutcome = MoveOutcome.new()
	peaceful.mover = RegionData.Owner.ENEMY
	peaceful.branch = MoveOutcome.Branch.PEACEFUL
	var r: TurnSummaryReport = _report([neutral_hit, peaceful] as Array[MoveOutcome], null)
	assert_bool(r.has_events()).is_false()


func test_turn_summary_spread_vs_deepened_and_shadow_warning_only_with_spread() -> void:
	var fresh: TurnSummaryReport = _report([] as Array[MoveOutcome], _spread(0), true)
	assert_str(_text(fresh, "Spread")).is_equal(tr("TURN_SUMMARY_SPREAD") % tr("REGION_ALTAI"))
	assert_object(fresh.find_child("ShadowWarning", true, false)).is_not_null()
	var deeper: TurnSummaryReport = _report([] as Array[MoveOutcome], _spread(2))
	assert_str(_text(deeper, "Spread")).is_equal(tr("TURN_SUMMARY_DEEPENED") % tr("REGION_ALTAI"))
	assert_object(deeper.find_child("ShadowWarning", true, false)).is_null()
	# Yayılım olmayan gecede uyarı yok (yalnız HUD'da kalıcı durum).
	var attack_only: TurnSummaryReport = _report([_attack(true, 4, 0)] as Array[MoveOutcome], null, true)
	assert_object(attack_only.find_child("ShadowWarning", true, false)).is_null()


func test_turn_summary_caps_attack_blocks_at_three() -> void:
	var many: Array[MoveOutcome] = []
	for i: int in 4:
		many.append(_attack(true, 4, 0))
	var r: TurnSummaryReport = _report(many, null)
	assert_object(r.find_child("Attack2Verse", true, false)).is_not_null()
	assert_object(r.find_child("Attack3Verse", true, false)).is_null()


func test_turn_summary_no_events_when_spread_not_due() -> void:
	var idle: ErlikSpreadController.SpreadDecision = ErlikSpreadController.SpreadDecision.new()
	idle.target_id = &"altai"
	assert_bool(_report([] as Array[MoveOutcome], idle).has_events()).is_false()
