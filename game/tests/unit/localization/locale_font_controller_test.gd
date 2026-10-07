extends GdUnitTestSuite
## LocaleFontController birim testleri — pixel fontların native boyutta kalması.


const DEFAULT_SIZE: int = 12
const ARABIC_SIZE: int = 16

var _theme: Theme = null
var _default_font: FontVariation = null
var _arabic_font: FontVariation = null
var _controller: LocaleFontController = null


func before_test() -> void:
	_theme = Theme.new()
	_default_font = FontVariation.new()
	_arabic_font = FontVariation.new()
	_theme.default_font = _default_font
	_theme.default_font_size = DEFAULT_SIZE
	_controller = LocaleFontController.new(_theme)
	_controller.add_override("ar", _arabic_font, ARABIC_SIZE)


func test_locale_font_override_language_switches_font_and_size() -> void:
	# Arrange: before_test

	# Act
	_controller.apply("ar")

	# Assert
	assert_object(_theme.default_font).is_same(_arabic_font)
	assert_int(_theme.default_font_size).is_equal(ARABIC_SIZE)


func test_locale_font_locale_with_region_uses_language_code() -> void:
	# Arrange: before_test

	# Act
	_controller.apply("ar_EG")

	# Assert
	assert_object(_theme.default_font).is_same(_arabic_font)


func test_locale_font_other_language_keeps_default() -> void:
	# Arrange: before_test

	# Act
	_controller.apply("ja")

	# Assert
	assert_object(_theme.default_font).is_same(_default_font)
	assert_int(_theme.default_font_size).is_equal(DEFAULT_SIZE)


func test_locale_font_switch_back_restores_default() -> void:
	# Arrange
	_controller.apply("ar")

	# Act
	_controller.apply("en")

	# Assert
	assert_object(_theme.default_font).is_same(_default_font)
	assert_int(_theme.default_font_size).is_equal(DEFAULT_SIZE)
