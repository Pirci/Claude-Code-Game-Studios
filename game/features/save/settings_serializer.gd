class_name SettingsSerializer
extends RefCounted
## SettingsSnapshot ↔ sürümlü JSON — saf (ADR-0007). Geçersiz ya da daha yeni sürüm dosya
## `null` döner; çağıran varsayılanlarla açılır (bozuk ayar oyunu engellemez).


const SCHEMA_VERSION: int = 1
## coding-standards "Desteklenen diller" (11).
const SUPPORTED_LOCALES: Array[String] = ["en", "tr", "de", "fr", "es", "zh", "ja", "ko", "ru", "pt", "ar"]


static func to_text(snapshot: SettingsSnapshot) -> String:
	var data: Dictionary = {
		"schema_version": SCHEMA_VERSION,
		"accessibility": {
			"color_blind_mode": snapshot.color_blind_mode,
			"reduce_motion": snapshot.reduce_motion,
			"show_region_names": snapshot.show_region_names,
		},
		"display": {"fullscreen": snapshot.fullscreen},
		"locale": snapshot.locale,
		"audio": {
			"master": snapshot.master_volume,
			"music": snapshot.music_volume,
			"sfx": snapshot.sfx_volume,
		},
		"tutorial": {"seen_hints": snapshot.seen_hints},
	}
	return JSON.stringify(data, "\t", true, true)


static func from_text(text: String) -> SettingsSnapshot:
	var clean: String = SaveSerializer.strip_bom(text)
	var json: JSON = JSON.new()
	if clean.is_empty() or json.parse(clean) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return null
	var data: Dictionary = json.data as Dictionary
	var version: Variant = SaveSerializer.as_int(data.get("schema_version"), 1, SCHEMA_VERSION)
	var accessibility: Variant = data.get("accessibility")
	var display: Variant = data.get("display")
	var audio: Variant = data.get("audio")
	var locale: Variant = data.get("locale")
	if version == null or typeof(accessibility) != TYPE_DICTIONARY or typeof(display) != TYPE_DICTIONARY \
			or typeof(audio) != TYPE_DICTIONARY or typeof(locale) != TYPE_STRING \
			or (locale as String) not in SUPPORTED_LOCALES:
		return null
	var snapshot: SettingsSnapshot = SettingsSnapshot.new()
	snapshot.locale = locale as String
	for pair: Array in [["color_blind_mode", accessibility], ["reduce_motion", accessibility],
			["show_region_names", accessibility], ["fullscreen", display]]:
		var value: Variant = (pair[1] as Dictionary).get(pair[0])
		if typeof(value) != TYPE_BOOL:
			return null
		snapshot.set(pair[0], value)
	for pair: Array in [["master", "master_volume"], ["music", "music_volume"], ["sfx", "sfx_volume"]]:
		var volume: Variant = (audio as Dictionary).get(pair[0])
		if typeof(volume) != TYPE_FLOAT and typeof(volume) != TYPE_INT:
			return null
		if not is_finite(float(volume)) or float(volume) < 0.0 or float(volume) > 1.0:
			return null
		snapshot.set(pair[1], float(volume))
	snapshot.seen_hints = _read_seen_hints(data.get("tutorial"))
	return snapshot


## Eski dosyalarda `tutorial` yok → boş. Bilinmeyen ya da yinelenen kimlikler atılır (bozuk
## öğretici durumu oyunu ya da ayarları geçersiz kılmaz).
static func _read_seen_hints(tutorial: Variant) -> Array[StringName]:
	var seen: Array[StringName] = []
	if typeof(tutorial) != TYPE_DICTIONARY:
		return seen
	var raw: Variant = (tutorial as Dictionary).get("seen_hints")
	if typeof(raw) != TYPE_ARRAY:
		return seen
	for item: Variant in raw as Array:
		if typeof(item) == TYPE_STRING and StringName(item as String) in TutorialRules.ALL \
				and StringName(item as String) not in seen:
			seen.append(StringName(item as String))
	return seen
