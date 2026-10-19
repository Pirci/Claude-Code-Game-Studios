extends GdUnitTestSuite
## Pixel font içe aktarma bayrakları — ADR-0009 karar 4. Godot 4.7 yeni font içe aktarma
## varsayılanlarını değiştirdi (hinting); yeniden içe aktarma bu değerleri bozmamalı (C-58).


const FONT_PATHS: Array[String] = [
	"res://assets/fonts/fusion_pixel_12px_latin.woff2",
	"res://assets/fonts/fusion_pixel_12px_ja.woff2",
	"res://assets/fonts/fusion_pixel_12px_ko.woff2",
	"res://assets/fonts/fusion_pixel_12px_zh_hans.woff2",
	"res://assets/fonts/unifont.otf",
]


func test_pixel_fonts_keep_crisp_import_flags() -> void:
	for path: String in FONT_PATHS:
		var font: FontFile = load(path) as FontFile
		assert_object(font).override_failure_message(path).is_not_null()
		assert_int(font.antialiasing).override_failure_message(path).is_equal(TextServer.FONT_ANTIALIASING_NONE)
		assert_int(font.hinting).override_failure_message(path).is_equal(TextServer.HINTING_NONE)
		assert_int(font.subpixel_positioning).override_failure_message(path).is_equal(TextServer.SUBPIXEL_POSITIONING_DISABLED)
		assert_bool(font.multichannel_signed_distance_field).override_failure_message(path).is_false()
		assert_bool(font.allow_system_fallback).override_failure_message(path).is_false()
		assert_bool(font.generate_mipmaps).override_failure_message(path).is_false()
