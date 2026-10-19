class_name ArmyController
extends RefCounted
## Ordu alanlarının (sahip, ordu sayısı) yazıcısı. Kurallar [MoveResolver]'dadır; burası
## yalnızca bir [MoveOutcome]'u uygular (ADR-0010). Bozulma ve Ruh SpiritController'ındır.


## Hareket geçerli mi? Kurallar [method MoveResolver.validate] ile aynı (army-system §3.1).
func can_move(
	map_state: MapState,
	from_id: StringName,
	to_id: StringName,
	mover: RegionData.Owner = RegionData.Owner.PLAYER,
) -> bool:
	return MoveResolver.validate(map_state, from_id, to_id, mover) == &""


## [param outcome]'daki kaynak ve hedef ordu/sahip değerlerini yazar; geçersizse dokunmaz.
func apply_outcome(map_state: MapState, outcome: MoveOutcome) -> void:
	if not outcome.is_valid():
		return
	map_state.get_region(outcome.from_id).army_count = outcome.source_army_after
	var target: RegionData = map_state.get_region(outcome.to_id)
	# Sahip değişince üretim sayacı yeni sahipte 0'dan başlar (resource §3.2, AC19).
	if target.owner != outcome.target_owner_after:
		target.recruited_this_turn = 0
	target.owner = outcome.target_owner_after
	target.army_count = outcome.target_army_after
