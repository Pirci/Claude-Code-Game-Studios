@tool
class_name WinCondition
extends Resource
## Bir bölümün kazanma koşulları (region-map-system.md §3.6, §4 — C-32/C-51).
## Zafer = siyasi ∧ genişleme ∧ Erlik odakları temiz ∧ oyuncunun en az bir bölgesi var.


## Başlangıçta nötr olan ve odak olmayan bölgelerden kaç tanesi oyuncuda olmalı.
@export var required_neutral_conquests: int = 0
@export var must_defeat_all_enemies: bool = true
## Arındırılması zorunlu Erlik odakları (ör. Prolog: Canavarın İni). Boş = koşul yok.
@export var erlik_foci: Array[StringName] = []
@export var description_key: StringName = &""


func is_met(map_state: MapState) -> bool:
	if map_state.get_player_regions().is_empty():
		return false
	if must_defeat_all_enemies and not map_state.get_enemy_regions().is_empty():
		return false
	if conquered_neutral_count(map_state) < required_neutral_conquests:
		return false
	return foci_cleansed(map_state)


## Başlangıçta nötr olup odak olmayan ve şu an oyuncunun elindeki bölge sayısı. Başlangıç
## bölgesi, ele geçirilen düşman bölgeleri ve odaklar sayılmaz (eski `oyuncu − 1` hatası, W7).
func conquered_neutral_count(map_state: MapState) -> int:
	var count: int = 0
	for region: RegionData in map_state.regions.values():
		if region.initial_owner == RegionData.Owner.NEUTRAL \
				and region.region_id not in erlik_foci \
				and region.owner == RegionData.Owner.PLAYER:
			count += 1
	return count


## Listedeki her odak arındırılmış mı (corruption_level == 0); tanımsız odak yok sayılır.
func foci_cleansed(map_state: MapState) -> bool:
	for focus_id: StringName in erlik_foci:
		var focus: RegionData = map_state.get_region(focus_id)
		if focus != null and focus.corruption_level > 0:
			return false
	return true
