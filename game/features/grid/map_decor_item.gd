class_name MapDecorItem
extends Resource
## Harita dekor öğesi (seviye belgesi perde1 §7.6): ağaç, köprü, otağ, körmös. Yalnızca veri; çizimi
## [MapDecorLayer] (C-85) yapar. Konum **ayak** noktasıdır (görünür alt-orta piksel; varlık pivotu,
## generate_env_forest.gd). Bir bölgeye bağlıysa görünürlüğü o bölgenin bozulma seviyesine göre
## [method is_visible] ile hesaplanır — saf, durum yok (dekor kaydedilmez, haritadan türetilir).


## Çizim katmanı (§7.6): GROUND (nehir/zemin) → çizgiler → PROP → bölgeler → OVERLAY (körmös).
enum Layer { GROUND, PROP, OVERLAY }

## Kareler; tek kare = durağan. Çok kare + `fps > 0` = döngü animasyonu (Hareketi Azalt'ta kare 0).
@export var frames: Array[Texture2D] = []
## Ayak noktası (harita koordinatı, 640×360 taban).
@export var position: Vector2 = Vector2.ZERO
@export var layer: Layer = Layer.PROP
## Bağlı bölge; boşsa öğe bozulmadan bağımsızdır (seviye 0 sayılır).
@export var bound_region_id: StringName = &""
## Görünürlük aralığı `min ≤ seviye ≤ max`; `max = -1` sınırsız (çürük ağaç min 1; aynı yerdeki sağlıklı ağaç max 0).
@export_range(0, 3) var min_corruption: int = 0
@export_range(-1, 3) var max_corruption: int = -1
@export_range(0.0, 8.0) var fps: float = 0.0


## Bağlı bölgenin bozulma seviyesinde görünür mü (§7.6 "Bozulma bağlı görünürlük").
func is_visible(level: int) -> bool:
	return level >= min_corruption and (max_corruption < 0 or level <= max_corruption)


## Animasyon gerektiriyor mu (çizim katmanı `_process`'i yalnız bu varken açar).
func is_animated() -> bool:
	return frames.size() > 1 and fps > 0.0
