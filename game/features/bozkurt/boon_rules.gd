class_name BoonRules
extends RefCounted
## Lütuf sunumunun saf kuralları (spirit-system.md §3.4, §4.4, §4.5). Durum yok — sunum
## koşulu `ruh` ve `boons`'tan her an yeniden türetilir; ayrı "bekleyen sunum" alanı yok.


## Bir sunumdaki kart sayısı (§3.4).
const OFFER_SIZE: int = 3


## §4.4: `BASE_BOON_COST + n × BOON_COST_STEP` (n = daha önce seçilen lütuf sayısı).
static func boon_cost(picked_count: int, config: SpiritConfig) -> int:
	return config.base_boon_cost + picked_count * config.boon_cost_step


## Uygun havuz (§3.5): katalog − gerektirdiği sistem etkin olmayanlar − yığın sınırına
## ulaşmışlar ([method ModifierController.can_add]), `boon_id`'ye göre sıralı.
static func eligible_pool(catalog: BoonCatalog, modifiers: ModifierController) -> Array[BoonDefinition]:
	var pool: Array[BoonDefinition] = []
	for boon: BoonDefinition in catalog.boons:
		if not catalog.is_available(boon):
			continue
		if modifiers != null and not modifiers.can_add(boon.modifier_source):
			continue
		pool.append(boon)
	pool.sort_custom(func(a: BoonDefinition, b: BoonDefinition) -> bool:
		return String(a.boon_id) < String(b.boon_id))
	return pool


## §4.5 deterministik 3'lü: `seed = (scene_id × 31 + n × 7) mod |pool|`, slot k =
## `pool[(seed + k) mod |pool|]`. Havuz 3'ten küçükse slotlar tekrar eder; boşsa sunum yok.
static func offer(pool: Array[BoonDefinition], scene_id: int, picked_count: int) -> Array[BoonDefinition]:
	var result: Array[BoonDefinition] = []
	if pool.is_empty():
		return result
	var start: int = posmod(scene_id * 31 + picked_count * 7, pool.size())
	for k: int in OFFER_SIZE:
		result.append(pool[(start + k) % pool.size()])
	return result


## Sunum bekler ⇔ `ruh ≥ boon_cost(n)` ve uygun havuz boş değil (§3.4).
static func is_offer_pending(ruh: int, picked_count: int, pool_size: int, config: SpiritConfig) -> bool:
	return pool_size > 0 and ruh >= boon_cost(picked_count, config)
