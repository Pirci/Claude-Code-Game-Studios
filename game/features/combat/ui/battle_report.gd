class_name BattleReport
extends ReportModal
## Oyuncu savaş raporu (ux/battle-report.md §4.1): hamleden hemen sonra açılır; yalnız
## [MoveOutcome] okur, kural yeniden hesaplanmaz (ADR-0010 eki G1–G2).
## Dize sırası: ikisi de düştü → zafer → yenilgi (beraberlik dahil).


func _init(outcome: MoveOutcome, region_name_key: StringName, guard_s: float = 0.0) -> void:
	super(guard_s)
	name = "BattleReport"
	var result: CombatResolver.CombatResult = outcome.combat
	_add_heading(tr("BATTLE_REPORT_HEADING"))
	_add_region_name(region_name_key)
	var both_fell: bool = result.attacker_remaining == 0 and result.defender_remaining == 0
	if both_fell:
		_add_verse(tr("BATTLE_BOTH_FELL"))
	elif result.attacker_won:
		_add_verse(tr("BATTLE_WON_ATTACK"))
	else:
		_add_verse(tr("BATTLE_LOST_ATTACK"))
	_add_number("OurFallen", "REPORT_OUR_FALLEN", result.attacker_losses, -1)
	_add_number("TheirFallen", "REPORT_THEIR_FALLEN", result.defender_losses)
	if both_fell:
		return
	if result.attacker_won:
		_add_number("OurStanding", "REPORT_OUR_STANDING", result.attacker_remaining, 1)
	else:
		_add_number("TheirStanding", "REPORT_THEIR_STANDING", result.defender_remaining)
		if outcome.dispersed > 0:
			_add_number("Scattered", "REPORT_SCATTERED", outcome.dispersed, -1)
