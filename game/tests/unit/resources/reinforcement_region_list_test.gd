extends GdUnitTestSuite
## F6 takviye bölge listesi (C-83; enemy-layers §3.5, F-E3, AC11, AC12, AC14; resource F6): boş liste =
## eski davranış (tüm düşman bölgeleri), dolu liste = listedeki ve o an `ENEMY` olanlar; liste bölüm
## içeriğidir — kaydedilmez, yüklemede harita tanımından gelir.


const S := RegionData.Owner
const ECONOMY_CONFIG: String = "res://features/resources/data/economy_config.tres"


## Perde 1 benzeri: başkent (curcet_otagi, 4), oba (3), in (2), oyuncu bölgesi, nötr bölge.
func _map(listed: Array[StringName]) -> MapState:
	var m: MapState = MapState.new()
	m.enemy_reinforcement_per_turn = 1
	m.enemy_reinforcement_region_ids = listed
	for spec: Array in [[&"curcet_otagi", S.ENEMY, 4], [&"curcet_oba", S.ENEMY, 3], [&"kurt_ini_ormani", S.ENEMY, 2],
			[&"oguz", S.PLAYER, 5], [&"orman", S.NEUTRAL, 0]]:
		var r: RegionData = RegionData.new()
		r.region_id = spec[0]
		r.owner = spec[1]
		r.army_count = spec[2]
		m.regions[r.region_id] = r
	return m


func _resources() -> ResourceController:
	var controller: ResourceController = ResourceController.new()
	controller.bind_services(SpiritRules.new(), load(ECONOMY_CONFIG) as EconomyConfig)
	return controller


func _armies(m: MapState) -> Array[int]:
	var out: Array[int] = []
	for region_id: StringName in [&"curcet_otagi", &"curcet_oba", &"kurt_ini_ormani", &"oguz", &"orman"]:
		out.append(m.get_region(region_id).army_count)
	return out


# AC11
func test_reinforcement_empty_region_list_matches_legacy_all_enemy_regions() -> void:
	var m: MapState = _map([] as Array[StringName])
	_resources().reinforce_enemies(m)
	assert_array(_armies(m)).is_equal([5, 4, 3, 5, 0])


func test_reinforcement_capital_only_list_adds_to_capital_alone() -> void:
	var m: MapState = _map([&"curcet_otagi"] as Array[StringName])
	_resources().reinforce_enemies(m)
	assert_array(_armies(m)).is_equal([5, 3, 2, 5, 0])


func test_reinforcement_non_enemy_listed_region_gets_nothing() -> void:
	var m: MapState = _map([&"curcet_otagi", &"oguz", &"orman"] as Array[StringName])
	m.get_region(&"curcet_otagi").owner = S.PLAYER  # başkent oyuncuya geçti → takviye durur
	_resources().reinforce_enemies(m)
	assert_array(_armies(m)).is_equal([4, 3, 2, 5, 0])
	m.get_region(&"curcet_otagi").owner = S.ENEMY  # geri alındı → yeniden başlar
	_resources().reinforce_enemies(m)
	assert_int(m.get_region(&"curcet_otagi").army_count).is_equal(5)


# AC12 (F-E3): saldırı yok, 8 tur → başkent 4 + 8 = 12 (gerçek end_turn döngüsü).
func test_reinforcement_capital_grows_to_twelve_after_eight_turns() -> void:
	var state: GameState = GameState.new()
	state.map_state = _map([&"curcet_otagi"] as Array[StringName])
	state.map_state.enemy_actions_per_turn = 0  # saldırı yok
	var map: MapController = MapController.new()
	var combat: CombatResolver = CombatResolver.new()
	map.bind_services(state.map_state, state, ArmyController.new(), _resources(), combat, WinCondition.new(), EnemyAIController.new())
	for i: int in 8:
		map.end_turn()
	assert_int(state.map_state.get_region(&"curcet_otagi").army_count).is_equal(12)
	assert_int(state.map_state.get_region(&"curcet_oba").army_count).is_equal(3)  # listede değil


# AC14: AI'ın bu tur aldığı listedeki bölge aynı tur +E_r alır (ekonomi adımı AI'dan sonra).
func test_reinforcement_region_captured_this_turn_gets_reinforced() -> void:
	var state: GameState = GameState.new()
	var m: MapState = MapState.new()
	m.enemy_actions_per_turn = 1
	m.enemy_reinforcement_per_turn = 1
	m.enemy_reinforcement_region_ids = [&"sinir"] as Array[StringName]
	for spec: Array in [[&"kale", S.ENEMY, 9], [&"sinir", S.PLAYER, 1], [&"yurt", S.PLAYER, 3]]:
		var r: RegionData = RegionData.new()
		r.region_id = spec[0]
		r.owner = spec[1]
		r.army_count = spec[2]
		m.regions[r.region_id] = r
	m.get_region(&"kale").adjacent_regions.assign([&"sinir"])
	m.get_region(&"sinir").adjacent_regions.assign([&"kale", &"yurt"])
	m.get_region(&"yurt").adjacent_regions.assign([&"sinir"])
	state.map_state = m
	var map: MapController = MapController.new()
	var combat: CombatResolver = CombatResolver.new()
	var resolver: MoveResolver = MoveResolver.new()
	resolver.bind_services(combat)
	map.bind_services(m, state, ArmyController.new(), _resources(), combat, WinCondition.new(), EnemyAIController.new(), resolver)
	map.end_turn()
	var sinir: RegionData = m.get_region(&"sinir")
	assert_int(sinir.owner).is_equal(S.ENEMY)
	# Savaş: A = 8 vs D = 1 → kalan 8 − ceil(1 × 0,5) = 7; aynı tur takviye +1 = 8.
	assert_int(sinir.army_count).is_equal(8)
	assert_int(m.get_region(&"kale").army_count).is_equal(1)  # listede değil, takviye yok


# Kayıt/yükleme etkilenmez: liste kaydedilmez, yüklemede harita tanımından gelir.
func test_reinforcement_list_comes_from_chapter_data_not_save() -> void:
	var definition: ChapterMapDefinition = ChapterMapDefinition.new()
	definition.enemy_reinforcement_region_ids = [&"curcet_otagi"] as Array[StringName]
	var region: RegionDefinition = RegionDefinition.new()
	region.region_id = &"curcet_otagi"
	region.owner = S.ENEMY
	region.starting_army = 4
	definition.regions = [region] as Array[RegionDefinition]
	var state: GameState = GameState.new()
	state.map_state = definition.create_map_state()
	assert_array(state.map_state.enemy_reinforcement_region_ids).is_equal([&"curcet_otagi"])
	var text: String = SaveSerializer.to_text(state)
	assert_str(text).not_contains("enemy_reinforcement_region_ids")
	var loaded: LoadResult = SaveSerializer.from_text(text, func(_c: int) -> MapState: return definition.create_map_state())
	assert_int(loaded.code).is_equal(LoadResult.Code.OK)
	assert_array(loaded.state.map_state.enemy_reinforcement_region_ids).is_equal([&"curcet_otagi"])
	# Kopya: harita durumu tanımı değiştirmez.
	loaded.state.map_state.enemy_reinforcement_region_ids.append(&"x")
	assert_int(definition.enemy_reinforcement_region_ids.size()).is_equal(1)
