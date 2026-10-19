class_name CampaignRules
extends RefCounted
## Sahne akışının saf formülleri (scene-flow.md §4): F1 açılma/durum, F2 zorunlu seçim sayısı,
## F3 sahnede kazanılan Ruh, F7 hedef kümesi ve COMMIT. Durum yok — RootContext ve
## GameContext aynı fonksiyonları kullanır.


## F1 düğüm durumları (sefer haritası §3.9).
enum ChapterState { LOCKED, AVAILABLE, COMPLETED }


## F1: `c == 1` ya da `c − 1` tamamlanmış.
static func is_unlocked(chapter_id: int, completed: Array[int]) -> bool:
	return chapter_id == 1 or (chapter_id - 1) in completed


static func chapter_state(chapter_id: int, completed: Array[int]) -> ChapterState:
	if chapter_id in completed:
		return ChapterState.COMPLETED
	if is_unlocked(chapter_id, completed):
		return ChapterState.AVAILABLE
	return ChapterState.LOCKED


## F1: tamamlanmamış en küçük sahne; hepsi tamamsa 0.
static func next_chapter(completed: Array[int], scene_count: int) -> int:
	for chapter_id: int in range(1, scene_count + 1):
		if chapter_id not in completed:
			return chapter_id
	return 0


## F1 geçerlilik: her öğe 1…K ve öncülü tamamlanmış (kayıt doğrulaması).
static func is_valid_completion(completed: Array[int], scene_count: int) -> bool:
	for chapter_id: int in completed:
		if chapter_id < 1 or chapter_id > scene_count:
			return false
		if chapter_id != 1 and (chapter_id - 1) not in completed:
			return false
	return true


## F2 kapalı form (test kâhini; uygulama döngüyle yürür): `k = min(k_cost, k_pool, cap)`.
## [param pool_limit] < 0 = havuz sınırsız.
static func victory_pick_count(ruh: int, picked_count: int, pool_limit: int, config: SpiritConfig) -> int:
	var picks: int = 0
	var remaining: int = ruh
	while picks < config.victory_pick_cap and (pool_limit < 0 or picks < pool_limit):
		var cost: int = BoonRules.boon_cost(picked_count + picks, config)
		if remaining < cost:
			break
		remaining -= cost
		picks += 1
	return picks


## F3: `ruh_now − ruh_entry + Σ boon_cost(i), i = n_entry…n_now−1` (harcama geri eklenir).
static func ruh_gained(ruh_now: int, picked_now: int, ruh_entry: int, picked_entry: int, config: SpiritConfig) -> int:
	var spent: int = 0
	for i: int in range(picked_entry, picked_now):
		spent += BoonRules.boon_cost(i, config)
	return maxi(0, ruh_now - ruh_entry + spent)


## F7: `V = { r ∈ erlik_foci ∪ objective_region_ids : çözülmemiş }`, harita sırasıyla.
static func objective_markers(map_state: MapState, win_condition: WinCondition, scene: SceneDefinition) -> Array[StringName]:
	var markers: Array[StringName] = []
	if win_condition != null:
		for region_id: StringName in win_condition.erlik_foci:
			var region: RegionData = map_state.get_region(region_id)
			if region != null and region.corruption_level > 0 and region_id not in markers:
				markers.append(region_id)
	if scene != null:
		for region_id: StringName in scene.objective_region_ids:
			var region: RegionData = map_state.get_region(region_id)
			if region != null and region.owner != RegionData.Owner.PLAYER and region_id not in markers:
				markers.append(region_id)
	return markers


## F7 COMMIT (T18): tamamlanan eklenir (tekrar eklenmez), sıradaki sahne seçilir, harita ve
## altın sıfırlanır; `ruh`/`boons` seçimlerden sonraki değerleriyle kalır. İdempotent.
static func commit_scene(game_state: GameState, chapter_id: int, scene_count: int) -> void:
	if chapter_id not in game_state.chapters_completed:
		game_state.chapters_completed.append(chapter_id)
		game_state.chapters_completed.sort()
	game_state.current_chapter = mini(chapter_id + 1, scene_count)
	game_state.map_state = null
	game_state.gold = 0


## §3.7 yenilgi metni: sahneye özel → `DEFEAT_REASON_<loss_reason>` → genel (AC15b).
static func defeat_text_key(scene: SceneDefinition, reason: MapState.LossReason) -> StringName:
	if scene != null and scene.defeat_text_key != &"":
		return scene.defeat_text_key
	match reason:
		MapState.LossReason.ERLIK:
			return &"DEFEAT_REASON_ERLIK"
		MapState.LossReason.NO_REGIONS:
			return &"DEFEAT_REASON_NO_REGIONS"
	return &"DEFEAT_REASON_GENERIC"
