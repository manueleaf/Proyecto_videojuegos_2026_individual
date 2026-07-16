extends Area2D

## Proyectil de la torreta: se mueve recto. Respawnea al jugador si lo toca y
## desaparece al chocar con el mundo o al agotar su tiempo de vida.

@export var lifetime: float = 3.0

var _velocity: Vector2 = Vector2.ZERO
var _life: float = 0.0


func setup(vel: Vector2) -> void:
	_velocity = vel
	rotation = vel.angle()


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += _velocity * delta
	_life += delta
	if _life >= lifetime:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("respawn"):
			body.respawn()
		queue_free()
	elif body is StaticBody2D:
		queue_free()  # choca con pared / suelo / plataforma
