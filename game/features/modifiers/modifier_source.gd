class_name ModifierSource
extends Resource
## Değiştirici kaynağı içeriği (lütuf, konsey üyesi …) — `.tres`, yalnızca `res://`, asla
## kaydedilmez (ADR-0006, "seçimleri kaydet, etkileri türet").


## Kaynak kimliği; [StatModifier.source_id] olarak kayıtlara geçer.
@export var source_id: StringName = &""
## Aynı etkiyi veren farklı kaynaklar aynı grubu paylaşır; gruptan aynı anda yalnızca
## bir kaynak etkin olabilir (çift sayım engeli). Boş = grup yok.
@export var exclusive_group: StringName = &""
## Yığın üst sınırının tek sahibi (C-17 D2). 0 = sınırsız.
@export var max_stacks: int = 0
@export var effects: Array[ModifierEffect] = []
