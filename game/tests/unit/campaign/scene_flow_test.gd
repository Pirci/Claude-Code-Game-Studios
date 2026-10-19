extends GdUnitTestSuite
## SceneFlow geçiş tablosu — scene-flow.md §3.3 T1–T23, AC7, AC8 (C-40).


const S := SceneFlow.State

var _flow: SceneFlow = SceneFlow.new()


func _check(state: SceneFlow.State, event: StringName, facts: Dictionary,
		expected: SceneFlow.State, actions: Array[StringName]) -> SceneFlow.FlowStep:
	var step: SceneFlow.FlowStep = _flow.transition(state, event, facts)
	assert_int(step.next_state).override_failure_message("%s + %s" % [S.keys()[state], event]).is_equal(expected)
	assert_array(step.actions).override_failure_message("%s + %s" % [S.keys()[state], event]).is_equal(actions)
	assert_bool(step.ignored).is_false()
	return step


func test_menu_transitions_t1_to_t5() -> void:
	_check(S.MAIN_MENU, SceneFlow.EVENT_NEW_CAMPAIGN, {}, S.INTRO_NARRATIVE, [SceneFlow.ACTION_NEW_STATE])
	_check(S.MAIN_MENU, SceneFlow.EVENT_NEW_CAMPAIGN, {SceneFlow.FACT_HAS_SAVE: true}, S.MAIN_MENU,
		[SceneFlow.ACTION_CONFIRM_NEW_CAMPAIGN])
	_check(S.MAIN_MENU, SceneFlow.EVENT_NEW_CAMPAIGN_CONFIRMED, {}, S.INTRO_NARRATIVE, [SceneFlow.ACTION_NEW_STATE])
	var t3: SceneFlow.FlowStep = _check(S.MAIN_MENU, SceneFlow.EVENT_CONTINUE,
		{SceneFlow.FACT_LOAD_OK: true, SceneFlow.FACT_MAP_PRESENT: true, SceneFlow.FACT_CHAPTER_ID: 2},
		S.PLAYING, [SceneFlow.ACTION_ADOPT_STATE, SceneFlow.ACTION_REBUILD_MODIFIERS])
	assert_int(t3.chapter_id).is_equal(2)
	_check(S.MAIN_MENU, SceneFlow.EVENT_CONTINUE, {SceneFlow.FACT_LOAD_OK: true}, S.CHAPTER_SELECT,
		[SceneFlow.ACTION_ADOPT_STATE])
	_check(S.MAIN_MENU, SceneFlow.EVENT_CONTINUE, {SceneFlow.FACT_LOAD_OK: false}, S.MAIN_MENU,
		[SceneFlow.ACTION_SHOW_LOAD_ERROR])


func test_chapter_select_and_replay_t6_to_t9() -> void:
	var available: Dictionary = {SceneFlow.FACT_CHAPTER_STATE: CampaignRules.ChapterState.AVAILABLE, SceneFlow.FACT_CHAPTER_ID: 2}
	var completed: Dictionary = {SceneFlow.FACT_CHAPTER_STATE: CampaignRules.ChapterState.COMPLETED}
	assert_int(_check(S.CHAPTER_SELECT, SceneFlow.EVENT_START, available, S.INTRO_NARRATIVE, []).chapter_id).is_equal(2)
	assert_bool(_flow.transition(S.CHAPTER_SELECT, SceneFlow.EVENT_START, completed).ignored).is_true()
	_check(S.CHAPTER_SELECT, SceneFlow.EVENT_READ, completed, S.STORY_REPLAY, [])
	assert_bool(_flow.transition(S.CHAPTER_SELECT, SceneFlow.EVENT_READ, available).ignored).is_true()
	_check(S.CHAPTER_SELECT, SceneFlow.EVENT_MENU, {}, S.MAIN_MENU, [])
	_check(S.STORY_REPLAY, SceneFlow.EVENT_PAGES_FINISHED, {}, S.CHAPTER_SELECT, [])


func test_scene_entry_t10_to_t12() -> void:
	var enter: Array[StringName] = [SceneFlow.ACTION_BUILD_MAP, SceneFlow.ACTION_REBUILD_MODIFIERS, SceneFlow.ACTION_CAPTURE_ENTRY]
	_check(S.INTRO_NARRATIVE, SceneFlow.EVENT_PAGES_FINISHED, {SceneFlow.FACT_HAS_KOK_BORI_PAGES: true},
		S.KOK_BORI_MARK_PAGES, [])
	_check(S.INTRO_NARRATIVE, SceneFlow.EVENT_PAGES_FINISHED, {}, S.KOK_BORI_MARK_PANEL, enter)
	_check(S.KOK_BORI_MARK_PAGES, SceneFlow.EVENT_PAGES_FINISHED, {}, S.KOK_BORI_MARK_PANEL, enter)
	_check(S.KOK_BORI_MARK_PANEL, SceneFlow.EVENT_OBJECTIVE_DISMISSED, {}, S.PLAYING, [SceneFlow.ACTION_SAVE_ENTRY])


func test_playing_t13_to_t15() -> void:
	_check(S.PLAYING, SceneFlow.EVENT_GAME_WON, {}, S.VICTORY_BEAT, [])
	_check(S.PLAYING, SceneFlow.EVENT_GAME_LOST, {}, S.DEFEAT, [])
	_check(S.PLAYING, SceneFlow.EVENT_MENU, {SceneFlow.FACT_CONFIRM_LEAVE: true}, S.PLAYING, [SceneFlow.ACTION_CONFIRM_LEAVE])
	_check(S.PLAYING, SceneFlow.EVENT_MENU, {SceneFlow.FACT_CONFIRM_LEAVE: false}, S.MAIN_MENU, [])
	_check(S.PLAYING, SceneFlow.EVENT_LEAVE_CONFIRMED, {}, S.MAIN_MENU, [])


func test_victory_t16_to_t21() -> void:
	var commit: Array[StringName] = [SceneFlow.ACTION_COMMIT_SCENE, SceneFlow.ACTION_SAVE_COMPLETED]
	_check(S.VICTORY_BEAT, SceneFlow.EVENT_VICTORY_ACKNOWLEDGED, {SceneFlow.FACT_PICKS_PENDING: true},
		S.BOON_PICKS, [SceneFlow.ACTION_START_BOON_PICKS])
	_check(S.VICTORY_BEAT, SceneFlow.EVENT_VICTORY_ACKNOWLEDGED, {}, S.OUTRO_NARRATIVE, commit)
	_check(S.BOON_PICKS, SceneFlow.EVENT_BOON_PICKS_FINISHED, {}, S.OUTRO_NARRATIVE, commit)
	_check(S.OUTRO_NARRATIVE, SceneFlow.EVENT_PAGES_FINISHED, {}, S.CHAPTER_SELECT, [])
	_check(S.OUTRO_NARRATIVE, SceneFlow.EVENT_PAGES_FINISHED, {SceneFlow.FACT_IS_LAST_SCENE: true}, S.CAMPAIGN_END, [])
	_check(S.CAMPAIGN_END, SceneFlow.EVENT_PAGES_FINISHED, {}, S.MAIN_MENU, [])


func test_defeat_t22_t23() -> void:
	_check(S.DEFEAT, SceneFlow.EVENT_RETRY, {}, S.KOK_BORI_MARK_PANEL,
		[SceneFlow.ACTION_RESTORE_ENTRY, SceneFlow.ACTION_BUILD_MAP, SceneFlow.ACTION_REBUILD_MODIFIERS])
	_check(S.DEFEAT, SceneFlow.EVENT_MENU, {}, S.MAIN_MENU, [])


# AC7 (tabloda olmayan çift) + AC8 (tek terminal sinyal): ikinci sonuç yok sayılır.
func test_unlisted_pairs_and_second_terminal_signal_are_ignored() -> void:
	for event: StringName in [SceneFlow.EVENT_GAME_LOST, SceneFlow.EVENT_GAME_WON]:
		var step: SceneFlow.FlowStep = _flow.transition(S.VICTORY_BEAT, event, {})
		assert_bool(step.ignored).is_true()
		assert_int(step.next_state).is_equal(S.VICTORY_BEAT)
		assert_array(step.actions).is_empty()
	assert_bool(_flow.transition(S.DEFEAT, SceneFlow.EVENT_GAME_WON, {}).ignored).is_true()
	assert_bool(_flow.transition(S.KOK_BORI_MARK_PANEL, SceneFlow.EVENT_PAGES_FINISHED, {}).ignored).is_true()
	assert_bool(_flow.transition(S.MAIN_MENU, SceneFlow.EVENT_RETRY, {}).ignored).is_true()
