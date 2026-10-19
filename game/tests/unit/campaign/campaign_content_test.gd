extends GdUnitTestSuite
## Kampanya içerik denetimi — scene-flow.md §3.10 L1–L5, L8, L9; AC26 (C-40).
## L6 (11 dilde sığma) glyph_coverage_test + ekran görüntüsüyle; L7 (illüstrasyon dosyaları)
## sanat görevi bitince eklenecek — dosyalar henüz yok.


const CAMPAIGN: String = "res://features/campaign/data/campaign.tres"
const TRANSLATIONS: String = "res://assets/locale/translations.csv"


func _campaign() -> CampaignDefinition:
	return load(CAMPAIGN) as CampaignDefinition


func _english() -> Dictionary:
	var keys: Dictionary = {}
	var file: FileAccess = FileAccess.open(TRANSLATIONS, FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() > 1:
			keys[row[0]] = row[1]
	return keys


func _all_pages(scene: SceneDefinition) -> Array[NarrativePage]:
	var pages: Array[NarrativePage] = []
	pages.append_array(scene.intro_pages)
	pages.append_array(scene.kok_bori_pages)
	pages.append_array(scene.outro_pages)
	return pages


# L1 + L2 + L3: kimlikler 1…K, harita eşleşmesi, başlık, hedef bölgeleri.
func test_scenes_match_their_maps() -> void:
	var campaign: CampaignDefinition = _campaign()
	assert_int(campaign.scene_count()).is_greater_equal(1)
	for i: int in campaign.scene_count():
		var scene: SceneDefinition = campaign.scenes[i]
		assert_int(scene.chapter_id).is_equal(i + 1)
		var definition: ChapterMapDefinition = scene.load_map_definition()
		assert_object(definition).override_failure_message(scene.map_path).is_not_null()
		assert_int(definition.chapter_id).is_equal(scene.chapter_id)
		assert_str(String(scene.title_key)).is_equal(String(definition.chapter_name_key))
		var region_ids: Array[StringName] = []
		for region: RegionDefinition in definition.regions:
			region_ids.append(region.region_id)
		for region_id: StringName in definition.win_condition.erlik_foci + scene.objective_region_ids:
			assert_bool(region_id in region_ids).override_failure_message(String(region_id)).is_true()


# L4 + L5 + L8: sayfa aralıkları, ilk sayfa illüstrasyonu, anahtarların `en` metni, bütçeler.
func test_pages_have_keys_and_fit_budgets() -> void:
	var english: Dictionary = _english()
	var campaign: CampaignDefinition = _campaign()
	for scene: SceneDefinition in campaign.scenes:
		assert_int(scene.intro_pages.size()).is_between(1, 4)
		assert_int(scene.kok_bori_pages.size()).is_between(0, 2)
		assert_int(scene.outro_pages.size()).is_between(1, 4)
		assert_str(scene.intro_pages[0].illustration_path).is_not_empty()
		assert_str(scene.outro_pages[0].illustration_path).is_not_empty()
		var intro_chars: int = 0
		for page: NarrativePage in scene.intro_pages + scene.kok_bori_pages:
			intro_chars += String(english.get(String(page.text_key), "")).length()
		var outro_chars: int = 0
		for page: NarrativePage in scene.outro_pages:
			outro_chars += String(english.get(String(page.text_key), "")).length()
		assert_int(intro_chars).is_less_equal(1100)
		assert_int(outro_chars).is_less_equal(900)
		var keys: Array[StringName] = [scene.title_key, scene.kok_bori_line_key]
		for page: NarrativePage in _all_pages(scene):
			keys.append(page.text_key)
			if page.title_key != &"":
				keys.append(page.title_key)
			assert_int(String(english.get(String(page.text_key), "")).length()).is_less_equal(220)
		for key: StringName in keys:
			assert_str(String(english.get(String(key), ""))).override_failure_message(String(key)).is_not_empty()
	for page: NarrativePage in campaign.end_pages:
		assert_str(String(english.get(String(page.text_key), ""))).is_not_empty()


# L9 + AC26: Prolog verisi.
func test_prolog_scene_data() -> void:
	var campaign: CampaignDefinition = _campaign()
	var prolog: SceneDefinition = campaign.scene(1)
	assert_int(prolog.intro_pages.size()).is_equal(2)
	assert_int(prolog.kok_bori_pages.size()).is_equal(1)
	assert_int(prolog.outro_pages.size()).is_equal(2)
	assert_int(prolog.kok_bori_pose).is_equal(SceneDefinition.Pose.DESCENT)
	assert_str(String(prolog.outro_pages[1].title_key)).is_equal("CHAPTER_1_KAGAN_TITLE")
	assert_int(campaign.end_pages.size()).is_greater_equal(1)
