extends StaticBody2D
class_name Door

## Puerta vinculada a uno o más botones. Se abre cuando se han presionado
## `required_presses` botones (por defecto 1). Si `auto_close` es true, se
## vuelve a cerrar al soltar alguno (mientras el conteo baje del requerido).

@export var start_open: bool = false
@export var auto_close: bool = true
@export_range(1, 4) var required_presses: int = 1

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sprite: Polygon2D = $Sprite

const COLOR_CLOSED: Color = Color(0.55, 0.35, 0.75, 1.0)
const COLOR_OPEN: Color = Color(0.55, 0.35, 0.75, 0.18)

var _press_count: int = 0
var _is_open: bool = false


func _ready() -> void:
	if start_open:
		_open()
	else:
		_close()


func on_button_pressed() -> void:
	_press_count += 1
	if _press_count >= required_presses and not _is_open:
		_open()
		Audio.play_sfx("door")
		Vfx.spark_burst(global_position)


func on_button_released() -> void:
	_press_count = max(0, _press_count - 1)
	if auto_close and _press_count < required_presses and _is_open:
		_close()


func _open() -> void:
	_is_open = true
	collision.set_deferred("disabled", true)
	sprite.color = COLOR_OPEN


func _close() -> void:
	_is_open = false
	collision.set_deferred("disabled", false)
	sprite.color = COLOR_CLOSED
