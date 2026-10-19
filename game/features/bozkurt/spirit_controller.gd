class_name SpiritController
extends RefCounted
## Erlik katmanı durumunun tek yazarı: `corruption_level`, `last_erlik_spread_turn`,
## `GameState.ruh` (registry `spirit_state`, C-17 D3). Kurallar [SpiritRules] ve
## [MoveResolver]'da hesaplanır; burası yalnızca sonuçları uygular.


signal ruh_changed(ruh: int)
signal corruption_changed(region_id: StringName, level: int)

var _game_state: GameState = null
var _rules: SpiritRules = SpiritRules.new()


func bind_services(game_state: GameState, rules: SpiritRules = null) -> void:
	_game_state = game_state
	if rules != null:
		_rules = rules


## Başarılı arındırmanın bozulma ve Ruh sonucunu yazar (army §3.3 dal 2, ADR-0010).
## Başarısız arındırmada bozulma ve Ruh değişmez — ordu tarafını [ArmyController] yazar.
func apply_purification(map_state: MapState, outcome: MoveOutcome) -> void:
	if outcome.branch != MoveOutcome.Branch.PURIFICATION or not outcome.purified:
		return
	var target: RegionData = map_state.get_region(outcome.to_id)
	target.corruption_level = outcome.target_corruption_after
	corruption_changed.emit(target.region_id, target.corruption_level)
	if outcome.ruh_gain != 0:
		_game_state.ruh += outcome.ruh_gain
		ruh_changed.emit(_game_state.ruh)


## Yayılım turunu işler (§3.6, §4.6): sayaç bu tura çekilir (hedef olmasa da), hedef
## bir seviye derinleşir (üst sınır [method SpiritRules.max_corruption_level]).
func apply_spread(map_state: MapState, decision: ErlikSpreadController.SpreadDecision) -> void:
	if not decision.is_spread_turn:
		return
	map_state.last_erlik_spread_turn = map_state.current_turn
	var target: RegionData = map_state.get_region(decision.target_id)
	if target == null:
		return
	target.corruption_level = mini(target.corruption_level + 1, _rules.max_corruption_level())
	corruption_changed.emit(target.region_id, target.corruption_level)
