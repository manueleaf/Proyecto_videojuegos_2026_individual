extends RigidBody2D

## Caja metalica: objeto manipulable por el iman del jugador.

const SELECTED_COLOR: Color = Color(0.3, 0.75, 1.0, 1.0)  # Azul claro

@onready var inner_mark: Polygon2D = $InnerMark
var _normal_color: Color
var _selected: bool = false


func _ready() -> void:
	add_to_group("metal_box")
	_normal_color = inner_mark.color


func set_selected(selected: bool) -> void:
	if _selected == selected:
		return
	_selected = selected
	inner_mark.color = SELECTED_COLOR if selected else _normal_color
