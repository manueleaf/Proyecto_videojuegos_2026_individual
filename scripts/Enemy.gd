extends CharacterBody2D
class_name SentinelDrone

## Dron Centinela: robot volador que patrulla horizontalmente desde su punto
## de aparición (`patrol_distance`) y flota con un leve vaivén. No dispara,
## pero daña al jugador al contacto (lo respawnea). Muere si lo golpea una caja
## metálica con suficiente velocidad (puzzle: repeler la caja con el imán).

@export var speed: float = 90.0
@export var patrol_distance: float = 220.0  # Distancia desde el spawn a cada lado
@export var box_kill_speed: float = 250.0   # Velocidad mínima de caja para destruirlo
@export var debug_enemy: bool = false

const BOB_FREQ: float = 3.0   # Velocidad del vaivén vertical
const BOB_AMP: float = 8.0    # Amplitud del vaivén (px)

@onready var hit_area: Area2D = $HitArea
@onready var sprite: Sprite2D = $Sprite

var _spawn_x: float
var _spawn_y: float
var _direction: int = -1
var _t: float = 0.0


func _ready() -> void:
	add_to_group("enemy")
	_spawn_x = global_position.x
	_spawn_y = global_position.y
	hit_area.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_t += delta

	# Patrullaje horizontal: rebota en los límites o al chocar con una pared.
	if _direction < 0 and global_position.x <= _spawn_x - patrol_distance:
		_direction = 1
	elif _direction > 0 and global_position.x >= _spawn_x + patrol_distance:
		_direction = -1
	if is_on_wall():
		_direction *= -1
	velocity.x = _direction * speed

	# Vuelo: flota alrededor de su altura de aparición con un leve vaivén.
	var target_y: float = _spawn_y + sin(_t * BOB_FREQ) * BOB_AMP
	velocity.y = (target_y - global_position.y) * 8.0

	move_and_slide()

	# Animación: mira hacia donde se mueve y se inclina un poco.
	sprite.flip_h = _direction > 0
	sprite.rotation = lerp(sprite.rotation, _direction * 0.12, 0.15)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if debug_enemy:
			print("[DRON] Jugador tocado -> respawn")
		if body.has_method("respawn"):
			body.respawn()
		return

	if body.is_in_group("metal_box") and body is RigidBody2D:
		var box_speed: float = (body as RigidBody2D).linear_velocity.length()
		if debug_enemy:
			print("[DRON] Caja impacto velocidad=%.1f" % box_speed)
		if box_speed >= box_kill_speed:
			_die()


func _die() -> void:
	if debug_enemy:
		print("[DRON] Eliminado")
	set_physics_process(false)
	hit_area.set_deferred("monitoring", false)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "scale", Vector2(1.7, 1.7), 0.2)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tw.set_parallel(false)
	tw.tween_callback(queue_free)
