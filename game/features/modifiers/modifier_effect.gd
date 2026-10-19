class_name ModifierEffect
extends Resource
## [ModifierSource] içeriğindeki tek etki: hangi stat'a, hangi türde, ne kadar (ADR-0006).


@export var stat_id: StringName = &""
@export var kind: StatModifier.Kind = StatModifier.Kind.FLAT
## Yığın başına değer (PERCENT için 0.2 = %20).
@export var value: float = 0.0
