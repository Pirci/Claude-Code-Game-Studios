class_name ModifierController
extends RefCounted
## [member GameState.modifiers]'ın tek yazarı (ADR-0006). [ModifierSource]'ları
## [StatModifier] kayıtlarına açar; özel grup çakışmasını ve [member ModifierSource.max_stacks]
## sınırını yazma anında uygular. Kayıtlar türetilmiş durumdur: yüklemede ve bağlam
## başlangıcında kaydedilmiş seçimlerden [method rebuild] ile yeniden kurulur.


## Bir stat'ı etkileyen kayıtlar değişti (signal up — HUD/tüketiciler yeniden çözer).
signal modifiers_changed(stat_id: StringName)

var _game_state: GameState = null
## Etkin kaynaklar ve yığınları — [member GameState.modifiers]'tan türetilmiş önbellek;
## [method rebuild] sıfırlar. Etkisiz bir kaynağın da yığını sayılabilsin diye ayrı tutulur.
var _active_sources: Dictionary[StringName, ModifierSource] = {}
var _source_stacks: Dictionary[StringName, int] = {}


func bind_services(game_state: GameState) -> void:
	_game_state = game_state


## Saf kurallara ([StatResolver] çağıran servisler) aktarılacak kayıt listesi. Tüketiciler
## listeyi dolaşmaz; yalnızca resolver'a verir (ADR-0006).
func get_modifiers() -> Array[StatModifier]:
	return _game_state.modifiers


## Kaynak eklenebilir mi? Lütuf havuzu gibi uygunluk denetimleri [code]stacks[/code]
## okumak yerine bunu sorar.
func can_add(source: ModifierSource) -> bool:
	if source == null or source.source_id == &"":
		return false
	if source.exclusive_group != &"":
		for other: ModifierSource in _active_sources.values():
			if other.source_id != source.source_id and other.exclusive_group == source.exclusive_group:
				return false
	if source.max_stacks > 0 and _source_stacks.get(source.source_id, 0) >= source.max_stacks:
		return false
	return true


## Kaynağı ekler; aynı [member ModifierSource.source_id] tekrar eklenirse kayıtların
## yığını artar (kopya kayıt eklenmez). Grup çakışması veya yığın sınırında [code]false[/code].
func add_source(source: ModifierSource) -> bool:
	var changed: Array[StringName] = []
	if not _add(source, changed):
		push_warning("ModifierController: kaynak reddedildi: %s" % _describe(source))
		return false
	_emit_changed(changed)
	return true


## Kaynağın tüm kayıtlarını (bütün yığınlarıyla) kaldırır.
func remove_source(source_id: StringName) -> void:
	if not _active_sources.has(source_id):
		return
	var changed: Array[StringName] = []
	var kept: Array[StatModifier] = []
	for modifier: StatModifier in _game_state.modifiers:
		if modifier.source_id == source_id:
			_append_unique(changed, modifier.stat_id)
		else:
			kept.append(modifier)
	_game_state.modifiers = kept
	_active_sources.erase(source_id)
	_source_stacks.erase(source_id)
	_emit_changed(changed)


## Kayıtları temizler ve kaynakları sırayla yeniden ekler (kaydedilmiş her seçim için bir
## giriş). Aynı listeyle tekrar çağrılması aynı kayıtları üretir; düşürülmüş bir
## [member ModifierSource.max_stacks] fazla seçimleri burada kırpar (uyarıyla atlanır).
func rebuild(sources: Array[ModifierSource]) -> void:
	var changed: Array[StringName] = []
	for modifier: StatModifier in _game_state.modifiers:
		_append_unique(changed, modifier.stat_id)
	_game_state.modifiers.clear()
	_active_sources.clear()
	_source_stacks.clear()
	for source: ModifierSource in sources:
		if not _add(source, changed):
			push_warning("ModifierController.rebuild: kaynak atlandı: %s" % _describe(source))
	_emit_changed(changed)


func _add(source: ModifierSource, changed: Array[StringName]) -> bool:
	if not can_add(source):
		return false
	if _active_sources.has(source.source_id):
		for modifier: StatModifier in _game_state.modifiers:
			if modifier.source_id == source.source_id:
				modifier.stacks += 1
				_append_unique(changed, modifier.stat_id)
	else:
		_active_sources[source.source_id] = source
		for effect: ModifierEffect in source.effects:
			_merge_effect(source.source_id, effect)
			_append_unique(changed, effect.stat_id)
	_source_stacks[source.source_id] = _source_stacks.get(source.source_id, 0) + 1
	return true


## İlk eklemede etkiyi kayda çevirir; aynı kaynakta aynı (stat, tür) iki kez geçerse
## değerler tek kayıtta toplanır (benzersizlik değişmezi).
func _merge_effect(source_id: StringName, effect: ModifierEffect) -> void:
	for modifier: StatModifier in _game_state.modifiers:
		if modifier.source_id == source_id and modifier.stat_id == effect.stat_id and modifier.kind == effect.kind:
			modifier.value += effect.value
			return
	var record: StatModifier = StatModifier.new()
	record.source_id = source_id
	record.stat_id = effect.stat_id
	record.kind = effect.kind
	record.value = effect.value
	_game_state.modifiers.append(record)


func _emit_changed(stat_ids: Array[StringName]) -> void:
	for stat_id: StringName in stat_ids:
		modifiers_changed.emit(stat_id)


static func _describe(source: ModifierSource) -> String:
	return String(source.source_id) if source else "<null>"


static func _append_unique(list: Array[StringName], item: StringName) -> void:
	if item not in list:
		list.append(item)
