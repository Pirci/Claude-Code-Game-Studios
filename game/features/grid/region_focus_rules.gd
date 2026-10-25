class_name RegionFocusRules
extends RefCounted
## Klavyeyle bölge gezinmesi (hud §10.3 kural 5, K4): ok tuşları harita **komşuluğu** içinde,
## ekran geometrisine göre en uygun bölgeye gider. Harita her dilde LTR çizildiği için
## (ADR-0009) yönler de her dilde aynıdır — RTL'de sol ok yine soldaki bölgeye gider (UD kapandı, C-75).
## Saf: konumlar ve komşuluk listesinden eşleme üretir; o yönde komşu yoksa giriş yoktur.


enum Side { LEFT, RIGHT, UP, DOWN }

const DIRECTIONS: Dictionary = {
	Side.LEFT: Vector2.LEFT,
	Side.RIGHT: Vector2.RIGHT,
	Side.UP: Vector2.UP,
	Side.DOWN: Vector2.DOWN,
}
## Yön konisi: komşu, yön vektörüyle en çok ~67,5° açı yapabilir (cos 67,5° ≈ 0,38). Daha geniş
## koni çapraz komşuyu iki ayrı oka birden bağlar; daha dar koni bazı komşuları erişilmez bırakır.
const MIN_ALIGNMENT: float = 0.38


## [param centers] bölge → harita konumu, [param adjacency] bölge → komşu kimlikleri.
## Dönüş: bölge → { Side → komşu kimliği } (yalnız komşusu olan yönler).
static func neighbors(centers: Dictionary, adjacency: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for region_id: StringName in centers:
		var sides: Dictionary = {}
		for side: Side in DIRECTIONS:
			var best: StringName = _best(region_id, DIRECTIONS[side] as Vector2, centers, adjacency)
			if best != &"":
				sides[side] = best
		result[region_id] = sides
	return result


## En iyi aday: yönle en hizalı; eşitlikte en yakın, sonra kimlik sırası (deterministik).
static func _best(region_id: StringName, direction: Vector2, centers: Dictionary, adjacency: Dictionary) -> StringName:
	var origin: Vector2 = centers[region_id] as Vector2
	var best: StringName = &""
	var best_alignment: float = 0.0
	var best_distance: float = 0.0
	for other: StringName in adjacency.get(region_id, []):
		if not centers.has(other):
			continue
		var offset: Vector2 = (centers[other] as Vector2) - origin
		if offset == Vector2.ZERO:
			continue
		var alignment: float = offset.normalized().dot(direction)
		if alignment < MIN_ALIGNMENT:
			continue
		var distance: float = offset.length()
		if best == &"" or _ranks_before(alignment, distance, other, best_alignment, best_distance, best):
			best = other
			best_alignment = alignment
			best_distance = distance
	return best


static func _ranks_before(alignment: float, distance: float, region_id: StringName,
		best_alignment: float, best_distance: float, best_id: StringName) -> bool:
	if not is_equal_approx(alignment, best_alignment):
		return alignment > best_alignment
	if not is_equal_approx(distance, best_distance):
		return distance < best_distance
	return String(region_id) < String(best_id)
