class_name ResourceController
extends RefCounted
## Altın ve ordu üretimi (resource-system.md §3.1). Formüller [IncomeRules]'ta (saf);
## bozulma çarpanı `M_c` [SpiritRules]'tan, lütuf bonusları değiştirici listesinden gelir.


var _spirit_rules: SpiritRules = SpiritRules.new()
var _config: EconomyConfig = EconomyConfig.new()


func bind_services(spirit_rules: SpiritRules, config: EconomyConfig = null) -> void:
	if spirit_rules != null:
		_spirit_rules = spirit_rules
	if config != null:
		_config = config


func recruit_cost() -> int:
	return _config.recruit_cost


## Ekonomi adımı (region-map §3.4 adım 3): F2 geliri hazineye ekler ve döndürür.
func collect_turn_income(map_state: MapState, game_state: GameState, modifiers: Array[StatModifier] = []) -> int:
	var income: int = forecast_income(map_state, modifiers)
	game_state.gold += income
	return income


## Bu turun geliri — ekonomi adımı ile aynı hesap (HUD tahmini, TR-resource-006).
func forecast_income(map_state: MapState, modifiers: Array[StatModifier] = []) -> int:
	var raw: int = 0
	var regions: Array[RegionData] = map_state.get_player_regions()
	for region: RegionData in regions:
		raw += IncomeRules.region_income(region, _multiplier(region))
	return IncomeRules.turn_income(raw, not regions.is_empty(), modifiers, _config)


## F6: her düşman bölgesine `+enemy_reinforcement_per_turn` (düşmanın hazinesi yok).
func reinforce_enemies(map_state: MapState) -> void:
	for region: RegionData in map_state.get_enemy_regions():
		region.army_count += map_state.enemy_reinforcement_per_turn


## F7 bakım: borcun altına yetenini öder, kalanı silinir; birlik dağıtılmaz. Ödeneni döner.
func pay_upkeep(map_state: MapState, game_state: GameState) -> int:
	var total_army: int = 0
	for region: RegionData in map_state.get_player_regions():
		total_army += region.army_count
	var paid: int = mini(IncomeRules.upkeep(total_army, _config), game_state.gold)
	game_state.gold -= paid
	return paid


## F3 tur tavanı `max(R_min, G_eff)` (oyuncunun değilse 0).
func recruit_cap(region: RegionData) -> int:
	if region == null or region.owner != RegionData.Owner.PLAYER:
		return 0
	return IncomeRules.recruit_cap(region, _multiplier(region), _config)


## Bölgenin bu turda kalan üretim hakkı (oyuncunun değilse 0).
func remaining_cap(region: RegionData) -> int:
	return maxi(0, recruit_cap(region) - (region.recruited_this_turn if region != null else 0))


## Şu an alınabilecek en büyük `k`: kalan tavan ile altının yettiği birlik sayısının küçüğü
## (Ordu Topla seçicisinin üst sınırı — resource-system §10).
func max_recruit(game_state: GameState, region: RegionData) -> int:
	@warning_ignore("integer_division")
	return mini(remaining_cap(region), game_state.gold / maxi(1, _config.recruit_cost))


## R4/F4: oyuncu bölgesi, `1 ≤ k ≤ kalan tavan`, `k × maliyet ≤ altın` — kısmi üretim yok.
func can_recruit(map_state: MapState, game_state: GameState, region_id: StringName, count: int) -> bool:
	var region: RegionData = map_state.get_region(region_id)
	if region == null or count < 1:
		return false
	return count <= remaining_cap(region) and count * _config.recruit_cost <= game_state.gold


## Üretir: altın düşer, ordu ve sayaç artar. Aksiyon harcamaz (R4).
func recruit(map_state: MapState, game_state: GameState, region_id: StringName, count: int) -> bool:
	if not can_recruit(map_state, game_state, region_id, count):
		return false
	var region: RegionData = map_state.get_region(region_id)
	game_state.gold -= count * _config.recruit_cost
	region.army_count += count
	region.recruited_this_turn += count
	return true


## Yeni oyuncu turu (region-map §3.4 adım 4): tüm bölgelerin üretim sayaçları sıfırlanır.
func reset_recruit_counters(map_state: MapState) -> void:
	for region: RegionData in map_state.regions.values():
		region.recruited_this_turn = 0


func _multiplier(region: RegionData) -> float:
	return _spirit_rules.production_multiplier(region.corruption_level)
