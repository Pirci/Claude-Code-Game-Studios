class_name TamgaLibrary
extends RefCounted
## tamga_id → tamga dokusu (9×9: 7×7 glif + 1px outline). Dosya adı art bible §8
## kalıbını izler: icon_tamga_<id>.png. Üretici: tools/asset-pipeline/generate_tamga_icons.gd


const ICON_DIR: String = "res://assets/art/ui/icons/"

var _cache: Dictionary[StringName, Texture2D] = {}


## [param tamga_id] için doku yolu.
static func texture_path(tamga_id: StringName) -> String:
	return "%sicon_tamga_%s.png" % [ICON_DIR, tamga_id]


## Tamga dokusu; id boşsa veya dosya yoksa null (bölge tamgasız çizilir).
func get_texture(tamga_id: StringName) -> Texture2D:
	if tamga_id == &"":
		return null
	if _cache.has(tamga_id):
		return _cache[tamga_id]
	var path: String = texture_path(tamga_id)
	if not ResourceLoader.exists(path):
		push_warning("Tamga dokusu yok: %s" % path)
		return null
	var texture: Texture2D = load(path) as Texture2D
	_cache[tamga_id] = texture
	return texture
