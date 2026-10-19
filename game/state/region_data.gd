class_name RegionData
extends RefCounted
## Tek bir harita bölgesinin durumunu tutar. Mantık yok, sadece veri.


enum Owner { NEUTRAL, PLAYER, ENEMY }


var region_id: StringName = &""
var display_name_key: StringName = &""
var owner: Owner = Owner.NEUTRAL
## Bölüm başındaki sahip — içerikten ([RegionDefinition]) gelir, kaydedilmez (ADR-0007);
## kazanmanın "başlangıçta nötr" sayımı için (region-map §4).
var initial_owner: Owner = Owner.NEUTRAL
var army_count: int = 0
var gold_per_turn: int = 0
var position: Vector2 = Vector2.ZERO
var polygon_points: PackedVector2Array = PackedVector2Array()
var adjacent_regions: Array[StringName] = []
## Erlik bozulma seviyesi 0 (temiz) – 3 (ağır); sahiplikten bağımsız (spirit-system.md §3.1).
## Tek yazıcı: SpiritController (C-38).
var corruption_level: int = 0
