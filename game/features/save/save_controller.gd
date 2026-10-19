class_name SaveController
extends RefCounted
## Ne zaman kaydedilip yükleneceği (ADR-0007). RootContext sahiplenir (C-17 D4); GameContext
## `turn_ended`'da [method save_campaign] çağırır; "Devam Et" [method load_campaign] kullanır.


signal save_failed(reason: StringName)

const CAMPAIGN_SLOT: StringName = &"campaign"

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
	var saved_at: String = Time.get_datetime_string_from_system(true) + "Z"
	if not _store.write(CAMPAIGN_SLOT, SaveSerializer.to_text(game_state, saved_at)):
		save_failed.emit(&"write_failed")
		return false
	return true


## Adayları sırayla dener (asıl → .bak → .tmp); ilk geçerli kayıt döner. Daha yeni sürüm
## görülürse yedeğe düşülmez (sonraki otomatik kayıt onu ezmesin diye).
func load_campaign() -> LoadResult:
	if _store == null:
		return LoadResult.error(LoadResult.Code.MISSING, "depo yok")
	var first_error: LoadResult = null
	for text: String in _store.read_candidates(CAMPAIGN_SLOT):
		var result: LoadResult = SaveSerializer.from_text(text, _map_factory)
		if result.code == LoadResult.Code.OK:
			return result
		if result.code == LoadResult.Code.VERSION_TOO_NEW:
			_newer_save_present = true
			return result
		if first_error == null:
			first_error = result
	return first_error if first_error != null else LoadResult.error(LoadResult.Code.MISSING, "kayıt yok")


## "Devam Et" yalnızca yüklenebilir bir kayıt varken etkin.
func has_campaign() -> bool:
	return load_campaign().code == LoadResult.Code.OK
