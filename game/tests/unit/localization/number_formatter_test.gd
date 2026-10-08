extends GdUnitTestSuite
## NumberFormatter — art bible §7 "Sayılar": binlik ayırıcı dile göre çeviri key'inden.


## Kırılmaz boşluk (fr/ru ayırıcısı).
const NBSP: String = "\u00A0"
const LOCALE_SEPARATORS: Dictionary = {
	"en": ",", "tr": ".", "de": ".", "fr": NBSP, "es": ".", "zh": ",",
	"ja": ",", "ko": ",", "ru": NBSP, "pt": ".", "ar": ",",
}

var _saved_locale: String = ""


func before_test() -> void:
	_saved_locale = TranslationServer.get_locale()


func after_test() -> void:
	TranslationServer.set_locale(_saved_locale)


func test_groups_by_three_from_the_right() -> void:
	assert_str(NumberFormatter.group_digits(1234567, ",")).is_equal("1,234,567")
	assert_str(NumberFormatter.group_digits(123456, ".")).is_equal("123.456")
	assert_str(NumberFormatter.group_digits(1000, ",")).is_equal("1,000")


func test_numbers_below_one_thousand_are_unchanged() -> void:
	for value: int in [0, 7, 42, 999]:
		assert_str(NumberFormatter.group_digits(value, ",")).is_equal(str(value))


func test_negative_keeps_sign_in_front() -> void:
	assert_str(NumberFormatter.group_digits(-1234, ".")).is_equal("-1.234")
	assert_str(NumberFormatter.group_digits(-12, ",")).is_equal("-12")


func test_each_locale_uses_its_separator() -> void:
	for locale: String in LOCALE_SEPARATORS:
		TranslationServer.set_locale(locale)
		var expected: String = LOCALE_SEPARATORS[locale]
		assert_str(NumberFormatter.current_separator()).override_failure_message(locale).is_equal(expected)
		assert_str(NumberFormatter.format_int(12345)).override_failure_message(locale).is_equal("12" + expected + "345")


func test_separator_glyphs_exist_in_ui_font() -> void:
	# Fusion Pixel Latin'de U+202F yok → fr/ru için U+00A0 seçildi; tema fontu çizebilmeli.
	var font: Font = load("res://assets/fonts/fusion_pixel_12px_latin.woff2") as Font
	for separator: String in [",", ".", NBSP]:
		assert_bool(font.has_char(separator.unicode_at(0))).override_failure_message("U+%04X" % separator.unicode_at(0)).is_true()
