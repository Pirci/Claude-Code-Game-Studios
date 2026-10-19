class_name SpiritRules
extends RefCounted
## Erlik katmanının saf formülleri (spirit-system.md §4.1–4.3). Durum yok, sinyal yok —
## hamle çözümü (ADR-0010), gelir ve önizleme aynı fonksiyonları kullanır.


## Arınma Ustalığı vb. lütufların hedeflediği stat (ADR-0006).
const STAT_RUH_GAIN: StringName = &"ruh_gain"

var _config: SpiritConfig = SpiritConfig.new()


func bind_config(config: SpiritConfig) -> void:
	if config != null:
		_config = config


## Arınma direnci `S` (§4.1). Arındırma `P > S` ile başarılı olur.
func corruption_strength(level: int) -> int:
	return level * _config.corr_str_per_level


## Arındırma ödülü (§4.2), arındırma *öncesi* seviyeyle; lütuf yüzdeleri StatResolver'dan.
func ruh_gain(level: int, modifiers: Array[StatModifier]) -> int:
	return roundi(StatResolver.resolve(STAT_RUH_GAIN, float(level * _config.ruh_per_level), modifiers))


## Üretim çarpanı `M_c` (§4.3); aralık dışı seviye sınırlanır.
func production_multiplier(level: int) -> float:
	var table: PackedFloat32Array = _config.corruption_production_multipliers
	if table.is_empty():
		return 1.0
	return table[clampi(level, 0, table.size() - 1)]


func max_corruption_level() -> int:
	return _config.max_corruption_level


## Lütuf maliyeti (§4.4) — [param picked_count] daha önce seçilen lütuf sayısı `n`.
func boon_cost(picked_count: int) -> int:
	return BoonRules.boon_cost(picked_count, _config)


func is_offer_pending(ruh: int, picked_count: int, pool_size: int) -> bool:
	return BoonRules.is_offer_pending(ruh, picked_count, pool_size, _config)


## Sahne sonu zorunlu seçim dizisinin üst sınırı (§3.4).
func victory_pick_cap() -> int:
	return _config.victory_pick_cap
