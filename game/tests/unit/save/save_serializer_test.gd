extends GdUnitTestSuite
## SaveSerializer — ADR-0007 doğrulama listesi (C-56). Dosya G/Ç yok.


const SAVED_AT: String = "2026-10-19T00:00:00Z"


func _definition_map(chapter_id: int) -> MapState:
	if chapter_id != 1:
		return null
	var m: MapState = MapState.new()
	m.chapter_id = 1
	m.actions_per_turn = 1
	for spec: Array in [[&"otag", RegionData.Owner.PLAYER, 5], [&"dogu", RegionData.Owner.NEUTRAL, 0], [&"lair", RegionData.Owner.NEUTRAL, 0]]:
		var r: RegionData = RegionData.new()
		r.region_id = spec[0]
		r.owner = spec[1]
		r.initial_owner = spec[1]
		r.army_count = spec[2]
		r.gold_per_turn = 2
		m.regions[r.region_id] = r
	return m


func _populated() -> GameState:
	var s: GameState = GameState.new()
	s.current_chapter = 1
	s.gold = 7
	s.ruh = 40
	s.boons.assign([&"bereket", &"gok_kalkani"])
	s.chapters_completed.assign([] as Array[int])
	s.map_state = _definition_map(1)
	s.map_state.current_turn = 6
	s.map_state.last_erlik_spread_turn = 6
	s.map_state.get_region(&"dogu").owner = RegionData.Owner.PLAYER
	s.map_state.get_region(&"dogu").army_count = 4
	s.map_state.get_region(&"lair").corruption_level = 3
	return s


func _round_trip(s: GameState) -> LoadResult:
	return SaveSerializer.from_text(SaveSerializer.to_text(s, SAVED_AT), _definition_map)


func _with(mutator: Callable) -> Dictionary:
	var data: Dictionary = SaveSerializer.to_dict(_populated(), SAVED_AT)
	mutator.call(data)
	return data


func _assert_corrupt(data: Dictionary, why: String) -> void:
	var result: LoadResult = SaveSerializer.from_dict(data, _definition_map)
	assert_int(result.code).override_failure_message(why).is_equal(LoadResult.Code.CORRUPT)
	assert_object(result.state).override_failure_message(why).is_null()


func test_round_trip_restores_every_saved_field() -> void:
	var result: LoadResult = _round_trip(_populated())
	assert_int(result.code).is_equal(LoadResult.Code.OK)
	var s: GameState = result.state
	assert_int(s.gold).is_equal(7)
	assert_int(s.ruh).is_equal(40)
	assert_array(s.boons).contains_exactly([&"bereket", &"gok_kalkani"])
	assert_int(s.map_state.current_turn).is_equal(6)
	assert_int(s.map_state.last_erlik_spread_turn).is_equal(6)
	assert_int(s.map_state.get_region(&"dogu").owner).is_equal(RegionData.Owner.PLAYER)
	assert_int(s.map_state.get_region(&"dogu").army_count).is_equal(4)
	assert_int(s.map_state.get_region(&"lair").corruption_level).is_equal(3)
	# İçerikten gelenler kayıttan değil tanımdan: initial_owner, gelir.
	assert_int(s.map_state.get_region(&"dogu").initial_owner).is_equal(RegionData.Owner.NEUTRAL)
	assert_int(s.map_state.get_region(&"dogu").gold_per_turn).is_equal(2)
	assert_int(s.map_state.actions_remaining).is_equal(s.map_state.actions_per_turn)


func test_same_state_serializes_to_identical_text() -> void:
	assert_str(SaveSerializer.to_text(_populated(), SAVED_AT)).is_equal(SaveSerializer.to_text(_populated(), SAVED_AT))


## Yeni bir durum alanı serializer'a eklenmeden unutulursa bu test düşer (ADR-0007 risk tablosu).
func test_every_state_field_is_saved_or_explicitly_derived() -> void:
	var covered: Dictionary = {
		GameState: ["current_chapter", "gold", "ruh", "boons", "chapters_completed", "map_state",
			"campaign_seed", "modifiers"],  # modifiers: türetilir (ADR-0006)
		MapState: ["chapter_id", "current_turn", "last_erlik_spread_turn", "regions",
			"actions_remaining", "selected_region_id", "game_result", "loss_reason",  # tur sonu / kaydedilmez
			"actions_per_turn", "enemy_actions_per_turn", "player_tamga_id", "enemy_tamga_id",
			"erlik_spread_interval", "enemy_reinforcement_per_turn", "enemy_reinforcement_region_ids",
			"enemy_region_ids_initial"],  # içerik
		RegionData: ["owner", "army_count", "corruption_level", "recruited_this_turn",  # sayaç: tur sonunda 0
			"region_id", "display_name_key", "initial_owner", "gold_per_turn", "position",
			"polygon_points", "adjacent_regions"],  # içerik
	}
	for script_class: Variant in covered:
		var instance: Object = (script_class as GDScript).new()
		for property: Dictionary in instance.get_property_list():
			if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
				assert_bool(property["name"] in covered[script_class]) \
					.override_failure_message("kapsanmayan alan: %s" % property["name"]).is_true()


func test_finished_scene_saves_null_map_and_loads_as_selection() -> void:
	var s: GameState = _populated()
	s.map_state = null
	s.chapters_completed.assign([1])
	s.current_chapter = 2
	var result: LoadResult = _round_trip(s)
	assert_int(result.code).is_equal(LoadResult.Code.OK)
	assert_object(result.state.map_state).is_null()
	assert_array(result.state.chapters_completed).contains_exactly([1])


func test_corrupt_inputs_never_produce_state() -> void:
	_assert_corrupt(_with(func(d: Dictionary) -> void: d.erase("game")), "game yok")
	_assert_corrupt(_with(func(d: Dictionary) -> void: d["game"]["gold"] = -1), "negatif altın")
	_assert_corrupt(_with(func(d: Dictionary) -> void: d["game"]["gold"] = 2.5), "kesirli altın")
	_assert_corrupt(_with(func(d: Dictionary) -> void: d["game"]["gold"] = "7"), "metin altın")
	_assert_corrupt(_with(func(d: Dictionary) -> void: d["game"]["boons"] = [1]), "sayısal lütuf")
	_assert_corrupt(_with(func(d: Dictionary) -> void: d["game"]["chapters_completed"] = [2]), "önek değil")
	_assert_corrupt(_with(func(d: Dictionary) -> void: d["game"]["map"]["chapter_id"] = 2), "bölüm uyuşmuyor")
	_assert_corrupt(_with(func(d: Dictionary) -> void: d["game"]["map"]["last_erlik_spread_turn"] = 9), "yayılım > tur")
	_assert_corrupt(_with(func(d: Dictionary) -> void: d["game"]["map"]["regions"]["hayalet"] = d["game"]["map"]["regions"]["otag"]), "bilinmeyen bölge")
	_assert_corrupt(_with(func(d: Dictionary) -> void: d["game"]["map"]["regions"].erase("lair")), "eksik bölge")
	_assert_corrupt(_with(func(d: Dictionary) -> void: d["game"]["map"]["regions"]["otag"]["army_count"] = -3), "negatif ordu")
	_assert_corrupt(_with(func(d: Dictionary) -> void: d["game"]["map"]["regions"]["otag"]["owner"] = 7), "sahip aralık dışı")
	_assert_corrupt(_with(func(d: Dictionary) -> void: d["game"]["map"]["regions"]["otag"]["army_count"] = 0), "sahipli 0 ordu")
	_assert_corrupt(_with(func(d: Dictionary) -> void: d["game"]["map"]["regions"]["lair"]["corruption_level"] = 4), "bozulma > 3")


func test_text_level_failures() -> void:
	assert_int(SaveSerializer.from_text("", _definition_map).code).is_equal(LoadResult.Code.MISSING)
	assert_int(SaveSerializer.from_text("{ bozuk", _definition_map).code).is_equal(LoadResult.Code.CORRUPT)
	assert_int(SaveSerializer.from_text("[1, 2]", _definition_map).code).is_equal(LoadResult.Code.CORRUPT)
	var huge: String = SaveSerializer.to_text(_populated(), SAVED_AT).replace("\"gold\": 7", "\"gold\": 1e999")
	var result: LoadResult = SaveSerializer.from_text(huge, _definition_map)
	assert_int(result.code).is_equal(LoadResult.Code.CORRUPT)


func test_bom_prefixed_valid_save_loads() -> void:
	var text: String = SaveSerializer.UTF8_BOM + SaveSerializer.to_text(_populated(), SAVED_AT)
	assert_int(SaveSerializer.from_text(text, _definition_map).code).is_equal(LoadResult.Code.OK)


## C-42: dışa aktarmada çıplak U+FEFF silinip sabit boş kalınca ilk karakter kesiliyordu.
func test_strip_bom_only_removes_real_bom() -> void:
	assert_int(SaveSerializer.UTF8_BOM.unicode_at(0)).is_equal(0xFEFF)
	assert_str(SaveSerializer.strip_bom(String.chr(0xFEFF) + "{}")).is_equal("{}")
	assert_str(SaveSerializer.strip_bom("{}")).is_equal("{}")
	assert_str(SaveSerializer.strip_bom("")).is_equal("")


func test_newer_schema_is_refused() -> void:
	var data: Dictionary = _with(func(d: Dictionary) -> void: d["schema_version"] = SaveSerializer.SCHEMA_VERSION + 1)
	assert_int(SaveSerializer.from_dict(data, _definition_map).code).is_equal(LoadResult.Code.VERSION_TOO_NEW)


func test_missing_chapter_content_is_reported() -> void:
	var s: GameState = _populated()
	var data: Dictionary = SaveSerializer.to_dict(s, SAVED_AT)
	data["game"]["current_chapter"] = 2
	data["game"]["chapters_completed"] = [1]
	data["game"]["map"]["chapter_id"] = 2
	assert_int(SaveSerializer.from_dict(data, _definition_map).code).is_equal(LoadResult.Code.CONTENT_MISSING)
