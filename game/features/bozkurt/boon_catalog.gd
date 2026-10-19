class_name BoonCatalog
extends Resource
## Lütuf kataloğu (spirit-system.md §3.5) — içerik `data/boon_catalog.tres`. Hangi
## `requires` sistemlerinin bu yapıda etkin olduğu da içerik kararıdır (ADR-0011 notu,
## TR-spirit-008): M1'de liste boştur, M2 etkin gücü ekler (`&"effective_power"`).


@export var boons: Array[BoonDefinition] = []
@export var active_systems: Array[StringName] = []


func get_boon(boon_id: StringName) -> BoonDefinition:
	for boon: BoonDefinition in boons:
		if boon.boon_id == boon_id:
			return boon
	return null


func is_available(boon: BoonDefinition) -> bool:
	return boon.requires == &"" or boon.requires in active_systems


## Kaydedilmiş seçimlerin kaynakları, seçim sırasıyla (ADR-0006 "seçimi sakla, etkiyi
## türet"). Katalogda olmayan kimlik uyarıyla atlanır (kaldırılmış içerik).
func sources_for(boon_ids: Array[StringName]) -> Array[ModifierSource]:
	var sources: Array[ModifierSource] = []
	for boon_id: StringName in boon_ids:
		var boon: BoonDefinition = get_boon(boon_id)
		if boon == null or boon.modifier_source == null:
			push_warning("BoonCatalog: bilinmeyen lütuf atlandı: %s" % boon_id)
			continue
		sources.append(boon.modifier_source)
	return sources
