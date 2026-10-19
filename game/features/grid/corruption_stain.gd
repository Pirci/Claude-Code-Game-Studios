class_name CorruptionStain
extends RefCounted
## Bir bölgenin Erlik lekesi görüntüleri — art bible §4 "Bozulma Seviyeleri" (C-50).
## Seviye, 4×4 Bayer eşiğine göre leke yoğunluğudur (%25 / %50 / %75); poligon kenarından
## içeri 2px temiz sahiplik bandı kalır; leke sınırında 1px kesintili kenar (2 çiz / 1 boşluk).
## Kareler: Bayer deseni her karede 1px köşegen kayar, leke piksellerinin 1/16'sı pırıltıdır.
## Yalnızca palet renkleri, alfa 0/255 (yarı saydamlık yok).


const COLOR_BODY := Color("#33173D")   # Erlik Moru 3
const COLOR_EDGE := Color("#1A1719")   # Erlik Kömürü 3
const COLOR_GLINT := Color("#522961")  # Erlik Moru 4
## 4×4 Bayer matrisi, satır satır düz (indeks = satır × 4 + sütun). Godot 4.7.1'de
## `const X: Array[PackedInt32Array]` değişken indeksle okununca 0 döndürüyor — düz dizi.
const BAYER: PackedInt32Array = [
	0, 8, 2, 10,
	12, 4, 14, 6,
	3, 11, 1, 9,
	15, 7, 13, 5,
]
const MAX_LEVEL: int = 3
const FRAME_COUNT: int = 4
## Hareketi Azalt açıkken gösterilen sabit "orta" kare (art bible §7).
const STATIC_FRAME: int = 2
## Poligon konturu (1px) + temiz sahiplik bandı (2px) — leke bunun içinde başlar.
const OUTLINE_PX: int = 1
const CLEAN_BAND_PX: int = 2
## Kesintili kenar ritmi: DASH_ON piksel çiz, DASH_PERIOD − DASH_ON piksel boşluk.
const DASH_ON: int = 2
const DASH_PERIOD: int = 3

## Görüntülerin bölge (yerel) koordinatındaki sol üst köşesi.
var origin: Vector2i = Vector2i.ZERO
var level: int = 0
var frames: Array[Image] = []


## [param polygon] (bölge yerel koordinatı) için [param level] seviyeli leke kareleri.
## Seviye 0 ya da leke alanı kalmayan küçük poligon → kare yok.
func _init(polygon: PackedVector2Array, p_level: int) -> void:
	level = clampi(p_level, 0, MAX_LEVEL)
	if level == 0 or polygon.size() < 3:
		return
	var inset: Array[PackedVector2Array] = Geometry2D.offset_polygon(
		polygon, -float(OUTLINE_PX + CLEAN_BAND_PX), Geometry2D.JOIN_MITER)
	if inset.is_empty():
		return
	var area: PackedVector2Array = inset[0]
	var bounds: Rect2i = _bounds(area)
	origin = bounds.position
	var inside: Array[Vector2i] = []
	for y: int in range(bounds.position.y, bounds.end.y):
		for x: int in range(bounds.position.x, bounds.end.x):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), area):
				inside.append(Vector2i(x, y))
	var edge: Array[Vector2i] = dashed_outline(area)
	for frame: int in FRAME_COUNT:
		var image: Image = Image.create_empty(bounds.size.x, bounds.size.y, false, Image.FORMAT_RGBA8)
		for p: Vector2i in inside:
			if is_stained(p.x, p.y, level, frame):
				var color: Color = COLOR_GLINT if is_glint(p.x, p.y, frame) else COLOR_BODY
				image.set_pixelv(p - origin, color)
		for p: Vector2i in edge:
			var local: Vector2i = p - origin
			if Rect2i(Vector2i.ZERO, bounds.size).has_point(local):
				image.set_pixelv(local, COLOR_EDGE)
		frames.append(image)


## Piksel bu karede leke mi: kaydırılmış Bayer değeri < seviye × 4.
static func is_stained(x: int, y: int, p_level: int, frame: int) -> bool:
	return _bayer(x, y, frame) < p_level * 4


## Pırıltı pikseli (her karede piksellerin 1/16'sı; seviye ≥ 1'de hep lekenin alt kümesi).
static func is_glint(x: int, y: int, frame: int) -> bool:
	return _bayer(x, y, frame) == frame


## Poligon sınırının 1px kesintili rasterı (2 çiz / 1 boşluk, sayaç kenarlar boyunca sürer).
static func dashed_outline(polygon: PackedVector2Array) -> Array[Vector2i]:
	var pixels: Array[Vector2i] = []
	var counter: int = 0
	for i: int in polygon.size():
		var a: Vector2 = polygon[i]
		var b: Vector2 = polygon[(i + 1) % polygon.size()]
		var steps: int = maxi(1, ceili(maxf(absf(b.x - a.x), absf(b.y - a.y))))
		for s: int in steps:
			if counter % DASH_PERIOD < DASH_ON:
				pixels.append(Vector2i(a.lerp(b, float(s) / steps).floor()))
			counter += 1
	return pixels


static func _bayer(x: int, y: int, frame: int) -> int:
	return BAYER[posmod(y + frame, 4) * 4 + posmod(x + frame, 4)]


static func _bounds(polygon: PackedVector2Array) -> Rect2i:
	var lo: Vector2 = polygon[0]
	var hi: Vector2 = polygon[0]
	for p: Vector2 in polygon:
		lo = lo.min(p)
		hi = hi.max(p)
	var start: Vector2i = Vector2i(lo.floor())
	return Rect2i(start, Vector2i(hi.ceil()) - start)
