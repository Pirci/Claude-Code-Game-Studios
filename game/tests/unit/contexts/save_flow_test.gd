extends GdUnitTestSuite
## Kayıt akışı — Devam Et ve tur sonu otomatik kayıt (ADR-0007, C-17 D4; C-56).


const ROOT_SCENE: String = "res://contexts/root_context/root_context.tscn"
const PROLOG_MAP: String = "res://features/grid/data/chapter_1_map.tres"


func _saved_campaign(turn: int, gold: int) -> String:
	var state: GameState = GameState.new()
	state.gold = gold
	state.map_state = (load(PROLOG_MAP) as ChapterMapDefinition).create_map_state()
	state.map_state.current_turn = turn
	return SaveSerializer.to_text(state)


func _root(store: MemorySaveStore) -> RootContext:
	var root_ctx: RootContext = auto_free((load(ROOT_SCENE) as PackedScene).instantiate()) as RootContext
	root_ctx.save_store = store
	add_child(root_ctx)
	return root_ctx


func _game(root_ctx: RootContext) -> GameContext:
	for child: Node in root_ctx.get_children():
		if child is GameContext:
			return child as GameContext
	return null


func test_continue_opens_the_saved_turn() -> void:
	var store: MemorySaveStore = MemorySaveStore.new()
	store.write(SaveController.CAMPAIGN_SLOT, _saved_campaign(4, 9))
	var root_ctx: RootContext = _root(store)
	var continue_button: Button = root_ctx.find_child("ContinueButton", true, false) as Button
	assert_bool(continue_button.disabled).is_false()
	continue_button.pressed.emit()
	var game: GameContext = _game(root_ctx)
	assert_object(game).is_not_null()
	var turn_label: Label = game.find_child("TurnLabel", true, false) as Label
	var gold_label: Label = game.find_child("GoldLabel", true, false) as Label
	assert_str(turn_label.text).ends_with("4")
	assert_str(gold_label.text).ends_with("9")


func test_continue_is_disabled_without_a_save() -> void:
	var root_ctx: RootContext = _root(MemorySaveStore.new())
	assert_bool((root_ctx.find_child("ContinueButton", true, false) as Button).disabled).is_true()


func test_end_turn_autosaves_the_campaign() -> void:
	var store: MemorySaveStore = MemorySaveStore.new()
	var root_ctx: RootContext = _root(store)
	(root_ctx.find_child("NewCampaignButton", true, false) as Button).pressed.emit()
	(root_ctx.find_child("EndTurnButton", true, false) as Button).pressed.emit()
	var saved: PackedStringArray = store.read_candidates(SaveController.CAMPAIGN_SLOT)
	assert_int(saved.size()).is_equal(1)
	var result: LoadResult = SaveSerializer.from_text(saved[0],
		func(_chapter: int) -> MapState: return (load(PROLOG_MAP) as ChapterMapDefinition).create_map_state())
	assert_int(result.code).is_equal(LoadResult.Code.OK)
	assert_int(result.state.map_state.current_turn).is_equal(2)
