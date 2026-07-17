extends Area2D
class_name PressureButton

## Botón de presión: se activa cuando un cuerpo (jugador o caja metálica) lo pisa.
## Notifica al nodo `target_path` llamando `on_button_pressed()` / `on_button_released()`.

signal pressed
signal released

@export var target_path: NodePath
@export var requires_metal_box: bool = false  # Si true, solo activa con cajas metálicas

const COLOR_IDLE: Color = Color(0.85, 0.25, 0.25, 1.0)   # Rojo apagado
const COLOR_ACTIVE: Color = Color(0.3, 0.95, 0.4, 1.0)    # Verde brillante

@onready var cap: Polygon2D = $Cap

var _bodies_on: int = 0
var _is_pressed: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	cap.color = COLOR_IDLE


func _on_body_entered(body: Node) -> void:
	if not _is_valid_body(body):
		return
	_bodies_on += 1
	_update_state()


func _on_body_exited(body: Node) -> void:
	if not _is_valid_body(body):
		return
	_bodies_on = max(0, _bodies_on - 1)
	_update_state()


func _is_valid_body(body: Node) -> bool:
	if requires_metal_box:
		return body.is_in_group("metal_box")
	return true


func _update_state() -> void:
	var new_state: bool = _bodies_on > 0
	if new_state == _is_pressed:
		return
	_is_pressed = new_state
	cap.color = COLOR_ACTIVE if _is_pressed else COLOR_IDLE
	if _is_pressed:
		Audio.play_sfx("button")
		pressed.emit()
		_notify_target("on_button_pressed")
	else:
		released.emit()
		_notify_target("on_button_released")


func _notify_target(method: String) -> void:
	if target_path.is_empty():
		return
	var target: Node = get_node_or_null(target_path)
	if target and target.has_method(method):
		target.call(method)
