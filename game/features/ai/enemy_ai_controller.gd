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
	# Düşman bölgeleri `region_id` sırasıyla işlenir — kayıt sırasından bağımsız,
	# deterministik (region-map-system.md AC6, W6).
	var enemies: Array[RegionData] = map_state.get_enemy_regions()
	enemies.sort_custom(_id_less)
	for region: RegionData in enemies:
		if region.region_id in acted:
			continue
		if region.army_count <= 1:
			continue
		var target: RegionData = _pick_target(map_state, region)
		if target == null:
			continue
		return MoveIntent.new(region.region_id, target.region_id)
	return null


## Düşman olmayan komşular arasında ordusu en düşük olan; eşitlikte `region_id`
## alfabetik ilki (region-map-system.md AC6, W6).
func _pick_target(map_state: MapState, region: RegionData) -> RegionData:
	var best: RegionData = null
	for adj_id: StringName in region.adjacent_regions:
		var adj: RegionData = map_state.get_region(adj_id)
		if adj == null or adj.owner == RegionData.Owner.ENEMY:
			continue
		if best == null or adj.army_count < best.army_count \
				or (adj.army_count == best.army_count and _id_less(adj, best)):
			best = adj
	return best


static func _id_less(a: RegionData, b: RegionData) -> bool:
	return String(a.region_id) < String(b.region_id)
