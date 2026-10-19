extends GdUnitTestSuite
## Glif kapsamı — ADR-0009 (C-61): her dilin her çevirisi, o dilin native boyutlu pixel
## fontunda çizilebilmeli. Fusion Pixel 12px'te olmayan bir glif zincirde Unifont 16px'e
## düşer ve 12px'te ölçeklenip bozulur; Arapça ise tamamen Unifont 16px'tir.


const CSV_PATH: String = "res://assets/locale/translations.csv"
const SUPPORTED_LOCALE_COUNT: int = 11  # coding-standards: 11 dil
const FUSION_PATHS: Array[String] = [
	"res://assets/fonts/fusion_pixel_12px_latin.woff2",
	"res://assets/fonts/fusion_pixel_12px_ja.woff2",
	"res://assets/fonts/fusion_pixel_12px_ko.woff2",
	"res://assets/fonts/fusion_pixel_12px_zh_hans.woff2",
]
const UNIFONT_PATH: String = "res://assets/fonts/unifont.otf"
## Unifont 16px'e geçen diller (RootContext arabic_font override'ı).
const UNIFONT_LOCALES: Array[String] = ["ar"]

var _saved_locale: String = ""


func before_test() -> void:
	_saved_locale = TranslationServer.get_locale()


func after_test() -> void:
	TranslationServer.set_locale(_saved_locale)


## Key'ler ve dil sütunları çeviri CSV'sinden (içerik verisi). İçe aktarılan çeviriler
## sıkıştırılmış (OptimizedTranslation) olduğundan key listesi TranslationServer'dan alınamaz.
func _keys_and_locales() -> Array:
	var file: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	var header: PackedStringArray = file.get_csv_line()
	var keys: Array[String] = []
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() > 1 and not row[0].is_empty():
			keys.append(row[0])
	var locales: Array[String] = []
	for i: int in range(1, header.size()):
		locales.append(header[i])
	return [keys, locales]


func _missing(text: String, fonts: Array[Font]) -> Array[String]:
	var missing: Array[String] = []
	for i: int in text.length():
		var c: int = text.unicode_at(i)
		if c == 0x20 or c == 0x0A:
			continue
		var covered: bool = false
		for font: Font in fonts:
			if font.has_char(c):
				covered = true
				break
		if not covered:
			missing.append("U+%04X" % c)
	return missing


func test_every_translation_is_covered_by_its_native_font() -> void:
	var fusion: Array[Font] = []
	for path: String in FUSION_PATHS:
		fusion.append(load(path) as Font)
	var unifont: Array[Font] = [load(UNIFONT_PATH) as Font]
	var data: Array = _keys_and_locales()
	assert_int((data[1] as Array).size()).is_equal(SUPPORTED_LOCALE_COUNT)
	assert_int((data[0] as Array).size()).is_greater(0)
	var problems: Array[String] = []
	for locale: String in data[1]:
		TranslationServer.set_locale(locale)
		var fonts: Array[Font] = unifont if locale in UNIFONT_LOCALES else fusion
		for key: String in data[0]:
			var missing: Array[String] = _missing(tr(key), fonts)
			if not missing.is_empty():
				problems.append("%s/%s: %s" % [locale, key, ", ".join(missing)])
	assert_array(problems).override_failure_message("\n".join(problems)).is_empty()


func test_symbols_outside_fusion_are_known() -> void:
	# Bu semboller Fusion Pixel'de yok: metinde kullanılmaz, piksel ikon olarak çizilir
	# (ADR-0009); kayıp işareti için ASCII "-" kullanılır.
	var fusion: Array[Font] = []
	for path: String in FUSION_PATHS:
		fusion.append(load(path) as Font)
	for symbol: String in ["−", "⚠", "✕", "✓", " "]:
		assert_array(_missing(symbol, fusion)).override_failure_message(symbol).is_not_empty()
	for symbol: String in ["↑", "↓", "-", "◆", "…", " "]:
		assert_array(_missing(symbol, fusion)).override_failure_message(symbol).is_empty()
