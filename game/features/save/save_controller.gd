class_name SaveController
extends RefCounted
## Ne zaman kaydedilip yükleneceği (ADR-0007). RootContext sahiplenir (C-17 D4); GameContext
## `turn_ended`'da [method save_campaign] çağırır; "Devam Et" [method load_campaign] kullanır.


signal save_failed(reason: StringName)

const CAMPAIGN_SLOT: StringName = &"campaign"
## Sahne girişi anlık görüntüsü (scene-flow S2, ADR-0012 karar 5): `campaign` ile aynı belge
## biçimi; her sahne girişinde üzerine yazılır, Yeniden Dene buradan okur.
const SCENE_ENTRY_SLOT: StringName = &"scene_entry"
## Ayarlar ayrı belge (`settings.json`), kendi şema sürümü (C-65).
const SETTINGS_SLOT: StringName = &"settings"

var _store: SaveStore = null
var _map_factory: Callable = Callable()
## Daha yeni sürümün kaydı bulunduysa üzerine yazılmaz (VERSION_TOO_NEW).
var _newer_save_present: bool = false


## [param map_factory]: `(chapter_id: int) -> MapState` — içerikten taze bölüm haritası.
func bind_services(store: SaveStore, map_factory: Callable) -> void:
	_store = store
	_map_factory = map_factory


## Yalnızca oyun sürerken kaydeder (bitmiş sahneyi sahne akışı kaydeder — scene-flow S3).
func save_campaign(game_state: GameState) -> bool:
	if _store == null or game_state == null:
		return false
	if game_state.map_state != null and game_state.map_state.game_result != MapState.GameResult.ONGOING:
		return false
	if _newer_save_present:
		save_failed.emit(&"newer_save_present")
		return false
	if not _store.write(CAMPAIGN_SLOT, SaveSerializer.to_text(game_state, _timestamp())):
		save_failed.emit(&"write_failed")
		return false
	return true


## S2 (scene-flow §3.4): 1. tur başı durumu `campaign` **ve** `scene_entry` yuvalarına yazar.
## İkisi de yazılırsa true; `scene_entry` yazılamazsa Yeniden Dene bellekteki kopyayı kullanır.
func save_scene_entry(game_state: GameState) -> bool:
	if not save_campaign(game_state):
		return false
	if not _store.write(SCENE_ENTRY_SLOT, SaveSerializer.to_text(game_state, _timestamp())):
		save_failed.emit(&"scene_entry_write_failed")
		return false
	return true


## S3 (T18 COMMIT sonrası): tamamlanmış sahne, `map = null` — oyun-sonu kilidinden bağımsız.
func save_completed(game_state: GameState) -> bool:
	if _store == null or game_state == null or game_state.map_state != null:
		return false
	if _newer_save_present:
		save_failed.emit(&"newer_save_present")
		return false
	if not _store.write(CAMPAIGN_SLOT, SaveSerializer.to_text(game_state, _timestamp())):
		save_failed.emit(&"write_failed")
		return false
	return true


## Yeniden Dene için sahne girişi kaydı (asıl → .bak → .tmp).
func load_scene_entry() -> LoadResult:
	return _load_slot(SCENE_ENTRY_SLOT)


## Adayları sırayla dener (asıl → .bak → .tmp); ilk geçerli kayıt döner. Daha yeni sürüm
## görülürse yedeğe düşülmez (sonraki otomatik kayıt onu ezmesin diye).
func load_campaign() -> LoadResult:
	return _load_slot(CAMPAIGN_SLOT)


func _load_slot(slot: StringName) -> LoadResult:
	if _store == null:
		return LoadResult.error(LoadResult.Code.MISSING, "depo yok")
	var first_error: LoadResult = null
	for text: String in _store.read_candidates(slot):
		var result: LoadResult = SaveSerializer.from_text(text, _map_factory)
		if result.code == LoadResult.Code.OK:
			return result
		if result.code == LoadResult.Code.VERSION_TOO_NEW:
			_newer_save_present = true
			return result
		if first_error == null:
			first_error = result
	return first_error if first_error != null else LoadResult.error(LoadResult.Code.MISSING, "kayıt yok")


## Ayarlar değişince yazılır (ADR-0007). Başarıda true.
func save_settings(snapshot: SettingsSnapshot) -> bool:
	if _store == null or snapshot == null:
		return false
	if not _store.write(SETTINGS_SLOT, SettingsSerializer.to_text(snapshot)):
		save_failed.emit(&"settings_write_failed")
		return false
	return true


## İlk geçerli ayar belgesi (asıl → .bak → .tmp); yoksa null → varsayılanlar.
func load_settings() -> SettingsSnapshot:
	if _store == null:
		return null
	for text: String in _store.read_candidates(SETTINGS_SLOT):
		var snapshot: SettingsSnapshot = SettingsSerializer.from_text(text)
		if snapshot != null:
			return snapshot
	return null


## "Devam Et" yalnızca yüklenebilir bir kayıt varken etkin.
func has_campaign() -> bool:
	return load_campaign().code == LoadResult.Code.OK


static func _timestamp() -> String:
	return Time.get_datetime_string_from_system(true) + "Z"
