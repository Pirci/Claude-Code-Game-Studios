extends SceneTree
## Kök Böri lütuf ekranı varlıklarını üretir (C-46 / C-67; art bible §7 "İlahi" panel, ux/boon-selection.md §6):
##   → game/assets/art/ui/theme/frame_divine.png — 9-slice, 2px Ülgen altını kenar + 7×7 tündük köşe
##   → game/assets/art/ui/icons/icon_boon_<boon_id>.png — 24×24 lütuf ikonları
##
## Kullanım (repo kökünden):
##   godot --headless --path game --script ../tools/asset-pipeline/generate_divine_ui.gd
##
## Simetrik ikonlar sol yarıdan (12 sütun) aynalanır. Alfa 0/255, yalnız küresel palet.
## default_theme.tres "divine_panel" StyleBoxTexture'ı texture_margin = CORNER ile eşleşir.
const ICON_OUT: String = "res://assets/art/ui/icons/"
const THEME_OUT: String = "res://assets/art/ui/theme/"
const CORNER: int = 7
const FRAME_SIZE: int = 18          # 7 + 4 + 7 → orta parça esner
const ICON_SIZE: int = 24
const T := Color(0, 0, 0, 0)

const COLORS: Dictionary = {
	".": T,
	# Ülgen Altını
	"1": Color("#3D2E0A"), "2": Color("#6B4F12"), "3": Color("#9A7020"), "4": Color("#C99A3D"),
	"5": Color("#EDC76B"), "6": Color("#F5DE9E"), "7": Color("#FFF4D4"),
	# Kök Böri Gök Mavisi
	"A": Color("#0A1A29"), "B": Color("#14334D"), "C": Color("#1F5278"), "D": Color("#2E7AB8"),
	"E": Color("#47A3E8"), "F": Color("#87C4F5"), "G": Color("#D4EDFF"),
	# Erlik Moru (arınan leke)
	"p": Color("#33173D"), "r": Color("#522961"), "v": Color("#7A3D8F"),
	# Keçe Grisi (demir)
	"q": Color("#2E2A24"), "n": Color("#4A453C"), "s": Color("#6B655A"), "i": Color("#8F897D"),
	"j": Color("#B5AFA3"),
	# Deri Kahve (zemin çizgisi)
	"o": Color("#0D0A06"),
	# İlahi panel dolgusu (Ülgen İndigosu 1)
	"f": Color("#0A0D1C"),
}

## Tündük köşesi (sol üst, 7×7): 2px kenar ('5'), içte çember + çapraz parmaklık.
const DIVINE_CORNER: Array = [
	"5555555",
	"5555555",
	"55f444f",
	"554f6f4",
	"5546664",
	"554f6f4",
	"55f444f",
]

## Arınma Ustalığı: dört kollu Kök Böri ışığı, etrafında dağılan Erlik lekeleri. Sol yarı.
const ARINMA_USTALIGI: Array = [
	"............",
	"...........5",
	"...........6",
	"...r.......6",
	"..rvr......6",
	"...r......56",
	"..........67",
	".........567",
	"..p.....5677",
	".pvp...56777",
	"..p..5667777",
	".5666677777G",
	".5666677777G",
	"..p..5667777",
	".pvp...56777",
	"..p.....5677",
	".........567",
	"..........67",
	"...r......56",
	"..rvr......6",
	"...r.......6",
	"...........6",
	"...........5",
	"............",
]

## Bereket: kare delikli altın sikke. Sol yarı.
const BEREKET: Array = [
	"............",
	"............",
	"........3333",
	"......334444",
	".....3445555",
	"....34555566",
	"...345556666",
	"...345566666",
	"..3455666666",
	"..3456666666",
	".34556666622",
	".34556666621",
	".34556666621",
	".34556666622",
	".34455666666",
	"..3445566666",
	"..3444556666",
	"...344455566",
	"...334444555",
	"....33444444",
	".....3334444",
	".......33333",
	"............",
	"............",
]

## Gök Kalkanı: gök mavisi yuvarlak kalkan, altın kenar ve tündük parmaklıkları. Sol yarı.
const GOK_KALKANI: Array = [
	"............",
	"........4444",
	"......445555",
	".....45DDDD5",
	"....45DDEEE5",
	"...45DDEEEE5",
	"...5DDEEEFF5",
	"..45DEEEEFF5",
	"..5DDEEEFF55",
	"..5DEEEFF5FF",
	".45DEEEF5FFG",
	".55555555555",
	".55555555555",
	".45DEEEF5FFG",
	"..5DEEEFF5FF",
	"..5DDEEEFF55",
	"..45DEEEEFF5",
	"...5DDEEEFF5",
	"...45DDEEEE5",
	"....45DDEEE5",
	".....45DDDD5",
	"......445555",
	"........4444",
	"............",
]

## Kurt Gücü: önden kurt başı (kulaklar, altın gözler, burun, dişler). Sol yarı.
const KURT_GUCU: Array = [
	"............",
	"..B.........",
	"..BC........",
	"..BDC.......",
	"..BEDC......",
	"..BEEDCCCCCC",
	"..BDEEDDDDDD",
	"...BDEEEEEEE",
	"...BDEFFEEEE",
	"..BDEEFFEEEE",
	"..BDE65EEEEE",
	"..BDEEEEEEFE",
	"...BDEEEEFFG",
	"...BCDEEFFGG",
	"....BCDEFGGG",
	"....BCDEEGGG",
	".....BCDEEGG",
	".....BCDDEAA",
	"......BCDEEA",
	"......BCCDEG",
	".......BCDGG",
	"........BCCD",
	".........BBB",
	"............",
]

## Demir Post: demir bantlı üç sivri kazık (palisat). Sol yarı.
const DEMIR_POST: Array = [
	"............",
	"...........j",
	"..........ij",
	"..j.......ij",
	"..ij.....sij",
	".sij.....sij",
	".sij.....sij",
	".nnnnnnnnnnn",
	".qqqqqqqqqqq",
	".sij.....sij",
	".sij.....sij",
	".sij.....sij",
	".sij.....sij",
	".sij.....sij",
	".sij.....sij",
	".nnnnnnnnnnn",
	".qqqqqqqqqqq",
	".sij.....sij",
	".sij.....sij",
	".sij.....sij",
	".sij.....sij",
	".sij.....sij",
	".ooooooooooo",
	"............",
]


func _init() -> void:
	for dir: String in [ICON_OUT, THEME_OUT]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	_save(build_divine_frame(), THEME_OUT + "frame_divine.png")
	var icons: Dictionary = {
		"arinma_ustaligi": ARINMA_USTALIGI,
		"bereket": BEREKET,
		"gok_kalkani": GOK_KALKANI,
		"kurt_gucu": KURT_GUCU,
		"demir_post": DEMIR_POST,
	}
	for boon_id: String in icons:
		_save(build_mirrored(icons[boon_id] as Array), ICON_OUT + "icon_boon_%s.png" % boon_id)
	quit()


## Dolgu + 2px kenar; dört köşeye aynalanmış tündük.
static func build_divine_frame() -> Image:
	var img: Image = Image.create_empty(FRAME_SIZE, FRAME_SIZE, false, Image.FORMAT_RGBA8)
	var last: int = FRAME_SIZE - 1
	for y: int in FRAME_SIZE:
		for x: int in FRAME_SIZE:
			var edge: bool = x < 2 or y < 2 or x > last - 2 or y > last - 2
			img.set_pixel(x, y, COLORS["5"] if edge else COLORS["f"])
	for ly: int in CORNER:
		var row: String = DIVINE_CORNER[ly] as String
		assert(row.length() == CORNER)
		for lx: int in CORNER:
			var c: Color = COLORS[row[lx]] as Color
			img.set_pixel(lx, ly, c)
			img.set_pixel(last - lx, ly, c)
			img.set_pixel(lx, last - ly, c)
			img.set_pixel(last - lx, last - ly, c)
	return img


## Sol yarı ızgarayı (12 sütun) yatayda aynalayıp 24×24 ikon çizer.
static func build_mirrored(half_rows: Array) -> Image:
	var half: int = ICON_SIZE / 2
	assert(half_rows.size() == ICON_SIZE)
	var img: Image = Image.create_empty(ICON_SIZE, ICON_SIZE, false, Image.FORMAT_RGBA8)
	for y: int in ICON_SIZE:
		var row: String = half_rows[y] as String
		assert(row.length() == half, "satır %d uzunluğu %d ≠ %d" % [y, row.length(), half])
		for x: int in half:
			assert(COLORS.has(row[x]), "bilinmeyen renk anahtarı '%s'" % row[x])
			var c: Color = COLORS[row[x]] as Color
			img.set_pixel(x, y, c)
			img.set_pixel(ICON_SIZE - 1 - x, y, c)
	return img


static func _save(img: Image, path: String) -> void:
	var err: Error = img.save_png(ProjectSettings.globalize_path(path))
	print(path, " ", img.get_size(), " err=", err)
