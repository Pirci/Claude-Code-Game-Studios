class_name NumberFormatter
extends RefCounted
## Dile göre binlik ayırıcılı tam sayı biçimlendirme (art bible §7 "Sayılar").
##
## TranslationServer.format_number() gruplama yapmaz (Godot 4.7); ayırıcı her dil
## için THOUSANDS_SEPARATOR çeviri key'inden gelir (en ",", tr/de ".", fr/ru U+00A0 …).
## U+202F (ince boşluk) Fusion Pixel Latin'de yok → kırılmaz boşluk U+00A0 kullanılır.


const SEPARATOR_KEY: StringName = &"THOUSANDS_SEPARATOR"
const FALLBACK_SEPARATOR: String = ","
const GROUP_SIZE: int = 3
## Unicode yön yalıtımı (LRI … PDI): sayısal ifade sağdan sola metinde de soldan sağa kalır —
## Arapçada "4 / 9" → "9 / 4", "(+2)" → "(2+)" ters dönmesin (C-69). Görünmez karakterlerdir.
const LTR_ISOLATE: String = "\u2066"
const POP_ISOLATE: String = "\u2069"


## Etkin dilin ayırıcısıyla biçimlendirir: 12345 → "12,345" (en) / "12.345" (tr).
static func format_int(value: int) -> String:
	return group_digits(value, current_separator())


## Etkin dilin binlik ayırıcısı; çeviri yoksa (key aynen dönerse) ",".
static func current_separator() -> String:
	var separator: String = String(TranslationServer.translate(SEPARATOR_KEY))
	if separator.is_empty() or separator == String(SEPARATOR_KEY):
		return FALLBACK_SEPARATOR
	return separator


## Sayısal ifadeyi (kesir, işaretli sayı) soldan sağa yalıtır; LTR dillerde görünür etkisi yok.
static func ltr(text: String) -> String:
	return LTR_ISOLATE + text + POP_ISOLATE


## "a / b" — her dilde soldan sağa okunan kesir (ilerleme, tavan, Erlik'in Gölgesi).
static func fraction(current: int, total: int) -> String:
	return ltr("%s / %s" % [format_int(current), format_int(total)])


## [param value] rakamlarını sağdan üçerli gruplar; negatiflerde "-" önde kalır.
static func group_digits(value: int, separator: String) -> String:
	var digits: String = str(absi(value))
	var groups: PackedStringArray = []
	var end: int = digits.length()
	while end > GROUP_SIZE:
		groups.insert(0, digits.substr(end - GROUP_SIZE, GROUP_SIZE))
		end -= GROUP_SIZE
	groups.insert(0, digits.substr(0, end))
	var result: String = separator.join(groups)
	return "-" + result if value < 0 else result
