extends GdUnitTestSuite
## Prolog öğretici kuralları, ilerleme ve ayar kalıcılığı (C-41; design/ux/prolog-tutorial.md).


const TRANSLATIONS: String = "res://assets/locale/translations.csv"


func _region(owner: RegionData.Owner, army: int, corruption: int = 0) -> RegionData:
	var region: RegionData = RegionData.new()
	region.owner = owner
	region.army_count = army
	region.corruption_level = corruption
	return region


func test_start_hint_only_on_turn_one_with_affordable_recruit() -> void:
	assert_str(TutorialRules.hint_at_turn_start(1, 6, 2)).is_equal("recruit")
	assert_str(TutorialRules.hint_at_turn_start(1, 1, 2)).is_equal("")
	assert_str(TutorialRules.hint_at_turn_start(2, 6, 2)).is_equal("")


func test_selection_hint_priority_corrupted_then_neutral_then_send_army() -> void:
	assert_str(TutorialRules.hint_for_selection(_region(RegionData.Owner.NEUTRAL, 0, 3))).is_equal("corrupted")
	assert_str(TutorialRules.hint_for_selection(_region(RegionData.Owner.NEUTRAL, 2))).is_equal("neutral")
	assert_str(TutorialRules.hint_for_selection(_region(RegionData.Owner.PLAYER, 5))).is_equal("send_army")
	assert_str(TutorialRules.hint_for_selection(_region(RegionData.Owner.PLAYER, 1))).is_equal("")
	assert_str(TutorialRules.hint_for_selection(null)).is_equal("")


# C-92: takviye alan düşman başkenti → başkent ipucu; listede olmayan düşman ya da boş liste → yok.
func test_selection_hint_capital_only_for_listed_enemy_region() -> void:
	var capital: RegionData = _region(RegionData.Owner.ENEMY, 4)
	capital.region_id = &"otag"
	var capitals: Array[StringName] = [&"otag"]
	assert_str(TutorialRules.hint_for_selection(capital, capitals)).is_equal("capital")
	assert_str(TutorialRules.hint_for_selection(capital)).is_equal("")
	var village: RegionData = _region(RegionData.Owner.ENEMY, 4)
	village.region_id = &"oba"
	assert_str(TutorialRules.hint_for_selection(village, capitals)).is_equal("")
	capital.owner = RegionData.Owner.PLAYER  # alındıktan sonra başkent ipucu yok
	assert_str(TutorialRules.hint_for_selection(capital, capitals)).is_equal("send_army")


# C-92: düşman kağanı ipucu yalnız 1. turda ve haritada düşman varken.
func test_enemy_king_hint_only_turn_one_with_enemies() -> void:
	var m: MapState = MapState.new()
	var enemy: RegionData = _region(RegionData.Owner.ENEMY, 2)
	enemy.region_id = &"e"
	m.regions[enemy.region_id] = enemy
	m.current_turn = 1
	assert_str(TutorialRules.hint_enemy_king(m)).is_equal("enemy_king")
	m.current_turn = 2
	assert_str(TutorialRules.hint_enemy_king(m)).is_equal("")
	m.current_turn = 1
	enemy.owner = RegionData.Owner.NEUTRAL
	assert_str(TutorialRules.hint_enemy_king(m)).is_equal("")
	assert_str(TutorialRules.hint_enemy_king(null)).is_equal("")


func test_every_hint_has_english_text_and_button_keys() -> void:
	var english: Dictionary = {}
	var file: FileAccess = FileAccess.open(TRANSLATIONS, FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() > 1:
			english[row[0]] = row[1]
	for hint_id: StringName in TutorialRules.ALL:
		assert_str(String(english.get(TutorialRules.text_key(hint_id), ""))) \
			.override_failure_message(String(hint_id)).is_not_empty()
	assert_str(String(english.get("TUTORIAL_GOT_IT", ""))).is_not_empty()
	assert_str(String(english.get("TUTORIAL_RESET", ""))).is_not_empty()


func test_progress_marks_once_signals_and_resets() -> void:
	var progress: TutorialProgress = TutorialProgress.new()
	var changes: Array[int] = [0]
	progress.changed.connect(func() -> void: changes[0] += 1)
	progress.mark_seen(TutorialRules.HINT_RECRUIT)
	progress.mark_seen(TutorialRules.HINT_RECRUIT)
	assert_int(changes[0]).is_equal(1)
	assert_bool(progress.has_seen(TutorialRules.HINT_RECRUIT)).is_true()
	progress.reset()
	assert_int(changes[0]).is_equal(2)
	assert_bool(progress.has_seen(TutorialRules.HINT_RECRUIT)).is_false()
	progress.reset()
	assert_int(changes[0]).is_equal(2)


func test_settings_roundtrip_keeps_seen_hints_and_drops_unknown() -> void:
	var snapshot: SettingsSnapshot = SettingsSnapshot.new()
	snapshot.seen_hints = [TutorialRules.HINT_RECRUIT, TutorialRules.HINT_SPREAD] as Array[StringName]
	var restored: SettingsSnapshot = SettingsSerializer.from_text(SettingsSerializer.to_text(snapshot))
	assert_array(restored.seen_hints).is_equal([&"recruit", &"spread"])
	var data: Dictionary = JSON.parse_string(SettingsSerializer.to_text(snapshot)) as Dictionary
	data["tutorial"] = {"seen_hints": ["recruit", "recruit", "bogus", 7]}
	assert_array(SettingsSerializer.from_text(JSON.stringify(data)).seen_hints).is_equal([&"recruit"])


func test_old_settings_without_tutorial_load_with_no_hints_seen() -> void:
	var data: Dictionary = JSON.parse_string(SettingsSerializer.to_text(SettingsSnapshot.new())) as Dictionary
	data.erase("tutorial")
	var restored: SettingsSnapshot = SettingsSerializer.from_text(JSON.stringify(data))
	assert_object(restored).is_not_null()
	assert_array(restored.seen_hints).is_empty()
