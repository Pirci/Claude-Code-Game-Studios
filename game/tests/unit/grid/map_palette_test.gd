extends GdUnitTestSuite
## Harita zemini ve komşuluk çizgileri palete bağlı ve data-driven — art bible §4
## "Yön Başına Sıcaklık" (C-22). Beklenen hex'ler art-source/global_palette_ulus.gpl'dedir.


const PROLOG_MAP: String = "res://features/grid/data/chapter_1_map.tres"
const GAME_SCENE: String = "res://contexts/game_context/game_context.tscn"
const PROLOG_GROUND: String = "1a2614"  # Bozkır Yeşili 2
const PROLOG_LINE: String = "436129"    # Bozkır Yeşili 4


func test_prolog_defines_palette_ground_and_line_colors() -> void:
	var def: ChapterMapDefinition = load(PROLOG_MAP) as ChapterMapDefinition
	assert_str(def.ground_color.to_html(false)).is_equal(PROLOG_GROUND)
	assert_str(def.adjacency_line_color.to_html(false)).is_equal(PROLOG_LINE)


func test_adjacency_line_color_is_opaque() -> void:
	var def: ChapterMapDefinition = load(PROLOG_MAP) as ChapterMapDefinition
	assert_float(def.adjacency_line_color.a).is_equal(1.0)
	var drawer: AdjacencyLineDrawer = auto_free(AdjacencyLineDrawer.new()) as AdjacencyLineDrawer
	assert_float(drawer.line_color.a).is_equal(1.0)


func test_campaign_map_applies_line_color_before_and_after_build() -> void:
	var map: CampaignMap = auto_free(CampaignMap.new()) as CampaignMap
	add_child(map)
	var custom: Color = Color("#4A453C")  # Keçe Grisi 3
	map.set_line_color(custom)
	map.build_map(MapState.new())
	var drawer: AdjacencyLineDrawer = map.get("_line_drawer") as AdjacencyLineDrawer
	assert_str(drawer.line_color.to_html(false)).is_equal("4a453c")
	map.set_line_color(Color("#436129"))
	assert_str(drawer.line_color.to_html(false)).is_equal(PROLOG_LINE)


func test_game_background_uses_chapter_ground_color() -> void:
	var game: GameContext = (load(GAME_SCENE) as PackedScene).instantiate() as GameContext
	game.bind_services(GameState.new(), AccessibilitySettings.new())
	add_child(game)
	auto_free(game)
	var background: ColorRect = game.find_child("Background", true, false) as ColorRect
	assert_str(background.color.to_html(false)).is_equal(PROLOG_GROUND)
