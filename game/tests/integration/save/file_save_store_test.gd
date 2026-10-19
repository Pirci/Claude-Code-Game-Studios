extends GdUnitTestSuite
## FileSaveStore — gerçek dosyalarla atomik yazma ve adım adım hata benzetimi (ADR-0007, C-56).
## Entegrasyon testi: `user://` altında geçici klasör kullanır ve temizler.


const DIR: String = "user://test_saves_c56"
const SLOT: StringName = &"campaign"


## Belirli bir dosya işleminde hata veren depo (antivirüs kilidi / disk dolu benzetimi).
class FailingStore extends FileSaveStore:
	var fail_write: bool = false
	var fail_rename_to: String = ""

	func _write_text(path: String, text: String) -> bool:
		return false if fail_write else super(path, text)

	func _rename(from_path: String, to_path: String) -> Error:
		return ERR_FILE_CANT_WRITE if to_path.ends_with(fail_rename_to) and fail_rename_to != "" else super(from_path, to_path)


func before_test() -> void:
	_clean()


func after_test() -> void:
	_clean()


func _clean() -> void:
	var store: FileSaveStore = FileSaveStore.new(DIR)
	var base: String = store.path_for(SLOT)
	for path: String in [base, base + ".bak", base + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if DirAccess.dir_exists_absolute(DIR):
		DirAccess.remove_absolute(DIR)


func test_second_write_rotates_previous_into_backup() -> void:
	var store: FileSaveStore = FileSaveStore.new(DIR)
	assert_bool(store.write(SLOT, "bir")).is_true()
	assert_bool(store.write(SLOT, "iki")).is_true()
	assert_array(Array(store.read_candidates(SLOT))).contains_exactly(["iki", "bir"])


func test_failed_temp_write_leaves_previous_save() -> void:
	var store: FailingStore = FailingStore.new(DIR)
	store.write(SLOT, "eski")
	store.fail_write = true
	assert_bool(store.write(SLOT, "yeni")).is_false()
	assert_str(store.read_candidates(SLOT)[0]).is_equal("eski")


func test_failed_backup_rotation_keeps_final() -> void:
	var store: FailingStore = FailingStore.new(DIR)
	store.write(SLOT, "eski")
	store.fail_rename_to = ".bak"
	assert_bool(store.write(SLOT, "yeni")).is_false()
	assert_str(store.read_candidates(SLOT)[0]).is_equal("eski")


func test_failed_final_rename_leaves_backup_then_temp() -> void:
	var store: FailingStore = FailingStore.new(DIR)
	store.write(SLOT, "eski")
	store.fail_rename_to = ".json"
	assert_bool(store.write(SLOT, "yeni")).is_false()
	# Asıl yok; önce .bak (eski, iyi), sonra .tmp (yeni) denenir.
	assert_array(Array(store.read_candidates(SLOT))).contains_exactly(["eski", "yeni"])
