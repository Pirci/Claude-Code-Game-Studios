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
## COMBAT ve PURIFICATION dalında savaş çözümü (arındırmada `resolve(P, S)`); PEACEFUL'da null.
var combat: CombatResolver.CombatResult = null
## PURIFICATION: arınma direnci `S` (spirit §4.1), başarı (`P > S`) ve kazanılan Ruh.
var corruption_strength: int = 0
var purified: bool = false
var ruh_gain: int = 0
## Haritada kalmayan saldıran birlikler (kaybedilen savaşta hayatta kalanlar; başarısız
## arındırmada gelen kuvvetin tamamı).
var dispersed: int = 0
var source_army_after: int = 0
## Hedefin hamle *öncesi* sahibi — rapor "düşman kampımızı aldı" ile "biz onlarınkini aldık"ı ayırır
## (ADR-0010 eki G2).
var target_owner_before: RegionData.Owner = RegionData.Owner.NEUTRAL
var target_owner_after: RegionData.Owner = RegionData.Owner.NEUTRAL
var target_army_after: int = 0
var target_corruption_after: int = 0
## Hamlenin nedeni: oyuncu hamlesinde boş; düşman hamlesinde [member EnemyAIController.MoveIntent.reason]
## (ör. `&"strike"`). Çözümü değiştirmez — yalnız rapor okur (ADR-0010 eki G2).
var reason: StringName = &""


func is_valid() -> bool:
	return branch != Branch.INVALID
