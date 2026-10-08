extends GdUnitTestSuite
## TamgaLibrary + tamga verisi — art bible §5/§7 (7×7 glif + 1px outline = 9×9).


const ALL_TAMGAS: Array[StringName] = [&"oguz", &"curcet", &"urum", &"kil_barak", &"kuzey", &"guney", &"erlik_beast"]
const ICON_SIZE := Vector2i(9, 9)
const CHAPTER_1: String = "res://features/grid/data/chapter_1_map.tres"


func test_texture_path_follows_naming_convention() -> void:
	assert_str(TamgaLibrary.texture_path(&"curcet")).is_equal("res://assets/art/ui/icons/icon_tamga_curcet.png")


func test_every_tamga_exists_and_is_9x9() -> void:
	var library: TamgaLibrary = TamgaLibrary.new()
	for id: StringName in ALL_TAMGAS:
		var texture: Texture2D = library.get_texture(id)
		assert_object(texture).override_failure_message(String(id)).is_not_null()
		assert_vector(Vector2(texture.get_size())).is_equal(Vector2(ICON_SIZE))


func test_empty_id_has_no_texture() -> void:
	assert_object(TamgaLibrary.new().get_texture(&"")).is_null()


func test_owner_tamga_lookup() -> void:
	var state: MapState = MapState.new()
	state.player_tamga_id = &"oguz"
	state.enemy_tamga_id = &"erlik_beast"
	assert_str(String(state.get_owner_tamga_id(RegionData.Owner.PLAYER))).is_equal("oguz")
	assert_str(String(state.get_owner_tamga_id(RegionData.Owner.ENEMY))).is_equal("erlik_beast")
	assert_str(String(state.get_owner_tamga_id(RegionData.Owner.NEUTRAL))).is_empty()


func test_prolog_map_uses_oguz_and_erlik_beast() -> void:
	var state: MapState = (load(CHAPTER_1) as ChapterMapDefinition).create_map_state()
	assert_str(String(state.player_tamga_id)).is_equal("oguz")
	assert_str(String(state.enemy_tamga_id)).is_equal("erlik_beast")


func test_conquest_switches_region_tamga_to_player() -> void:
	var state: MapState = (load(CHAPTER_1) as ChapterMapDefinition).create_map_state()
	var map: CampaignMap = auto_free(CampaignMap.new()) as CampaignMap
	add_child(map)
	map.build_map(state)
	var enemy: RegionData = state.get_enemy_regions()[0]
	assert_str(_tamga_path(map, enemy.region_id)).is_equal(TamgaLibrary.texture_path(&"erlik_beast"))
	enemy.owner = RegionData.Owner.PLAYER
	map.refresh(state)
	assert_str(_tamga_path(map, enemy.region_id)).is_equal(TamgaLibrary.texture_path(&"oguz"))


func _tamga_path(map: CampaignMap, region_id: StringName) -> String:
	for node: Node in map.get_children():
		var region: RegionNode = node as RegionNode
		if region and region.region_id == region_id:
			var sprite: Sprite2D = region.find_children("*", "Sprite2D", false, false)[0] as Sprite2D
			return sprite.texture.resource_path if sprite.texture else ""
	return ""
