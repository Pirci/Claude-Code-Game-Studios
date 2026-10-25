class_name EnemyAIProfile
extends Resource
## Bölüm başına siyasi düşman AI ayarı (enemy-layers.md §3.2, ADR-0005 eki C-44). Yalnızca veri;
## [EnemyAIController.bind_config] ile verilir. Varsayılan (`strike_enabled = false`) eski "en düşük
## ordulu komşuya saldır" davranışıdır (Prolog). Başka alan eklenmez (yeni mekanik yok).


## Bu turdan önce R1 hiç vurmaz (öğretici nefes; Perde 1: 5).
@export_range(1, 20) var attack_start_turn: int = 1
## Karşı vuruş oranı `A / P_eff ≥ num / den` (tam sayı aritmetiği; Perde 1: 3/2).
@export_range(1, 10) var strike_ratio_num: int = 3
@export_range(1, 10) var strike_ratio_den: int = 2
## R1 açık; kapalıysa eski davranış.
@export var strike_enabled: bool = false
