class_name BoonDefinition
extends Resource
## Kök Böri lütfu içeriği (spirit-system.md §3.5): kimlik, metin key'leri, gerektirdiği sistem
## ve etkisini taşıyan [ModifierSource]. Yığın sınırının tek sahibi kaynağın
## [member ModifierSource.max_stacks] alanıdır (ADR-0006, C-17 D2). Asla kaydedilmez;
## kayıtta yalnızca [member boon_id] durur ([member GameState.boons]).


@export var boon_id: StringName = &""
@export var name_key: String = ""
## Kart açıklaması; `%s` = [method display_amount] (yüzde için çeviri `%%` taşır).
@export var description_key: String = ""
## Lütfun anlam kazanması için etkin olması gereken sistem (ör. `&"effective_power"`);
## boş = her zaman uygun. Etkin sistemler [member BoonCatalog.active_systems].
@export var requires: StringName = &""
@export var modifier_source: ModifierSource = null


## Kartta gösterilen büyüklük: ilk etkinin yığın başına değeri (yüzde için ×100, tam sayı).
func display_amount() -> int:
	if modifier_source == null or modifier_source.effects.is_empty():
		return 0
	var effect: ModifierEffect = modifier_source.effects[0]
	if effect.kind == StatModifier.Kind.PERCENT:
		return roundi(effect.value * 100.0)
	return roundi(effect.value)
