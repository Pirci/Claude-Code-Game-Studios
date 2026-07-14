@tool
class_name CombatConfig
extends Resource
## Savaş çözümü ayar değerleri (data-driven). Kazananın kayıp oranları ve
## eşitlik kuralı buradan ayarlanır. Kaybeden taraf her zaman tamamen yok olur.


## Saldıran kazandığında: attacker_losses = ceil(defender_army * bu)
@export_range(0.0, 1.0, 0.05) var attacker_win_loss_ratio: float = 0.5
## Savunan kazandığında: defender_losses = ceil(attacker_army * bu)
@export_range(0.0, 1.0, 0.05) var defender_win_loss_ratio: float = 0.3
## Eşitlikte: attacker_losses = ceil(attacker_army * bu)
@export_range(0.0, 1.0, 0.05) var draw_attacker_loss_ratio: float = 0.7
## Eşitlikte: defender_losses = ceil(defender_army * bu)
@export_range(0.0, 1.0, 0.05) var draw_defender_loss_ratio: float = 0.5
## Eşitlikte savunan mı kazanır? (savunma avantajı)
@export var draw_favors_defender: bool = true
