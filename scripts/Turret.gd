extends Node2D
class_name Turret

## Torreta fija: detecta al jugador dentro de un rango y le dispara proyectiles.
## Es más difícil que el dron porque ataca a distancia. Muere si la golpea una
## caja rápida (repulsión magnética) o si el jugador la embiste con un dash
## magnético (velocidad alta). Obstáculo sólido: se puede saltar o destruir.

const BOLT := preload("res://scenes/Bolt.tscn")

@export var fire_interval: float = 1.3     # segundos entre disparos
@export var bolt_speed: float = 360.0
@export var box_kill_speed: float = 250.0  # velocidad de caja para destruirla
@export var player_kill_speed: float = 600.0  # velocidad del dash del jugador
@export var debug_turret: bool = false

@onready var cannon: Node2D = $Cannon
@onready var muzzle: Marker2D = $Cannon/Muzzle
@onready var detect_area: Area2D = $DetectArea
@onready var hit_area: Area2D = $HitArea

var _player: Node2D = null
var _fire_timer: float = 0.6
var _alive: bool = true


func _ready() -> void:
	add_to_group("enemy")
	detect_area.body_entered.connect(func(b): if b.is_in_group("player"): _player = b)
	detect_area.body_exited.connect(func(b): if b == _player: _player = null)
	hit_area.body_entered.connect(_on_hit)


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	if _player != null and is_instance_valid(_player):
		var to_p: Vector2 = _player.global_position - global_position
		cannon.rotation = to_p.angle()          # apunta al jugador
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_fire_timer = fire_interval
			_shoot(to_p.normalized())
	else:
		_fire_timer = 0.5   # pequeño telegrafiado al reaparecer el jugador


func _shoot(dir: Vector2) -> void:
	var b := BOLT.instantiate()
	get_parent().add_child(b)
	b.global_position = muzzle.global_position
	if b.has_method("setup"):
		b.setup(dir * bolt_speed)
	if debug_turret:
		print("[TORRETA] dispara ", dir)


func _on_hit(body: Node) -> void:
	if not _alive:
		return
	if body.is_in_group("metal_box") and body is RigidBody2D:
		if (body as RigidBody2D).linear_velocity.length() >= box_kill_speed:
			_die()
	elif body.is_in_group("player") and body is CharacterBody2D:
		if (body as CharacterBody2D).velocity.length() >= player_kill_speed:
			_die()


func _die() -> void:
	_alive = false
	set_physics_process(false)
	hit_area.set_deferred("monitoring", false)
	detect_area.set_deferred("monitoring", false)
	var body_col := get_node_or_null("Body/CollisionShape2D")
	if body_col:
		body_col.set_deferred("disabled", true)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.set_parallel(false)
	tw.tween_callback(queue_free)
