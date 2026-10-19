class_name SpiritController
extends RefCounted
## Erlik katmanı durumunun tek yazarı: `corruption_level`, `last_erlik_spread_turn`,
## `GameState.ruh` ve `GameState.boons` (registry `spirit_state`, C-17 D3). Kurallar
## [SpiritRules], [BoonRules] ve [MoveResolver]'da hesaplanır; burası yalnızca sonuçları uygular.


signal ruh_changed(ruh: int)
signal corruption_changed(region_id: StringName, level: int)
signal boon_picked(boon_id: StringName)

var _game_state: GameState = null
var _rules: SpiritRules = SpiritRules.new()
var _catalog: BoonCatalog = null
var _modifiers: ModifierController = null


func bind_services(game_state: GameState, rules: SpiritRules = null) -> void:
	_game_state = game_state
	if rules != null:
		_rules = rules


## Lütuf katmanı (§3.4–3.5): [param catalog] içerik, [param modifiers] etkinin tek yazarı
## (ADR-0006). Bağlanmazsa sunum hiç beklemez.
func bind_boons(catalog: BoonCatalog, modifiers: ModifierController) -> void:
	_catalog = catalog
	_modifiers = modifiers


## Kaydedilmiş seçimlerden ([member GameState.boons]) lütuf kayıtlarını yeniden kurar —
## bağlam başlangıcında ve yüklemede (spirit AC19, ADR-0006/0007).
func rebuild_boon_modifiers() -> void:
	if _catalog == null or _modifiers == null:
		return
	_modifiers.rebuild(_catalog.sources_for(_game_state.boons))


## Bir sonraki lütfun maliyeti `boon_cost(n)`, `n = boons.size()` (§4.4).
func next_boon_cost() -> int:
	return _rules.boon_cost(_game_state.boons.size())


## Sunum koşulu (§3.4) — durumdan türetilir, ayrıca saklanmaz.
func is_offer_pending() -> bool:
	if _catalog == null:
		return false
	return _rules.is_offer_pending(_game_state.ruh, _game_state.boons.size(), _pool().size())


## Bekleyen sunumun 3 kartı (§4.5) — açıldığı anda yeniden hesaplanır; sunum yoksa boş.
func current_offer(scene_id: int) -> Array[BoonDefinition]:
	if not is_offer_pending():
		return [] as Array[BoonDefinition]
	return BoonRules.offer(_pool(), scene_id, _game_state.boons.size())


## Seçim (§3.4): yalnızca bekleyen sunumdaki bir kart; etki hemen başlar
## ([method ModifierController.add_source]), maliyet Ruh'tan düşer, seçim `boons`'a eklenir.
func pick_boon(scene_id: int, boon_id: StringName) -> bool:
	var chosen: BoonDefinition = null
	for boon: BoonDefinition in current_offer(scene_id):
		if boon.boon_id == boon_id:
			chosen = boon
			break
	if chosen == null:
		return false
	var cost: int = next_boon_cost()
	if not _modifiers.add_source(chosen.modifier_source):
		return false
	_game_state.ruh -= cost
	_game_state.boons.append(chosen.boon_id)
	ruh_changed.emit(_game_state.ruh)
	boon_picked.emit(chosen.boon_id)
	return true


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


func _pool() -> Array[BoonDefinition]:
	return BoonRules.eligible_pool(_catalog, _modifiers)
