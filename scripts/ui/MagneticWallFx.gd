extends Node2D

## Visual de la pared/riel magnético (Rol C): cuerpo metálico con bisel, bandas
## de polaridad (azul/rojo) que laten, un aura de campo a los lados y partículas
## de energía. Todo por código para no ensuciar la escena; el nodo raíz de la
## pared conserva su lógica intacta.

const SPARK := preload("res://assets/sprites/fx_spark.png")

const HALF_W := 10.0   # medio ancho del rail (colisión 20 de ancho)
const HALF_H := 100.0  # media altura (colisión 200 de alto)

var _bands: Array[ColorRect] = []
var _glow_l: Sprite2D
var _glow_r: Sprite2D
var _t: float = 0.0


func _ready() -> void:
	# Cuerpo metálico
	var body := Polygon2D.new()
	body.color = Color(0.16, 0.18, 0.22, 1.0)
	body.polygon = PackedVector2Array([
		Vector2(-HALF_W, -HALF_H), Vector2(HALF_W, -HALF_H),
		Vector2(HALF_W, HALF_H), Vector2(-HALF_W, HALF_H)])
	add_child(body)

	# Bisel: brillo izquierda, sombra derecha
	var hi := Polygon2D.new()
	hi.color = Color(0.36, 0.41, 0.49, 1.0)
	hi.polygon = PackedVector2Array([
		Vector2(-HALF_W, -HALF_H), Vector2(-HALF_W + 3, -HALF_H),
		Vector2(-HALF_W + 3, HALF_H), Vector2(-HALF_W, HALF_H)])
	add_child(hi)
	var sh := Polygon2D.new()
	sh.color = Color(0.09, 0.1, 0.13, 1.0)
	sh.polygon = PackedVector2Array([
		Vector2(HALF_W - 3, -HALF_H), Vector2(HALF_W, -HALF_H),
		Vector2(HALF_W, HALF_H), Vector2(HALF_W - 3, HALF_H)])
	add_child(sh)

	# Auras de campo a los lados (aditivas, laten en contrafase)
	_glow_l = _make_glow(Vector2(-15, 0))
	_glow_r = _make_glow(Vector2(15, 0))

	# Bandas de bobina con polaridad alternada (azul/rojo)
	var n := 5
	for i in n:
		var band := ColorRect.new()
		band.size = Vector2(HALF_W * 2 + 6, 9)
		var y := -HALF_H + 14 + i * (2.0 * HALF_H - 28) / (n - 1)
		band.position = Vector2(-HALF_W - 3, y - 4.5)
		band.color = Color(0.3, 0.6, 1.0) if i % 2 == 0 else Color(1.0, 0.35, 0.42)
		var bm := CanvasItemMaterial.new()
		bm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		band.material = bm
		add_child(band)
		_bands.append(band)

	# Partículas de energía que se desprenden del rail
	var p := CPUParticles2D.new()
	p.texture = SPARK
	p.amount = 18
	p.lifetime = 1.2
	p.preprocess = 1.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(3, HALF_H - 8)
	p.direction = Vector2(1, 0)
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 28.0
	p.scale_amount_min = 0.4
	p.scale_amount_max = 1.1
	p.color = Color(0.55, 0.8, 1.0, 0.7)
	var pm := CanvasItemMaterial.new()
	pm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = pm
	add_child(p)


func _make_glow(pos: Vector2) -> Sprite2D:
	var g := Sprite2D.new()
	g.texture = SPARK
	g.scale = Vector2(3.2, 12.0)
	g.position = pos
	g.modulate = Color(0.42, 0.7, 1.0, 0.35)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	g.material = m
	add_child(g)
	return g


func _process(delta: float) -> void:
	_t += delta
	var pulse := 0.5 + 0.5 * sin(_t * 3.0)
	_glow_l.modulate.a = 0.18 + 0.28 * pulse
	_glow_r.modulate.a = 0.18 + 0.28 * (1.0 - pulse)
	for i in _bands.size():
		_bands[i].modulate.a = 0.55 + 0.45 * sin(_t * 4.0 + i * 0.8)
