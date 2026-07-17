extends Node2D

## VFX de la pared/riel magnético (Rol C). Se coloca ENCIMA del rail texturizado
## del equipo y solo añade "chispa": un núcleo energizado, un aura pulsante y
## bastantes partículas de energía que oscilan entre azul y magenta (polaridad),
## para que la pared se vea mucho más llamativa. Se adapta al tamaño real del
## rail leyendo el CollisionShape2D del nodo padre (funciona horizontal o vertical).

const SPARK := preload("res://assets/sprites/fx_spark.png")

var _half: Vector2 = Vector2(100, 10)
var _glow: Sprite2D
var _core: ColorRect
var _p: CPUParticles2D
var _p2: CPUParticles2D
var _t: float = 0.0


func _ready() -> void:
	# Tamaño real del rail (para adaptarse a la geometría del equipo).
	var cs := get_parent().get_node_or_null("CollisionShape2D")
	if cs and cs.shape is RectangleShape2D:
		_half = (cs.shape as RectangleShape2D).size * 0.5

	# Aura suave detrás
	_glow = Sprite2D.new()
	_glow.texture = SPARK
	_glow.scale = Vector2((_half.x * 2.0) / 16.0 * 1.3, (_half.y * 2.0) / 16.0 * 2.6)
	_glow.modulate = Color(0.4, 0.7, 1.0, 0.4)
	_glow.material = _add()
	add_child(_glow)

	# Núcleo energizado sobre el rail
	_core = ColorRect.new()
	_core.size = _half * 2.0
	_core.position = -_half
	_core.color = Color(0.6, 0.9, 1.0, 0.5)
	_core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_core.material = _add()
	add_child(_core)

	# Muchas partículas de energía
	_p = _make_particles(34, 8.0, 44.0, 1.0)
	add_child(_p)
	# Chispas grandes ocasionales
	_p2 = _make_particles(12, 22.0, 72.0, 1.3)
	_p2.scale_amount_min = 0.9
	_p2.scale_amount_max = 2.1
	add_child(_p2)


func _add() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m


func _make_particles(amount: int, vmin: float, vmax: float, life: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = SPARK
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = _half * 0.9
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = vmin
	p.initial_velocity_max = vmax
	p.scale_amount_min = 0.4
	p.scale_amount_max = 1.2
	p.color = Color(0.55, 0.8, 1.0, 0.9)
	p.material = _add()
	return p


func _process(delta: float) -> void:
	_t += delta
	var pulse := 0.5 + 0.5 * sin(_t * 4.0)
	var pol := 0.5 + 0.5 * sin(_t * 1.5)                       # oscila la polaridad
	var c := Color(0.45, 0.75, 1.0).lerp(Color(1.0, 0.4, 0.7), pol)
	_glow.modulate = Color(c.r, c.g, c.b, 0.28 + 0.25 * pulse)
	_core.color = Color(c.r, c.g, c.b, 0.32 + 0.3 * pulse)
	_p.color = Color(c.r, c.g, c.b, 0.9)
	_p2.color = Color(c.r, c.g, c.b, 0.8)
