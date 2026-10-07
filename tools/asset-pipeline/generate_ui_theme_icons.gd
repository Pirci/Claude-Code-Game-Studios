extends SceneTree
## Pixel UI tema ikonlarını üretir → game/assets/art/ui/theme/*.png
##
## Kullanım (repo kökünden):
##   godot --headless --path game --script ../tools/asset-pipeline/generate_ui_theme_icons.gd
##
## Palet geçicidir (default_theme.tres ile aynı); art bible kesinleşince
## buradaki renkleri güncelleyip yeniden çalıştır.
const OUT: String = "res://assets/art/ui/theme/"
const T := Color(0, 0, 0, 0)
const DARK := Color(0.11, 0.09, 0.06)
const BROWN := Color(0.45, 0.36, 0.24)
const BROWN_L := Color(0.62, 0.5, 0.34)
const GOLD := Color(0.93, 0.78, 0.42)
const GOLD_D := Color(0.72, 0.58, 0.3)
const CREAM := Color(0.95, 0.9, 0.78)

func _img(w: int, h: int) -> Image:
	var i: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	i.fill(T)
	return i

func _rect(i: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	i.fill_rect(Rect2i(x, y, w, h), c)

func _box(i: Image, x: int, y: int, w: int, h: int, border: Color, fill: Color) -> void:
	_rect(i, x, y, w, h, border)
	_rect(i, x + 1, y + 1, w - 2, h - 2, fill)

func _grabber(fill: Color) -> Image:
	var i: Image = _img(6, 10)
	_box(i, 0, 0, 6, 10, DARK, fill)
	return i

func _toggle(on: bool, disabled: bool) -> Image:
	var i: Image = _img(16, 8)
	var border: Color = GOLD if on else BROWN
	var fill: Color = GOLD_D if on else DARK
	if disabled:
		border = BROWN; fill = DARK
	_box(i, 0, 0, 16, 8, border, fill)
	var knob: Color = (CREAM if on else BROWN_L) if not disabled else BROWN
	_rect(i, 10 if on else 2, 2, 4, 4, knob)
	return i

func _arrow() -> Image:
	var i: Image = _img(7, 4)
	for r: int in 4:
		_rect(i, r, r, 7 - 2 * r, 1, CREAM)
	return i

func _radio(on: bool) -> Image:
	var i: Image = _img(6, 6)
	_box(i, 0, 0, 6, 6, BROWN, DARK)
	if on:
		_rect(i, 2, 2, 2, 2, GOLD)
	return i

func _save(i: Image, name: String) -> void:
	var err: Error = i.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print(name, " ", i.get_size(), " err=", err)

func _init() -> void:
	_save(_grabber(GOLD), "slider_grabber")
	_save(_grabber(CREAM), "slider_grabber_highlight")
	_save(_grabber(BROWN), "slider_grabber_disabled")
	for on: bool in [true, false]:
		for dis: bool in [false, true]:
			var base: String = ("toggle_on" if on else "toggle_off") + ("_disabled" if dis else "")
			var img: Image = _toggle(on, dis)
			_save(img, base)
			var m: Image = img.duplicate() as Image
			m.flip_x()
			_save(m, base + "_mirrored")
	_save(_arrow(), "dropdown_arrow")
	_save(_radio(true), "radio_checked")
	_save(_radio(false), "radio_unchecked")
	quit()
