class_name EnemyAIController
extends RefCounted
## Siyasi düşman AI'ı — saf karar servisi (ADR-0005).
## [MapState]'i yalnızca okur: durumu değiştirmez, sinyal yaymaz. [MapController] her
## düşman aksiyonu için [method decide]'ı çağırır ve dönen niyeti uygular (karar → uygula
## döngüsü), böylece her hamle bir öncekinin sonucunu görür (region-map-system.md §3.5).


## Tek bir düşman hamlesi: [member from_id] bölgesinden [member to_id] komşusuna.
## Bu script dışında [code]EnemyAIController.MoveIntent[/code] olarak yazılır.
class MoveIntent extends RefCounted:
	var from_id: StringName
	var to_id: StringName
	## Hamlenin nedeni (ADR-0005 eki: ör. `&"strike"`); rapor için [MoveOutcome]'a kopyalanır.
	var reason: StringName

	func _init(p_from: StringName = &"", p_to: StringName = &"", p_reason: StringName = &"") -> void:
		from_id = p_from
		to_id = p_to
		reason = p_reason


## R1 vuruşunun rapor nedeni (enemy-layers §3.4 → `BATTLE_LOST_DEFENSE`).
const REASON_STRIKE: StringName = &"strike"

var _profile: EnemyAIProfile = EnemyAIProfile.new()


## Bölüm profili (ADR-0005 eki D6: bölüm başına `bind_config`, `decide` argümanı değil). null → varsayılan.
func bind_config(profile: EnemyAIProfile) -> void:
	_profile = profile if profile != null else EnemyAIProfile.new()


## Sıradaki düşman hamlesi. [param acted] bu tur hamle yapmış (ya da bu tur ele geçirilmiş)
## bölgelerdir; her düşman bölgesi tur başına en fazla bir kez hareket eder. [param defense_modifiers]
## oyuncunun lütuf modifikatörleri — R1 hedefin **etkin** savunmasını okur (`P_eff`, AC19); girdiler
## değiştirilmez (AC20). Hamle yapabilecek bölge yoksa [code]null[/code] döner.
func decide(map_state: MapState, acted: Array[StringName],
		defense_modifiers: Array[StatModifier] = []) -> MoveIntent:
	if _profile.strike_enabled:
		return _decide_strike(map_state, acted, defense_modifiers)
	return _decide_legacy(map_state, acted)


## R1 karşı vuruş (enemy-layers §3.3, F-E1, F-E2): tur kapısı → adaylar → küresel sıra
## (en küçük `P_eff`, en büyük `A`, `from`, `to`). Nötr bölgeye girmez, bozulmayı okumaz.
func _decide_strike(map_state: MapState, acted: Array[StringName],
		defense_modifiers: Array[StatModifier]) -> MoveIntent:
	if map_state.current_turn < _profile.attack_start_turn:
		return null
	var best: Array = []  # [p_eff, attack, from_id, to_id]
	for source: RegionData in map_state.get_enemy_regions():
		if source.region_id in acted or source.army_count < 2:
			continue
		var attack: int = source.army_count - 1
		var player_neighbors: Array[RegionData] = []
		for adj_id: StringName in source.adjacent_regions:
			var adj: RegionData = map_state.get_region(adj_id)
			if adj != null and adj.owner == RegionData.Owner.PLAYER:
				player_neighbors.append(adj)
		# F-E2 savunma tutma: iki+ oyuncu komşusu varken kaynak açıkta bırakılmaz.
		if player_neighbors.size() >= 2 and attack >= 2:
			continue
		for target: RegionData in player_neighbors:
			var p_eff: int = effective_defense(target.army_count, defense_modifiers)
			if not strike_allowed(attack, p_eff):
				continue
			var candidate: Array = [p_eff, attack, String(source.region_id), String(target.region_id)]
			if best.is_empty() or _ranks_before(candidate, best):
				best = candidate
	if best.is_empty():
		return null
	return MoveIntent.new(StringName(best[2]), StringName(best[3]), REASON_STRIKE)


## F-E1 koşulları: `A > P_eff` ve `den · A ≥ num · P_eff` — HUD eşiğiyle aynı fonksiyon ([StrikeThreshold]).
func strike_allowed(attack: int, p_eff: int) -> bool:
	return attack >= StrikeThreshold.min_force(p_eff, _profile.strike_ratio_num, _profile.strike_ratio_den)


## Bölge profili (HUD eşik satırı için salt okunur).
func profile() -> EnemyAIProfile:
	return _profile


## `P_eff`: boş bölge 0 (savaş yok), değilse savaşın kullandığı etkin savunma (combat §4).
static func effective_defense(army: int, defense_modifiers: Array[StatModifier]) -> int:
	if army <= 0:
		return 0
	return MoveResolver.effective_power(MoveResolver.STAT_ARMY_DEFENSE, army, defense_modifiers)


static func _ranks_before(a: Array, b: Array) -> bool:
	if a[0] != b[0]:
		return a[0] < b[0]
	if a[1] != b[1]:
		return a[1] > b[1]
	if a[2] != b[2]:
		return a[2] < b[2]
	return a[3] < b[3]


## Eski davranış (varsayılan profil, AC10): ordusu > 1 olan düşman bölgeleri `region_id` sırasıyla,
## düşman-olmayan komşular arasında ordusu en düşük olana.
func _decide_legacy(map_state: MapState, acted: Array[StringName]) -> MoveIntent:
	# Düşman bölgeleri `region_id` sırasıyla işlenir — kayıt sırasından bağımsız,
	# deterministik (region-map-system.md AC6, W6).
	var enemies: Array[RegionData] = map_state.get_enemy_regions()
	enemies.sort_custom(_id_less)
	for region: RegionData in enemies:
		if region.region_id in acted:
			continue
		if region.army_count <= 1:
			continue
		var target: RegionData = _pick_target(map_state, region)
		if target == null:
			continue
		return MoveIntent.new(region.region_id, target.region_id)
	return null


## Düşman olmayan komşular arasında ordusu en düşük olan; eşitlikte `region_id`
## alfabetik ilki (region-map-system.md AC6, W6).
func _pick_target(map_state: MapState, region: RegionData) -> RegionData:
	var best: RegionData = null
	for adj_id: StringName in region.adjacent_regions:
		var adj: RegionData = map_state.get_region(adj_id)
		if adj == null or adj.owner == RegionData.Owner.ENEMY:
			continue
		if best == null or adj.army_count < best.army_count \
				or (adj.army_count == best.army_count and _id_less(adj, best)):
			best = adj
	return best


static func _id_less(a: RegionData, b: RegionData) -> bool:
	return String(a.region_id) < String(b.region_id)
