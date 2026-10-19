class_name PanelPlacement
extends RefCounted
## Harita üstü panel yerleşimi (scene-flow §3.5 UX kuralı: panel hedef işaretlerini örtmez) —
## saf. Adaylar tercih sırasıyla verilir: hiçbir engelle kesişmeyen ilk aday, yoksa toplam
## kesişme alanı en küçük olan (eşitlikte önce gelen) seçilir.


static func choose(candidates: Array[Rect2], obstacles: Array[Rect2]) -> int:
	var best: int = 0
	var best_overlap: float = INF
	for i: int in candidates.size():
		var overlap: float = 0.0
		for obstacle: Rect2 in obstacles:
			overlap += candidates[i].intersection(obstacle).get_area()
		if overlap == 0.0:
			return i
		if overlap < best_overlap:
			best_overlap = overlap
			best = i
	return best
