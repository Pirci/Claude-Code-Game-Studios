class_name FocusReveal
extends RefCounted
## Klavye odağını fare kullanıcısını rahatsız etmeden hazır tutar (C-25).
## Ekranlar açılışta birincil kontrole **gizli** odak verir ([method focus_quietly]);
## klavyedeki ilk gezinme / onay tuşu odağı taşımadan veya butona basmadan yalnızca
## görünür yapar ([method reveal_on_navigation]). Fare tıklamaları odak çerçevesi
## göstermez — `gui/common/show_focus_state_on_pointer_event` varsayılanı "Text Input
## Controls" (Godot 4.6+, GH-110250; 4.7.1'de doğrulandı).


## İlk basışta odağı görünür yapan eylemler. `ui_accept` da dahil: gizli odaklı
## "Tur Bitir"e kazara Boşluk/Enter basmak turu bitirmesin.
const REVEAL_ACTIONS: Array[StringName] = [
	&"ui_up", &"ui_down", &"ui_left", &"ui_right",
	&"ui_focus_next", &"ui_focus_prev", &"ui_accept",
]


## Açılış odağı: klavyeye hazır ama görünmez. Kontrol odaklanamıyorsa dokunmaz.
static func focus_quietly(control: Control) -> void:
	if control == null or not control.is_visible_in_tree():
		return
	if control.focus_mode == Control.FOCUS_NONE:
		return
	control.grab_focus(true)


## Gizli odak varken gelen ilk [constant REVEAL_ACTIONS] basışı odağı görünür yapar.
## [code]true[/code] dönerse çağıran olayı işlenmiş saymalıdır
## ([method Viewport.set_input_as_handled]).
static func reveal_on_navigation(viewport: Viewport, event: InputEvent) -> bool:
	if not _is_reveal_press(event):
		return false
	var owner: Control = viewport.gui_get_focus_owner()
	if owner == null or owner.has_focus(true):
		return false
	owner.grab_focus()
	return true


static func _is_reveal_press(event: InputEvent) -> bool:
	if not event.is_pressed() or event.is_echo():
		return false
	for action: StringName in REVEAL_ACTIONS:
		if event.is_action_pressed(action):
			return true
	return false
