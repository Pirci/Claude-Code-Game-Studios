extends GdUnitTestSuite
## Sahne akışı uçtan uca — RootContext + SceneFlow + bağlamlar ve kayıt noktaları
## (scene-flow.md §8 AC10, AC12, AC15, AC16, AC18, AC19, AC21, AC22; C-40).


const ROOT_SCENE: String = "res://contexts/root_context/root_context.tscn"
const S := SceneFlow.State

var _store: MemorySaveStore


func before_test() -> void:
	TranslationServer.set_locale("en")
	_store = MemorySaveStore.new()


func _root() -> RootContext:
	var root_ctx: RootContext = auto_free((load(ROOT_SCENE) as PackedScene).instantiate()) as RootContext
	root_ctx.save_store = _store
	var config: SceneFlowConfig = SceneFlowConfig.new()
	config.screen_input_guard_s = 0.0
	config.text_reveal_cps = 0.0
	root_ctx.flow_config = config
	add_child(root_ctx)
	return root_ctx


func _press(root_ctx: RootContext, button_name: String) -> void:
	var button: Button = root_ctx.find_child(button_name, true, false) as Button
	assert_object(button).override_failure_message("düğme yok: %s" % button_name).is_not_null()
	button.pressed.emit()


func _game(root_ctx: RootContext) -> GameContext:
	return root_ctx.find_child("GameContext", true, false) as GameContext


func _state(root_ctx: RootContext) -> GameState:
	return root_ctx.get("_game_state") as GameState


## Yeni Sefer → giriş → Kök Böri sayfası → hedef paneli → [Başla] (PLAYING).
func _start_prolog(root_ctx: RootContext) -> void:
	_press(root_ctx, "NewCampaignButton")
	assert_int(root_ctx.flow_state()).is_equal(S.INTRO_NARRATIVE)
	_press(root_ctx, "SkipButton")
	assert_int(root_ctx.flow_state()).is_equal(S.KOK_BORI_MARK_PAGES)
	_press(root_ctx, "SkipButton")
	assert_int(root_ctx.flow_state()).is_equal(S.KOK_BORI_MARK_PANEL)
	_press(root_ctx, "StartButton")
	assert_int(root_ctx.flow_state()).is_equal(S.PLAYING)


func _controller(root_ctx: RootContext) -> MapController:
	return _game(root_ctx).get("_map_controller") as MapController


func _win(root_ctx: RootContext) -> void:
	_state(root_ctx).map_state.game_result = MapState.GameResult.WON
	_controller(root_ctx).game_won.emit()


func _lose(root_ctx: RootContext) -> void:
	_state(root_ctx).map_state.game_result = MapState.GameResult.LOST
	_state(root_ctx).map_state.loss_reason = MapState.LossReason.ERLIK
	_controller(root_ctx).game_lost.emit()


func _saved(slot: StringName) -> GameState:
	var texts: PackedStringArray = _store.read_candidates(slot)
	if texts.is_empty():
		return null
	return SaveSerializer.from_text(texts[0], func(_c: int) -> MapState:
		return (load("res://features/grid/data/chapter_1_map.tres") as ChapterMapDefinition).create_map_state()).state


# AC18: S2 yalnızca hedef paneli kapatılınca; anlatı ve panel sırasında yazım yok.
func test_s2_written_only_when_objective_dismissed() -> void:
	var root_ctx: RootContext = _root()
	_press(root_ctx, "NewCampaignButton")
	_press(root_ctx, "SkipButton")
	_press(root_ctx, "SkipButton")
	assert_int(_store.write_count).is_equal(0)
	_press(root_ctx, "StartButton")
	assert_object(_saved(SaveController.CAMPAIGN_SLOT)).is_not_null()
	var entry: GameState = _saved(SaveController.SCENE_ENTRY_SLOT)
	assert_int(entry.map_state.current_turn).is_equal(1)
	assert_int(entry.gold).is_equal(6)


# AC10 + AC12: zafer → kart → zorunlu seçimler → S3 → çıkış; K=1 → kampanya sonu → menü.
func test_victory_sequence_commits_after_last_pick() -> void:
	var root_ctx: RootContext = _root()
	_start_prolog(root_ctx)
	_state(root_ctx).ruh = 40
	_win(root_ctx)
	assert_int(root_ctx.flow_state()).is_equal(S.VICTORY_BEAT)
	assert_str((root_ctx.find_child("RuhLine", true, false) as Label).text).is_equal("Spirit gained: 40")
	var writes_before: int = _store.write_count
	_press(root_ctx, "ContinueButton")
	assert_int(root_ctx.flow_state()).is_equal(S.BOON_PICKS)
	assert_int(_store.write_count).is_equal(writes_before)
	_press(root_ctx, "Card0")
	await await_idle_frame()
	assert_int(root_ctx.flow_state()).is_equal(S.OUTRO_NARRATIVE)
	var completed: GameState = _saved(SaveController.CAMPAIGN_SLOT)
	assert_object(completed.map_state).is_null()
	assert_array(completed.chapters_completed).is_equal([1])
	assert_int(completed.current_chapter).is_equal(1)
	assert_int(completed.ruh).is_equal(10)
	assert_int(completed.boons.size()).is_equal(1)
	_press(root_ctx, "SkipButton")
	assert_int(root_ctx.flow_state()).is_equal(S.CAMPAIGN_END)
	_press(root_ctx, "SkipButton")
	assert_int(root_ctx.flow_state()).is_equal(S.MAIN_MENU)


# AC10 (k = 0): seçim yoksa lütuf durumu hiç görünmez.
func test_victory_without_spirit_skips_boon_picks() -> void:
	var root_ctx: RootContext = _root()
	_start_prolog(root_ctx)
	_win(root_ctx)
	_press(root_ctx, "ContinueButton")
	assert_int(root_ctx.flow_state()).is_equal(S.OUTRO_NARRATIVE)


# AC15 + AC16: yenilgi yazmaz; Yeniden Dene giriş durumuna döner, hedef paneli gelir.
func test_defeat_writes_nothing_and_retry_restores_entry() -> void:
	var root_ctx: RootContext = _root()
	_start_prolog(root_ctx)
	var state: GameState = _state(root_ctx)
	state.ruh = 40
	(_game(root_ctx).get("_spirit") as SpiritController).pick_boon(1, &"bereket")
	state.gold = 99
	var writes_before: int = _store.write_count
	_lose(root_ctx)
	assert_int(root_ctx.flow_state()).is_equal(S.DEFEAT)
	assert_int(_store.write_count).is_equal(writes_before)
	assert_bool(root_ctx.find_child("ErlikValue", true, false) != null).is_true()
	_press(root_ctx, "RetryButton")
	assert_int(root_ctx.flow_state()).is_equal(S.KOK_BORI_MARK_PANEL)
	state = _state(root_ctx)
	assert_int(state.ruh).is_equal(0)
	assert_array(state.boons).is_empty()
	assert_int(state.gold).is_equal(6)
	assert_int(state.map_state.current_turn).is_equal(1)
	assert_float(StatResolver.resolve(&"gold_income", 0.0, state.modifiers)).is_equal(0.0)
	_press(root_ctx, "StartButton")
	assert_int(root_ctx.flow_state()).is_equal(S.PLAYING)


# AC19: Devam Et yönlendirmesi — harita var → PLAYING, harita yok → CHAPTER_SELECT.
func test_continue_routes_by_saved_map() -> void:
	var playing: GameState = GameState.new()
	playing.map_state = (load("res://features/grid/data/chapter_1_map.tres") as ChapterMapDefinition).create_map_state()
	_store.write(SaveController.CAMPAIGN_SLOT, SaveSerializer.to_text(playing))
	var root_ctx: RootContext = _root()
	_press(root_ctx, "ContinueButton")
	assert_int(root_ctx.flow_state()).is_equal(S.PLAYING)
	assert_object(_game(root_ctx)).is_not_null()

	var done: GameState = GameState.new()
	done.chapters_completed = [1] as Array[int]
	_store = MemorySaveStore.new()
	_store.write(SaveController.CAMPAIGN_SLOT, SaveSerializer.to_text(done))
	var second: RootContext = _root()
	_press(second, "ContinueButton")
	assert_int(second.flow_state()).is_equal(S.CHAPTER_SELECT)
	assert_object(second.find_child("CampaignCompleteBadge", true, false)).is_not_null()
	assert_object(second.find_child("ReadButton", true, false)).is_not_null()
	_press(second, "ReadButton")
	assert_int(second.flow_state()).is_equal(S.STORY_REPLAY)
	_press(second, "SkipButton")
	assert_int(second.flow_state()).is_equal(S.CHAPTER_SELECT)


# AC21: kayıt varken Yeni Sefer onay ister; Hayır kayda dokunmaz.
func test_new_campaign_with_save_asks_first() -> void:
	var saved: GameState = GameState.new()
	saved.ruh = 7
	_store.write(SaveController.CAMPAIGN_SLOT, SaveSerializer.to_text(saved))
	var before: String = _store.read_candidates(SaveController.CAMPAIGN_SLOT)[0]
	var root_ctx: RootContext = _root()
	_press(root_ctx, "NewCampaignButton")
	assert_int(root_ctx.flow_state()).is_equal(S.MAIN_MENU)
	_press(root_ctx, "NoButton")
	assert_str(_store.read_candidates(SaveController.CAMPAIGN_SLOT)[0]).is_equal(before)
	_press(root_ctx, "NewCampaignButton")
	_press(root_ctx, "YesButton")
	assert_int(root_ctx.flow_state()).is_equal(S.INTRO_NARRATIVE)


# AC22: harita sırasında Ana Menü onay ister; Hayır kalır, Evet yazmadan çıkar.
func test_leave_scene_needs_confirmation() -> void:
	var root_ctx: RootContext = _root()
	_start_prolog(root_ctx)
	var writes_before: int = _store.write_count
	_press(root_ctx, "MenuButton")
	_press(root_ctx, "NoButton")
	assert_int(root_ctx.flow_state()).is_equal(S.PLAYING)
	_press(root_ctx, "MenuButton")
	_press(root_ctx, "YesButton")
	assert_int(root_ctx.flow_state()).is_equal(S.MAIN_MENU)
	assert_int(_store.write_count).is_equal(writes_before)
