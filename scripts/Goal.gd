extends Area2D
class_name LevelGoal

## Zona de meta ("Salida Segura"): cuando el jugador entra, avisa a `Game`
## (victoria) y emite la señal `reached`.

signal reached

var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	if not body.is_in_group("player"):
		return
	_triggered = true
	reached.emit()
	Game.notify_win()
