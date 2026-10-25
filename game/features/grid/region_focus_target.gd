class_name RegionFocusTarget
extends Control
## Bölgenin klavye odağı (K4): Node2D bölge odak alamadığı için sınır kutusunu kaplayan görünmez
## kontrol. Fareyi geçirir (tıklama Area2D'de kalır); odak görünürken (klavye) bölge poligonunu
## 1px Ülgen altınıyla çizer, gizli odakta çizmez (FocusReveal, C-25). `ui_accept` = [signal accepted].


signal accepted

## Hover / seçim konturuyla aynı altın (RegionNode.COLOR_HIGHLIGHT_OUTLINE).
const COLOR_FOCUS := Color("#EDC76B")

## Kontrolün yerel koordinatlarında bölge poligonu.
var outline: PackedVector2Array = PackedVector2Array()


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Harita dünya koordinatıdır, aynalanmaz (ADR-0009); odak yönleri de LTR.
	layout_direction = Control.LAYOUT_DIRECTION_LTR


func _draw() -> void:
	if outline.size() < 3 or not has_focus(true):
		return
	var closed: PackedVector2Array = outline.duplicate()
	closed.append(outline[0])
	draw_polyline(closed, COLOR_FOCUS, -1.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT:
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_accept") and not event.is_echo():
		accept_event()
		accepted.emit()
