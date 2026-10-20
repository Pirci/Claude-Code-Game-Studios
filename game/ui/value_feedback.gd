class_name ValueFeedback
extends RefCounted
## Bir sayının değişim geri bildirimi (resource §9, art bible §7 "HUD sayı değişimi") — saf
## durum, zamanlayıcı yok. Görünüm değeri [method observe] ile bildirir; süreler dolunca
## [method expire_flash] / [method expire_delta] çağırır (testler doğrudan çağırır).
##
## - Renk vurgusu 2 UI karesi: artış yeşil, azalış kırmızı; boyut/alfa değişmez.
## - Fark metni (`↑+X` / `↓-X`) rengin tek başına anlam taşımaması için; vurgudan uzun durur.
## - Hareketi Azalt: ikisi de anında uygulanır ve bir sonraki değişime kadar kalıcıdır.
## İlk gözlem taban değerdir (bağlam açılışı / kayıt yüklemesi geri bildirim üretmez).


## Art bible §7 UI karesi (lütuf kartı: 6 kare ≈ 0.3 sn).
const UI_FRAME_SEC: float = 0.05
const FLASH_FRAMES: int = 2
const FLASH_SEC: float = UI_FRAME_SEC * FLASH_FRAMES
## Fark metninin okunma süresi (Hareketi Azalt kapalıyken).
const DELTA_HOLD_SEC: float = 1.5
## Art bible §4 başarı / kayıp renkleri (kontrast testli: ui_palette_contrast_test).
const COLOR_GAIN := Color("#87B85C")
const COLOR_LOSS := Color("#E87A7A")

var reduce_motion: bool = false
## Yalnız artışlar mı bildirilsin (harita ordu etiketi: azalış hareket/savaştandır, §9'da yok).
var increases_only: bool = false

var _has_value: bool = false
var _value: int = 0
var _delta: int = 0
var _flash_on: bool = false
var _delta_on: bool = false


## Yeni değeri bildirir; geri bildirim başladıysa `true` (görünüm zamanlayıcı kurar).
func observe(value: int) -> bool:
	if not _has_value:
		_has_value = true
		_value = value
		return false
	var change: int = value - _value
	_value = value
	if change == 0 or (increases_only and change < 0):
		if change != 0:
			clear()
		return false
	_delta = change
	_flash_on = true
	_delta_on = true
	return true


## Renk vurgusu süresi doldu (Hareketi Azalt'ta yok sayılır — kalıcı).
func expire_flash() -> void:
	if not reduce_motion:
		_flash_on = false


## Fark metni süresi doldu (Hareketi Azalt'ta yok sayılır — kalıcı).
func expire_delta() -> void:
	if not reduce_motion:
		_delta_on = false


func clear() -> void:
	_delta = 0
	_flash_on = false
	_delta_on = false


func is_flashing() -> bool:
	return _flash_on and _delta != 0


## Vurgu rengi; vurgu yoksa [param fallback].
func flash_color(fallback: Color) -> Color:
	if not is_flashing():
		return fallback
	return COLOR_GAIN if _delta > 0 else COLOR_LOSS


## `↑+X` / `↓-X` (LTR yalıtımlı, ADR-0009); gösterilmiyorsa boş.
func delta_text() -> String:
	if not _delta_on or _delta == 0:
		return ""
	var amount: String = NumberFormatter.format_int(absi(_delta))
	return NumberFormatter.ltr(("↑+%s" if _delta > 0 else "↓-%s") % amount)


func last_delta() -> int:
	return _delta
