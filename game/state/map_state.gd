class_name MapState
extends RefCounted
## Haritanın tüm durumunu tutar. Mantık yok, sadece veri.


enum GameResult { ONGOING, WON, LOST }
## Kaybın nedeni — yenilgi ekranı metni için (region-map §3.6, scene-flow §3.7).
enum LossReason { NONE, NO_REGIONS, ERLIK }

var regions: Dictionary = {}  # StringName -> RegionData
## Oyun sonucu; ONGOING dışına bir kez çıkar ve oyunu kilitler (region-map §3.7).
var game_result: GameResult = GameResult.ONGOING
## `game_result == LOST` iken nedeni; aksi halde NONE. Bitmiş durum kaydedilmez (ADR-0007).
var loss_reason: LossReason = LossReason.NONE
var current_turn: int = 1
var actions_remaining: int = 1
var actions_per_turn: int = 1
var enemy_actions_per_turn: int = 1
## Ekonomi adımında düşman bölgesi başına takviye (resource F6) — bölüm içeriğinden.
var enemy_reinforcement_per_turn: int = 1
## Takviye alan bölgeler (enemy-layers §3.5): boş = tüm `ENEMY` bölgeler; doluysa listedeki ve o an
## `ENEMY` olanlar. Bölüm içeriğinden gelir, kaydedilmez (yüklemede harita tanımından kurulur).
var enemy_reinforcement_region_ids: Array[StringName] = []
var selected_region_id: StringName = &""
var chapter_id: int = 1
## Sahip → tamga (art bible §5/§7). Fetihte bölgenin tamgası yeni sahibinkine geçer.
var player_tamga_id: StringName = &""
var enemy_tamga_id: StringName = &""
## Erlik yayılımının taban aralığı (tur) — bölüm içeriğinden gelir (spirit-system.md §4).
var erlik_spread_interval: int = 4
## Son yayılım turunun numarası; sahne başında 0 (spirit-system.md §3.6).
var last_erlik_spread_turn: int = 0


func get_region(region_id: StringName) -> RegionData:
	return regions.get(region_id) as RegionData


## [param owner] sahibinin tamga id'si; nötr bölgeler tamgasızdır (boş).
func get_owner_tamga_id(owner: RegionData.Owner) -> StringName:
	match owner:
		RegionData.Owner.PLAYER:
			return player_tamga_id
		RegionData.Owner.ENEMY:
			return enemy_tamga_id
		_:
			return &""


func get_player_regions() -> Array[RegionData]:
	var result: Array[RegionData] = []
	for region: RegionData in regions.values():
		if region.owner == RegionData.Owner.PLAYER:
			result.append(region)
	return result


func get_enemy_regions() -> Array[RegionData]:
	var result: Array[RegionData] = []
	for region: RegionData in regions.values():
		if region.owner == RegionData.Owner.ENEMY:
			result.append(region)
	return result
