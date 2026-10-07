class_name LocaleFontController
extends RefCounted
## Dile göre tema fontunu ve temel font boyutunu değiştirir.
##
## Pixel fontlar sadece kendi piksel boyutlarında (ve tam katlarında) keskin
## görünür. Farklı native boyutlu bir font gerektiren diller (ör. Arapça →
## Unifont 16px) glif bazlı fallback ile karışırsa ölçeklenip bozulur; bu yüzden
## o dillerde temanın tamamı override fontuna geçirilir.


var _theme: Theme = null
var _default_font: Font = null
var _default_size: int = 0
var _override_fonts: Dictionary[String, Font] = {}
var _override_sizes: Dictionary[String, int] = {}


## Temanın mevcut default_font / default_font_size değerleri varsayılan olarak saklanır.
func _init(theme: Theme) -> void:
	_theme = theme
	_default_font = theme.default_font
	_default_size = theme.default_font_size


## [param language] için ([code]"ar"[/code] gibi dil kodu) font ve boyut override'ı tanımlar.
func add_override(language: String, font: Font, size: int) -> void:
	_override_fonts[language] = font
	_override_sizes[language] = size


## [param locale]'in dil koduna göre temayı override fontuna ya da varsayılana ayarlar.
func apply(locale: String) -> void:
	var language: String = TranslationServer.standardize_locale(locale).get_slice("_", 0)
	if _override_fonts.has(language):
		_theme.default_font = _override_fonts[language]
		_theme.default_font_size = _override_sizes[language]
	else:
		_theme.default_font = _default_font
		_theme.default_font_size = _default_size
