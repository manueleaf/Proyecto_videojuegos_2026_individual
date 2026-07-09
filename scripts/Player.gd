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

# Paredes magneticas
@export var wall_dash_impulse: float = 650.0
@export var wall_repel_impulse: float = 700.0
@export var wall_repel_boost_y: float = -320.0
@export var wall_cling_pull: float = 260.0
@export var wall_action_cooldown: float = 0.35

var _wall_cooldown_timer: float = 0.0

enum Polarity { NONE, ATTRACT, REPEL }
var current_polarity: int = Polarity.NONE
var selected_box: RigidBody2D = null  # Caja actualmente atraida

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var magnet_area: Area2D = $MagnetArea
@onready var sprite: Sprite2D = $Sprite
@onready var core: Sprite2D = $Core

var _spawn_position: Vector2
var _anim_t: float = 0.0
var _was_on_floor: bool = true
var _affected: Array = []  # Cajas a las que se dibuja el rayo magnetico


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
	Audio.play_sfx("hurt")
	Game.notify_death()


func _physics_process(delta: float) -> void:
	_handle_gravity(delta)
	_handle_jump()
	_handle_horizontal_movement(delta)
	_handle_polarity_input()
	_update_target_selection()
	_apply_magnetism()
	_process_wall_magnetism(delta)
	_update_visual_feedback()
	move_and_slide()
	_update_sprite_anim(delta)
	queue_redraw()


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
	_affected.clear()
	if current_polarity == Polarity.NONE:
		return

	if current_polarity == Polarity.ATTRACT:
		# Atraccion: solo a la caja seleccionada.
		if selected_box != null:
			_apply_magnet_force(selected_box, true)
			_affected.append(selected_box)
	else:
		# Repulsion: a todas las cajas en rango (util contra drones / lanzar varias).
		for body in _get_metal_bodies_in_range():
			_apply_magnet_force(body, false)
			_affected.append(body)


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


func _get_walls_in_range() -> Array:
	var result: Array = []
	for body in magnet_area.get_overlapping_bodies():
		if body is StaticBody2D and body.is_in_group("magnetic_wall_root"):
			result.append(body)
	return result


func _closest_wall(walls: Array) -> StaticBody2D:
	var closest: StaticBody2D = null
	var closest_dist_sq: float = INF
	for w in walls:
		var d_sq: float = (w.global_position - global_position).length_squared()
		if d_sq < closest_dist_sq:
			closest = w
			closest_dist_sq = d_sq
	return closest


func _process_wall_magnetism(delta: float) -> void:
	if _wall_cooldown_timer > 0.0:
		_wall_cooldown_timer -= delta

	var walls: Array = _get_walls_in_range()
	if walls.is_empty():
		return

	var wall: StaticBody2D = _closest_wall(walls)
	var dir: Vector2 = (wall.global_position - global_position).normalized()

	# ATRAER
	if Input.is_action_just_pressed("attract") and _wall_cooldown_timer <= 0.0:
		if not is_on_floor():
			velocity = dir * wall_dash_impulse
			_wall_cooldown_timer = wall_action_cooldown
	elif Input.is_action_pressed("attract") and is_on_floor():
		velocity.x = move_toward(velocity.x, dir.x * wall_cling_pull, wall_cling_pull * delta * 4.0)

	# REPELER
	if Input.is_action_just_pressed("repel") and _wall_cooldown_timer <= 0.0:
		var away: Vector2 = -dir
		if not is_on_floor():
			velocity = away * wall_repel_impulse
			velocity.y += wall_repel_boost_y
		else:
			velocity.x = away.x * (wall_repel_impulse * 0.4)
		_wall_cooldown_timer = wall_action_cooldown

	if debug_magnetism:
		print("[WALL] %s dir=%s cooldown=%.2f" % [wall.name, dir, _wall_cooldown_timer])


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
	# El nucleo (orbe) cambia de color segun la polaridad activa.
	match current_polarity:
		Polarity.ATTRACT:
			core.modulate = Color(0.3, 0.7, 1.0, 1.0)  # Azul electrico
		Polarity.REPEL:
			core.modulate = Color(1.0, 0.3, 0.3, 1.0)  # Rojo carmesi
		_:
			core.modulate = Color(0.95, 0.85, 0.5, 1.0)  # Ambar (neutro)


func _update_sprite_anim(delta: float) -> void:
	# Animacion procedural barata: vaiven, inclinacion y squash al aterrizar.
	_anim_t += delta
	var on_floor: bool = is_on_floor()

	# Squash al tocar suelo tras estar en el aire.
	if on_floor and not _was_on_floor:
		sprite.scale = Vector2(1.18, 0.82)
	_was_on_floor = on_floor
	sprite.scale = sprite.scale.lerp(Vector2.ONE, 0.2)

	# Vaiven vertical (mas marcado al caminar, suave en reposo, nulo en el aire).
	var amp: float = 0.0
	var freq: float = 3.0
	if on_floor:
		if absf(velocity.x) > 10.0:
			amp = 1.5
			freq = 14.0
		else:
			amp = 0.8
	var bob: float = sin(_anim_t * freq) * amp
	sprite.position.y = bob
	core.position.y = 5.0 + bob

	# Inclinacion hacia la direccion de movimiento (solo en suelo).
	var lean: float = clampf(velocity.x / speed, -1.0, 1.0) * 0.08
	sprite.rotation = lerp(sprite.rotation, lean if on_floor else 0.0, 0.2)


func _draw() -> void:
	# Rayo magnetico hacia cada caja afectada (azul al atraer, rojo al repeler).
	if current_polarity == Polarity.NONE or _affected.is_empty():
		return
	var col: Color = Color(0.3, 0.7, 1.0) if current_polarity == Polarity.ATTRACT else Color(1.0, 0.3, 0.3)
	for b in _affected:
		if not is_instance_valid(b):
			continue
		var p: Vector2 = to_local(b.global_position)
		draw_line(Vector2.ZERO, p, Color(col.r, col.g, col.b, 0.22), 6.0)
		draw_line(Vector2.ZERO, p, Color(col.r, col.g, col.b, 0.9), 2.0)
		draw_circle(p, 6.0, Color(col.r, col.g, col.b, 0.45)) 
