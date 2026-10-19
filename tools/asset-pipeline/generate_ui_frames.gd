extends SceneTree
## 9-slice UI çerçeve dokularını üretir → game/assets/art/ui/theme/frame_*.png
## Art bible §3 "UI Şekil Grameri" + §7 "Panel Sistemi" (C-21):
##   - Birincil buton: 1px kenarlık + 5×5 koçboynuzu köşe süsü, düz dolgu (4 durum).
##   - Modal panel: 1px kenarlık + 2px kilim şevron bandı + 5×5 koçboynuzu köşe, opak dolgu.
##
## Kullanım (repo kökünden):
##   godot --headless --path game --script ../tools/asset-pipeline/generate_ui_frames.gd
##
## Renkler global paletten (Deri Kahve rampası + Ülgen Altını) ve default_theme.tres'teki
## düz buton stilleriyle aynıdır; birini değiştirirsen diğerini de güncelle.
## Dokuların 9-slice kenar payı CORNER (5) — default_theme.tres StyleBoxTexture'ları bununla eşleşir.
const OUT: String = "res://assets/art/ui/theme/"
const CORNER: int = 5
const BUTTON_SIZE: int = 16          # 5 + 6 + 5 → orta parça tek renk, esner
const PANEL_SIZE: int = 18           # 5 + 8 + 5 → orta kenar 2 şevron periyodu, döşenir
const CHEVRON_PERIOD: int = 4

const DARKEST := Color("#0D0A06")    # Deri Kahve 1 — basılı buton dolgusu
const PANEL_FILL := Color("#1C150D") # Deri Kahve 2 — modal / devre dışı dolgu
const BAND_DARK := Color("#3A2817")  # Deri Kahve 3 — buton dolgusu, şevron zemini
const BROWN_D := Color("#5C4229")    # Deri Kahve 4 — devre dışı kenarlık
const BROWN := Color("#8A6D4F")      # Deri Kahve 5 — kenarlık
const BROWN_L := Color("#B8945D")    # Deri Kahve 6 — koçboynuzu, şevron
const GOLD := Color("#EDC76B")       # Ülgen Altını — hover / basılı vurgu

## Sol üst köşe maskesi (5×5): 1 = kenarlık, 2 = koçboynuzu, 0 = dolgu.
## Köşeden çıkan köşegen gövde iki yana kıvrılır — boynuz çiftinin piksel soyutlaması.
## Köşegene göre simetrik (merkez piksel kuralı); diğer köşeler aynalanır.
const CORNER_MASK: Array[Array] = [
	[1, 1, 1, 1, 1],
	[1, 2, 0, 0, 0],
	[1, 0, 2, 2, 0],
	[1, 0, 2, 0, 0],
	[1, 0, 0, 0, 0],
]


func _corner_pixel(lx: int, ly: int, border: Color, curl: Color, fill: Color) -> Color:
	match int(CORNER_MASK[ly][lx]):
		1:
			return border
		2:
			return curl
		_:
			return fill


## Köşe süslü düz çerçeve; [param band] true ise kenarlarda 2px kilim şevron bandı.
func _frame(size: int, border: Color, curl: Color, fill: Color, band: bool) -> Image:
	var img: Image = Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	img.fill(fill)
	var last: int = size - 1
	for y: int in size:
		for x: int in size:
			var lx: int = mini(x, last - x)
			var ly: int = mini(y, last - y)
			if lx < CORNER and ly < CORNER:
				img.set_pixel(x, y, _corner_pixel(lx, ly, border, curl, fill))
			elif lx == 0 or ly == 0:
				img.set_pixel(x, y, border)
			elif band and (lx <= 2 or ly <= 2):
				img.set_pixel(x, y, _band_pixel(x, y, lx, ly))
	return img


## Şevron: kenara dik 2 satır; dış satır periyodun ilk yarısında, iç satır ikinci
## yarısında yanar (▀▄ basamaklı zikzak). Faz köşe payından başlar → 9-slice döşemede kesintisiz.
func _band_pixel(x: int, y: int, lx: int, ly: int) -> Color:
	var along: int = (x if ly <= 2 else y) - CORNER
	var depth: int = ly if ly <= 2 else lx
	var phase: int = posmod(along, CHEVRON_PERIOD)
	var outer_lit: bool = phase < CHEVRON_PERIOD / 2
	var lit: bool = outer_lit if depth == 1 else not outer_lit
	return BROWN_L if lit else BAND_DARK


func _save(img: Image, name: String) -> void:
	var err: Error = img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print(name, " ", img.get_size(), " err=", err)


func _init() -> void:
	_save(_frame(BUTTON_SIZE, BROWN, BROWN_L, BAND_DARK, false), "frame_primary_normal")
	_save(_frame(BUTTON_SIZE, GOLD, GOLD, BAND_DARK, false), "frame_primary_hover")
	_save(_frame(BUTTON_SIZE, GOLD, GOLD, DARKEST, false), "frame_primary_pressed")
	_save(_frame(BUTTON_SIZE, BROWN_D, BROWN_D, PANEL_FILL, false), "frame_primary_disabled")
	_save(_frame(PANEL_SIZE, BROWN, BROWN_L, PANEL_FILL, true), "frame_modal")
	quit()
