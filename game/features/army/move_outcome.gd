class_name MoveOutcome
extends RefCounted
## Tek bir hamlenin tam sonucu — yalnızca veri (ADR-0010). [MoveResolver] haritayı okuyarak
## üretir; önizleme bunu gösterir, uygulama ([ArmyController.apply_outcome]) yalnızca
## buradaki değerleri yazar. Hedefin hamle *sonrası* durumu da buradadır.


enum Branch { INVALID, COMBAT, PURIFICATION, PEACEFUL }

var branch: Branch = Branch.INVALID
## INVALID nedeni ([MoveResolver] `REASON_*` sabitleri); geçerli hamlede boş.
var invalid_reason: StringName = &""
var mover: RegionData.Owner = RegionData.Owner.PLAYER
var from_id: StringName = &""
var to_id: StringName = &""
## Taşınan kuvvet = kaynak ordusu − 1 (army-system §3.2).
var moving: int = 0
## COMBAT (ve ileride PURIFICATION) dalında savaş çözümü; PEACEFUL'da null.
var combat: CombatResolver.CombatResult = null
## Haritada kalmayan saldıran birlikler (kaybedilen savaşta hayatta kalanlar).
var dispersed: int = 0
var source_army_after: int = 0
var target_owner_after: RegionData.Owner = RegionData.Owner.NEUTRAL
var target_army_after: int = 0
var target_corruption_after: int = 0


func is_valid() -> bool:
	return branch != Branch.INVALID
