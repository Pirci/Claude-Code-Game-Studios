class_name RegionNode
extends Node2D
## Haritada tıklanabilir bölge görsel temsili.
##
## Renkler art bible §4 "Sahiplik Renkleri"nden gelir: dolgu opak ana renk,
## kenar 1px rampanın koyu tonu; hover/seçim 1px Ülgen altını kontur (dolgu değişmez).


signal clicked(region_id: StringName)

## Sahiplik mini rampaları (koyu / ana / açık) — art bible §4. Opak; yarı saydam yasak.
const RAMP_PLAYER: PackedColorArray = [Color("#2E7AB8"), Color("#47A3E8"), Color("#87C4F5")]
const RAMP_ENEMY: PackedColorArray = [Color("#9A4220"), Color("#C45A2A"), Color("#E07E45")]
const RAMP_NEUTRAL: PackedColorArray = [Color("#4A453C"), Color("#6B655A"), Color("#8F897D")]
const RAMP_DARK: int = 0
const RAMP_MAIN: int = 1
const RAMP_LIGHT: int = 2
## Seçili / üzerine gelinen bölge konturu — Ülgen altını (art bible §4).
const COLOR_HIGHLIGHT_OUTLINE := Color("#EDC76B")
## Seçim köşe işareti ◆: altın elmas (yarıçap 2px → 5×5) + 1px koyu çerçeve;
## yalnızca seçimde çizilir — hover'dan ayıran işaret budur (art bible §4, §7).
const SELECTION_MARK_RADIUS: int = 2
const COLOR_SELECTION_MARK_EDGE := Color("#1C170F")
## 1px primitive çizgi köşe koordinatının bir piksel sol-üstüne düşer;
## işaret kontur köşesine ortalansın diye aynı kayma uygulanır.
const OUTLINE_PIXEL_OFFSET := Vector2i(-1, -1)
## Harita etiketi tema varyasyonu: krem metin + 1px koyu kontur (art bible §4).
## LabelSettings değil: o font_size'ı sabitler, dil bazlı pixel font geçişini bozar.
## Temada outline_size = 2 (çap gibi davranır → her yönde 1px).
const MAP_LABEL_VARIATION: StringName = &"MapLabel"
## Bölge adı / ordu etiket kutusu (640×360 base, piksel).
const LABEL_WIDTH: int = 96
const LABEL_HEIGHT: int = 16
## Tamga, ordu etiket kutusunun hemen altında, bölgenin dikey ekseninde durur
## (merkezde etiketlerle çakışırdı). Kutunun alt boş satırları metinle arasında
## ~2px bırakır; 0 boşlukla tamga ile alt kontur arasında da 1px dolgu kalır.
const TAMGA_GAP: int = 0

var region_id: StringName = &""
var is_selected: bool = false:
	set(value):
		if is_selected == value:
			return
		is_selected = value
		queue_redraw()
		_update_tamga_visibility()
## Renk Körlüğü Modu (art bible §4): tamga seçimden bağımsız hep görünür ve
## sahipli bölgeler rampanın açık tonunda ek 1px iç kontur alır.
var color_blind_mode: bool = false:
	set(value):
		color_blind_mode = value
		queue_redraw()
		_update_tamga_visibility()
## Bölge adı etiketi (Bölge Adlarını Göster/Gizle); ordu sayısı hep görünür.
## Ad gizliyken ordu etiketi (ve altındaki tamga) yarım satır yukarı, ortaya kayar.
var show_name_label: bool = true:
	set(value):
		show_name_label = value
		if _label:
			_label.visible = value
		_layout_army_and_tamga()

var _points: PackedVector2Array = PackedVector2Array()
var _inner_points: PackedVector2Array = PackedVector2Array()
var _owner: RegionData.Owner = RegionData.Owner.NEUTRAL
var _area: Area2D
var _collision: CollisionPolygon2D
var _label: Label
var _army_label: Label
var _tamga: Sprite2D
var _anchor: Vector2 = Vector2.ZERO
var _is_hovered: bool = false


func _draw() -> void:
	if _points.size() < 3:
		return
	draw_colored_polygon(_points, get_fill_color())
	var outline: PackedVector2Array = _points.duplicate()
	outline.append(_points[0])
	# Negatif genişlik = 1px primitive çizgi (pixel grid'de keskin, ölçekten bağımsız).
	draw_polyline(outline, get_outline_color(), -1.0)
	if has_inner_outline() and _inner_points.size() >= 3:
		var inner: PackedVector2Array = _inner_points.duplicate()
		inner.append(_inner_points[0])
		draw_polyline(inner, get_inner_outline_color(), -1.0)
	if is_selected:
		for point: Vector2 in _points:
			var center: Vector2i = Vector2i(point.round()) + OUTLINE_PIXEL_OFFSET
			for row: Rect2i in diamond_rows(center, SELECTION_MARK_RADIUS + 1):
				draw_rect(Rect2(row), COLOR_SELECTION_MARK_EDGE)
			for row: Rect2i in diamond_rows(center, SELECTION_MARK_RADIUS):
				draw_rect(Rect2(row), COLOR_HIGHLIGHT_OUTLINE)


func setup(data: RegionData) -> void:
	region_id = data.region_id
	position = Vector2.ZERO
	_points = data.polygon_points
	_anchor = data.position
	# 1px içe kaydırılmış poligon: çizildiğinde konturun hemen içindeki piksellere düşer.
	var inset: Array[PackedVector2Array] = Geometry2D.offset_polygon(_points, -1.0, Geometry2D.JOIN_MITER)
	_inner_points = inset[0] if not inset.is_empty() else PackedVector2Array()

	_area = Area2D.new()
	_area.input_pickable = true
	_collision = CollisionPolygon2D.new()
	_collision.polygon = data.polygon_points
	_area.add_child(_collision)
	add_child(_area)

	_area.input_event.connect(_on_input_event)
	_area.mouse_entered.connect(_on_mouse_entered)
	_area.mouse_exited.connect(_on_mouse_exited)

	# Font boyutu override edilmez: tema dil bazlı pixel font boyutunu belirler
	# (Fusion 12 / Arapça Unifont 16). Ara boyutlar pixel fontu bozar.
	# Konumlar harita (dünya) koordinatıdır: RTL dillerde aynalanmamalı → LTR yerleşim;
	# metnin kendisi text_direction=AUTO ile yine doğru yönde çizilir.
	# Kutudan uzun metin (uzun çeviriler) "…" ile kısaltılır; kutu genişliği sabit kalır.
	_label = _create_map_label()
	_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_label.text = tr(String(data.display_name_key))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_label.position = data.position - Vector2(LABEL_WIDTH / 2.0, LABEL_HEIGHT)
	_label.size = Vector2(LABEL_WIDTH, LABEL_HEIGHT)
	_label.visible = show_name_label
	add_child(_label)

	_army_label = _create_map_label()
	_army_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_army_label.size = Vector2(LABEL_WIDTH, LABEL_HEIGHT)
	add_child(_army_label)

	# centered=false + tam sayı konum: 9×9 doku piksel grid'ine oturur, merkez sütunu
	# bölge ekseninde kalır.
	_tamga = Sprite2D.new()
	_tamga.centered = false
	add_child(_tamga)
	_layout_army_and_tamga()
	_update_tamga_visibility()
	update_display(data)


func update_display(data: RegionData) -> void:
	_owner = data.owner
	queue_redraw()
	if _army_label:
		_army_label.text = "%s: %d" % [tr("ARMY"), data.army_count]
	if _label:
		_label.text = tr(String(data.display_name_key))


## Sahibin tamga dokusu (null = tamgasız, ör. nötr bölge). Sahiplik değişince yeniden çağrılır.
func set_tamga(texture: Texture2D) -> void:
	if _tamga == null:
		return
	_tamga.texture = texture
	_layout_army_and_tamga()
	_update_tamga_visibility()


## Tamga şu an çiziliyor mu: dokusu var ve (seçili veya Renk Körlüğü Modu).
func is_tamga_visible() -> bool:
	return _tamga != null and _tamga.texture != null and (is_selected or color_blind_mode)


## Renk Körlüğü Modu'nda sahipli (oyuncu/düşman) bölgeler ek iç kontur alır; nötr almaz.
func has_inner_outline() -> bool:
	return color_blind_mode and _owner != RegionData.Owner.NEUTRAL


## Ek iç kontur rengi — sahibin rampasındaki açık ton.
func get_inner_outline_color() -> Color:
	return get_owner_ramp(_owner)[RAMP_LIGHT]


## Sahibin 3 tonluk mini rampası (koyu / ana / açık).
static func get_owner_ramp(owner: RegionData.Owner) -> PackedColorArray:
	match owner:
		RegionData.Owner.PLAYER:
			return RAMP_PLAYER
		RegionData.Owner.ENEMY:
			return RAMP_ENEMY
		_:
			return RAMP_NEUTRAL


## [param center] pikseline ortalı, [param radius] yarıçaplı piksel elmasın satırları
## (her satır 1px yüksek dikdörtgen; genişlikler 1, 3, …, 2r+1, …, 3, 1).
static func diamond_rows(center: Vector2i, radius: int) -> Array[Rect2i]:
	var rows: Array[Rect2i] = []
	for dy: int in range(-radius, radius + 1):
		var half: int = radius - absi(dy)
		rows.append(Rect2i(center.x - half, center.y + dy, half * 2 + 1, 1))
	return rows


## Opak dolgu rengi — sahibin ana tonu; hover/seçim dolguyu değiştirmez.
func get_fill_color() -> Color:
	return get_owner_ramp(_owner)[RAMP_MAIN]


## 1px kontur rengi: seçili veya üzerine gelinmişse altın, değilse rampanın koyu tonu.
func get_outline_color() -> Color:
	if is_selected or _is_hovered:
		return COLOR_HIGHLIGHT_OUTLINE
	return get_owner_ramp(_owner)[RAMP_DARK]


func _update_tamga_visibility() -> void:
	if _tamga:
		_tamga.visible = is_tamga_visible()


## Ordu etiketi çapa noktasının altında (ad gizliyse yarım satır yukarıda, ortada);
## tamga onun hemen altında, aynı dikey eksende.
func _layout_army_and_tamga() -> void:
	if _army_label == null:
		return
	var center: Vector2i = Vector2i(_anchor.round())
	var army_top: int = center.y if show_name_label else center.y - LABEL_HEIGHT / 2
	_army_label.position = Vector2(center.x - LABEL_WIDTH / 2.0, army_top)
	if _tamga and _tamga.texture:
		var size: Vector2i = Vector2i(_tamga.texture.get_size())
		_tamga.position = Vector2(center.x - size.x / 2, army_top + LABEL_HEIGHT + TAMGA_GAP)


func _create_map_label() -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = MAP_LABEL_VARIATION
	label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(region_id)


func _on_mouse_entered() -> void:
	_is_hovered = true
	queue_redraw()


func _on_mouse_exited() -> void:
	_is_hovered = false
	queue_redraw()
