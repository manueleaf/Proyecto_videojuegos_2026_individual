extends Node

## Autoload "Vfx" (Rol C): efectos de muerte del jugador segun la causa.
##   - "enemy" -> el robot explota y se desarma en piezas de metal.
##   - "acid"  -> el personaje se derrite en un charco verde.
##   - otro    -> pequeño estallido de chispas.
## Se dispara desde Player.respawn(cause) EN el sitio de la muerte, antes de
## reposicionar al jugador. Los efectos se auto-eliminan solos.

const SPARK := preload("res://assets/sprites/fx_spark.png")
const CHUNK := preload("res://assets/sprites/fx_chunk.png")
const DROP := preload("res://assets/sprites/fx_drop.png")
const SHEET := preload("res://assets/sprites/player_sheet.png")


func play_death(cause: String, pos: Vector2) -> void:
	match cause:
		"enemy":
			explode_robot(pos)
		"acid":
			melt_player(pos)
		_:
			spark_burst(pos)


# ------------------------------------------------------------------- utilidades
func _spawn(node: Node2D, pos: Vector2) -> Node2D:
	var scene := get_tree().current_scene
	if scene == null:
		node.queue_free()
		return node
	scene.add_child(node)
	node.global_position = pos
	return node


func _additive() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m


func _particles(tex: Texture2D, amount: int, col: Color, vmin: float, vmax: float,
		grav: float, life: float, scl: float, additive: bool) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = tex
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = life
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, grav)
	p.initial_velocity_min = vmin
	p.initial_velocity_max = vmax
	p.scale_amount_min = scl * 0.6
	p.scale_amount_max = scl
	p.angular_velocity_min = -400.0
	p.angular_velocity_max = 400.0
	p.damping_min = 20.0
	p.damping_max = 70.0
	p.color = col
	if additive:
		p.material = _additive()
	return p


func _free_later(node: Node, secs: float) -> void:
	get_tree().create_timer(secs).timeout.connect(func() -> void:
		if is_instance_valid(node):
			node.queue_free())


# ----------------------------------------------------------- efectos concretos
func explode_robot(pos: Vector2) -> void:
	var root := _spawn(Node2D.new(), pos)

	# Destello inicial
	var flash := Sprite2D.new()
	flash.texture = SPARK
	flash.modulate = Color(1.0, 0.72, 0.32, 0.9)
	flash.scale = Vector2(6, 6)
	flash.material = _additive()
	root.add_child(flash)
	var tw := root.create_tween()
	tw.tween_property(flash, "scale", Vector2(12, 12), 0.25)
	tw.parallel().tween_property(flash, "modulate:a", 0.0, 0.25)

	# Chispas
	root.add_child(_particles(SPARK, 22, Color(1.0, 0.8, 0.4), 90.0, 250.0, 40.0, 0.5, 3.0, true))
	# Piezas de metal (se desarma)
	root.add_child(_particles(CHUNK, 16, Color(0.82, 0.86, 0.92), 130.0, 320.0, 640.0, 0.95, 2.0, false))
	# Humo tenue
	root.add_child(_particles(SPARK, 8, Color(0.2, 0.2, 0.24, 0.5), 20.0, 70.0, -30.0, 0.9, 5.0, false))

	_free_later(root, 1.4)


func melt_player(pos: Vector2) -> void:
	var root := _spawn(Node2D.new(), pos)

	# Silueta del jugador que se derrite (usa el 1er frame del spritesheet)
	var sil := Sprite2D.new()
	var at := AtlasTexture.new()
	at.atlas = SHEET
	at.region = Rect2(0, 0, 32, 48)
	sil.texture = at
	sil.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(sil)
	var tw := root.create_tween()
	tw.tween_property(sil, "modulate", Color(0.5, 1.0, 0.45, 1.0), 0.15)   # se tiñe verde
	tw.tween_property(sil, "scale", Vector2(1.2, 0.1), 0.6)                # se aplasta
	tw.parallel().tween_property(sil, "position:y", 22.0, 0.6)            # escurre
	tw.parallel().tween_property(sil, "modulate:a", 0.0, 0.55)

	# Gotas verdes que salpican
	root.add_child(_particles(DROP, 16, Color(0.42, 0.95, 0.42), 40.0, 130.0, 420.0, 0.7, 1.6, false))
	# Vapor / burbujeo verde
	root.add_child(_particles(SPARK, 12, Color(0.6, 1.0, 0.6, 0.8), 20.0, 70.0, -60.0, 0.9, 2.2, true))

	_free_later(root, 1.3)


func spark_burst(pos: Vector2) -> void:
	var root := _spawn(Node2D.new(), pos)
	root.add_child(_particles(SPARK, 16, Color(1.0, 0.9, 0.5), 60.0, 190.0, 220.0, 0.5, 2.2, true))
	_free_later(root, 0.9)


# ------------------------------------------------ efectos de enemigos/proyectiles
## Fogonazo de la torreta al disparar (en la boca del cañón, hacia `dir`).
func muzzle_flash(pos: Vector2, dir: Vector2) -> void:
	var root := _spawn(Node2D.new(), pos)
	if root.get_parent() == null:
		return
	root.rotation = dir.angle()
	var flash := Sprite2D.new()
	flash.texture = SPARK
	flash.modulate = Color(1.0, 0.85, 0.4, 0.95)
	flash.scale = Vector2(3.5, 3.5)
	flash.material = _additive()
	root.add_child(flash)
	var tw := root.create_tween()
	tw.tween_property(flash, "scale", Vector2(5.5, 2.4), 0.12)
	tw.parallel().tween_property(flash, "modulate:a", 0.0, 0.12)
	var p := _particles(SPARK, 8, Color(1.0, 0.8, 0.4), 120.0, 260.0, 0.0, 0.25, 1.6, true)
	p.direction = Vector2(1, 0)
	p.spread = 22.0
	root.add_child(p)
	_free_later(root, 0.4)


## Explosión al destruir un enemigo (dron / torreta): chispas + metralla + humo.
func explode_enemy(pos: Vector2) -> void:
	Audio.play_sfx("enemy_death")
	var root := _spawn(Node2D.new(), pos)
	if root.get_parent() == null:
		return
	var flash := Sprite2D.new()
	flash.texture = SPARK
	flash.modulate = Color(1.0, 0.6, 0.3, 0.9)
	flash.scale = Vector2(5, 5)
	flash.material = _additive()
	root.add_child(flash)
	var tw := root.create_tween()
	tw.tween_property(flash, "scale", Vector2(10, 10), 0.22)
	tw.parallel().tween_property(flash, "modulate:a", 0.0, 0.22)
	root.add_child(_particles(SPARK, 20, Color(1.0, 0.75, 0.35), 90.0, 240.0, 30.0, 0.5, 3.0, true))
	root.add_child(_particles(CHUNK, 14, Color(0.82, 0.86, 0.92), 120.0, 300.0, 620.0, 0.9, 2.0, false))
	root.add_child(_particles(SPARK, 8, Color(0.2, 0.2, 0.24, 0.5), 20.0, 70.0, -30.0, 0.9, 5.0, false))
	Fx.shake(7.0)
	_free_later(root, 1.3)


## Impacto pequeño del proyectil de la torreta al chocar.
func bolt_impact(pos: Vector2) -> void:
	var root := _spawn(Node2D.new(), pos)
	if root.get_parent() == null:
		return
	root.add_child(_particles(SPARK, 8, Color(1.0, 0.7, 0.35), 50.0, 150.0, 120.0, 0.35, 1.6, true))
	_free_later(root, 0.5)
