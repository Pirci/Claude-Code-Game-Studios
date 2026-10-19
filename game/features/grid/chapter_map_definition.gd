@tool
class_name ChapterMapDefinition
extends Resource
## Bir bölümün harita tanımı — bölgeler, kazanma koşulu, tur başına aksiyon.


@export var chapter_id: int = 1
@export var chapter_name_key: StringName = &""
@export var actions_per_turn: int = 1
@export var enemy_actions_per_turn: int = 1
## Tamga id'leri → icon_tamga_<id>.png (TamgaLibrary). Oyuncu tamgası sabit Oğuz "kaşu".
@export var player_tamga_id: StringName = &"oguz"
## Bölümün düşman kralı / yaratığının tamgası (Prolog: Erlik canavarı).
@export var enemy_tamga_id: StringName = &""
## Harita zemini ve komşuluk çizgisi (art bible §4 "Yön Başına Sıcaklık"): bölüm başına,
## yalnızca global palet tonları. Çizgi opaktır — yarı saydam çizgi palet dışı ton üretir.
## Kural: çizgi = zeminin rampasında iki ton açık.
@export var ground_color: Color = Color("#1A2614")         # Bozkır Yeşili 2
@export var adjacency_line_color: Color = Color("#436129") # Bozkır Yeşili 4
## Erlik yayılımının bölüm taban aralığı (tur; spirit §4.6 — Prolog 3, C-49).
@export var erlik_spread_interval: int = 3
@export var regions: Array[RegionDefinition] = []
@export var win_condition: WinCondition = null


func create_map_state() -> MapState:
	var state: MapState = MapState.new()
	state.chapter_id = chapter_id
	state.actions_per_turn = actions_per_turn
	state.actions_remaining = actions_per_turn
	state.enemy_actions_per_turn = enemy_actions_per_turn
	state.player_tamga_id = player_tamga_id
	state.enemy_tamga_id = enemy_tamga_id
	state.erlik_spread_interval = erlik_spread_interval
	for definition: RegionDefinition in regions:
		var data: RegionData = definition.create_region_data()
		state.regions[data.region_id] = data
	return state
