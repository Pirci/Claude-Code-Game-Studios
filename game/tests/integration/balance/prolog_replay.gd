extends RefCounted
## Prolog denge oynatıcısı (C-64): GameContext'in kurduğu gerçek kontrolcülerle (MapController,
## ResourceController, MoveResolver, SpiritController, ModifierController, ErlikSpreadController)
## hamle dizilerini oynatır. Kural tekrarı değil — oyun kodunun kendisi (bkz. tools/balance/prolog_sim.py).


const PROLOG_MAP: String = "res://features/grid/data/chapter_1_map.tres"
const COMBAT_CONFIG: String = "res://features/combat/data/combat_config.tres"
const SPIRIT_CONFIG: String = "res://features/bozkurt/data/spirit_config.tres"
const ECONOMY_CONFIG: String = "res://features/resources/data/economy_config.tres"
const BOON_CATALOG: String = "res://features/bozkurt/data/boon_catalog.tres"
const ALIAS: Dictionary = {
	"O": &"otuken", "B": &"bati_bozkir", "D": &"dogu_bozkir",
	"A": &"altai", "G": &"guney_vadi", "L": &"sinir_bolge",
}

var game_state: GameState
var map: MapController
var resources: ResourceController
var spirit: SpiritController
var definition: ChapterMapDefinition
## `game_won` / `game_lost` kaç kez yayıldı (tek terminal sinyal denetimi).
var won_signals: int = 0
var lost_signals: int = 0
## Her `end_turn` sonundaki Erlik'in Gölgesi (tur → güç), kayıp turu dahil.
var power_by_turn: Dictionary = {}
## Zafer anındaki tur (tur ortası) ya da kaybın işlendiği tur; sürüyorsa 0.
var finished_turn: int = 0


## Yeni Prolog sahnesi (gold = starting_gold) ya da verilen durumdan devam.
func _init(state: GameState = null) -> void:
	definition = load(PROLOG_MAP) as ChapterMapDefinition
	if state == null:
		state = GameState.new()
		state.map_state = definition.create_map_state()
		state.gold = definition.starting_gold
	game_state = state
	_bind()


func _bind() -> void:
	var rules: SpiritRules = SpiritRules.new()
	rules.bind_config(load(SPIRIT_CONFIG) as SpiritConfig)
	resources = ResourceController.new()
	resources.bind_services(rules, load(ECONOMY_CONFIG) as EconomyConfig)
	var combat: CombatResolver = CombatResolver.new()
	combat.bind_config(load(COMBAT_CONFIG) as CombatConfig)
	var resolver: MoveResolver = MoveResolver.new()
	resolver.bind_services(combat, rules)
	spirit = SpiritController.new()
	spirit.bind_services(game_state, rules)
	var modifiers: ModifierController = ModifierController.new()
	modifiers.bind_services(game_state)
	spirit.bind_boons(load(BOON_CATALOG) as BoonCatalog, modifiers)
	spirit.rebuild_boon_modifiers()
	map = MapController.new()
	map.bind_services(game_state.map_state, game_state, ArmyController.new(), resources, combat,
		definition.win_condition, EnemyAIController.new(), resolver)
	map.bind_erlik_layer(spirit, ErlikSpreadController.new(), modifiers)
	map.game_won.connect(func() -> void:
		won_signals += 1
		finished_turn = game_state.map_state.current_turn)
	map.game_lost.connect(func() -> void:
		lost_signals += 1
		finished_turn = game_state.map_state.current_turn - 1)


static func id(alias: String) -> StringName:
	return ALIAS.get(alias, StringName(alias))


func region(alias: String) -> RegionData:
	return game_state.map_state.get_region(id(alias))


func ongoing() -> bool:
	return game_state.map_state.game_result == MapState.GameResult.ONGOING


func recruit(alias: String, count: int) -> bool:
	return map.recruit(id(alias), count)


func move(from_alias: String, to_alias: String) -> bool:
	map.select_region(id(from_alias))
	return map.attempt_move(id(to_alias))


func boon(boon_id: StringName) -> bool:
	return spirit.pick_boon(game_state.map_state.chapter_id, boon_id)


func end_turn() -> void:
	var turn: int = game_state.map_state.current_turn
	map.end_turn()
	power_by_turn[turn] = WinCondition.erlik_power(game_state.map_state)


## Tur içi hamleler: ["rec", bölge, k] / ["mv", kaynak, hedef] / ["boon", id]. Hata → false.
func play_turn(ops: Array) -> bool:
	for op: Array in ops:
		if not ongoing():
			break
		var ok: bool = true
		match op[0]:
			"rec":
				ok = recruit(op[1], op[2])
			"mv":
				ok = move(op[1], op[2])
			"boon":
				ok = boon(StringName(op[1]))
		if not ok:
			push_error("PrologReplay: T%d %s reddedildi" % [game_state.map_state.current_turn, op])
			return false
	if ongoing():
		end_turn()
	return true


## Yalnızca [param alias]'ta tavana / altına kadar üretim (pasif tur).
func recruit_max(alias: String) -> void:
	var count: int = resources.max_recruit(game_state, region(alias))
	if count > 0:
		recruit(alias, count)


## Python oynatıcısının `run`'ı: [param passive] tur yalnızca Otağ'da üretim, sonra çizgi, sonra
## [param idle] bölgesinde (boşsa Otağ) üretimle oyun bitene ya da [param until] turuna dek.
func run_line(script: Array, passive: int = 0, idle: String = "O", until: int = 40) -> bool:
	for i: int in passive:
		recruit_max("O")
		end_turn()
	for ops: Array in script:
		if not ongoing():
			break
		if not play_turn(ops):
			return false
	while ongoing() and game_state.map_state.current_turn <= until:
		recruit_max(idle)
		end_turn()
	return true
