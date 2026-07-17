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
	_add_trail()


func _add_trail() -> void:
	# Estela de fuego detrás del proyectil.
	var tr := CPUParticles2D.new()
	tr.texture = preload("res://assets/sprites/fx_spark.png")
	tr.local_coords = false
	tr.amount = 16
	tr.lifetime = 0.35
	tr.direction = Vector2(-1, 0)
	tr.spread = 12.0
	tr.gravity = Vector2.ZERO
	tr.initial_velocity_min = 0.0
	tr.initial_velocity_max = 18.0
	tr.scale_amount_min = 0.3
	tr.scale_amount_max = 0.9
	tr.color = Color(1.0, 0.7, 0.3, 0.8)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	tr.material = m
	add_child(tr)


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
		Vfx.bolt_impact(global_position)  # chispa de impacto
		queue_free()  # choca con pared / suelo / plataforma
