extends GdUnitTestSuite
## HUD + bilgi paneli M2 görünümleri (C-88; hud.md §5.1–§5.5, H5, H6, H10, L3, B4): Kağan vuruş eşiği satırı,
## takviye satırı liste süzgeci, Gölge hücresinin yayılım / odak segmenti, düşman bölgesi sayacı.


const S := RegionData.Owner


func before_test() -> void:
	TranslationServer.set_locale("en")


## Prolog haritası üzerinde: Batı Bozkır düşman (başkent), Altai düşman (listede değil), R1 açık.
func _game(strike_enabled: bool = true) -> GameContext:
	var state: GameState = GameState.new()
	var game: GameContext = (load("res://contexts/game_context/game_context.tscn") as PackedScene).instantiate() as GameContext
	game.bind_services(state, AccessibilitySettings.new())
	add_child(game)
	auto_free(game)
	var m: MapState = state.map_state
	m.get_region(&"bati_bozkir").owner = S.ENEMY
	m.get_region(&"bati_bozkir").army_count = 6
	m.get_region(&"altai").owner = S.ENEMY
	m.get_region(&"altai").army_count = 2
	m.get_region(&"otuken").army_count = 4
	m.enemy_reinforcement_region_ids.assign([&"bati_bozkir"])
	var profile: EnemyAIProfile = EnemyAIProfile.new()
	profile.strike_enabled = strike_enabled
	(game.get("_enemy_ai") as EnemyAIController).bind_config(profile)
	return game


func _select(game: GameContext, region_id: StringName) -> void:
	game.call("_on_region_clicked", region_id)


func _label(game: GameContext, node_name: String) -> Label:
	return game.find_child(node_name, true, false) as Label


# H5: düşmana komşu oyuncu bölgesinde eşik (P_eff 4 → 6); lütufla artar; nötr/düşman bölgede yok.
func test_info_panel_strike_threshold_row() -> void:
	var game: GameContext = _game()
	_select(game, &"otuken")
	var row: Label = _label(game, "StrikeThresholdLabel")
	assert_bool(row.visible).is_true()
	assert_str(row.text).contains("6")
	var state: GameState = game.get("_game_state") as GameState
	state.boons.assign([&"demir_post", &"demir_post"])
	(game.get("_spirit") as SpiritController).rebuild_boon_modifiers()
	game.call("_refresh_views")
	assert_str(row.text).contains("9")  # P_eff 6 → max(7, 9) = 9
	game.call("_on_controller_region_deselected")
	_select(game, &"dogu_bozkir")  # nötr
	assert_bool(row.visible).is_false()
	game.call("_on_controller_region_deselected")
	_select(game, &"altai")  # düşman
	assert_bool(row.visible).is_false()


func test_info_panel_strike_row_hidden_when_r1_off_or_not_bordering_enemy() -> void:
	var off: GameContext = _game(false)
	_select(off, &"otuken")
	assert_bool(_label(off, "StrikeThresholdLabel").visible).is_false()
	var game: GameContext = _game()
	var state: GameState = game.get("_game_state") as GameState
	state.map_state.get_region(&"guney_vadi").owner = S.PLAYER  # komşuları otuken, bati(düşman), sinir
	state.map_state.get_region(&"bati_bozkir").owner = S.NEUTRAL
	state.map_state.get_region(&"altai").owner = S.NEUTRAL
	_select(game, &"otuken")
	assert_bool(_label(game, "StrikeThresholdLabel").visible).is_false()


# H6: takviye satırı yalnız listedeki düşman bölgesinde; liste boşsa her düşman bölgesinde.
func test_info_panel_reinforcement_row_follows_region_list() -> void:
	var game: GameContext = _game()
	_select(game, &"bati_bozkir")
	assert_bool((game.find_child("ReinforcementRow", true, false) as Control).visible).is_true()
	game.call("_on_controller_region_deselected")
	_select(game, &"altai")
	assert_bool((game.find_child("ReinforcementRow", true, false) as Control).visible).is_false()
	(game.get("_game_state") as GameState).map_state.enemy_reinforcement_region_ids.clear()
	game.call("_on_controller_region_deselected")
	_select(game, &"altai")
	assert_bool((game.find_child("ReinforcementRow", true, false) as Control).visible).is_true()


# H10 / L3: yayılım segmenti geri sayar, N = 0'da metin değişir ve kırmızı; odaksa "Odak tehlikede" + ikon.
func test_hud_spread_segment_text_and_focus_swap() -> void:
	var game: GameContext = _game()
	var m: MapState = (game.get("_game_state") as GameState).map_state
	var label: Label = _label(game, "SpreadLabel")
	var icon: TextureRect = game.find_child("SpreadIcon", true, false) as TextureRect
	assert_str(label.text).is_equal(tr("SPREAD_COUNTDOWN") % NumberFormatter.ltr("2"))  # T1, aralık 3, son 0
	assert_bool(icon.visible).is_false()
	m.current_turn = 3
	game.call("_refresh_views")
	assert_str(label.text).is_equal(tr("SPREAD_THIS_TURN_END"))
	assert_bool(icon.visible).is_false()
	# Odağı (sinir_bolge) yayılım hedefi yap: L2, bozuk komşu, diğer adayların ordusu daha büyük.
	m.get_region(&"sinir_bolge").corruption_level = 2
	m.get_region(&"dogu_bozkir").corruption_level = 1
	m.get_region(&"dogu_bozkir").army_count = 5
	m.get_region(&"guney_vadi").army_count = 5
	game.call("_refresh_views")
	assert_str(label.text).is_equal(tr("FOCUS_AT_RISK") % tr("REGION_SINIR_BOLGE"))
	assert_bool(icon.visible).is_true()
	assert_bool(label.visible).is_true()
	assert_int(label.get_theme_color(&"font_color").to_rgba32()).is_equal(RegionInfoPanel.COLOR_LOSS.to_rgba32())


# H9: düşman sayacı ilerleme satırında (sahne başında düşman yoksa görünmez — Prolog).
func test_hud_enemy_counter_only_with_initial_enemies() -> void:
	var game: GameContext = _game()
	assert_str(_label(game, "ProgressLabel").text).not_contains(tr("PROGRESS_ENEMY_REGIONS").split(":")[0])
	var m: MapState = (game.get("_game_state") as GameState).map_state
	m.enemy_region_ids_initial.assign([&"bati_bozkir", &"altai"])
	m.get_region(&"altai").owner = S.PLAYER
	game.call("_refresh_views")
	assert_str(_label(game, "ProgressLabel").text).contains(
		tr("PROGRESS_ENEMY_REGIONS") % NumberFormatter.fraction(1, 2))
