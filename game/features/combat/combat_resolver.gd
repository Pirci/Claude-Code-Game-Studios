class_name CombatResolver
extends RefCounted
## Otomatik savaş çözümü. Saldıran vs savunan ordu karşılaştırması.


signal combat_resolved(result: CombatResult)


func resolve(attacker_army: int, defender_army: int) -> CombatResult:
	var result: CombatResult = CombatResult.new()
	result.attacker_army = attacker_army
	result.defender_army = defender_army

	if attacker_army > defender_army:
		result.attacker_won = true
		result.attacker_losses = ceili(defender_army * 0.5)
		result.defender_losses = defender_army
	elif defender_army > attacker_army:
		result.attacker_won = false
		result.attacker_losses = attacker_army
		result.defender_losses = ceili(attacker_army * 0.3)
	else:
		result.attacker_won = false
		result.attacker_losses = ceili(attacker_army * 0.7)
		result.defender_losses = ceili(defender_army * 0.5)

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
