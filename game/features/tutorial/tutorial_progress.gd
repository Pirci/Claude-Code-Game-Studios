class_name TutorialProgress
extends RefCounted
## Görülen öğretici ipuçları (kalıcı oyuncu ayarı — `settings.json`, C-41 kararı; kampanya
## kaydından bağımsız, Yeni Sefer'de de tekrar gösterilmez). Yazarı: ipucu balonu kapanınca
## GameContext ve ayarlardaki "Öğreticiyi Sıfırla".


## Görülen ipuçları değişti — RootContext ayarları kalıcı yazar (signal up).
signal changed

var _seen: Array[StringName] = []


func has_seen(hint_id: StringName) -> bool:
	return hint_id in _seen


func mark_seen(hint_id: StringName) -> void:
	if hint_id == &"" or has_seen(hint_id):
		return
	_seen.append(hint_id)
	changed.emit()


## Kayıtlı listeyi yükler (sinyal yayılmaz — yükleme değişiklik sayılmaz).
func load_seen(hint_ids: Array[StringName]) -> void:
	_seen.clear()
	for hint_id: StringName in hint_ids:
		if hint_id not in _seen:
			_seen.append(hint_id)


func seen_ids() -> Array[StringName]:
	return _seen.duplicate()


func reset() -> void:
	if _seen.is_empty():
		return
	_seen.clear()
	changed.emit()
