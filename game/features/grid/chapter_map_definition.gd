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
	for definition: RegionDefinition in regions:
		var data: RegionData = definition.create_region_data()
		state.regions[data.region_id] = data
	return state
