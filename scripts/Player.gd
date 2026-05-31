extends CharacterBody2D

## Mag-Boy: jugador con movimiento de plataformas y polaridad magnetica.

# Movimiento
@export var speed: float = 220.0
@export var jump_velocity: float = -420.0
@export var acceleration: float = 1500.0
@export var friction: float = 1800.0
@export var air_control: float = 0.6

# Magnetismo
@export var magnet_force: float = 1800.0
@export var magnet_falloff: float = 0.35  # 0 = fuerza constante, 1 = decae linealmente con distancia
@export var debug_magnetism: bool = false

enum Polarity { NONE, ATTRACT, REPEL }
var current_polarity: int = Polarity.NONE
var selected_box: RigidBody2D = null  # Caja actualmente atraida

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var magnet_area: Area2D = $MagnetArea
@onready var sprite: Sprite2D = $Sprite
@onready var core: Polygon2D = $Core

var _spawn_position: Vector2


func _ready() -> void:
	add_to_group("player")
	_spawn_position = global_position


func respawn() -> void:
	## Devuelve al jugador al punto de aparición y limpia su estado magnético.
	global_position = _spawn_position
	velocity = Vector2.ZERO
	current_polarity = Polarity.NONE
	_set_selected_box(null)
	Audio.set_magnet_active(false)


func _physics_process(delta: float) -> void:
	_handle_gravity(delta)
	_handle_jump()
	_handle_horizontal_movement(delta)
	_handle_polarity_input()
	_update_target_selection()
	_apply_magnetism()
	_update_visual_feedback()
	move_and_slide()


func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta


func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		Audio.play_sfx("jump")


func _handle_horizontal_movement(delta: float) -> void:
	var direction: float = Input.get_axis("move_left", "move_right")
	var control: float = 1.0 if is_on_floor() else air_control

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * control * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * control * delta)


func _handle_polarity_input() -> void:
	if Input.is_action_pressed("attract"):
		current_polarity = Polarity.ATTRACT
	elif Input.is_action_pressed("repel"):
		current_polarity = Polarity.REPEL
	else:
		current_polarity = Polarity.NONE
	Audio.set_magnet_active(current_polarity != Polarity.NONE)


func _update_target_selection() -> void:
	# Solo seleccionamos cuando estamos atrayendo.
	if current_polarity != Polarity.ATTRACT:
		_set_selected_box(null)
		return

	var bodies_in_range: Array = _get_metal_bodies_in_range()

	# Si la caja actual salio del rango (o fue destruida), deseleccionamos.
	if selected_box != null and not (selected_box in bodies_in_range):
		_set_selected_box(null)

	# Si no hay seleccion, tomamos la caja mas cercana.
	if selected_box == null and not bodies_in_range.is_empty():
		_set_selected_box(_closest_body(bodies_in_range))

	# Shift cambia a la siguiente caja en rango (cycle).
	if Input.is_action_just_pressed("cycle_target") and bodies_in_range.size() > 1:
		_set_selected_box(_next_in_cycle(bodies_in_range, selected_box))


func _apply_magnetism() -> void:
	if current_polarity == Polarity.NONE:
		return

	if current_polarity == Polarity.ATTRACT:
		# Atraccion: solo a la caja seleccionada.
		if selected_box != null:
			_apply_magnet_force(selected_box, true)
	else:
		# Repulsion: a todas las cajas en rango (util contra drones / lanzar varias).
		for body in _get_metal_bodies_in_range():
			_apply_magnet_force(body, false)


func _apply_magnet_force(body: RigidBody2D, is_attract: bool) -> void:
	var to_box: Vector2 = body.global_position - global_position
	var distance: float = to_box.length()
	if distance < 1.0:
		return

	var dir: Vector2 = to_box / distance
	var falloff: float = lerp(1.0, clamp(1.0 - distance / magnet_area_radius(), 0.0, 1.0), magnet_falloff)
	var force_magnitude: float = magnet_force * falloff

	var force: Vector2 = -dir * force_magnitude if is_attract else dir * force_magnitude

	body.sleeping = false
	body.apply_central_force(force)

	if debug_magnetism:
		print("[MAG] %s dist=%.0f fuerza=%s" % [body.name, distance, force])


func _get_metal_bodies_in_range() -> Array:
	var result: Array = []
	for body in magnet_area.get_overlapping_bodies():
		if body is RigidBody2D:
			result.append(body)
	return result


func _closest_body(bodies: Array) -> RigidBody2D:
	var closest: RigidBody2D = null
	var closest_dist_sq: float = INF
	for body in bodies:
		var d_sq: float = (body.global_position - global_position).length_squared()
		if d_sq < closest_dist_sq:
			closest = body
			closest_dist_sq = d_sq
	return closest


func _next_in_cycle(bodies: Array, current: RigidBody2D) -> RigidBody2D:
	if bodies.is_empty():
		return null
	if current == null:
		return bodies[0]
	var idx: int = bodies.find(current)
	if idx == -1:
		return bodies[0]
	return bodies[(idx + 1) % bodies.size()]


func _set_selected_box(box: RigidBody2D) -> void:
	if selected_box == box:
		return
	if selected_box != null and selected_box.has_method("set_selected"):
		selected_box.set_selected(false)
	selected_box = box
	if selected_box != null and selected_box.has_method("set_selected"):
		selected_box.set_selected(true)


func magnet_area_radius() -> float:
	# Lee el radio del CollisionShape2D del Area2D (asume CircleShape2D).
	var shape_node: CollisionShape2D = magnet_area.get_node("CollisionShape2D")
	if shape_node and shape_node.shape is CircleShape2D:
		return (shape_node.shape as CircleShape2D).radius
	return 200.0


func _update_visual_feedback() -> void:
	# El nucleo cambia de color segun la polaridad activa.
	match current_polarity:
		Polarity.ATTRACT:
			core.color = Color(0.2, 0.6, 1.0, 1.0)  # Azul
		Polarity.REPEL:
			core.color = Color(1.0, 0.25, 0.25, 1.0)  # Rojo
		_:
			core.color = Color(0.9, 0.9, 0.4, 1.0)  # Amarillo (neutro)
