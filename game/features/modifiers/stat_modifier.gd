class_name StatModifier
extends RefCounted
## Tek bir kaynaktan tek bir stat'a gelen toplamsal değiştirici — yalnızca veri (ADR-0004, ADR-0006).
## [code](source_id, stat_id, kind)[/code] başına en fazla bir kayıt vardır; aynı kaynağın
## tekrar eklenmesi [member stacks]'i artırır. Tek yazar [ModifierController]; okuma
## yalnızca [StatResolver] üzerinden.


enum Kind { FLAT, PERCENT }

## Kaynak kimliği, ör. [code]&"boon:bereket"[/code], [code]&"council:oguz"[/code].
var source_id: StringName = &""
## Hedef stat, ör. [code]&"gold_income"[/code], [code]&"erlik_spread_interval"[/code].
var stat_id: StringName = &""
var kind: Kind = Kind.FLAT
## Yığın başına değer (PERCENT için 0.2 = %20).
var value: float = 0.0
var stacks: int = 1
