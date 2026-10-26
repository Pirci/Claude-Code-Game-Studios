extends SceneTree
## Perde 1 (Doğu — Cürcet) harita verisini üretir → game/features/grid/data/chapter_2_map.tres (C-89).
## Kaynak: design/levels/perde1-dogu-curcet.md §3 (bölgeler, komşuluk), §4 (AI, takviye, Erlik), §6 (kazanma
## koşulu), §7.1 (renkler), §7.3–7.5 (nehir, otağ, dekor yerleşimi). Değer değişikliği önce seviye belgesine
## yazılır, sonra bu betik çalıştırılır; `.tres` elle düzenlenmez (tek kaynak bu betik + belge).
##
## Kullanım (repo kökünden):
##   godot --headless --path game --script ../tools/level-data/build_perde1_map.gd
##
## §7.5'te koordinatı verilmeyen gruplar (köprü–koru boşluğu, koru–oba arası, otağ–oba sağı, kuzey çamları x'i)
## burada seçilir; kurallar `tests/unit/grid/map_decor_geometry_test.gd` ile kilitlidir.

const OUT: String = "res://features/grid/data/chapter_2_map.tres"
const ENV: String = "res://assets/art/maps/env/"
const UNITS: String = "res://assets/art/units/"
const N := RegionData.Owner.NEUTRAL
const P := RegionData.Owner.PLAYER
const E := RegionData.Owner.ENEMY

## [id, ad key'i, sahip, ordu, altın, bozulma, merkez, poligon]
const REGIONS: Array = [
	[&"orman_agzi", &"REGION_ORMAN_AGZI", P, 6, 2, 0, Vector2(100, 190),
		[Vector2(73, 163), Vector2(127, 163), Vector2(140, 190), Vector2(127, 217), Vector2(73, 217), Vector2(60, 190)]],
	[&"kayin_koruluk", &"REGION_KAYIN_KORULUK", N, 2, 1, 0, Vector2(200, 270),
		[Vector2(145, 243), Vector2(255, 243), Vector2(255, 297), Vector2(145, 297)]],
	[&"kuzey_aksu", &"REGION_KUZEY_AKSU", N, 3, 2, 0, Vector2(225, 101),
		[Vector2(175, 72), Vector2(275, 72), Vector2(275, 130), Vector2(175, 130)]],
	[&"tahta_kopru", &"REGION_TAHTA_KOPRU", N, 2, 1, 0, Vector2(345, 96),
		[Vector2(313, 62), Vector2(377, 62), Vector2(377, 130), Vector2(313, 130)]],
	[&"kurt_ini_ormani", &"REGION_KURT_INI_ORMANI", E, 2, 1, 1, Vector2(445, 100),
		[Vector2(395, 72), Vector2(495, 72), Vector2(495, 128), Vector2(395, 128)]],
	[&"curuk_koru", &"REGION_CURUK_KORU", N, 0, 2, 3, Vector2(335, 240),
		[Vector2(280, 212), Vector2(390, 212), Vector2(390, 268), Vector2(280, 268)]],
	[&"curcet_oba", &"REGION_CURCET_OBA", E, 4, 2, 0, Vector2(460, 205),
		[Vector2(410, 178), Vector2(510, 178), Vector2(510, 232), Vector2(410, 232)]],
	[&"curcet_otagi", &"REGION_CURCET_OTAGI", E, 4, 3, 0, Vector2(562, 125),
		[Vector2(526, 92), Vector2(598, 92), Vector2(610, 104), Vector2(610, 146), Vector2(598, 158),
		Vector2(526, 158), Vector2(514, 146), Vector2(514, 104)]],
]
## §3.2 — 9 kenar (kiriş kurt_ini – curuk_koru dahil).
const EDGES: Array = [
	[&"orman_agzi", &"kayin_koruluk"], [&"orman_agzi", &"kuzey_aksu"], [&"kayin_koruluk", &"curuk_koru"],
	[&"kuzey_aksu", &"tahta_kopru"], [&"tahta_kopru", &"kurt_ini_ormani"], [&"kurt_ini_ormani", &"curuk_koru"],
	[&"kurt_ini_ormani", &"curcet_otagi"], [&"curuk_koru", &"curcet_oba"], [&"curcet_oba", &"curcet_otagi"],
]
## §7.5 bağımsız sağlıklı ağaçlar (ayak noktaları).
const TREES: Array = [
	# Orman Ağzı batı
	Vector2(30, 120), Vector2(48, 300),
	# Doğu kapı kümesi
	Vector2(150, 184), Vector2(158, 200), Vector2(148, 212),
	# Köprü–koru boşluğu (x ≤ 346, y 150–205)
	Vector2(300, 160), Vector2(330, 172), Vector2(288, 192), Vector2(342, 200),
	# Koru–oba arası
	Vector2(400, 254), Vector2(398, 302), Vector2(440, 296),
	# Kuzey şerit çamları (ayak y 62–68; köprü poligonu ve nehir kolu dışında)
	Vector2(20, 66), Vector2(64, 64), Vector2(112, 68), Vector2(158, 62), Vector2(292, 64), Vector2(420, 66),
	# Otağ–oba sağı
	Vector2(622, 100), Vector2(624, 130), Vector2(620, 160), Vector2(532, 180), Vector2(600, 180),
]
## Bozulmaya bağlı slotlar: [bölge, ayak] — çürük (min 1) + aynı yerde sağlıklı (max 0).
const CORRUPTION_SLOTS: Array = [
	[&"curuk_koru", Vector2(292, 208)], [&"curuk_koru", Vector2(322, 206)], [&"curuk_koru", Vector2(362, 205)],
	[&"curuk_koru", Vector2(350, 290)], [&"curuk_koru", Vector2(310, 292)],
	[&"kurt_ini_ormani", Vector2(440, 147)], [&"kurt_ini_ormani", Vector2(478, 147)],
	[&"kayin_koruluk", Vector2(168, 322)], [&"kayin_koruluk", Vector2(232, 324)],
]
## Körmös (OVERLAY): curuk_koru içinde, görünür alan x287–299 / x371–383, y247–261 → ayak (alt-orta).
const KORMOS_FEET: Array = [Vector2(293, 261), Vector2(377, 261)]
## §7.3 nehir: y45–60 bandı x0→386, köprü ile kurt_ini arasından (x382–390) güneye y≈140, ≈12×8 gölcük.
const WATER: Array = [Rect2(0, 45, 386, 15), Rect2(382, 45, 8, 95), Rect2(380, 136, 12, 8)]


func _init() -> void:
	var definition: ChapterMapDefinition = ChapterMapDefinition.new()
	definition.chapter_id = 2
	definition.chapter_name_key = &"CHAPTER_2_TITLE"
	definition.actions_per_turn = 1
	definition.enemy_actions_per_turn = 1
	definition.player_tamga_id = &"oguz"
	definition.enemy_tamga_id = &"curcet"
	definition.ground_color = Color("#0F1A0D")
	definition.adjacency_line_color = Color("#5C8F5C")
	definition.enemy_reinforcement_per_turn = 1
	definition.enemy_reinforcement_region_ids = [&"curcet_otagi"] as Array[StringName]
	definition.starting_gold = 6
	definition.erlik_spread_interval = 3
	definition.regions = _regions()
	definition.win_condition = _win()
	definition.enemy_ai_profile = _profile()
	definition.decor = _decor()
	var err: Error = ResourceSaver.save(definition, OUT)
	print(OUT, " err=", err)
	quit()


func _regions() -> Array[RegionDefinition]:
	var adjacency: Dictionary = {}
	for edge: Array in EDGES:
		for i: int in 2:
			if not adjacency.has(edge[i]):
				adjacency[edge[i]] = [] as Array[StringName]
			(adjacency[edge[i]] as Array[StringName]).append(edge[1 - i])
	var out: Array[RegionDefinition] = []
	for spec: Array in REGIONS:
		var region: RegionDefinition = RegionDefinition.new()
		region.region_id = spec[0]
		region.display_name_key = spec[1]
		region.owner = spec[2]
		region.starting_army = spec[3]
		region.gold_per_turn = spec[4]
		region.starting_corruption = spec[5]
		region.position = spec[6]
		region.polygon_points = PackedVector2Array(spec[7])
		region.adjacent_region_ids = adjacency[spec[0]]
		out.append(region)
	return out


func _win() -> WinCondition:
	var win: WinCondition = WinCondition.new()
	win.required_neutral_conquests = 2
	win.must_defeat_all_enemies = true
	win.erlik_foci = [&"curuk_koru"] as Array[StringName]
	win.erlik_loss_threshold = 9
	win.description_key = &"WIN_CONDITION_CH2"
	win.foci_label_key = &"OBJECTIVE_FOCI_CH2"
	return win


func _profile() -> EnemyAIProfile:
	var profile: EnemyAIProfile = EnemyAIProfile.new()
	profile.attack_start_turn = 5
	profile.strike_ratio_num = 3
	profile.strike_ratio_den = 2
	profile.strike_enabled = true
	return profile


func _decor() -> MapDecor:
	var decor: MapDecor = MapDecor.new()
	var items: Array[MapDecorItem] = []
	for i: int in TREES.size():
		items.append(_item(ENV + ("env_tree_healthy_01.png" if i % 3 != 2 else "env_tree_healthy_02.png"), TREES[i]))
	for i: int in CORRUPTION_SLOTS.size():
		var slot: Array = CORRUPTION_SLOTS[i]
		# Sağlıklı ikiz kısa huş (18 px): çürük ağaçla aynı ayakta, poligon kenarına taşmaz.
		items.append(_item(ENV + "env_tree_healthy_02.png", slot[1], MapDecorItem.Layer.PROP, slot[0], 0, 0))
		items.append(_item(ENV + ("env_tree_rotten_01.png" if i % 2 == 0 else "env_tree_rotten_02.png"), slot[1],
			MapDecorItem.Layer.PROP, slot[0], 1, -1))
	items.append(_item(ENV + "env_bridge_wood_01.png", Vector2(386, 98)))
	items.append(_item(ENV + "env_otag_curcet_01.png", Vector2(584, 90)))
	for foot: Vector2 in KORMOS_FEET:
		var kormos: MapDecorItem = _item(UNITS + "unit_kormos_forest_idle_0.png", foot, MapDecorItem.Layer.OVERLAY,
			&"curuk_koru", 1, -1)
		kormos.frames.append(load(UNITS + "unit_kormos_forest_idle_1.png") as Texture2D)
		kormos.fps = 2.0
		items.append(kormos)
	decor.items = items
	decor.water_rects.assign(WATER)
	return decor


func _item(path: String, foot: Vector2, layer: MapDecorItem.Layer = MapDecorItem.Layer.PROP,
		bound: StringName = &"", min_level: int = 0, max_level: int = -1) -> MapDecorItem:
	var item: MapDecorItem = MapDecorItem.new()
	item.frames = [load(path) as Texture2D] as Array[Texture2D]
	item.position = foot
	item.layer = layer
	item.bound_region_id = bound
	item.min_corruption = min_level
	item.max_corruption = max_level
	return item
