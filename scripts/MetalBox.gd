extends RigidBody2D

## Caja metalica: objeto manipulable por el iman del jugador.

const SELECTED_TINT: Color = Color(0.55, 0.85, 1.1, 1.0)  # Resalte azulado al seleccionar

@onready var sprite: Sprite2D = $Sprite
var _selected: bool = false


func _ready() -> void:
	add_to_group("metal_box")


func set_selected(selected: bool) -> void:
	if _selected == selected:
		return
	_selected = selected
	sprite.modulate = SELECTED_TINT if selected else Color.WHITE
