extends GdUnitTestSuite
## L6 / AC-E1-7 (scene-flow §3.10 F4, scene-screens §0.8; C-91): her anlatı sayfası 11 dilde gerçek
## `NarrativeContext` panelinde native fontla sığar — başlıksız ≤ 3, başlıklı ≤ 2 satır. Arapça RootContext
## gibi temanın tamamını Unifont 16'ya geçirir (LocaleFontController).


const CAMPAIGN: String = "res://features/campaign/data/campaign.tres"
const UNIFONT_PATH: String = "res://assets/fonts/unifont.otf"
const LOCALES: Array[String] = ["en", "tr", "de", "fr", "es", "zh", "ja", "ko", "ru", "pt", "ar"]
const MAX_LINES_UNTITLED: int = 3
const MAX_LINES_TITLED: int = 2

var _saved_locale: String = ""
var _fonts: LocaleFontController


func before() -> void:
	_saved_locale = TranslationServer.get_locale()
	_fonts = LocaleFontController.new(ThemeDB.get_project_theme())
	_fonts.add_override("ar", load(UNIFONT_PATH) as Font, 16)


func after() -> void:
	TranslationServer.set_locale(_saved_locale)
	_fonts.apply(_saved_locale)


func _pages() -> Array[NarrativePage]:
	var campaign: CampaignDefinition = load(CAMPAIGN) as CampaignDefinition
	var pages: Array[NarrativePage] = []
	for scene: SceneDefinition in campaign.scenes:
		pages.append_array(scene.intro_pages + scene.kok_bori_pages + scene.outro_pages)
	pages.append_array(campaign.end_pages)
	return pages


## Sayfayı gerçek panelde gösterir ve sarılmış metin satırı sayısını döndürür.
func _line_count(page: NarrativePage) -> int:
	var config: SceneFlowConfig = SceneFlowConfig.new()
	config.screen_input_guard_s = 0.0
	config.text_reveal_cps = 0.0
	var context: NarrativeContext = NarrativeContext.new()
	context.bind_services([page] as Array[NarrativePage], config, AccessibilitySettings.new())
	add_child(context)
	auto_free(context)
	await await_idle_frame()
	var label: Label = context.find_child("TextLabel", true, false) as Label
	return label.get_line_count()


func test_narrative_pages_fit_panel_in_all_locales() -> void:
	var problems: Array[String] = []
	var checked: int = 0
	for locale: String in LOCALES:
		TranslationServer.set_locale(locale)
		_fonts.apply(locale)
		for page: NarrativePage in _pages():
			var limit: int = MAX_LINES_TITLED if page.title_key != &"" else MAX_LINES_UNTITLED
			var lines: int = await _line_count(page)
			checked += 1
			if lines > limit:
				problems.append("%s/%s: %d > %d" % [page.text_key, locale, lines, limit])
	assert_int(checked).is_greater_equal(11 * 10)
	assert_array(problems).override_failure_message("\n".join(problems)).is_empty()


# Ölçümün kendisi: 220 karakterlik Prolog sayfası 2-3 satır, iki katı metin 3'ü aşar (genişlik sıfır değil).
func test_narrative_page_fit_measurement_wraps() -> void:
	TranslationServer.set_locale("en")
	_fonts.apply("en")
	var page: NarrativePage = NarrativePage.new()
	page.text_key = &"CHAPTER_1_INTRO_2"
	assert_int(await _line_count(page)).is_between(2, 3)
	var long_page: NarrativePage = NarrativePage.new()
	long_page.text_key = StringName(tr("CHAPTER_1_INTRO_2") + " " + tr("CHAPTER_1_OUTRO_1"))
	assert_int(await _line_count(long_page)).is_greater(MAX_LINES_UNTITLED)
