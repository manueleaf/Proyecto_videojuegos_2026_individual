extends Area2D
class_name Hazard

## Peligro: respawnea al jugador al contacto (rayo láser, pozo de ácido, etc.).
## Si `blink` es true, alterna activo/inactivo para poder cruzarlo con timing;
## oculta el nodo hijo "Beam" mientras está inactivo.

@export var blink: bool = false
@export var on_time: float = 1.1
@export var off_time: float = 1.0
## Causa de muerte para los efectos (Vfx): "acid" derrite al jugador, otro = chispas.
@export var death_cause: String = "generic"

@onready var _beam: CanvasItem = get_node_or_null("Beam")

var _active: bool = true
var _t: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if not blink:
		return
	_t += delta
	var was: bool = _active
	_active = fmod(_t, on_time + off_time) < on_time
	if _active != was:
		if _beam:
			_beam.visible = _active
		if _active:
			# Si el jugador ya estaba dentro al reactivarse, también lo alcanza.
			for b in get_overlapping_bodies():
				_try_hit(b)


func _on_body_entered(body: Node) -> void:
	if _active:
		_try_hit(body)


func _try_hit(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("respawn"):
		body.respawn(death_cause)
