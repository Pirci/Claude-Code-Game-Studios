extends GdUnitTestSuite
## Gece tamponu — ADR-0010 eki G4 (C-71): düşman sonuçları ve yayılım kararı birikir; oyuncu turu
## bitirince ve oyun bitince temizlenir; oyuncu hamlesi tamponlanmaz.


func _game() -> GameContext:
	var game: GameContext = (load("res://contexts/game_context/game_context.tscn") as PackedScene).instantiate() as GameContext
	game.bind_services(GameState.new(), AccessibilitySettings.new())
	add_child(game)
	auto_free(game)
	return game


func _outcome(mover: RegionData.Owner) -> MoveOutcome:
	var o: MoveOutcome = MoveOutcome.new()
	o.branch = MoveOutcome.Branch.COMBAT
	o.mover = mover
	return o


func test_night_buffer_keeps_enemy_outcomes_only() -> void:
	var game: GameContext = _game()
	game.call("_on_combat_occurred", _outcome(RegionData.Owner.ENEMY))
	game.call("_on_combat_occurred", _outcome(RegionData.Owner.PLAYER))
	assert_int(game.night_outcomes().size()).is_equal(1)


func test_night_buffer_clears_when_player_ends_turn() -> void:
	var game: GameContext = _game()
	game.call("_on_combat_occurred", _outcome(RegionData.Owner.ENEMY))
	game.call("_on_corruption_spread", ErlikSpreadController.SpreadDecision.new())
	game.call("_on_end_turn_pressed")
	# Prolog'da düşman yok; T1 sonu yayılım turu değil → gece boş kalır.
	assert_array(game.night_outcomes()).is_empty()
	assert_object(game.night_spread()).is_null()


func test_night_buffer_records_spread_decision_and_clears_on_game_end() -> void:
	var game: GameContext = _game()
	var decision: ErlikSpreadController.SpreadDecision = ErlikSpreadController.SpreadDecision.new()
	decision.is_spread_turn = true
	decision.target_id = &"dogu_bozkir"
	decision.level_before = 1
	game.call("_on_corruption_spread", decision)
	assert_object(game.night_spread()).is_same(decision)
	game.call("_clear_night")
	game.call("_on_combat_occurred", _outcome(RegionData.Owner.ENEMY))
	game.call("_on_game_lost")
	assert_array(game.night_outcomes()).is_empty()
