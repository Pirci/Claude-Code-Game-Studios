extends GdUnitTestSuite
## Öğretici akışı uçtan uca — ipucu tetikleri, kalıcılık, HUD hedef/Erlik satırları ve harita
## işareti (C-41; design/ux/prolog-tutorial.md, scene-flow §3.5/§10, spirit AC24).


const ROOT_SCENE: String = "res://contexts/root_context/root_context.tscn"

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
	root_ctx.campaign_seed_source = func() -> int: return 1  # deterministik lütuf sunumu (C-78)
	add_child(root_ctx)
	return root_ctx


func _press(root_ctx: Node, button_name: String) -> void:
	var button: Button = root_ctx.find_child(button_name, true, false) as Button
	assert_object(button).override_failure_message("düğme yok: %s" % button_name).is_not_null()
	button.pressed.emit()


func _start(root_ctx: RootContext) -> GameContext:
	_press(root_ctx, "NewCampaignButton")
	if root_ctx.find_child("YesButton", true, false) != null:  # kayıt varsa Yeni Sefer onay ister
		_press(root_ctx, "YesButton")
	_press(root_ctx, "SkipButton")
	_press(root_ctx, "SkipButton")
	_press(root_ctx, "StartButton")
	return root_ctx.find_child("GameContext", true, false) as GameContext


func _hint_text(root_ctx: Node) -> String:
	var text: Label = root_ctx.find_child("HintText", true, false) as Label
	return text.text if text != null else ""


func _settings_hints() -> Array[StringName]:
	var texts: PackedStringArray = _store.read_candidates(SaveController.SETTINGS_SLOT)
	return SettingsSerializer.from_text(texts[0]).seen_hints if not texts.is_empty() else [] as Array[StringName]


# 1. turda altın yetiyorsa hedef paneli kapanınca "önce üret" ipucu gelir; Anladım kalıcı yazar.
func test_recruit_hint_after_objective_and_persists_when_dismissed() -> void:
	var root_ctx: RootContext = _root()
	var game: GameContext = _start(root_ctx)
	await await_idle_frame()
	assert_str(_hint_text(game)).is_equal(tr("HINT_RECRUIT"))
	assert_array(_settings_hints()).is_empty()
	_press(game, "GotItButton")
	await await_idle_frame()
	assert_str(_hint_text(game)).is_equal("")
	assert_array(_settings_hints()).is_equal([&"recruit"])


# Görülen ipucu bir daha çıkmaz; yeni oturum (yeni RootContext) ayarlardan yükler.
func test_seen_hint_stays_hidden_in_new_session() -> void:
	var first: RootContext = _root()
	var game: GameContext = _start(first)
	await await_idle_frame()
	_press(game, "GotItButton")
	first.queue_free()
	await await_idle_frame()
	var second: RootContext = _root()
	var again: GameContext = _start(second)
	await await_idle_frame()
	assert_str(_hint_text(again)).is_equal("")


# Bozuk bölge seçimi arındırma ipucu verir; balon açıkken başka ipucu kuyruğa girmez.
func test_corrupted_region_hint_and_single_bubble() -> void:
	var root_ctx: RootContext = _root()
	var game: GameContext = _start(root_ctx)
	await await_idle_frame()
	_press(game, "GotItButton")
	game.call("_on_region_clicked", &"sinir_bolge")
	assert_str(_hint_text(game)).is_equal(tr("HINT_CORRUPTED"))
	game.call("_on_region_clicked", &"altai")
	assert_str(_hint_text(game)).is_equal(tr("HINT_CORRUPTED"))


# Ayarlardan "Öğreticiyi Sıfırla" görülenleri siler ve kalıcı yazar.
func test_reset_tutorial_clears_seen_hints() -> void:
	var root_ctx: RootContext = _root()
	var game: GameContext = _start(root_ctx)
	await await_idle_frame()
	_press(game, "GotItButton")
	assert_array(_settings_hints()).is_equal([&"recruit"])
	_press(game, "MenuButton")
	_press(game, "YesButton")
	_press(root_ctx, "SettingsButton")
	_press(root_ctx, "TutorialResetButton")
	assert_array(_settings_hints()).is_empty()


# HUD: hedef metni, ilerleme ve Erlik'in Gölgesi (Prolog 4 / 9); 8 / 9'da uyarı satırı.
func test_hud_shows_objective_progress_and_erlik_shadow_warning() -> void:
	var root_ctx: RootContext = _root()
	var game: GameContext = _start(root_ctx)
	var objective: Label = game.find_child("ObjectiveLabel", true, false) as Label
	assert_str(objective.text).is_equal("%s: %s" % [tr("OBJECTIVE_LABEL"), tr("WIN_CONDITION_CH1")])
	assert_str((game.find_child("ProgressLabel", true, false) as Label).text).contains(NumberFormatter.fraction(0, 3))
	assert_str((game.find_child("ShadowLabel", true, false) as Label).text).is_equal("Erlik's Shadow: %s" % NumberFormatter.fraction(4, 9))
	assert_str(objective.text).starts_with(tr("OBJECTIVE_LABEL"))
	var state: GameState = game.get("_game_state") as GameState
	state.map_state.get_region(&"dogu_bozkir").corruption_level = 3
	state.map_state.get_region(&"sinir_bolge").corruption_level = 3
	state.map_state.get_region(&"altai").corruption_level = 2  # 3 + 3 + 2 = 8 = eşik − 1
	game.call("_refresh_views")
	assert_str((game.find_child("ShadowLabel", true, false) as Label).text).is_equal("Erlik's Shadow: %s" % NumberFormatter.fraction(8, 9))
	assert_str(objective.text).is_equal(tr("ERLIK_SHADOW_WARNING"))


# Hedef işareti Canavarın İni'nde; arındırılınca söner, yayılımla yeniden bozulunca geri gelir (AC6).
func test_objective_marker_follows_corruption() -> void:
	var root_ctx: RootContext = _root()
	var game: GameContext = _start(root_ctx)
	var map: CampaignMap = game.get("_campaign_map") as CampaignMap
	var state: GameState = game.get("_game_state") as GameState
	assert_bool(map.is_region_marked(&"sinir_bolge")).is_true()
	assert_bool(map.is_region_marked(&"altai")).is_false()
	state.map_state.get_region(&"sinir_bolge").corruption_level = 0
	game.call("_refresh_views")
	assert_bool(map.is_region_marked(&"sinir_bolge")).is_false()
	state.map_state.get_region(&"sinir_bolge").corruption_level = 1
	game.call("_refresh_views")
	assert_bool(map.is_region_marked(&"sinir_bolge")).is_true()
