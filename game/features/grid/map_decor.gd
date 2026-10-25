class_name MapDecor
extends Resource
## Bir bölümün harita dekoru (seviye belgesi perde1 §7.6): öğeler + su dikdörtgenleri (nehir kodla çizilir,
## §7.3). [member ChapterMapDefinition.decor] null ise dekor yoktur (Prolog — davranış değişmez).


@export var items: Array[MapDecorItem] = []
## Nehir / gölcük dikdörtgenleri (harita koordinatı); GROUND katmanında çizilir.
@export var water_rects: Array[Rect2] = []


## Katmanın öğeleri çizim sırasıyla: ayak `y` artan (aşağıdaki önde), eşitlikte `x` artan (deterministik).
func items_in_layer(layer: MapDecorItem.Layer) -> Array[MapDecorItem]:
	var out: Array[MapDecorItem] = []
	for item: MapDecorItem in items:
		if item != null and item.layer == layer:
			out.append(item)
	out.sort_custom(func(a: MapDecorItem, b: MapDecorItem) -> bool:
		if not is_equal_approx(a.position.y, b.position.y):
			return a.position.y < b.position.y
		return a.position.x < b.position.x)
	return out
