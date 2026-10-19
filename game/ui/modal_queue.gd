class_name ModalQueue
extends Control
## Tek seferde tek modal (ADR-0011 karar 5): FIFO sıra, tam ekran arka plan harita
## tıklamalarını keser (`MOUSE_FILTER_STOP`), klavye odağı modala gizlice taşınır
## ([method FocusReveal.focus_quietly]) ve kuyruk boşalınca önceki odak geri verilir.
## Sözleşme: modal kapanınca `closed` yayar; isteğe bağlı `get_focus_target() -> Control`.


signal drained

## Arka plan karartması — art bible §7 koyu zemin (`#1C150D`), alfa sabit (fade yok).
const BACKDROP_COLOR := Color(0.109804, 0.082353, 0.05098, 0.6)

var _queue: Array[Control] = []
var _current: Control = null
var _return_focus: Control = null
var _center: CenterContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	_center = CenterContainer.new()
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_center)
	hide()


## Modalı sıraya ekler; açık modal yoksa hemen gösterir.
func push(modal: Control) -> void:
	assert(modal.has_signal(&"closed"), "ModalQueue: modal `closed` sinyali yaymalı")
	_queue.append(modal)
	if _current == null:
		_return_focus = get_viewport().gui_get_focus_owner()
		_show_next()


func is_open() -> bool:
	return _current != null


## Açık modal (yoksa null) — testler ve sunucunun durum sorguları için.
func current() -> Control:
	return _current


func _show_next() -> void:
	if _queue.is_empty():
		_current = null
		hide()
		if is_instance_valid(_return_focus):
			FocusReveal.focus_quietly(_return_focus)
		_return_focus = null
		drained.emit()
		return
	_current = _queue.pop_front()
	_center.add_child(_current)
	_current.connect(&"closed", _on_current_closed, CONNECT_ONE_SHOT)
	show()
	if _current.has_method(&"get_focus_target"):
		FocusReveal.focus_quietly(_current.call(&"get_focus_target") as Control)


func _on_current_closed() -> void:
	var closed_modal: Control = _current
	_center.remove_child(closed_modal)
	closed_modal.queue_free()
	_show_next()
