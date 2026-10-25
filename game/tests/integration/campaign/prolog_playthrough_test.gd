extends GdUnitTestSuite
## Prolog uçtan uca oynanış (C-42, M1 kapanışı): yalnızca oyuncunun kullandığı arayüz yollarıyla —
## menü düğmeleri, bölge tıklaması, Ordu Topla seçicisi, Ordu Gönder, Tur Bitir, modallar.
## Yeni Sefer → anlatı → hedef → A çizgisi (T5 zafer) → sonuç kartı → zorunlu lütuf → çıkış →
## kampanya sonu → menü → Devam Et → tamamlanmış sefer haritası.


const ROOT_SCENE: String = "res://contexts/root_context/root_context.tscn"
const S := SceneFlow.State

var _store: MemorySaveStore
var _root_ctx: RootContext


func before_test() -> void:
	TranslationServer.set_locale("en")
	_store = MemorySaveStore.new()
	_root_ctx = auto_free((load(ROOT_SCENE) as PackedScene).instantiate()) as RootContext
	_root_ctx.save_store = _store
	var config: SceneFlowConfig = SceneFlowConfig.new()
	config.screen_input_guard_s = 0.0
	config.text_reveal_cps = 0.0
	_root_ctx.flow_config = config
	_root_ctx.campaign_seed_source = func() -> int: return 1  # deterministik lütuf sunumu (C-78)
	add_child(_root_ctx)


func _press(button_name: String) -> void:
	var button: Button = _root_ctx.find_child(button_name, true, false) as Button
	assert_object(button).override_failure_message("düğme yok: %s" % button_name).is_not_null()
	assert_bool(button.disabled).override_failure_message("pasif: %s" % button_name).is_false()
	button.pressed.emit()


func _game() -> GameContext:
	return _root_ctx.find_child("GameContext", true, false) as GameContext


func _state() -> GameState:
	return _root_ctx.get("_game_state") as GameState


func _click(region_id: StringName) -> void:
	_game().call("_on_region_clicked", region_id)


## Bölgeyi seçip Ordu Topla seçicisiyle [param count] birlik üretir, seçimi kaldırır.
func _recruit(region_id: StringName, count: int) -> void:
	_click(region_id)
	for i: int in count - 1:
		_press("RecruitPlus")
	_press("RecruitConfirm")
	_click(region_id)


func _send(from_id: StringName, to_id: StringName) -> void:
	_click(from_id)
	_press("SendArmyButton")
	_click(to_id)
	_dismiss_reports()


## Oyuncu hamlesi raporu (C-72) hamleden sonra açılır; [Devam] ile kapatılır.
## Tur sonu: gece olaylıysa (Prolog'da yayılım) özet açılır; okunup kapatılır (C-73).
func _end_turn() -> void:
	_press("EndTurnButton")
	_dismiss_reports()


func _dismiss_reports() -> void:
	for report_name: String in ["BattleReport", "PurificationReport", "TurnSummaryReport"]:
		var report: Node = _root_ctx.find_child(report_name, true, false)
		if report != null:
			var button: Button = report.find_child("ContinueButton", true, false) as Button
			assert_bool(button.disabled).is_false()
			button.pressed.emit()


func _dismiss_hints() -> void:
	while _root_ctx.find_child("GotItButton", true, false) != null:
		_press("GotItButton")


func test_prolog_plays_from_new_campaign_to_kagan_and_back_to_menu() -> void:
	_press("NewCampaignButton")
	_press("SkipButton")
	_press("SkipButton")
	assert_int(_root_ctx.flow_state()).is_equal(S.KOK_BORI_MARK_PANEL)
	_press("StartButton")
	await await_idle_frame()
	_dismiss_hints()

	# A çizgisi (prolog_balance_test ile aynı; burada arayüzden).
	_recruit(&"otuken", 2); _send(&"otuken", &"altai"); _dismiss_hints(); _end_turn()
	_recruit(&"otuken", 2); _send(&"otuken", &"guney_vadi"); _recruit(&"guney_vadi", 1); _end_turn()
	_dismiss_hints()
	_recruit(&"guney_vadi", 3); _send(&"altai", &"bati_bozkir"); _end_turn()
	_dismiss_hints()
	_recruit(&"guney_vadi", 3); _recruit(&"bati_bozkir", 1); _send(&"bati_bozkir", &"guney_vadi"); _end_turn()
	_dismiss_hints()
	assert_int(_state().map_state.current_turn).is_equal(5)
	_recruit(&"guney_vadi", 3)
	_click(&"guney_vadi")
	_press("SendArmyButton")
	_click(&"sinir_bolge")
	# Canavar ini Erlik odağı: arındırma raporu Prolog ritüel başlığıyla, zafer kartından önce.
	var report: Node = _root_ctx.find_child("PurificationReport", true, false)
	assert_object(report).is_not_null()
	assert_str((report.find_child("Heading", true, false) as Label).text).is_equal(tr("CHAPTER_1_SLAIN_HEADING"))
	_dismiss_reports()

	assert_int(_root_ctx.flow_state()).is_equal(S.VICTORY_BEAT)
	assert_int(_state().ruh).is_equal(30)
	_press("ContinueButton")
	assert_int(_root_ctx.flow_state()).is_equal(S.BOON_PICKS)
	_press("Card0")
	await await_idle_frame()
	assert_int(_root_ctx.flow_state()).is_equal(S.OUTRO_NARRATIVE)
	_press("ContinueButton")
	_press("ContinueButton")
	assert_int(_root_ctx.flow_state()).is_equal(S.CAMPAIGN_END)
	_press("SkipButton")
	assert_int(_root_ctx.flow_state()).is_equal(S.MAIN_MENU)

	# S3 kaydı: tamamlanmış Prolog; Devam Et salt-okunur sefer haritasını açar.
	_press("ContinueButton")
	assert_int(_root_ctx.flow_state()).is_equal(S.CHAPTER_SELECT)
	assert_array(_state().chapters_completed).is_equal([1])
	assert_int(_state().boons.size()).is_equal(1)
	assert_object(_root_ctx.find_child("CampaignCompleteBadge", true, false)).is_not_null()
