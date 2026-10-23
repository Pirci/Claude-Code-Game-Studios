extends GdUnitTestSuite
## Savaş ve arındırma raporları — ux/battle-report.md §4.1–§4.2, §5, §9 (C-72).


func before_test() -> void:
	TranslationServer.set_locale("en")


func _combat(won: bool, a_loss: int, d_loss: int, a_rem: int, d_rem: int) -> CombatResolver.CombatResult:
	var r: CombatResolver.CombatResult = CombatResolver.CombatResult.new()
	r.attacker_won = won
	r.attacker_losses = a_loss
	r.defender_losses = d_loss
	r.attacker_remaining = a_rem
	r.defender_remaining = d_rem
	return r


func _outcome(branch: MoveOutcome.Branch, combat: CombatResolver.CombatResult) -> MoveOutcome:
	var o: MoveOutcome = MoveOutcome.new()
	o.branch = branch
	o.combat = combat
	o.to_id = &"altai"
	return o


func _show(report: ReportModal) -> ReportModal:
	add_child(report)
	auto_free(report)
	return report


func _row(report: Node, row_name: String) -> Label:
	return report.find_child(row_name, true, false) as Label


func test_battle_report_victory_shows_our_losses_their_losses_and_standing() -> void:
	var r: ReportModal = _show(BattleReport.new(_outcome(MoveOutcome.Branch.COMBAT, _combat(true, 2, 3, 4, 0)), &"REGION_ALTAI"))
	assert_str(_row(r, "Verse").text).is_equal(tr("BATTLE_WON_ATTACK"))
	assert_str(_row(r, "RegionName").text).is_equal(tr("REGION_ALTAI"))
	assert_str(_row(r, "OurFallen").text).is_equal("↓ " + tr("REPORT_OUR_FALLEN") % NumberFormatter.ltr("2"))
	assert_object(_row(r, "OurFallen").get_theme_color(&"font_color")).is_equal(ValueFeedback.COLOR_LOSS)
	assert_str(_row(r, "OurStanding").text).is_equal("↑ " + tr("REPORT_OUR_STANDING") % NumberFormatter.ltr("4"))
	assert_object(_row(r, "TheirStanding")).is_null()
	assert_object(_row(r, "Scattered")).is_null()


func test_battle_report_draw_lost_shows_their_standing_and_scattered() -> void:
	var o: MoveOutcome = _outcome(MoveOutcome.Branch.COMBAT, _combat(false, 2, 2, 1, 1))
	o.dispersed = 1
	var r: ReportModal = _show(BattleReport.new(o, &""))
	assert_str(_row(r, "Verse").text).is_equal(tr("BATTLE_LOST_ATTACK"))
	assert_object(_row(r, "RegionName")).is_null()
	assert_object(_row(r, "TheirStanding")).is_not_null()
	assert_str(_row(r, "Scattered").text).is_equal("↓ " + tr("REPORT_SCATTERED") % NumberFormatter.ltr("1"))
	assert_object(_row(r, "OurStanding")).is_null()


func test_battle_report_both_fell_shows_only_losses() -> void:
	var r: ReportModal = _show(BattleReport.new(_outcome(MoveOutcome.Branch.COMBAT, _combat(false, 1, 1, 0, 0)), &""))
	assert_str(_row(r, "Verse").text).is_equal(tr("BATTLE_BOTH_FELL"))
	assert_object(_row(r, "OurStanding")).is_null()
	assert_object(_row(r, "TheirStanding")).is_null()


func test_purification_report_success_shows_spirit_fallen_settled() -> void:
	var o: MoveOutcome = _outcome(MoveOutcome.Branch.PURIFICATION, _combat(true, 2, 4, 5, 0))
	o.purified = true
	o.ruh_gain = 10
	var r: ReportModal = _show(PurificationReport.new(o, &"REGION_ALTAI"))
	assert_str(_row(r, "Heading").text).is_equal(tr("PURIFY_REPORT_HEADING"))
	assert_str(_row(r, "Verse").text).is_equal(tr("PURIFY_SUCCESS"))
	assert_str(_row(r, "SpiritGained").text).is_equal("↑ " + tr("PURIFY_SPIRIT_GAINED") % NumberFormatter.ltr("10"))
	assert_object(_row(r, "Settled")).is_not_null()
	assert_object(_row(r, "FailedHint")).is_null()


func test_purification_report_failure_shows_lost_and_strength_hint_without_spirit() -> void:
	# Başarısızlıkta MoveResolver savaş sonucu üretmez (bütün kuvvet dağılır).
	var o: MoveOutcome = _outcome(MoveOutcome.Branch.PURIFICATION, null)
	o.moving = 4
	o.corruption_strength = 8
	var r: ReportModal = _show(PurificationReport.new(o, &""))
	assert_str(_row(r, "Verse").text).is_equal(tr("PURIFY_FAILED"))
	assert_str(_row(r, "Lost").text).is_equal("↓ " + tr("PURIFY_LOST") % NumberFormatter.ltr("4"))
	assert_str(_row(r, "FailedHint").text).is_equal(tr("PURIFY_FAILED_HINT") % NumberFormatter.ltr("8"))
	assert_object(_row(r, "SpiritGained")).is_null()


func test_purification_report_focus_uses_scene_ritual_keys_with_fallback() -> void:
	var scene: SceneDefinition = SceneDefinition.new()
	scene.focus_heading_key = &"CHAPTER_1_SLAIN_HEADING"
	scene.focus_success_key = &"CHAPTER_1_SLAIN_LINE"
	var o: MoveOutcome = _outcome(MoveOutcome.Branch.PURIFICATION, _combat(true, 1, 1, 5, 0))
	o.purified = true
	var r: ReportModal = _show(PurificationReport.new(o, &"", scene))
	assert_str(_row(r, "Heading").text).is_equal(tr("CHAPTER_1_SLAIN_HEADING"))
	assert_str(_row(r, "Verse").text).is_equal(tr("CHAPTER_1_SLAIN_LINE"))
	o.purified = false
	var failed: ReportModal = _show(PurificationReport.new(o, &"", scene))
	assert_str(_row(failed, "Verse").text).is_equal(tr("PURIFY_FAILED"))  # focus_failed_key boş → düz metin
	assert_str(_row(failed, "Heading").text).is_equal(tr("PURIFY_REPORT_HEADING"))  # zafer başlığı başarısızlıkta yok


func test_report_esc_and_continue_close_and_guard_blocks() -> void:
	var r: ReportModal = _show(BattleReport.new(_outcome(MoveOutcome.Branch.COMBAT, _combat(true, 1, 1, 1, 0)), &"", 5.0))
	var closes: Array[int] = [0]
	r.closed.connect(func() -> void: closes[0] += 1)
	var button: Button = r.get_focus_target() as Button
	assert_bool(button.disabled).is_true()  # giriş koruması (0.4 sn yerine test 5 sn)
	var esc: InputEventAction = InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	r._unhandled_input(esc)
	assert_int(closes[0]).is_equal(0)
	button.disabled = false
	r._unhandled_input(esc)
	assert_int(closes[0]).is_equal(1)


func test_modal_queue_push_avoiding_moves_report_off_the_target_region() -> void:
	var queue: ModalQueue = ModalQueue.new()
	queue.size = Vector2(640, 360)
	add_child(queue)
	auto_free(queue)
	queue.size = Vector2(640, 360)
	var report: ReportModal = BattleReport.new(_outcome(MoveOutcome.Branch.COMBAT, _combat(true, 1, 1, 1, 0)), &"")
	# Ortanın biraz üstündeki bölge: merkez yerleşimi örter, alt kenar örtmez → alta iner.
	var target: Rect2 = Rect2(Vector2(300, 100), Vector2(40, 16))
	queue.push_avoiding(report, [target] as Array[Rect2])
	await await_idle_frame()
	var rect: Rect2 = report.get_global_rect()
	assert_bool(rect.intersects(target)).override_failure_message("rapor %s hedefi örtüyor" % rect).is_false()
	assert_float(rect.end.y).is_equal_approx(360.0 - queue.bottom_margin, 1.0)


## Gerçek yol: GameContext başarısız arındırmada da raporu açar (savaş sonucu yokken).
func test_game_context_opens_report_for_failed_purification() -> void:
	var game: GameContext = (load("res://contexts/game_context/game_context.tscn") as PackedScene).instantiate() as GameContext
	game.bind_services(GameState.new(), AccessibilitySettings.new())
	add_child(game)
	auto_free(game)
	var m: MapState = (game.get("_game_state") as GameState).map_state
	var vadi: RegionData = m.get_region(&"guney_vadi")
	vadi.owner = RegionData.Owner.PLAYER
	vadi.army_count = 6
	game.call("_on_region_clicked", &"guney_vadi")
	game.call("_on_send_army_pressed", &"guney_vadi")
	game.call("_on_region_clicked", &"sinir_bolge")
	var report: Node = game.find_child("PurificationReport", true, false)
	assert_object(report).is_not_null()
	assert_str(_row(report, "Verse").text).is_equal(tr("CHAPTER_1_HUNT_FAILED"))
