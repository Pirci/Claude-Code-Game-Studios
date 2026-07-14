@tool
class_name RegionDefinition
extends Resource
## Bir bölgenin editörde tanımlanan başlangıç değerleri.


@export var region_id: StringName = &""
@export var display_name_key: StringName = &""
@export var owner: RegionData.Owner = RegionData.Owner.NEUTRAL
@export var starting_army: int = 0
@export var gold_per_turn: int = 0
@export var position: Vector2 = Vector2.ZERO
@export var polygon_points: PackedVector2Array = PackedVector2Array()
@export var adjacent_region_ids: Array[StringName] = []


func create_region_data() -> RegionData:
	var data: RegionData = RegionData.new()
	data.region_id = region_id
	data.display_name_key = display_name_key
	data.owner = owner
	data.army_count = starting_army
	data.gold_per_turn = gold_per_turn
	data.position = position
	data.polygon_points = polygon_points
	data.adjacent_regions = adjacent_region_ids.duplicate()
	return data
