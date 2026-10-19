class_name EconomyConfig
extends Resource
## Oyun geneli ekonomi ayarları — resource-system.md §7 (içerik: data/economy_config.tres).


## Birlik başı üretim maliyeti (F4; MVP 2, güvenli 1–4).
@export var recruit_cost: int = 2
## Asgari üretim tavanı `R_min` (F3; MVP 1).
@export var recruit_min_cap: int = 1
## Gelir tabanı `I_floor` (F2; MVP 0).
@export var income_floor: int = 0
## Birlik başı bakım `U` (F7; MVP 0 = bakım yok) ve ücretsiz eşik `A_free`.
@export var upkeep_per_army: int = 0
@export var upkeep_free_armies: int = 10
## Lütuf yüzde çarpanı `M_g` üst sınırı (F2; aralık 1.0–2.0).
@export var max_income_multiplier: float = 2.0
