class_name ErlikSpreadController
extends RefCounted
## Erlik bozulma yayılımı — saf karar servisi (ADR-0005, spirit-system.md §3.6/§4.6).
## Yayılım turunu ve hedefi hesaplar; bozulmayı yazmaz (tek yazıcı SpiritController,
## C-38). Efektif aralığı (taban + Gök Kalkanı) çağıran [StatResolver] ile çözer.


const MAX_CORRUPTION_LEVEL: int = 3
## Etkin yayılım aralığı stat'ı (Gök Kalkanı FLAT +1; ADR-0006, spirit §4.6).
const STAT_SPREAD_INTERVAL: StringName = &"erlik_spread_interval"


## [member is_spread_turn]: bu tur yayılım turu mu. [member target_id]: kuralın şu anki
## duruma göre seçtiği aday — her çağrıda hesaplanır (HUD göstergesi, TR-spirit-010);
## aday yoksa boş. Bu script dışında [code]ErlikSpreadController.SpreadDecision[/code].
class SpreadDecision extends RefCounted:
	var is_spread_turn: bool = false
	var target_id: StringName = &""
	## Hedefin karar anındaki bozulma seviyesi (0 → yeni yayılım, ≥ 1 → derinleşme; hedef yoksa 0)
	## — ADR-0010 eki G3.
	var level_before: int = 0


## [param effective_interval] < 1 ise 1 sayılır (her tur yayılım).
func decide(map_state: MapState, effective_interval: int) -> SpreadDecision:
	var decision: SpreadDecision = SpreadDecision.new()
	var interval: int = maxi(1, effective_interval)
	decision.is_spread_turn = map_state.current_turn - map_state.last_erlik_spread_turn >= interval
	decision.target_id = _pick_target(map_state)
	if decision.target_id != &"":
		decision.level_before = map_state.get_region(decision.target_id).corruption_level
	return decision


## Adaylar: seviyesi < 3 olan ve en az bir bozuk komşusu bulunan bölgeler (sahipten
## bağımsız). Ordusu en düşük olan; eşitlikte region_id alfabetik ilk.
func _pick_target(map_state: MapState) -> StringName:
	var best: RegionData = null
	for region: RegionData in map_state.regions.values():
		if region.corruption_level >= MAX_CORRUPTION_LEVEL:
			continue
		if not _has_corrupted_neighbor(map_state, region):
			continue
		if best == null or _is_better_target(region, best):
			best = region
	return best.region_id if best != null else &""


func _has_corrupted_neighbor(map_state: MapState, region: RegionData) -> bool:
	for adj_id: StringName in region.adjacent_regions:
		var adj: RegionData = map_state.get_region(adj_id)
		if adj != null and adj.corruption_level >= 1:
			return true
	return false


func _is_better_target(candidate: RegionData, current: RegionData) -> bool:
	if candidate.army_count != current.army_count:
		return candidate.army_count < current.army_count
	return String(candidate.region_id) < String(current.region_id)
