class_name SaveSerializer
extends RefCounted
## GameState ↔ sürümlü JSON sözlüğü — saf: durum yok, dosya G/Ç yok (ADR-0007).
## Yalnızca değişken alanlar yazılır; bölge geometrisi, komşuluk, adlar ve `initial_owner`
## içerikten (`map_factory(chapter_id)`) yeniden kurulur. `modifiers` türetilir (ADR-0006),
## `game_result` kaydedilmez (yalnızca oyun sürerken kaydedilir).


## v2 (C-77): `game.campaign_seed` zorunlu; v1 kayıt `migrate` ile 0 alır.
const SCHEMA_VERSION: int = 2
## Doğrulama aralıkları (GDD aralıklarının üstünde güvenlik sınırları).
const MAX_GOLD: int = 1_000_000_000
const MAX_RUH: int = 1_000_000_000
const MAX_ARMY: int = 1_000_000
const MAX_TURN: int = 1_000_000
const MAX_CHAPTER: int = 1000
## Tohum aralığı: pozitif 31 bit (0 = tohumsuz eski kayıt).
const MAX_SEED: int = 0x7FFFFFFF
const MAX_CORRUPTION: int = 3
## Kayıtta sahiplik enum'u int olarak (RegionData.Owner: NEUTRAL 0, PLAYER 1, ENEMY 2).
const OWNER_MAX: int = 2
## Kaçış dizisiyle yazılır: kaynakta çıplak U+FEFF dışa aktarmada silinir (C-42 hatası).
const UTF8_BOM: String = "\uFEFF"


## [param saved_at] bilgi amaçlıdır, mantık okumaz; testlerde sabit verilir (byte-eşit çıktı).
static func to_dict(game_state: GameState, saved_at: String = "") -> Dictionary:
	var boons: Array = []
	for boon_id: StringName in game_state.boons:
		boons.append(String(boon_id))
	var game: Dictionary = {
		"current_chapter": game_state.current_chapter,
		"gold": game_state.gold,
		"ruh": game_state.ruh,
		"boons": boons,
		"chapters_completed": game_state.chapters_completed.duplicate(),
		"campaign_seed": game_state.campaign_seed,
		"map": _map_to_dict(game_state.map_state),
	}
	return {"schema_version": SCHEMA_VERSION, "saved_at": saved_at, "game": game}


## Deterministik metin: girintili, anahtarlar sıralı, tam hassasiyet (ADR-0007).
static func to_text(game_state: GameState, saved_at: String = "") -> String:
	return JSON.stringify(to_dict(game_state, saved_at), "\t", true, true)


## Öndeki UTF-8 BOM'u atar; karşılaştırma karakter koduyla (sabit boş olsa bile ilk
## karakteri kesmez — C-42).
static func strip_bom(text: String) -> String:
	return text.substr(1) if not text.is_empty() and text.unicode_at(0) == 0xFEFF else text


## Metni ayrıştırır (önde BOM atılır) ve doğrular. Hiçbir zaman `str_to_var`/`load()` yok.
static func from_text(text: String, map_factory: Callable) -> LoadResult:
	if text.is_empty():
		return LoadResult.error(LoadResult.Code.MISSING, "boş kayıt")
	var clean: String = strip_bom(text)
	var json: JSON = JSON.new()
	if json.parse(clean) != OK:
		return LoadResult.error(LoadResult.Code.CORRUPT,
			"JSON satır %d: %s" % [json.get_error_line(), json.get_error_message()])
	if typeof(json.data) != TYPE_DICTIONARY:
		return LoadResult.error(LoadResult.Code.CORRUPT, "kök sözlük değil")
	return from_dict(json.data as Dictionary, map_factory)


## Toplam doğrulama: herhangi bir yapısal hata → hata kodu, `state = null` (kısmi uygulama yok).
## [param map_factory]: `(chapter_id: int) -> MapState` (içerikten taze harita; yoksa null).
static func from_dict(data: Dictionary, map_factory: Callable) -> LoadResult:
	var version: Variant = as_int(data.get("schema_version"), 1, MAX_TURN)
	if version == null:
		return LoadResult.error(LoadResult.Code.CORRUPT, "schema_version geçersiz")
	if int(version) > SCHEMA_VERSION:
		return LoadResult.error(LoadResult.Code.VERSION_TOO_NEW, "kayıt sürümü %d > %d" % [version, SCHEMA_VERSION])
	var migrated: Dictionary = migrate(data)
	var game: Variant = migrated.get("game")
	if typeof(game) != TYPE_DICTIONARY:
		return LoadResult.error(LoadResult.Code.CORRUPT, "game bloğu yok")
	return _game_from_dict(game as Dictionary, map_factory)


## Sürüm zinciri v1 → v2 → …; her adım bir sonraki sürümün zorunlu alanlarını ekler. Girdi değişmez.
static func migrate(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	var version: int = int(out.get("schema_version", 1))
	if version < 2:
		# v1 → v2: tohumsuz sefer (0 = eski sunum çıktısı, spirit AC4).
		var game: Variant = out.get("game")
		if typeof(game) == TYPE_DICTIONARY and not (game as Dictionary).has("campaign_seed"):
			(game as Dictionary)["campaign_seed"] = 0
		out["schema_version"] = 2
	return out


static func _map_to_dict(map_state: MapState) -> Variant:
	if map_state == null:
		return null
	var regions: Dictionary = {}
	for region: RegionData in map_state.regions.values():
		regions[String(region.region_id)] = {
			"owner": int(region.owner),
			"army_count": region.army_count,
			"corruption_level": region.corruption_level,
		}
	return {
		"chapter_id": map_state.chapter_id,
		"current_turn": map_state.current_turn,
		"last_erlik_spread_turn": map_state.last_erlik_spread_turn,
		"regions": regions,
	}


static func _game_from_dict(game: Dictionary, map_factory: Callable) -> LoadResult:
	var state: GameState = GameState.new()
	var chapter: Variant = as_int(game.get("current_chapter"), 1, MAX_CHAPTER)
	var gold: Variant = as_int(game.get("gold"), 0, MAX_GOLD)
	var ruh: Variant = as_int(game.get("ruh"), 0, MAX_RUH)
	if chapter == null or gold == null or ruh == null:
		return LoadResult.error(LoadResult.Code.CORRUPT, "current_chapter / gold / ruh geçersiz")
	state.current_chapter = int(chapter)
	state.gold = int(gold)
	state.ruh = int(ruh)
	var seed_value: Variant = as_int(game.get("campaign_seed"), 0, MAX_SEED)
	if seed_value == null:
		return LoadResult.error(LoadResult.Code.CORRUPT, "campaign_seed geçersiz")
	state.campaign_seed = int(seed_value)

	var boons: Variant = game.get("boons")
	if typeof(boons) != TYPE_ARRAY:
		return LoadResult.error(LoadResult.Code.CORRUPT, "boons dizi değil")
	for boon: Variant in boons as Array:
		if typeof(boon) != TYPE_STRING or (boon as String).is_empty():
			return LoadResult.error(LoadResult.Code.CORRUPT, "boons öğesi geçersiz")
		state.boons.append(StringName(boon as String))

	var completed: Variant = game.get("chapters_completed")
	if typeof(completed) != TYPE_ARRAY:
		return LoadResult.error(LoadResult.Code.CORRUPT, "chapters_completed dizi değil")
	var expected: int = 1
	for item: Variant in completed as Array:
		# Doğrusal kampanya: tamamlananlar {1…m} öneki olmalı (scene-flow F1, ADR-0007 C-35 eki).
		var value: Variant = as_int(item, 1, MAX_CHAPTER)
		if value == null or int(value) != expected:
			return LoadResult.error(LoadResult.Code.CORRUPT, "chapters_completed önek değil")
		state.chapters_completed.append(int(value))
		expected += 1

	var map: Variant = game.get("map")
	if map == null:
		return LoadResult.ok(state)
	if typeof(map) != TYPE_DICTIONARY:
		return LoadResult.error(LoadResult.Code.CORRUPT, "map sözlük değil")
	return _attach_map(state, map as Dictionary, map_factory)


static func _attach_map(state: GameState, map: Dictionary, map_factory: Callable) -> LoadResult:
	var chapter_id: Variant = as_int(map.get("chapter_id"), 1, MAX_CHAPTER)
	if chapter_id == null or int(chapter_id) != state.current_chapter:
		return LoadResult.error(LoadResult.Code.CORRUPT, "map.chapter_id current_chapter ile uyuşmuyor")
	var turn: Variant = as_int(map.get("current_turn"), 1, MAX_TURN)
	if turn == null:
		return LoadResult.error(LoadResult.Code.CORRUPT, "current_turn geçersiz")
	var last_spread: Variant = as_int(map.get("last_erlik_spread_turn"), 0, int(turn))
	if last_spread == null:
		return LoadResult.error(LoadResult.Code.CORRUPT, "last_erlik_spread_turn geçersiz")
	if not map_factory.is_valid():
		return LoadResult.error(LoadResult.Code.CONTENT_MISSING, "harita fabrikası yok")
	var map_state: MapState = map_factory.call(int(chapter_id)) as MapState
	if map_state == null:
		return LoadResult.error(LoadResult.Code.CONTENT_MISSING, "bölüm içeriği yok: %d" % chapter_id)

	var regions: Variant = map.get("regions")
	if typeof(regions) != TYPE_DICTIONARY or (regions as Dictionary).size() != map_state.regions.size():
		return LoadResult.error(LoadResult.Code.CORRUPT, "regions bölüm içeriğiyle uyuşmuyor")
	for key: Variant in (regions as Dictionary).keys():
		var region: RegionData = map_state.get_region(StringName(str(key)))
		var saved: Variant = (regions as Dictionary)[key]
		if region == null or typeof(saved) != TYPE_DICTIONARY:
			return LoadResult.error(LoadResult.Code.CORRUPT, "bilinmeyen bölge: %s" % key)
		var owner: Variant = as_int((saved as Dictionary).get("owner"), 0, OWNER_MAX)
		var army: Variant = as_int((saved as Dictionary).get("army_count"), 0, MAX_ARMY)
		var corruption: Variant = as_int((saved as Dictionary).get("corruption_level"), 0, MAX_CORRUPTION)
		if owner == null or army == null or corruption == null:
			return LoadResult.error(LoadResult.Code.CORRUPT, "bölge alanı geçersiz: %s" % key)
		# Sahipli bölge 0 orduyla kalmaz (army §3.3, W3).
		if int(owner) != RegionData.Owner.NEUTRAL and int(army) == 0:
			return LoadResult.error(LoadResult.Code.CORRUPT, "sahipli bölge 0 ordulu: %s" % key)
		region.owner = int(owner) as RegionData.Owner
		region.army_count = int(army)
		region.corruption_level = int(corruption)

	map_state.current_turn = int(turn)
	map_state.last_erlik_spread_turn = int(last_spread)
	map_state.actions_remaining = map_state.actions_per_turn
	state.map_state = map_state
	return LoadResult.ok(state)


## JSON sayısı → int: sonlu, tam ve aralıkta olmalı; değilse null (`int(INF)` = INT64_MIN).
static func as_int(value: Variant, min_value: int, max_value: int) -> Variant:
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		return null
	var number: float = float(value)
	if not is_finite(number) or floorf(number) != number:
		return null
	if number < min_value or number > max_value:
		return null
	return int(number)
