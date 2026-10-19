class_name EnemyAIController
extends RefCounted
## Siyasi düşman AI'ı — saf karar servisi (ADR-0005).
## [MapState]'i yalnızca okur: durumu değiştirmez, sinyal yaymaz. [MapController] her
## düşman aksiyonu için [method decide]'ı çağırır ve dönen niyeti uygular (karar → uygula
## döngüsü), böylece her hamle bir öncekinin sonucunu görür (region-map-system.md §3.5).


## Tek bir düşman hamlesi: [member from_id] bölgesinden [member to_id] komşusuna.
## Bu script dışında [code]EnemyAIController.MoveIntent[/code] olarak yazılır.
class MoveIntent extends RefCounted:
	var from_id: StringName
	var to_id: StringName

	func _init(p_from: StringName = &"", p_to: StringName = &"") -> void:
		from_id = p_from
		to_id = p_to


## Sıradaki düşman hamlesi. [param acted] bu tur hamle yapmış (ya da bu tur ele geçirilmiş)
## bölgelerdir; her düşman bölgesi tur başına en fazla bir kez hareket eder.
## Hamle yapabilecek bölge yoksa [code]null[/code] döner.
func decide(map_state: MapState, acted: Array[StringName]) -> MoveIntent:
	for region: RegionData in map_state.get_enemy_regions():
		if region.region_id in acted:
			continue
		if region.army_count <= 1:
			continue
		var target: RegionData = _pick_target(map_state, region)
		if target == null:
			continue
		return MoveIntent.new(region.region_id, target.region_id)
	return null


## Düşman olmayan komşular arasında ordusu en düşük olan; eşitlikte komşuluk listesinde
## ilk bulunan (bugünkü davranış — alfabetik eşitlik bozma C-52).
func _pick_target(map_state: MapState, region: RegionData) -> RegionData:
	var best: RegionData = null
	for adj_id: StringName in region.adjacent_regions:
		var adj: RegionData = map_state.get_region(adj_id)
		if adj == null or adj.owner == RegionData.Owner.ENEMY:
			continue
		if best == null or adj.army_count < best.army_count:
			best = adj
	return best
