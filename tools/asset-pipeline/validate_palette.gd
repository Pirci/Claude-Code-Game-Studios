extends SceneTree
## Pixel art palet doğrulayıcısı (art bible §8 "Palet Doğrulama").
##
## Kullanım (repo kökünden):
##   godot --headless --path game --script ../tools/asset-pipeline/validate_palette.gd \
##       -- <palet.gpl> <taranacak_klasör>
## Varsayılan: ../art-source/global_palette_ulus.gpl, res://assets/art
##
## Klasördeki tüm PNG'leri tarar; alfa 0 pikseller atlanır. Alfa 0/255 dışındaki
## (yarı saydam) ve paletteki 94 renk dışındaki her pikseli dosya + konum + hex ile
## raporlar. İhlal varsa exit 1. Aynı dosyada tekrar eden ihlaller renk başına
## gruplanır (ilk konum + adet) — rapor okunur kalsın.

const DEFAULT_PALETTE: String = "../art-source/global_palette_ulus.gpl"
const DEFAULT_DIR: String = "res://assets/art"
const MAX_LINES_PER_FILE: int = 20


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var palette_path: String = args[0] if args.size() > 0 else ProjectSettings.globalize_path("res://").path_join(DEFAULT_PALETTE)
	var scan_dir: String = args[1] if args.size() > 1 else DEFAULT_DIR

	var palette: Dictionary = load_gpl(palette_path)
	if palette.is_empty():
		printerr("HATA: palet okunamadı veya boş: ", palette_path)
		quit(1)
		return

	var files: PackedStringArray = _find_pngs(scan_dir)
	var bad_files: int = 0
	for file: String in files:
		var issues: PackedStringArray = check_image(file, palette)
		if issues.is_empty():
			continue
		bad_files += 1
		printerr("✕ ", file)
		for i: int in mini(issues.size(), MAX_LINES_PER_FILE):
			printerr("    ", issues[i])
		if issues.size() > MAX_LINES_PER_FILE:
			printerr("    … +%d renk daha" % (issues.size() - MAX_LINES_PER_FILE))

	print("Palet: %d renk · %d PNG tarandı · %d dosyada ihlal" % [palette.size(), files.size(), bad_files])
	quit(1 if bad_files > 0 else 0)


## GIMP .gpl → { "RRGGBB": true }. Yorum (#), başlık ve boş satırlar atlanır.
static func load_gpl(path: String) -> Dictionary:
	var colors: Dictionary = {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return colors
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#") or line.begins_with("GIMP") \
				or line.begins_with("Name:") or line.begins_with("Columns:"):
			continue
		var parts: PackedStringArray = line.replace("\t", " ").split(" ", false)
		if parts.size() < 3 or not parts[0].is_valid_int():
			continue
		var c: Color = Color8(parts[0].to_int(), parts[1].to_int(), parts[2].to_int())
		colors[c.to_html(false)] = true
	return colors


## Tek bir PNG'nin ihlalleri: "x,y  #RRGGBB  (N piksel) — palet dışı | yarı saydam αNNN".
static func check_image(path: String, palette: Dictionary) -> PackedStringArray:
	# Disk yolundan yükle: res:// üzerinden Image.load_from_file import uyarısı basar.
	var img: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null or img.is_empty():
		return PackedStringArray(["okunamadı"])
	img.convert(Image.FORMAT_RGBA8)
	var first_pos: Dictionary = {}
	var counts: Dictionary = {}
	var reasons: Dictionary = {}
	for y: int in img.get_height():
		for x: int in img.get_width():
			var c: Color = img.get_pixel(x, y)
			var a8: int = c.a8
			if a8 == 0:
				continue
			var key: String = ""
			if a8 != 255:
				key = "%s α%d" % [c.to_html(false), a8]
				reasons[key] = "yarı saydam"
			elif not palette.has(c.to_html(false)):
				key = c.to_html(false)
				reasons[key] = "palet dışı"
			else:
				continue
			if not counts.has(key):
				first_pos[key] = Vector2i(x, y)
				counts[key] = 0
			counts[key] += 1
	var issues: PackedStringArray = []
	for key: String in counts:
		var p: Vector2i = first_pos[key]
		# Yalnızca hex büyük harfe: "α" to_upper() ile Yunanca "Α" olur.
		var shown: String = key.substr(0, 6).to_upper() + key.substr(6)
		issues.append("%d,%d  #%s  (%d piksel) — %s" % [p.x, p.y, shown, counts[key], reasons[key]])
	return issues


static func _find_pngs(dir_path: String) -> PackedStringArray:
	var result: PackedStringArray = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return result
	for sub: String in dir.get_directories():
		result.append_array(_find_pngs(dir_path.path_join(sub)))
	for file: String in dir.get_files():
		if file.get_extension().to_lower() == "png":
			result.append(dir_path.path_join(file))
	return result
