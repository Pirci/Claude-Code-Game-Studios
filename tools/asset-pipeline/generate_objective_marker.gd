extends SceneTree
## Hedef işareti ikonunu üretir → game/assets/art/ui/icons/icon_objective_marker_<0|1>.png
##
## Kullanım (repo kökünden):
##   godot --headless --path game --script ../tools/asset-pipeline/generate_objective_marker.gd
##
## scene-flow §9: 9×9, Kök Böri ışığı — gök mavisi / beyaz / Ülgen altını pikseller, 2 kare
## (1 fps), alfa 0/255; sahiplik ve bozulma katmanını örtmesin diye koyu 1px dış çerçeve.
## Kare 0: elmas; kare 1: aynı elmas, ışık uçlara yayılmış (parıltı). Hareketi Azalt → kare 0.
const OUT: String = "res://assets/art/ui/icons/"
const EDGE := Color("#1C170F")     # Keçe Krem 1
const BLUE := Color("#47A3E8")     # Kök Böri Gök Mavisi 5
const WHITE := Color("#D4EDFF")    # Kök Böri Gök Mavisi 7
const GOLD := Color("#EDC76B")     # Ülgen Altını 5
const T := Color(0, 0, 0, 0)

## '.' boş, 'k' kenar, 'b' mavi, 'w' beyaz, 'g' altın. 9 satır × 9 sütun.
const FRAMES: Array = [
	[
		"....k....",
		"...kbk...",
		"..kbwbk..",
		".kbwgwbk.",
		"kbwgggwbk",
		".kbwgwbk.",
		"..kbwbk..",
		"...kbk...",
		"....k....",
	],
	[
		"....g....",
		"...kwk...",
		"..kbwbk..",
		".kbwgwbk.",
		"gwwgggwwg",
		".kbwgwbk.",
		"..kbwbk..",
		"...kwk...",
		"....g....",
	],
]
const COLORS: Dictionary = {".": T, "k": EDGE, "b": BLUE, "w": WHITE, "g": GOLD}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for i: int in FRAMES.size():
		var img: Image = build_frame(FRAMES[i] as Array)
		var path: String = OUT + "icon_objective_marker_%d.png" % i
		var err: Error = img.save_png(ProjectSettings.globalize_path(path))
		print(path, " ", img.get_size(), " err=", err)
	quit()


static func build_frame(rows: Array) -> Image:
	var img: Image = Image.create_empty(9, 9, false, Image.FORMAT_RGBA8)
	for y: int in 9:
		var row: String = rows[y] as String
		for x: int in 9:
			img.set_pixel(x, y, COLORS[row[x]] as Color)
	return img
