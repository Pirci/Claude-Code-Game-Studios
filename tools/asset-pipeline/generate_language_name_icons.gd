extends SceneTree
## Dil seçim listesindeki her dilin kendi adını, o dilin pixel fontuyla ve native
## boyutunda PNG olarak önceden çizer → game/assets/art/ui/theme/lang_name_<code>.png
##
## Neden görsel: liste tek bir tema fontuyla çizilir; "العربية" Fusion 12px'te yok,
## Unifont'u 12px'e küçültmek pikselleri bozar. Her ad kendi fontunda çizilince
## liste hangi arayüz dilinde açılırsa açılsın tutarlı ve keskin kalır.
##
## Kullanım (repo kökünden, pencereli — metin render gerektirir, --headless OLMAZ):
##   godot --path game --script ../tools/asset-pipeline/generate_language_name_icons.gd

const OUT: String = "res://assets/art/ui/theme/"
const CREAM := Color(0.95, 0.9, 0.78)
const LATIN: String = "res://assets/fonts/fusion_pixel_12px_latin.woff2"
const NAMES: Dictionary[String, Array] = {
	"en": ["English", LATIN, 12],
	"tr": ["Türkçe", LATIN, 12],
	"de": ["Deutsch", LATIN, 12],
	"fr": ["Français", LATIN, 12],
	"es": ["Español", LATIN, 12],
	"zh": ["中文", "res://assets/fonts/fusion_pixel_12px_zh_hans.woff2", 12],
	"ja": ["日本語", "res://assets/fonts/fusion_pixel_12px_ja.woff2", 12],
	"ko": ["한국어", "res://assets/fonts/fusion_pixel_12px_ko.woff2", 12],
	"ru": ["Русский", LATIN, 12],
	"pt": ["Português", LATIN, 12],
	"ar": ["العربية", "res://assets/fonts/unifont.otf", 16],
}

var _jobs: Array[Dictionary] = []
var _frames: int = 0


func _initialize() -> void:
	for code: String in NAMES:
		var spec: Array = NAMES[code]
		var vp: SubViewport = SubViewport.new()
		vp.transparent_bg = true
		vp.size = Vector2i(128, 32)
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		var label: Label = Label.new()
		label.text = spec[0] as String
		label.add_theme_font_override(&"font", load(spec[1] as String) as Font)
		label.add_theme_font_size_override(&"font_size", spec[2] as int)
		label.add_theme_color_override(&"font_color", CREAM)
		vp.add_child(label)
		root.add_child(vp)
		_jobs.append({"code": code, "vp": vp, "label": label})


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 5:
		return false
	for job: Dictionary in _jobs:
		var img: Image = (job["vp"] as SubViewport).get_texture().get_image()
		# Sadece yatay kırp: tam satır yüksekliği korunur → listede taban çizgileri hizalı.
		var used: Rect2i = img.get_used_rect()
		var line_h: int = ceili((job["label"] as Label).get_minimum_size().y)
		img = img.get_region(Rect2i(used.position.x, 0, used.size.x, line_h))
		var path: String = OUT + "lang_name_%s.png" % job["code"]
		print(path, " ", img.get_size(), " err=", img.save_png(ProjectSettings.globalize_path(path)))
	return true
