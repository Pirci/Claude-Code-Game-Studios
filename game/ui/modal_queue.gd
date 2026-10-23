class_name ModalQueue
extends Control
## Tek seferde tek modal (ADR-0011 karar 5): FIFO sıra, tam ekran arka plan harita
## tıklamalarını keser (`MOUSE_FILTER_STOP`), klavye odağı modala gizlice taşınır
## ([method FocusReveal.focus_quietly]) ve kuyruk boşalınca önceki odak geri verilir.
## Sözleşme: modal kapanınca `closed` yayar; isteğe bağlı `get_focus_target() -> Control`.


signal drained

## Arka plan karartması — art bible §7 koyu zemin (`#1C150D`), alfa sabit (fade yok).
const BACKDROP_COLOR := Color(0.109804, 0.082353, 0.05098, 0.6)

## Modal yerleşimi: ortada (varsayılan) ya da üst/alt kenara yaslı, yatayda ortalı (harita
## üstü paneller işaretleri örtmesin diye — scene-flow §3.5).
enum Placement { CENTER, TOP, BOTTOM }

## Üst/alt yaslı modalların HUD çubuklarından uzaklığı (GameContext çubuk boylarından verir).
var top_margin: float = 40.0
var bottom_margin: float = 31.0

var _queue: Array[Control] = []
var _placements: Array[Placement] = []
## Modal başına kaçınılacak alanlar (boş → verilen yerleşim aynen kullanılır).
var _obstacles: Array[Array] = []
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
func push(modal: Control, placement: Placement = Placement.CENTER) -> void:
	_enqueue(modal, placement, [] as Array[Rect2])


## Modalı sıraya ekler; gösterilirken ortada, altta ya da üstte [param obstacles]'ı (ör. raporun hedef
## bölgesi) örtmeyen ilk yeri seçer — hepsi örterse en az örteni (ux/battle-report.md §3 Q2).
func push_avoiding(modal: Control, obstacles: Array[Rect2]) -> void:
	_enqueue(modal, Placement.CENTER, obstacles)


func is_open() -> bool:
	return _current != null


## Açık modal (yoksa null) — testler ve sunucunun durum sorguları için.
func current() -> Control:
	return _current


## Açık bir kenar modalını üst ya da alt kenara (yatayda ortalı) taşır.
func place(modal: Control, placement: Placement) -> void:
	if modal.get_parent() != self:
		return
	if placement == Placement.CENTER:
		modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
		return
	var preset: Control.LayoutPreset = Control.PRESET_CENTER_TOP if placement == Placement.TOP \
		else Control.PRESET_CENTER_BOTTOM
	var margin: float = top_margin if placement == Placement.TOP else bottom_margin
	modal.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, int(margin))


## Kenar modalının o yerleşimde kaplayacağı alan (en küçük boyuttan; yerleşim seçimi için).
func rect_for(modal: Control, placement: Placement) -> Rect2:
	var size: Vector2 = modal.get_combined_minimum_size()
	var x: float = (self.size.x - size.x) / 2.0
	var y: float = (self.size.y - size.y) / 2.0
	if placement == Placement.TOP:
		y = top_margin
	elif placement == Placement.BOTTOM:
		y = self.size.y - bottom_margin - size.y
	return Rect2(Vector2(x, y), size)


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
	var placement: Placement = _placements.pop_front()
	var obstacles: Array = _obstacles.pop_front()
	if not obstacles.is_empty():
		add_child(_current)
		_choose_placement(_current, obstacles)
	elif placement == Placement.CENTER:
		_center.add_child(_current)
	else:
		add_child(_current)
		place(_current, placement)
	_current.connect(&"closed", _on_current_closed, CONNECT_ONE_SHOT)
	show()
	if _current.has_method(&"get_focus_target"):
		FocusReveal.focus_quietly(_current.call(&"get_focus_target") as Control)


func _enqueue(modal: Control, placement: Placement, obstacles: Array[Rect2]) -> void:
	assert(modal.has_signal(&"closed"), "ModalQueue: modal `closed` sinyali yaymalı")
	_queue.append(modal)
	_placements.append(placement)
	_obstacles.append(obstacles)
	if _current == null:
		_return_focus = get_viewport().gui_get_focus_owner()
		_show_next()


func _choose_placement(modal: Control, obstacles: Array) -> void:
	var options: Array[Placement] = [Placement.CENTER, Placement.BOTTOM, Placement.TOP]
	var rects: Array[Rect2] = []
	for option: Placement in options:
		rects.append(rect_for(modal, option))
	var avoid: Array[Rect2] = []
	avoid.assign(obstacles)
	place(modal, options[PanelPlacement.choose(rects, avoid)])


func _on_current_closed() -> void:
	var closed_modal: Control = _current
	closed_modal.get_parent().remove_child(closed_modal)
	closed_modal.queue_free()
	_show_next()
