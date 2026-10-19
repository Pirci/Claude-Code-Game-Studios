class_name SceneFlowConfig
extends Resource
## Sahne akışı ayarları — scene-flow.md §7 (içerik: data/scene_flow_config.tres). Zorunlu lütuf
## dizisi tavanı `VICTORY_PICK_CAP`'in tek sahibi [SpiritConfig]'tir.


## Metin ortaya çıkış hızı (karakter/sn); 0 = anında (Hareketi Azalt'ta zorlanır).
@export var text_reveal_cps: float = 45.0
## Her yeni ekran/sayfada ilk bu kadar saniyedeki girdi yok sayılır (F6).
@export var screen_input_guard_s: float = 0.4
## 0 = otomatik ilerleme kapalı.
@export var auto_advance_delay_s: float = 0.0
## Yeniden Dene sahne girişi anlık görüntüsünü geri yükler (R3, Ruh çiftçiliğine karşı).
@export var retry_restores_entry_snapshot: bool = true
@export var confirm_leave_scene: bool = true
@export var illustration_load_timeout_s: float = 3.0
