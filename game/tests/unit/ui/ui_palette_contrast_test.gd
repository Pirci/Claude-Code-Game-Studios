extends GdUnitTestSuite
## Tema renkleri ↔ art bible §4 "UI Paleti" — renk değerleri ve WCAG kontrastı.
##
## Hedef: metin ≥4.5:1, UI bileşen kenarı ≥3:1 (panel zemini #1C150D üzerinde).


const THEME_PATH: String = "res://assets/fonts/default_theme.tres"
const PANEL_BG := Color("#1C150D")
const TEXT_MIN: float = 4.5
const BORDER_MIN: float = 3.0

var _theme: Theme


func before_test() -> void:
	_theme = load(THEME_PATH) as Theme


## WCAG 2.x göreli parlaklık kontrast oranı.
func _contrast(a: Color, b: Color) -> float:
	var la: float = _luminance(a)
	var lb: float = _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _luminance(c: Color) -> float:
	var lin: Color = c.srgb_to_linear()
	return 0.2126 * lin.r + 0.7152 * lin.g + 0.0722 * lin.b


func _style(name: StringName, type: StringName) -> StyleBoxFlat:
	return _theme.get_stylebox(name, type) as StyleBoxFlat


func test_text_colours_match_ui_palette() -> void:
	assert_str(_theme.get_color(&"font_color", &"Label").to_html(false)).is_equal("f2e6c7")
	assert_str(_theme.get_color(&"font_color", &"SecondaryLabel").to_html(false)).is_equal("b8a689")
	assert_str(_theme.get_color(&"font_color", &"HeaderLabel").to_html(false)).is_equal("edc76b")
	assert_str(_theme.get_color(&"font_color", &"Button").to_html(false)).is_equal("f2e6c7")
	assert_str(_theme.get_color(&"font_hover_color", &"Button").to_html(false)).is_equal("f5de9e")
	assert_str(_theme.get_color(&"font_disabled_color", &"Button").to_html(false)).is_equal("6b655a")


func test_panel_and_border_match_ui_palette() -> void:
	var panel: StyleBoxFlat = _style(&"panel", &"PanelContainer")
	assert_str(panel.bg_color.to_html(true)).is_equal("1c150dff")
	assert_str(panel.border_color.to_html(false)).is_equal("8a6d4f")
	assert_str(_style(&"normal", &"Button").border_color.to_html(false)).is_equal("8a6d4f")
	assert_str(_style(&"focus", &"Button").border_color.to_html(false)).is_equal("edc76b")


func test_text_on_panel_meets_wcag_aa() -> void:
	for type: StringName in [&"Label", &"SecondaryLabel", &"HeaderLabel"]:
		var ratio: float = _contrast(_theme.get_color(&"font_color", type), PANEL_BG)
		assert_float(ratio).override_failure_message("%s: %.2f" % [type, ratio]).is_greater_equal(TEXT_MIN)


func test_contrast_matches_art_bible_table() -> void:
	# Art bible §4 UI Paleti tablosundaki değerler — bir ondalığa aşağı yuvarlanmış.
	var expected: Dictionary = {
		"#F2E6C7": 14.5, "#B8A689": 7.6, "#6B655A": 3.1, "#8A6D4F": 3.7,
		"#EDC76B": 11.1, "#F5DE9E": 13.6, "#87B85C": 7.7, "#E87A7A": 6.4, "#FFADAD": 10.1,
	}
	for hex: String in expected:
		var ratio: float = _contrast(Color(hex), PANEL_BG)
		var floored: float = floorf(ratio * 10.0) / 10.0
		assert_float(floored).override_failure_message("%s: %.3f" % [hex, ratio]).is_equal_approx(expected[hex], 0.001)


func test_button_text_meets_wcag_aa_in_every_state() -> void:
	var pairs: Array = [
		[&"font_color", &"normal"], [&"font_hover_color", &"hover"],
		[&"font_pressed_color", &"pressed"],
	]
	for pair: Array in pairs:
		var text: Color = _theme.get_color(pair[0], &"Button")
		var bg: Color = _style(pair[1], &"Button").bg_color
		var ratio: float = _contrast(text, bg)
		assert_float(ratio).override_failure_message("%s: %.2f" % [pair[1], ratio]).is_greater_equal(TEXT_MIN)


func test_button_borders_meet_component_contrast() -> void:
	for state: StringName in [&"normal", &"hover", &"pressed"]:
		var box: StyleBoxFlat = _style(state, &"Button")
		var ratio: float = _contrast(box.border_color, PANEL_BG)
		assert_float(ratio).override_failure_message("%s: %.2f" % [state, ratio]).is_greater_equal(BORDER_MIN)
