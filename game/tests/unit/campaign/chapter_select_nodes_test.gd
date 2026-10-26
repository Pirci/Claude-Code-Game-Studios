extends GdUnitTestSuite
## E5 sefer haritası M2 düğümleri (C-93; scene-screens E5.3–E5.8): durum ikonları, teaser, odaklanabilir
## kilitli satır + ortak durum satırı, yeni açılma işareti / parıltısı, yalıtılmış güç şeridi, 640×360'a sığma.


const CAMPAIGN: String = "res://features/campaign/data/campaign.tres"
const CATALOG: String = "res://features/bozkurt/data/boon_catalog.tres"
const UNIFONT_PATH: String = "res://assets/fonts/unifont.otf"

var _saved_locale: String = ""
var _fonts: LocaleFontController


func before() -> void:
	_saved_locale = TranslationServer.get_locale()
	_fonts = LocaleFontController.new(ThemeDB.get_project_theme())
	_fonts.add_override("ar", load(UNIFONT_PATH) as Font, 16)


func before_test() -> void:
	TranslationServer.set_locale("en")
	_fonts.apply("en")


func after() -> void:
	TranslationServer.set_locale(_saved_locale)
	_fonts.apply(_saved_locale)


func _state(completed: Array[int], boons: Array[StringName] = []) -> GameState:
	var state: GameState = GameState.new()
	state.chapters_completed = completed
	state.ruh = 10
	state.boons = boons
	return state


func _select(state: GameState, newly_unlocked: int = 0, reduce_motion: bool = false) -> ChapterSelectContext:
	var select: ChapterSelectContext = ChapterSelectContext.new()
	select.bind_services(load(CAMPAIGN) as CampaignDefinition, state, load(CATALOG) as BoonCatalog, 0.0,
		newly_unlocked, reduce_motion)
	add_child(select)
	auto_free(select)
	return select


func _node(select: ChapterSelectContext, chapter_id: int) -> Node:
	return select.find_child("Chapter%d" % chapter_id, true, false)


func _icon(select: ChapterSelectContext, chapter_id: int) -> Texture2D:
	return (_node(select, chapter_id).find_child("StateIcon", true, false) as TextureRect).texture


# E5.6 "M2 ilk giriş": Prolog COMPLETED (tik + Destanı Oku), Perde 1 AVAILABLE (ışık + Başla + CHAPTER_1_TEASER).
func test_chapter_select_nodes_after_prolog_show_icons_and_teaser() -> void:
	var select: ChapterSelectContext = _select(_state([1] as Array[int]))
	assert_object(_icon(select, 1)).is_same(ChapterSelectContext.ICON_COMPLETED)
	assert_object(_node(select, 1).find_child("ReadButton", true, false)).is_not_null()
	assert_object(_node(select, 1).find_child("Teaser", true, false)).is_null()
	assert_object(_icon(select, 2)).is_same(ChapterSelectContext.ICON_AVAILABLE)
	assert_object(_node(select, 2).find_child("StartButton", true, false)).is_not_null()
	var teaser: Label = _node(select, 2).find_child("Teaser", true, false) as Label
	assert_str(teaser.text).is_equal(tr("CHAPTER_1_TEASER"))
	assert_int(teaser.get_visible_line_count()).is_less_equal(2)
	assert_object(select.find_child("LockedButton", true, false)).is_null()


# AC-E5-1 / AC-E5-4: kilitli düğüm kilit ikonu + soluk ad; odaklanabilir; basış eylem yerine ipucu yazar.
func test_chapter_select_locked_node_focusable_and_shows_hint() -> void:
	var select: ChapterSelectContext = _select(_state([] as Array[int]))
	await await_idle_frame()  # ad etiketinin genişliği yerleşimden gelir
	assert_object(_icon(select, 2)).is_same(ChapterSelectContext.ICON_LOCKED)
	assert_object(_node(select, 2).find_child("StartButton", true, false)).is_null()
	var locked: Button = _node(select, 2).find_child("LockedButton", true, false) as Button
	assert_int(locked.focus_mode).is_equal(Control.FOCUS_ALL)
	assert_str(locked.text).is_equal(tr("CHAPTER_2_TITLE"))
	var starts: Array[int] = []
	select.start_requested.connect(func(chapter_id: int) -> void: starts.append(chapter_id))
	locked.pressed.emit()
	assert_array(starts).is_empty()
	var status: Label = select.find_child("StatusLine", true, false) as Label
	assert_str(status.text).is_equal(tr("CHAPTER_LOCKED_HINT"))
	(select.find_child("MenuButton", true, false) as Button).grab_focus()
	(_node(select, 1).find_child("StartButton", true, false) as Button).grab_focus()
	await await_idle_frame()
	assert_str(status.text).is_empty()  # ad sığıyor: tekrar yok
	var name_label: Label = _node(select, 1).find_child("NameLabel", true, false) as Label
	name_label.text = tr("CHAPTER_1_TITLE").repeat(4)  # kesilen ad
	(select.find_child("MenuButton", true, false) as Button).grab_focus()
	(_node(select, 1).find_child("StartButton", true, false) as Button).grab_focus()
	await await_idle_frame()
	assert_str(status.text).is_equal(name_label.text)  # kesilen ad odakta tam (AC-E5-5)


# AC-E5-2: E1 çıkışından gelişte yeni açılan düğüm işaretli ve parlar; Hareketi Azalt'ta sabit; Devam Et'te yok.
func test_chapter_select_unlock_glow_once_and_static_with_reduce_motion() -> void:
	var fresh: ChapterSelectContext = _select(_state([1] as Array[int]), 2)
	assert_object(_node(fresh, 2).find_child("NewMark", true, false)).is_not_null()
	assert_bool(fresh.is_unlock_glowing()).is_true()
	await await_millis(int((ChapterSelectContext.GLOW_FRAMES * ChapterSelectContext.GLOW_FRAME_S + 0.2) * 1000))
	assert_bool(fresh.is_unlock_glowing()).is_false()
	var mark: TextureRect = _node(fresh, 2).find_child("NewMark", true, false) as TextureRect
	assert_bool(mark.visible).is_true()  # parıltı biter, işaret kalır
	assert_object(_icon(fresh, 2)).is_same(ChapterSelectContext.ICON_AVAILABLE)
	var calm: ChapterSelectContext = _select(_state([1] as Array[int]), 2, true)
	assert_object(_node(calm, 2).find_child("NewMark", true, false)).is_not_null()
	assert_bool(calm.is_unlock_glowing()).is_false()
	var resumed: ChapterSelectContext = _select(_state([1] as Array[int]), 0)
	assert_object(_node(resumed, 2).find_child("NewMark", true, false)).is_null()
	assert_bool(resumed.is_unlock_glowing()).is_false()


# AC-E5-3 + AC-E5-7: şerit GameState ile eşleşir; her parça kendi yönünde yalıtılmış.
func test_chapter_select_power_strip_matches_state_and_isolates_parts() -> void:
	var select: ChapterSelectContext = _select(_state([1] as Array[int], [&"bereket", &"bereket", &"gok_kalkani"] as Array[StringName]))
	var strip: Label = select.find_child("PowerStrip", true, false) as Label
	var parts: PackedStringArray = strip.text.split("  ")
	assert_int(parts.size()).is_equal(3)
	for part: String in parts:
		assert_str(part.left(1)).is_equal(NumberFormatter.FIRST_STRONG_ISOLATE)
		assert_str(part.right(1)).is_equal(NumberFormatter.POP_ISOLATE)
	assert_str(parts[0]).contains("10")
	assert_str(strip.text).contains("x2")
	assert_str(strip.text).contains("x1")


# AC-E5-5: en uzun dillerde ve Arapçada panel 640×360'a taşmadan sığar (kilitli ve açık düzenler, dolu şerit).
func test_chapter_select_fits_screen_in_long_locales() -> void:
	var boons: Array[StringName] = [&"arinma_ustaligi", &"bereket", &"gok_kalkani", &"kurt_gucu", &"demir_post"]
	for locale: String in ["de", "ru", "fr", "ar"]:
		TranslationServer.set_locale(locale)
		_fonts.apply(locale)
		for completed: Array[int] in [[] as Array[int], [1] as Array[int], [1, 2] as Array[int]]:
			var select: ChapterSelectContext = _select(_state(completed, boons), 2 if completed.size() == 1 else 0)
			await await_idle_frame()
			var panel: Control = select.find_child("SelectPanel", true, false) as Control
			var size: Vector2 = panel.get_combined_minimum_size()
			assert_float(size.x).override_failure_message("%s %s: %s" % [locale, completed, size]).is_less_equal(640.0)
			assert_float(size.y).override_failure_message("%s %s: %s" % [locale, completed, size]).is_less_equal(360.0)
