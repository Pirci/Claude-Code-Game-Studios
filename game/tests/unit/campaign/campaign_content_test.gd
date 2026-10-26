extends GdUnitTestSuite
## Kampanya içerik denetimi — scene-flow.md §3.10 L1–L5, L8–L10; AC26 (C-40); Perde 1 sahnesi (C-90).
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
		for key: StringName in [scene.teaser_key, scene.focus_heading_key, scene.focus_success_key, scene.focus_failed_key]:
			if key != &"":
				keys.append(key)
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


# L1: kimlikler 1…K boşluksuz ve benzersiz (C-90: K = 2).
func test_campaign_ids_contiguous_and_unique() -> void:
	var campaign: CampaignDefinition = _campaign()
	assert_int(campaign.scene_count()).is_equal(2)
	var ids: Array[int] = []
	for scene: SceneDefinition in campaign.scenes:
		ids.append(scene.chapter_id)
	assert_array(ids).is_equal([1, 2])


# L10: sahne havuzu katalogda, tekrarsız; dolu havuz ≥ 3 lütuf. Perde 1 boş = tüm katalog.
func test_campaign_boon_pools_valid() -> void:
	var catalog: BoonCatalog = load("res://features/bozkurt/data/boon_catalog.tres") as BoonCatalog
	var catalog_ids: Array[StringName] = []
	for boon: BoonDefinition in catalog.boons:
		catalog_ids.append(boon.boon_id)
	for scene: SceneDefinition in _campaign().scenes:
		var seen: Array[StringName] = []
		for boon_id: StringName in scene.boon_pool_ids:
			assert_bool(boon_id in catalog_ids).override_failure_message(String(boon_id)).is_true()
			assert_bool(boon_id in seen).override_failure_message(String(boon_id)).is_false()
			seen.append(boon_id)
		if not scene.boon_pool_ids.is_empty():
			assert_int(scene.boon_pool_ids.size()).is_greater_equal(3)
	assert_array(_campaign().scene(2).boon_pool_ids).is_empty()


# Seviye perde1 §2 / §6: G-1..G-3, O-1..O-2 (O-2 "Kanglı"), hedef otağ, odak ritüeli "şifa" anahtarları, teaser.
func test_perde1_scene_data() -> void:
	var perde1: SceneDefinition = _campaign().scene(2)
	assert_str(perde1.map_path).is_equal("res://features/grid/data/chapter_2_map.tres")
	assert_int(perde1.intro_pages.size()).is_equal(2)
	assert_str(String(perde1.intro_pages[0].title_key)).is_equal("CHAPTER_2_TITLE")
	assert_int(perde1.kok_bori_pose).is_equal(SceneDefinition.Pose.PROFILE)
	assert_array(perde1.kok_bori_pages.map(func(p: NarrativePage) -> StringName: return p.text_key)).is_equal(
		[&"CHAPTER_2_KOKBORI_1"])
	assert_str(String(perde1.kok_bori_line_key)).is_equal("CHAPTER_2_KOKBORI_LINE")
	assert_int(perde1.outro_pages.size()).is_equal(2)
	assert_str(String(perde1.outro_pages[1].title_key)).is_equal("CHAPTER_2_KANGLI_TITLE")
	assert_array(perde1.objective_region_ids).is_equal([&"curcet_otagi"])
	assert_array([perde1.focus_heading_key, perde1.focus_success_key, perde1.focus_failed_key]).is_equal(
		[&"CHAPTER_2_CLEANSED_HEADING", &"CHAPTER_2_CLEANSED_LINE", &"CHAPTER_2_HUNT_FAILED"])
	assert_str(String(perde1.teaser_key)).is_equal("CHAPTER_2_TEASER")
	assert_str(String(_campaign().scene(1).teaser_key)).is_equal("CHAPTER_1_TEASER")


# Haritanın gösterdiği anahtarlar (bölge adları, kazanma koşulu) `en` metnine sahip (L5 harita tarafı).
func test_perde1_map_keys_have_english() -> void:
	var english: Dictionary = _english()
	var definition: ChapterMapDefinition = _campaign().scene(2).load_map_definition()
	var keys: Array[StringName] = [definition.win_condition.description_key]
	for region: RegionDefinition in definition.regions:
		keys.append(region.display_name_key)
	for key: StringName in keys:
		assert_str(String(english.get(String(key), ""))).override_failure_message(String(key)).is_not_empty()
