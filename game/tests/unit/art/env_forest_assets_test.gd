extends GdUnitTestSuite
## Perde 1 orman dekoru + orman körmösü varlıkları — seviye belgesi §7.7, art bible "Boyut Tablosu" (C-46).
## Tuval = görünür + her kenarda 2px; alfa yalnız 0/255; körmösün iki karesi aynı tuvalde, kare 1 = 1px yukarı.


const ENV_DIR: String = "res://assets/art/maps/env/"
const UNIT_DIR: String = "res://assets/art/units/"
## Dosya → tuval boyutu (görünür + 4).
const CANVAS: Dictionary = {
	"env_tree_healthy_01": Vector2i(16, 24),
	"env_tree_healthy_02": Vector2i(16, 22),
	"env_tree_rotten_01": Vector2i(14, 20),
	"env_tree_rotten_02": Vector2i(14, 20),
	"env_bridge_wood_01": Vector2i(20, 14),
	"env_otag_curcet_01": Vector2i(32, 28),
}
const KORMOS_FRAMES: Array[String] = ["unit_kormos_forest_idle_0", "unit_kormos_forest_idle_1"]
const KORMOS_CANVAS := Vector2i(16, 18)
const PAD: int = 2


func _image(path: String) -> Image:
	var texture: Texture2D = load(path) as Texture2D
	assert_object(texture).is_not_null()
	return texture.get_image()


func _opaque_rows(img: Image) -> Array[int]:
	var rows: Array[int] = []
	for y: int in img.get_height():
		for x: int in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				rows.append(y)
				break
	return rows


func test_env_forest_assets_canvas_matches_art_bible_size_table() -> void:
	for asset: String in CANVAS:
		assert_object(_image(ENV_DIR + asset + ".png").get_size()).is_equal(CANVAS[asset])
	for frame: String in KORMOS_FRAMES:
		assert_object(_image(UNIT_DIR + frame + ".png").get_size()).is_equal(KORMOS_CANVAS)


func test_env_forest_assets_alpha_is_binary_and_padding_is_clear() -> void:
	var paths: Array[String] = []
	for asset: String in CANVAS:
		paths.append(ENV_DIR + asset + ".png")
	for frame: String in KORMOS_FRAMES:
		paths.append(UNIT_DIR + frame + ".png")
	for path: String in paths:
		var img: Image = _image(path)
		for y: int in img.get_height():
			for x: int in img.get_width():
				var a: float = img.get_pixel(x, y).a
				assert_bool(a == 0.0 or a == 1.0).override_failure_message("%s (%d,%d) alfa %f" % [path, x, y, a]).is_true()
				var in_pad: bool = x < PAD or y < PAD or x >= img.get_width() - PAD or y >= img.get_height() - PAD
				if in_pad:
					assert_float(a).override_failure_message("%s dolgu (%d,%d) boş değil" % [path, x, y]).is_equal(0.0)


func test_env_forest_kormos_second_frame_floats_one_pixel_higher_over_same_shadow() -> void:
	var frame_0: Array[int] = _opaque_rows(_image(UNIT_DIR + KORMOS_FRAMES[0] + ".png"))
	var frame_1: Array[int] = _opaque_rows(_image(UNIT_DIR + KORMOS_FRAMES[1] + ".png"))
	assert_int(frame_1[0]).is_equal(frame_0[0] - 1)
	assert_int(frame_1[-1]).is_equal(frame_0[-1])  # gölge satırı aynı yerde
