extends SceneTree
## Tamga ikonlarını üretir → game/assets/art/ui/icons/icon_tamga_<id>.png
##
## Kullanım (repo kökünden):
##   godot --headless --path game --script ../tools/asset-pipeline/generate_tamga_icons.gd
##
## Art bible §5 / §7: tamga 7×7 glif, krem (#F2E6C7) + 1px koyu outline (#1C170F)
## → 9×9 PNG. Oyuncu tamgası sabit (Oğuz "kaşu": yay içinde iki ok); kral
## tamgaları bible §5 tablosundan; Prolog canavarı (kral değil) boynuz işareti.
const OUT: String = "res://assets/art/ui/icons/"
const GLYPH := Color("#F2E6C7")
const OUTLINE := Color("#1C170F")
const T := Color(0, 0, 0, 0)
const GLYPH_SIZE: int = 7
const PAD: int = 1

## '#' = glif pikseli, '.' = boş. Her desen 7 satır × 7 sütun.
const TAMGAS: Dictionary = {
	"oguz": [
		".#...#.",
		"###.###",
		".#...#.",
		".#...#.",
		".#...#.",
		"##...##",
		".#####.",
	],
	"curcet": [  # Baklava ◈
		"...#...",
		"..#.#..",
		".#...#.",
		"#..#..#",
		".#...#.",
		"..#.#..",
		"...#...",
	],
	"urum": [  # Çarpı ⊠
		"#######",
		"##...##",
		"#.#.#.#",
		"#..#..#",
		"#.#.#.#",
		"##...##",
		"#######",
	],
	"kil_barak": [  # Çift üçgen ▲▼
		"...#...",
		"..###..",
		".#####.",
		".......",
		".#####.",
		"..###..",
		"...#...",
	],
	"kuzey": [  # Kar tanesi ❅ (7×7'de okunsun diye altı kollu yıldız)
		"...#...",
		".#.#.#.",
		"..###..",
		"###.###",
		"..###..",
		".#.#.#.",
		"...#...",
	],
	"guney": [  # Üç dişli çatal ⋔
		"#..#..#",
		"#..#..#",
		"#..#..#",
		"#######",
		"...#...",
		"...#...",
		"...#...",
	],
	"erlik_beast": [  # Tek boynuz — Prolog'un Erlik canavarı (2026-10-08 kararı)
		".....#.",
		"....##.",
		"...##..",
		"..##...",
		".###...",
		"#####..",
		".###...",
	],
}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for id: String in TAMGAS:
		var img: Image = build_icon(TAMGAS[id] as Array)
		var err: Error = img.save_png(ProjectSettings.globalize_path(OUT + "icon_tamga_" + id + ".png"))
		print("icon_tamga_", id, " ", img.get_size(), " err=", err)
	quit()


## 7×7 deseni 1px boşluklu 9×9 görüntüye çizer; yalnızca dış siluetin çevresine
## (kenardan ulaşılabilen boş pikseller) outline koyar. İç boşluklar şeffaf kalır,
## bölge dolgusu oradan görünür — yoğun gliflerin koyu bloğa dönüşmesini önler.
static func build_icon(rows: Array) -> Image:
	var size: int = GLYPH_SIZE + PAD * 2
	var img: Image = Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	img.fill(T)
	for y: int in GLYPH_SIZE:
		var row: String = rows[y] as String
		for x: int in GLYPH_SIZE:
			if row[x] == "#":
				img.set_pixel(x + PAD, y + PAD, GLYPH)
	var outside: Dictionary = _exterior_pixels(img)
	for p: Vector2i in outside:
		if _touches_glyph(img, p.x, p.y):
			img.set_pixel(p.x, p.y, OUTLINE)
	return img


## Kenardan 4-komşulukla ulaşılabilen boş pikseller (flood fill).
static func _exterior_pixels(img: Image) -> Dictionary:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var seen: Dictionary = {}
	var stack: Array[Vector2i] = []
	for i: int in w:
		stack.append(Vector2i(i, 0))
		stack.append(Vector2i(i, h - 1))
	for i: int in h:
		stack.append(Vector2i(0, i))
		stack.append(Vector2i(w - 1, i))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or seen.has(p):
			continue
		if img.get_pixelv(p).a > 0.0:
			continue
		seen[p] = true
		stack.append(p + Vector2i.LEFT)
		stack.append(p + Vector2i.RIGHT)
		stack.append(p + Vector2i.UP)
		stack.append(p + Vector2i.DOWN)
	return seen


static func _touches_glyph(img: Image, x: int, y: int) -> bool:
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var nx: int = x + dx
			var ny: int = y + dy
			if nx < 0 or ny < 0 or nx >= img.get_width() or ny >= img.get_height():
				continue
			if img.get_pixel(nx, ny) == GLYPH:
				return true
	return false
