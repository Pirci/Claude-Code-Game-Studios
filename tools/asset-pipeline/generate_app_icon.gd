extends SceneTree
## Uygulama ikonunu üretir → game/icon.png (256×256; macOS .icns ve Windows .ico export'ta bundan türer).
##
## Kullanım (repo kökünden):
##   godot --headless --path game --script ../tools/asset-pipeline/generate_app_icon.gd
##
## Koyu indigo zemin (#141A33, ana menü) + 2px Ülgen altını kenar + ortada Oğuz tamgası
## (icon_tamga_oguz.png, 9×9) tam kat (×20) en yakın komşu ölçekle — pixel art kuralı.
const OUT: String = "res://icon.png"
const SIZE: int = 256
const SCALE: int = 20
const BACKGROUND := Color("#141A33")
const BORDER := Color("#EDC76B")


func _init() -> void:
	var tamga: Image = (load("res://assets/art/ui/icons/icon_tamga_oguz.png") as Texture2D).get_image()
	tamga.decompress()
	tamga.resize(tamga.get_width() * SCALE, tamga.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	var icon: Image = Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	icon.fill(BACKGROUND)
	for i: int in 2:
		for x: int in SIZE:
			for y: int in [i, SIZE - 1 - i]:
				icon.set_pixel(x, y, BORDER)
				icon.set_pixel(y, x, BORDER)
	var offset: Vector2i = (Vector2i(SIZE, SIZE) - tamga.get_size()) / 2
	icon.blend_rect(tamga, Rect2i(Vector2i.ZERO, tamga.get_size()), offset)
	var err: Error = icon.save_png(ProjectSettings.globalize_path(OUT))
	print(OUT, " ", icon.get_size(), " err=", err)
	quit()
