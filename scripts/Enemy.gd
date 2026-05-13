extends CharacterBody2D
class_name PatrolEnemy

## Enemigo básico: patrulla horizontalmente desde su punto de aparición
## hacia ambos lados (`patrol_distance`). Daña al jugador al contacto
## (lo respawnea) y muere si lo golpea una caja metálica con suficiente
## velocidad (puzzle: usar repulsión magnética para "lanzar" la caja).

@export var speed: float = 90.0
@export var patrol_distance: float = 220.0  # Distancia desde el spawn a cada lado
@export var box_kill_speed: float = 250.0   # Velocidad mínima de caja para matar al enemigo
@export var debug_enemy: bool = false

@onready var hit_area: Area2D = $HitArea
@onready var sprite: Polygon2D = $Sprite
@onready var eye_left: Polygon2D = $EyeLeft
@onready var eye_right: Polygon2D = $EyeRight

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _spawn_x: float
var _direction: int = -1


func _ready() -> void:
	add_to_group("enemy")
	_spawn_x = global_position.x
	hit_area.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	# Gravedad
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	# Patrullaje: rebota al alcanzar el límite de su rango
	if _direction < 0 and global_position.x <= _spawn_x - patrol_distance:
		_direction = 1
	elif _direction > 0 and global_position.x >= _spawn_x + patrol_distance:
		_direction = -1

	# Si choca con pared, también invierte
	if is_on_wall():
		_direction *= -1

	velocity.x = _direction * speed
	move_and_slide()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if debug_enemy:
			print("[ENEMY] Jugador tocado -> respawn")
		if body.has_method("respawn"):
			body.respawn()
		return

	if body.is_in_group("metal_box") and body is RigidBody2D:
		var box_speed: float = (body as RigidBody2D).linear_velocity.length()
		if debug_enemy:
			print("[ENEMY] Caja impacto velocidad=%.1f" % box_speed)
		if box_speed >= box_kill_speed:
			_die()


func _die() -> void:
	if debug_enemy:
		print("[ENEMY] Eliminado")
	queue_free()
