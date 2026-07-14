class_name CombatResolver
extends RefCounted
## Otomatik savaş çözümü. Saldıran vs savunan ordu karşılaştırması.


signal combat_resolved(result: CombatResult)

# Config verilmezse varsayılan değerlerle (CombatConfig @export defaults) çalışır.
var _config: CombatConfig = CombatConfig.new()


func bind_config(config: CombatConfig) -> void:
	if config != null:
		_config = config


func resolve(attacker_army: int, defender_army: int) -> CombatResult:
	var result: CombatResult = CombatResult.new()
	result.attacker_army = attacker_army
	result.defender_army = defender_army

	if attacker_army > defender_army:
		result.attacker_won = true
		result.attacker_losses = ceili(defender_army * _config.attacker_win_loss_ratio)
		result.defender_losses = defender_army
	elif defender_army > attacker_army:
		result.attacker_won = false
		result.attacker_losses = attacker_army
		result.defender_losses = ceili(attacker_army * _config.defender_win_loss_ratio)
	else:
		result.attacker_won = not _config.draw_favors_defender
		result.attacker_losses = ceili(attacker_army * _config.draw_attacker_loss_ratio)
		result.defender_losses = ceili(defender_army * _config.draw_defender_loss_ratio)

	result.attacker_remaining = maxi(0, attacker_army - result.attacker_losses)
	result.defender_remaining = maxi(0, defender_army - result.defender_losses)
	return result


class CombatResult extends RefCounted:
	var attacker_won: bool = false
	var attacker_army: int = 0
	var defender_army: int = 0
	var attacker_losses: int = 0
	var defender_losses: int = 0
	var attacker_remaining: int = 0
	var defender_remaining: int = 0
