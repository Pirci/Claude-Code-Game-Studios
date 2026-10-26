extends GdUnitTestSuite
## Harita okunabilirliği (C-86; seviye perde1 §7.8 #2–#3, kabul #5; hud A-2): düşman bölgesinde sahip
## tamgası her zaman görünür ve renk körlüğü simülasyonunda zemine ≥ 3:1; nötrde tamga yok; komşuluk
## çizgisi zemine ≥ 3:1 (bölüm verisi). Prolog'da düşman bölgesi yok → tamga kuralı Prolog'u etkilemez.


const CAMPAIGN_PATH: String = "res://features/campaign/data/campaign.tres"
## Perde 1 renkleri (seviye §7.1) — Perde 1 harita verisi bu değerlerle yazılır.
const PERDE1_GROUND := Color("#0F1A0D")
const PERDE1_LINE := Color("#5C8F5C")
const MIN_NON_TEXT_CONTRAST: float = 3.0
## Bilinen, izlenen istisnalar: bölüm → kuyruk görevi. Düzeltilince buradan silinir.
## Prolog çizgisi #436129 / zemin #1A2614 = 2,24:1 (C-86'da bulundu; demo görünümü — ayrı görev).
const LINE_CONTRAST_EXCEPTIONS: Dictionary = {1: "C-100"}
## Machado ve diğ. (2009) renk körlüğü benzetimi, şiddet 1.0, doğrusal RGB'de.
const PROTANOPIA: Array = [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]]
const DEUTERANOPIA: Array = [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]]


func _luminance(c: Color) -> float:
	var lin: Color = c.srgb_to_linear()
	return 0.2126 * lin.r + 0.7152 * lin.g + 0.0722 * lin.b


func _contrast(a: Color, b: Color) -> float:
	var la: float = _luminance(a)
	var lb: float = _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _simulate(c: Color, m: Array) -> Color:
	var lin: Color = c.srgb_to_linear()
	var v: Array[float] = []
	for row: Array in m:
		v.append(clampf(row[0] * lin.r + row[1] * lin.g + row[2] * lin.b, 0.0, 1.0))
	return Color(v[0], v[1], v[2]).linear_to_srgb()


func _opaque_colors(texture: Texture2D) -> Array[Color]:
	var image: Image = texture.get_image()
	var colors: Array[Color] = []
	for y: int in image.get_height():
		for x: int in image.get_width():
			var c: Color = image.get_pixel(x, y)
			if c.a > 0.5 and not colors.has(Color(c, 1.0)):
				colors.append(Color(c, 1.0))
	return colors


func _node(owner: RegionData.Owner) -> RegionNode:
	var data: RegionData = RegionData.new()
	data.region_id = &"r"
	data.owner = owner
	data.polygon_points = PackedVector2Array([Vector2(0, 0), Vector2(40, 0), Vector2(40, 20), Vector2(0, 20)])
	var node: RegionNode = auto_free(RegionNode.new()) as RegionNode
	node.setup(data)
	add_child(node)
	return node


# §7.8 #2: düşmanda her zaman, oyuncuda yalnız seçiliyken; nötrde doku yok.
func test_map_readability_enemy_tamga_always_visible() -> void:
	var tamgas: TamgaLibrary = TamgaLibrary.new()
	var enemy: RegionNode = _node(RegionData.Owner.ENEMY)
	enemy.set_tamga(tamgas.get_texture(&"curcet"))
	assert_bool(enemy.is_tamga_visible()).is_true()  # seçili değil, renk körlüğü modu kapalı
	var player: RegionNode = _node(RegionData.Owner.PLAYER)
	player.set_tamga(tamgas.get_texture(&"oguz"))
	assert_bool(player.is_tamga_visible()).is_false()
	var neutral: RegionNode = _node(RegionData.Owner.NEUTRAL)
	neutral.set_tamga(null)
	assert_bool(neutral.is_tamga_visible()).is_false()
	# Bölge el değiştirince kural izler (oyuncu düşmana geçti → tamga görünür).
	var data: RegionData = RegionData.new()
	data.region_id = &"r"
	data.owner = RegionData.Owner.ENEMY
	player.update_display(data)
	player.set_tamga(tamgas.get_texture(&"curcet"))
	assert_bool(player.is_tamga_visible()).is_true()


# hud A-2: tamga renkleri düşman zeminine normal görüşte ve protanopi / döteranopi benzetiminde ≥ 3:1.
func test_map_readability_enemy_tamga_contrast_under_color_blindness() -> void:
	var fill: Color = RegionNode.RAMP_ENEMY[RegionNode.RAMP_MAIN]
	var colors: Array[Color] = _opaque_colors(TamgaLibrary.new().get_texture(&"curcet"))
	assert_int(colors.size()).is_greater(1)
	for c: Color in colors:
		assert_float(_contrast(c, fill)).override_failure_message("normal %s" % c.to_html(false)).is_greater_equal(MIN_NON_TEXT_CONTRAST)
		for m: Array in [PROTANOPIA, DEUTERANOPIA]:
			var ratio: float = _contrast(_simulate(c, m), _simulate(fill, m))
			assert_float(ratio).override_failure_message("benzetim %s %.2f" % [c.to_html(false), ratio]).is_greater_equal(MIN_NON_TEXT_CONTRAST)


# §7.8 #3: Perde 1 çizgisi zemine ≥ 3:1 (#5C8F5C / #0F1A0D ≈ 4,72).
func test_map_readability_perde1_line_contrast() -> void:
	assert_float(_contrast(PERDE1_LINE, PERDE1_GROUND)).is_greater_equal(MIN_NON_TEXT_CONTRAST)


# Lint: kampanyadaki her bölüm haritasının çizgisi zemine ≥ 3:1 — izlenen istisnalar dışında.
func test_map_readability_every_chapter_line_contrast() -> void:
	var campaign: CampaignDefinition = load(CAMPAIGN_PATH) as CampaignDefinition
	for scene: SceneDefinition in campaign.scenes:
		var definition: ChapterMapDefinition = scene.load_map_definition()
		var ratio: float = _contrast(definition.adjacency_line_color, definition.ground_color)
		if LINE_CONTRAST_EXCEPTIONS.has(scene.chapter_id):
			assert_float(ratio).override_failure_message("istisna düzeldi — listeden sil: %d" % scene.chapter_id).is_less(MIN_NON_TEXT_CONTRAST)
			continue
		assert_float(ratio).override_failure_message("bölüm %d: %.2f" % [scene.chapter_id, ratio]).is_greater_equal(MIN_NON_TEXT_CONTRAST)


# UD doğrulandı: Prolog'da düşman bölgesi yok → tamga kuralı Prolog görünümünü değiştirmez.
func test_map_readability_prolog_has_no_enemy_regions() -> void:
	var prolog: MapState = (load("res://features/grid/data/chapter_1_map.tres") as ChapterMapDefinition).create_map_state()
	assert_array(prolog.get_enemy_regions()).is_empty()
