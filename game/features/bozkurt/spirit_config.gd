class_name SpiritConfig
extends Resource
## Erlik katmanı ayarları — spirit-system.md §4 / §7 (içerik: data/spirit_config.tres).


## Seviye başına arınma direnci: `S = corruption_level × corr_str_per_level` (§4.1).
@export var corr_str_per_level: int = 4
## Seviye başına Ruh: `ruh_gain = round(L × ruh_per_level × (1 + bonus))` (§4.2).
@export var ruh_per_level: int = 10
@export var max_corruption_level: int = 3
## Bozulma seviyesine göre üretim çarpanı `M_c` (§4.3; indeks = seviye).
@export var corruption_production_multipliers: PackedFloat32Array = [1.0, 0.75, 0.5, 0.0]
