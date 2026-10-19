extends GdUnitTestSuite
## SaveController — yükleme sırası, yedek, yazma hatası, sürüm koruması (ADR-0007, C-56).


func _map(chapter_id: int) -> MapState:
	if chapter_id != 1:
		return null
	var m: MapState = MapState.new()
	m.chapter_id = 1
	var r: RegionData = RegionData.new()
	r.region_id = &"otag"
	r.owner = RegionData.Owner.PLAYER
	r.army_count = 5
	m.regions[r.region_id] = r
	return m


func _state(gold: int) -> GameState:
	var s: GameState = GameState.new()
	s.gold = gold
	s.map_state = _map(1)
	return s


func _controller(store: SaveStore) -> SaveController:
	var c: SaveController = SaveController.new()
	c.bind_services(store, _map)
	return c


func test_save_then_load_round_trips() -> void:
	var c: SaveController = _controller(MemorySaveStore.new())
	assert_bool(c.has_campaign()).is_false()
	assert_bool(c.save_campaign(_state(12))).is_true()
	var result: LoadResult = c.load_campaign()
	assert_int(result.code).is_equal(LoadResult.Code.OK)
	assert_int(result.state.gold).is_equal(12)
	assert_bool(c.has_campaign()).is_true()


func test_corrupt_save_falls_back_to_backup() -> void:
	var store: MemorySaveStore = MemorySaveStore.new()
	var good: String = SaveSerializer.to_text(_state(9))
	store.set_candidates(SaveController.CAMPAIGN_SLOT, PackedStringArray(["{ yarım yazılmış", good]))
	var result: LoadResult = _controller(store).load_campaign()
	assert_int(result.code).is_equal(LoadResult.Code.OK)
	assert_int(result.state.gold).is_equal(9)


func test_all_candidates_bad_reports_first_error() -> void:
	var store: MemorySaveStore = MemorySaveStore.new()
	store.set_candidates(SaveController.CAMPAIGN_SLOT, PackedStringArray(["{", "[]"]))
	assert_int(_controller(store).load_campaign().code).is_equal(LoadResult.Code.CORRUPT)


func test_write_failure_signals_and_keeps_previous() -> void:
	var store: MemorySaveStore = MemorySaveStore.new()
	var c: SaveController = _controller(store)
	c.save_campaign(_state(3))
	store.fail_writes = true
	var reasons: Array[StringName] = []
	c.save_failed.connect(func(reason: StringName) -> void: reasons.append(reason))
	assert_bool(c.save_campaign(_state(99))).is_false()
	assert_array(reasons).contains_exactly([&"write_failed"])
	assert_int(c.load_campaign().state.gold).is_equal(3)


func test_newer_save_is_never_overwritten() -> void:
	var store: MemorySaveStore = MemorySaveStore.new()
	var data: Dictionary = SaveSerializer.to_dict(_state(5))
	data["schema_version"] = SaveSerializer.SCHEMA_VERSION + 1
	var newer: String = JSON.stringify(data)
	store.set_candidates(SaveController.CAMPAIGN_SLOT, PackedStringArray([newer]))
	var c: SaveController = _controller(store)
	assert_int(c.load_campaign().code).is_equal(LoadResult.Code.VERSION_TOO_NEW)
	assert_bool(c.save_campaign(_state(1))).is_false()
	assert_str(store.read_candidates(SaveController.CAMPAIGN_SLOT)[0]).is_equal(newer)


func test_finished_scene_is_not_autosaved() -> void:
	var store: MemorySaveStore = MemorySaveStore.new()
	var s: GameState = _state(4)
	s.map_state.game_result = MapState.GameResult.LOST
	assert_bool(_controller(store).save_campaign(s)).is_false()
	assert_int(store.read_candidates(SaveController.CAMPAIGN_SLOT).size()).is_equal(0)
