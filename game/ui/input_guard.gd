class_name InputGuard
extends RefCounted
## Ekran girdi koruması (scene-flow F6, AC24): yeni ekran açıldıktan sonra ilk
## `screen_input_guard_s` içinde düğmeler basılamaz — kazandıran tık ya da çift basış bir
## sonraki ekranı geçemez. Süre 0 ise hiçbir şey yapılmaz.


## [param buttons] süre boyunca pasif kalır, sonra eski durumlarına döner.
static func arm(owner: Node, buttons: Array[BaseButton], seconds: float) -> void:
	if seconds <= 0.0 or not owner.is_inside_tree():
		return
	var previous: Array[bool] = []
	for button: BaseButton in buttons:
		previous.append(button.disabled)
		button.disabled = true
	owner.get_tree().create_timer(seconds).timeout.connect(func() -> void:
		for i: int in buttons.size():
			if is_instance_valid(buttons[i]):
				buttons[i].disabled = previous[i])
