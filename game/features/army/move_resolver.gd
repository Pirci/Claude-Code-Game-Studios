class_name MoveResolver
extends RefCounted
## Hamle çözümü — saf: haritayı yalnızca okur, durum yazmaz, sinyal yaymaz (ADR-0010).
## Önizleme, oyuncu hamlesi ve düşman hamlesi aynı [method resolve]'u kullanır; böylece
## önizleme sonuçla hiçbir zaman ayrışmaz. Varış dalları army-system.md §3.3 sırasıyla:
## savaş → (arındırma, C-38) → barışçıl.


const REASON_NO_SOURCE: StringName = &"no_source"
const REASON_NO_TARGET: StringName = &"no_target"
const REASON_NOT_OWNER: StringName = &"not_owner"
const REASON_SINGLE_GARRISON: StringName = &"single_garrison"
const REASON_NOT_ADJACENT: StringName = &"not_adjacent"
const REASON_NO_ACTIONS: StringName = &"no_actions"

var _combat: CombatResolver = CombatResolver.new()


func bind_services(combat: CombatResolver) -> void:
	if combat != null:
		_combat = combat


## Hamle kuralları ([param mover] için aynı, army-system §3.1); geçerliyse boş döner.
## Aksiyon bütçesi yalnızca oyuncu hamlesinde denetlenir (düşmanınkini [MapController] yönetir).
static func validate(
	map_state: MapState,
	from_id: StringName,
	to_id: StringName,
	mover: RegionData.Owner,
) -> StringName:
	var source: RegionData = map_state.get_region(from_id)
	if source == null:
		return REASON_NO_SOURCE
	if map_state.get_region(to_id) == null:
		return REASON_NO_TARGET
	if source.owner != mover:
		return REASON_NOT_OWNER
	if source.army_count <= 1:
		return REASON_SINGLE_GARRISON
	if to_id not in source.adjacent_regions:
		return REASON_NOT_ADJACENT
	if mover == RegionData.Owner.PLAYER and map_state.actions_remaining <= 0:
		return REASON_NO_ACTIONS
	return &""


## [param from_id] → [param to_id] hamlesinin sonucu. Geçersizse `Branch.INVALID` ve neden.
func resolve(
	map_state: MapState,
	from_id: StringName,
	to_id: StringName,
	mover: RegionData.Owner = RegionData.Owner.PLAYER,
) -> MoveOutcome:
	var outcome: MoveOutcome = MoveOutcome.new()
	outcome.mover = mover
	outcome.from_id = from_id
	outcome.to_id = to_id
	outcome.invalid_reason = validate(map_state, from_id, to_id, mover)
	if outcome.invalid_reason != &"":
		return outcome

	var source: RegionData = map_state.get_region(from_id)
	var target: RegionData = map_state.get_region(to_id)
	outcome.moving = source.army_count - 1
	outcome.source_army_after = 1
	outcome.target_corruption_after = target.corruption_level

	# 1. Savaş: hedefte yabancı garnizon (sahibi hamle yapan değil ve army > 0).
	if target.owner != mover and target.army_count > 0:
		_resolve_combat(outcome, target)
		return outcome

	# 3. Barışçıl: kendi bölgesine katılma ya da boş bölgeyi işgal.
	outcome.branch = MoveOutcome.Branch.PEACEFUL
	outcome.target_owner_after = mover
	if target.owner == mover:
		outcome.target_army_after = target.army_count + outcome.moving
	else:
		outcome.target_army_after = outcome.moving
	return outcome


func _resolve_combat(outcome: MoveOutcome, target: RegionData) -> void:
	outcome.branch = MoveOutcome.Branch.COMBAT
	var result: CombatResolver.CombatResult = _combat.resolve(outcome.moving, target.army_count)
	outcome.combat = result
	if result.attacker_won:
		outcome.target_owner_after = outcome.mover
		outcome.target_army_after = result.attacker_remaining
	else:
		outcome.target_owner_after = target.owner
		outcome.target_army_after = result.defender_remaining
		# Kaybeden saldıranın hayatta kalanları dağılır (army §3.3, W2).
		outcome.dispersed = result.attacker_remaining
	# Boş kalan bölge sahipsiz olur; bozulma korunur (army §3.3, W3).
	if outcome.target_army_after == 0:
		outcome.target_owner_after = RegionData.Owner.NEUTRAL
