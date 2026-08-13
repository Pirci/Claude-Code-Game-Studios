class_name GameState
extends RefCounted
## Oyunun tüm kalıcı durumunu tutar. Mantık yok, sadece veri.


var current_chapter: int = 1
var gold: int = 0
var bozkurt_bonuses: Array[float] = []
var chapters_completed: Array[int] = []
var map_state: MapState = null


func is_chapter_unlocked(chapter: int) -> bool:
	if chapter == 1:
		return true
	return (chapter - 1) in chapters_completed


func get_total_bozkurt_bonus() -> float:
	var total: float = 0.0
	for bonus: float in bozkurt_bonuses:
		total += bonus
	return total


func reset() -> void:
	current_chapter = 1
	gold = 0
	bozkurt_bonuses.clear()
	chapters_completed.clear()
	map_state = null
