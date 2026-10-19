class_name FileSaveStore
extends SaveStore
## `user://saves/<slot>.json` (+ `.bak`, `.tmp`) — atomik yazma (ADR-0007 "Atomicity"):
## (1) aynı klasörde `.tmp`'ye yaz, kapat; (2) asıl varsa eski `.bak`'ı sil, asıl → `.bak`;
## (3) `.tmp` → asıl. Üzerine-yazan rename'e güvenilmez; her adımın hatası denetlenir, bir kez
## yeniden denenir (antivirüs/OneDrive kilitleri). Herhangi bir adım düşerse önceki kayıt
## asıl, `.bak` ya da `.tmp` olarak yüklenebilir kalır.


const EXTENSION: String = ".json"
const BACKUP_SUFFIX: String = ".bak"
const TEMP_SUFFIX: String = ".tmp"

var _directory: String


func _init(directory: String = "user://saves") -> void:
	_directory = directory


func write(slot: StringName, text: String) -> bool:
	if DirAccess.make_dir_recursive_absolute(_directory) != OK:
		return false
	var final_path: String = path_for(slot)
	var temp_path: String = final_path + TEMP_SUFFIX
	var backup_path: String = final_path + BACKUP_SUFFIX
	if not _write_text(temp_path, text):
		return false
	if FileAccess.file_exists(final_path):
		if FileAccess.file_exists(backup_path) and not _with_retry(_remove.bind(backup_path)):
			return false
		if not _with_retry(_rename.bind(final_path, backup_path)):
			return false
	return _with_retry(_rename.bind(temp_path, final_path))


func read_candidates(slot: StringName) -> PackedStringArray:
	var texts: PackedStringArray = []
	var final_path: String = path_for(slot)
	for path: String in [final_path, final_path + BACKUP_SUFFIX, final_path + TEMP_SUFFIX]:
		if FileAccess.file_exists(path):
			texts.append(FileAccess.get_file_as_string(path))
	return texts


func path_for(slot: StringName) -> String:
	return _directory.path_join(String(slot) + EXTENSION)


## Dosya işlemleri — test alt sınıfları belirli bir adımda hata benzetmek için ezer.
func _write_text(path: String, text: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Kayıt açılamadı (%s): %s" % [path, FileAccess.get_open_error()])
		return false
	var stored: bool = file.store_string(text)
	file.close()
	return stored


func _rename(from_path: String, to_path: String) -> Error:
	return DirAccess.rename_absolute(from_path, to_path)


func _remove(path: String) -> Error:
	return DirAccess.remove_absolute(path)


func _with_retry(operation: Callable) -> bool:
	for attempt: int in 2:
		if operation.call() == OK:
			return true
	return false
