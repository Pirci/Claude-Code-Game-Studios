class_name MapDecorLayer
extends Node2D
## Harita dekorunun bir çizim katmanı (seviye perde1 §7.6): [CampaignMap] üç tane kurar — GROUND
## (nehir + zemin öğeleri, komşuluk çizgilerinin altında), PROP (ağaç, köprü, otağ; çizgilerin üstünde,
## bölgelerin altında) ve OVERLAY (körmös; bölgelerin üstünde). Katman içinde ayak-y sırası
## ([method MapDecor.items_in_layer]). Görünürlük bağlı bölgenin bozulmasından türetilir
## ([method apply_corruption]) — dekor kaydedilmez, kayıt/yükleme sonrası aynı çıkar.


## Varlık kuralı (generate_env_forest.gd): tuval = görünür + her kenarda 2 px; pivot = ayak
## (görünür alt-orta piksel). Ayak noktası buna göre tuvale çevrilir.
const CANVAS_PAD: int = 2
## Nehir (seviye §7.1): dolgu + 1 px kıyı çizgisi (zemine 3.21:1). Alfa / fade yok.
const WATER_FILL := Color("#1F2B52")
const WATER_SHORE := Color("#476B8F")

## Hareketi Azalt (art bible §7): animasyon durur, kare 0.
var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		_update_processing()
		queue_redraw()

var _layer: MapDecorItem.Layer = MapDecorItem.Layer.PROP
var _items: Array[MapDecorItem] = []
var _water: Array[Rect2] = []
var _shore: Array[Rect2] = []
var _levels: Dictionary = {}  # bölge kimliği → bozulma seviyesi
var _time: float = 0.0
var _frame_tick: int = -1


## [param draw_water] yalnız GROUND katmanında: su dikdörtgenleri ve birleşik kıyı çizgisi.
func setup(decor: MapDecor, layer: MapDecorItem.Layer, draw_water: bool = false) -> void:
	_layer = layer
	_items = decor.items_in_layer(layer)
	_water = decor.water_rects.duplicate() if draw_water else ([] as Array[Rect2])
	_shore = shore_segments(_water)
	_update_processing()
	queue_redraw()


## Bağlı bölgelerin bozulma seviyeleri ([CampaignMap.refresh] zinciri); görünürlük buradan türer.
func apply_corruption(levels: Dictionary) -> void:
	if levels == _levels:
		return
	_levels = levels.duplicate()
	_update_processing()
	queue_redraw()


## Şu an görünen öğeler (çizim sırasıyla) — testler ve ölçüm için.
func visible_items() -> Array[MapDecorItem]:
	var out: Array[MapDecorItem] = []
	for item: MapDecorItem in _items:
		if item.is_visible(int(_levels.get(item.bound_region_id, 0))):
			out.append(item)
	return out


## Öğenin çizilecek karesi (Hareketi Azalt ya da durağan → 0).
func frame_index(item: MapDecorItem) -> int:
	if reduce_motion or not item.is_animated():
		return 0
	return int(_time * item.fps) % item.frames.size()


## Ayak noktasından tuvalin sol-üst köşesi (tam piksel).
static func canvas_origin(foot: Vector2, texture_size: Vector2i) -> Vector2:
	var visible_bottom: int = texture_size.y - 1 - CANVAS_PAD
	return Vector2(roundi(foot.x) - texture_size.x / 2, roundi(foot.y) - visible_bottom)


## Birleşik su alanının 1 px kıyısı: dikdörtgen kenar pikselleri, dışarıdaki komşu piksel başka bir
## su dikdörtgeninin içindeyse çizilmez (L-dönüşünde iç çizgi kalmaz). Yatay/dikey ardışık pikseller
## tek dikdörtgende birleştirilir.
static func shore_segments(rects: Array[Rect2]) -> Array[Rect2]:
	var cells: Dictionary = {}
	for rect: Rect2 in rects:
		var r: Rect2i = Rect2i(rect)
		for x: int in range(r.position.x, r.end.x):
			for y: int in range(r.position.y, r.end.y):
				cells[Vector2i(x, y)] = true
	var edge: Dictionary = {}
	for cell: Vector2i in cells:
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not cells.has(cell + step):
				edge[cell] = true
				break
	# Satır satır yatay koşular.
	var rows: Dictionary = {}
	for cell: Vector2i in edge:
		if not rows.has(cell.y):
			rows[cell.y] = []
		(rows[cell.y] as Array).append(cell.x)
	var segments: Array[Rect2] = []
	var ys: Array = rows.keys()
	ys.sort()
	for y: int in ys:
		var xs: Array = rows[y]
		xs.sort()
		var start: int = xs[0]
		var previous: int = xs[0]
		for i: int in range(1, xs.size() + 1):
			var x: int = xs[i] if i < xs.size() else -999999
			if x != previous + 1:
				segments.append(Rect2(start, y, previous - start + 1, 1))
				start = x
			previous = x
	return segments


func _process(delta: float) -> void:
	_time += delta
	var tick: int = int(_time * _max_fps())
	if tick != _frame_tick:
		_frame_tick = tick
		queue_redraw()


func _draw() -> void:
	for rect: Rect2 in _water:
		draw_rect(rect, WATER_FILL)
	for segment: Rect2 in _shore:
		draw_rect(segment, WATER_SHORE)
	for item: MapDecorItem in visible_items():
		if item.frames.is_empty():
			continue
		var texture: Texture2D = item.frames[frame_index(item)]
		draw_texture(texture, canvas_origin(item.position, texture.get_size()))


## `_process` yalnız görünür animasyonlu öğe varken ve Hareketi Azalt kapalıyken (seviye §7.6 VFX).
func _update_processing() -> void:
	var animate: bool = false
	if not reduce_motion:
		for item: MapDecorItem in visible_items():
			if item.is_animated():
				animate = true
				break
	set_process(animate)


func _max_fps() -> float:
	var fps: float = 0.0
	for item: MapDecorItem in _items:
		fps = maxf(fps, item.fps)
	return fps
