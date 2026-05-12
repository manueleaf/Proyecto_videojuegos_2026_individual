extends Area2D
class_name LevelGoal

## Zona de meta: cuando el jugador entra, emite la señal `reached`
## y opcionalmente muestra una etiqueta de HUD.

signal reached

@export var hud_label_path: NodePath

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
	if not hud_label_path.is_empty():
		var label: CanvasItem = get_node_or_null(hud_label_path) as CanvasItem
		if label:
			label.visible = true
