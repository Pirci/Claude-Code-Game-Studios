class_name MemorySaveStore
extends SaveStore
## Bellek içi depo — testler ve hata ayıklama için (ADR-0007 test çifti).


## true iken her yazma başarısız olur (disk dolu benzetimi).
var fail_writes: bool = false
## Başarılı yazma sayısı (sahne akışı testleri: yenilgide yazım olmamalı).
var write_count: int = 0
var _texts: Dictionary[StringName, PackedStringArray] = {}


func write(slot: StringName, text: String) -> bool:
	if fail_writes:
		return false
	var history: PackedStringArray = _texts.get(slot, PackedStringArray())
	# Asıl + bir önceki (.bak benzeri) tutulur.
	history.insert(0, text)
	if history.size() > 2:
		history.resize(2)
	_texts[slot] = history
	write_count += 1
	return true


func read_candidates(slot: StringName) -> PackedStringArray:
	return _texts.get(slot, PackedStringArray())


## Testler için: [param slot]'a ham aday listesi koyar (bozuk asıl + iyi yedek gibi).
func set_candidates(slot: StringName, texts: PackedStringArray) -> void:
	_texts[slot] = texts
