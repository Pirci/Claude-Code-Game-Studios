extends GdUnitTestSuite
## Sahne akışı formülleri — scene-flow.md §4 F1/F2/F3/F7, AC1–AC6, AC15b (C-40).


const PROLOG_MAP: String = "res://features/grid/data/chapter_1_map.tres"

var _config: SpiritConfig = SpiritConfig.new()


func _states(completed: Array[int], count: int) -> Array:
	var result: Array = []
	for c: int in range(1, count + 1):
		result.append(CampaignRules.chapter_state(c, completed))
	return result


# AC1 (F1)
func test_chapter_states_and_next_chapter() -> void:
	var L := CampaignRules.ChapterState
	assert_array(_states([] as Array[int], 3)).is_equal([L.AVAILABLE, L.LOCKED, L.LOCKED])
	assert_array(_states([1] as Array[int], 3)).is_equal([L.COMPLETED, L.AVAILABLE, L.LOCKED])
	assert_array(_states([1, 2, 3] as Array[int], 3)).is_equal([L.COMPLETED, L.COMPLETED, L.COMPLETED])
	assert_int(CampaignRules.next_chapter([] as Array[int], 3)).is_equal(1)
	assert_int(CampaignRules.next_chapter([1] as Array[int], 3)).is_equal(2)
	assert_int(CampaignRules.next_chapter([1, 2, 3] as Array[int], 3)).is_equal(0)
	var state: GameState = GameState.new()
	state.chapters_completed = [1] as Array[int]
	for c: int in range(1, 4):
		assert_bool(state.is_chapter_unlocked(c)).is_equal(CampaignRules.is_unlocked(c, state.chapters_completed))


# AC2 (F1 geçerlilik)
func test_completion_validity() -> void:
	assert_bool(CampaignRules.is_valid_completion([2] as Array[int], 3)).is_false()
	assert_bool(CampaignRules.is_valid_completion([1, 3] as Array[int], 3)).is_false()
	assert_bool(CampaignRules.is_valid_completion([1, 4] as Array[int], 3)).is_false()
	assert_bool(CampaignRules.is_valid_completion([1, 2] as Array[int], 3)).is_true()


# AC3 (F7 COMMIT, idempotent)
func test_commit_scene_is_idempotent() -> void:
	var state: GameState = GameState.new()
	state.gold = 9
	state.map_state = MapState.new()
	CampaignRules.commit_scene(state, 1, 6)
	CampaignRules.commit_scene(state, 1, 6)
	assert_array(state.chapters_completed).is_equal([1])
	assert_int(state.current_chapter).is_equal(2)
	assert_object(state.map_state).is_null()
	assert_int(state.gold).is_equal(0)
	var demo: GameState = GameState.new()
	CampaignRules.commit_scene(demo, 1, 1)
	assert_int(demo.current_chapter).is_equal(1)


# AC4 (F2)
func test_victory_pick_count_matches_examples() -> void:
	var cases: Array = [[29, 0, 0], [30, 0, 1], [40, 0, 1], [79, 0, 1], [80, 0, 2], [100, 2, 1], [150, 0, 3], [10000, 0, 8]]
	for c: Array in cases:
		assert_int(CampaignRules.victory_pick_count(c[0], c[1], -1, _config)) \
			.override_failure_message("ruh %d n %d" % [c[0], c[1]]).is_equal(c[2])


# AC5 (F3)
func test_ruh_gained_adds_back_spending() -> void:
	assert_int(CampaignRules.ruh_gained(20, 1, 0, 0, _config)).is_equal(50)
	assert_int(CampaignRules.ruh_gained(30, 0, 0, 0, _config)).is_equal(30)


# AC6 (F7 hedef kümesi)
func test_objective_markers_follow_corruption() -> void:
	var definition: ChapterMapDefinition = load(PROLOG_MAP) as ChapterMapDefinition
	var map_state: MapState = definition.create_map_state()
	var scene: SceneDefinition = SceneDefinition.new()
	assert_array(CampaignRules.objective_markers(map_state, definition.win_condition, scene)).is_equal([&"sinir_bolge"])
	map_state.get_region(&"sinir_bolge").corruption_level = 0
	assert_array(CampaignRules.objective_markers(map_state, definition.win_condition, scene)).is_empty()
	map_state.get_region(&"sinir_bolge").corruption_level = 1
	assert_array(CampaignRules.objective_markers(map_state, definition.win_condition, scene)).is_equal([&"sinir_bolge"])


# AC15b (yenilgi metni)
func test_defeat_text_key_falls_back_by_reason() -> void:
	var scene: SceneDefinition = SceneDefinition.new()
	assert_str(CampaignRules.defeat_text_key(scene, MapState.LossReason.ERLIK)).is_equal("DEFEAT_REASON_ERLIK")
	assert_str(CampaignRules.defeat_text_key(scene, MapState.LossReason.NO_REGIONS)).is_equal("DEFEAT_REASON_NO_REGIONS")
	assert_str(CampaignRules.defeat_text_key(scene, MapState.LossReason.NONE)).is_equal("DEFEAT_REASON_GENERIC")
	assert_str(CampaignRules.defeat_text_key(scene, 99 as MapState.LossReason)).is_equal("DEFEAT_REASON_GENERIC")
	scene.defeat_text_key = &"CUSTOM_DEFEAT"
	assert_str(CampaignRules.defeat_text_key(scene, MapState.LossReason.ERLIK)).is_equal("CUSTOM_DEFEAT")
