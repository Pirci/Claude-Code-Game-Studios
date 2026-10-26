extends GdUnitTestSuite
## Harita bölge adları 11 dilde `RegionNode.LABEL_WIDTH` (96 px) etikete kırpılmadan sığar (C-91; ADR-0009
## native boyut: Fusion 12, Arapça Unifont 16). Kırpma (…) ad okunamaz kılar; çeviri kısaltılır.


const MAPS: Array[String] = [
	"res://features/grid/data/chapter_1_map.tres",
	"res://features/grid/data/chapter_2_map.tres",
]
const UNIFONT_PATH: String = "res://assets/fonts/unifont.otf"
const LOCALES: Array[String] = ["en", "tr", "de", "fr", "es", "zh", "ja", "ko", "ru", "pt", "ar"]
## Harita etiketi dış çizgisi her yönde 1 px (region_node_test).
const OUTLINE_PX: float = 2.0

var _saved_locale: String = ""


func before() -> void:
	_saved_locale = TranslationServer.get_locale()


func after() -> void:
	TranslationServer.set_locale(_saved_locale)


func test_region_names_fit_map_label_in_all_locales() -> void:
	var fusion: Font = ThemeDB.get_project_theme().default_font
	var unifont: Font = load(UNIFONT_PATH) as Font
	var problems: Array[String] = []
	var checked: int = 0
	for locale: String in LOCALES:
		TranslationServer.set_locale(locale)
		var font: Font = unifont if locale == "ar" else fusion
		var size: int = 16 if locale == "ar" else 12
		for path: String in MAPS:
			for region: RegionDefinition in (load(path) as ChapterMapDefinition).regions:
				var text: String = tr(String(region.display_name_key))
				var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + OUTLINE_PX
				checked += 1
				if width > RegionNode.LABEL_WIDTH:
					problems.append("%s/%s: %s (%d px)" % [region.display_name_key, locale, text, int(width)])
	assert_int(checked).is_greater_equal(11 * 13)
	assert_array(problems).override_failure_message("\n".join(problems)).is_empty()
