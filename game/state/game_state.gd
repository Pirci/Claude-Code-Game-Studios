class_name GameState
extends RefCounted
## Oyunun tüm kalıcı durumunu tutar. Mantık yok, sadece veri.


var current_chapter: int = 1
var gold: int = 0
## Kök Böri'nin Ruh hazinesi — tek musluk arındırma (spirit §3.3); yazarı SpiritController.
var ruh: int = 0
## Kaydedilmiş lütuf seçimleri (sırayla `boon_id`) — lütuf etkilerinin tek kaynağı;
## yazarı SpiritController (C-38/C-39), kaydı ADR-0007.
var boons: Array[StringName] = []
## Türetilmiş: [member boons] (ve ileride konsey) seçimlerinden [ModifierController.rebuild]
## ile kurulur, kaydedilmez. Yalnızca [StatResolver] ile okunur (ADR-0006).
var modifiers: Array[StatModifier] = []
var chapters_completed: Array[int] = []
## Sefer tohumu (scene-flow §3.4, ADR-0007 eki C-77): Yeni Sefer'de üretilir, sefer boyunca sabit
## (S1–S3, Devam Et, Yeniden Dene). 0 = tohumsuz (v1 kayıt) — lütuf sunumu eski çıktıyı verir (spirit AC4).
var campaign_seed: int = 0
var map_state: MapState = null


func is_chapter_unlocked(chapter: int) -> bool:
	if chapter == 1:
		return true
	return (chapter - 1) in chapters_completed


func reset() -> void:
	current_chapter = 1
	gold = 0
	ruh = 0
	boons.clear()
	modifiers.clear()
	chapters_completed.clear()
	campaign_seed = 0
	map_state = null
