extends Node2D

## Visual del pozo de ácido (Rol C): líquido verde con superficie ondulante,
## burbujas que suben y un resplandor tenue. Construye todo por código para que
## AcidPool.tscn quede simple; se escala junto con el nodo si el nivel lo estira.

const SPARK := preload("res://assets/sprites/fx_spark.png")

const HALF := 45.0   # medio ancho (coincide con la forma de colisión 90x16)
const TOP := -8.0
const BOT := 8.0

var _surface: Polygon2D
var _glow: Sprite2D
var _t: float = 0.0


func _ready() -> void:
	# Resplandor (aditivo, detrás)
	_glow = Sprite2D.new()
	_glow.texture = SPARK
	_glow.scale = Vector2(HALF * 0.32, 3.6)
	_glow.position = Vector2(0, -3)
	_glow.modulate = Color(0.3, 1.0, 0.42, 0.35)
	var gm := CanvasItemMaterial.new()
	gm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = gm
	add_child(_glow)

	# Cuerpo del líquido
	var body := Polygon2D.new()
	body.color = Color(0.13, 0.72, 0.28, 0.82)
	body.polygon = PackedVector2Array([
		Vector2(-HALF, TOP), Vector2(HALF, TOP), Vector2(HALF, BOT), Vector2(-HALF, BOT)])
	add_child(body)

	# Superficie brillante ondulante (se actualiza en _process)
	_surface = Polygon2D.new()
	_surface.color = Color(0.62, 1.0, 0.66, 0.95)
	add_child(_surface)

	# Burbujas que suben
	var b := CPUParticles2D.new()
	b.texture = SPARK
	b.amount = 14
	b.lifetime = 1.5
	b.preprocess = 1.2
	b.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	b.emission_rect_extents = Vector2(HALF - 4, 5)
	b.direction = Vector2(0, -1)
	b.spread = 12.0
	b.gravity = Vector2(0, -16)
	b.initial_velocity_min = 8.0
	b.initial_velocity_max = 26.0
	b.scale_amount_min = 0.4
	b.scale_amount_max = 1.3
	b.color = Color(0.6, 1.0, 0.6, 0.7)
	var bm := CanvasItemMaterial.new()
	bm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	b.material = bm
	b.position = Vector2(0, 4)
	add_child(b)


func _process(delta: float) -> void:
	_t += delta
	var n := 14
	var pts := PackedVector2Array()
	for i in n + 1:
		var x := -HALF + (2.0 * HALF) * float(i) / n
		var y := TOP + sin(_t * 3.0 + x * 0.14) * 1.8 + sin(_t * 1.7 - x * 0.06) * 0.8
		pts.append(Vector2(x, y))
	pts.append(Vector2(HALF, TOP + 3.5))
	pts.append(Vector2(-HALF, TOP + 3.5))
	_surface.polygon = pts
	_glow.modulate.a = 0.28 + 0.14 * sin(_t * 2.5)
