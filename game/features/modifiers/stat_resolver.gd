class_name StatResolver
extends RefCounted
## Saf stat çözümü — durum yok, sinyal yok (ADR-0006).
## [code]resolve = (base + flat_sum) × (1 + percent_sum)[/code]; yüzdeler kendi aralarında
## toplanır. Yuvarlama ve aralık kırpma çağıranın GDD'sine aittir (ör. resource F2 floor).
## [param modifiers] tam tipli [code]Array[StatModifier][/code] olmalıdır (tipli diziler
## çalışma zamanında değişmez — tipsiz kaynağı [code]assign()[/code] ile dönüştür).


static func resolve(stat_id: StringName, base: float, modifiers: Array[StatModifier]) -> float:
	return (base + flat_sum(stat_id, modifiers)) * (1.0 + percent_sum(stat_id, modifiers))


## [param stat_id] için FLAT değerlerin yığınlı toplamı (resource F2 `B_add`).
static func flat_sum(stat_id: StringName, modifiers: Array[StatModifier]) -> float:
	return _sum(stat_id, StatModifier.Kind.FLAT, modifiers)


## [param stat_id] için PERCENT değerlerin yığınlı toplamı (resource F2 `M_g = 1 + percent_sum`).
static func percent_sum(stat_id: StringName, modifiers: Array[StatModifier]) -> float:
	return _sum(stat_id, StatModifier.Kind.PERCENT, modifiers)


static func _sum(stat_id: StringName, kind: StatModifier.Kind, modifiers: Array[StatModifier]) -> float:
	var total: float = 0.0
	for modifier: StatModifier in modifiers:
		if modifier.stat_id == stat_id and modifier.kind == kind:
			total += modifier.value * modifier.stacks
	return total
