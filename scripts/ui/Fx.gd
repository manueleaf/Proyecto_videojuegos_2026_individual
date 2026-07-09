extends Node

## Autoload "Fx" (Rol C - UI/UX): capa global de "juice".
##   - Screen shake sobre la camara 2D activa (via offset, sin tocar Player.gd).
##   - Hit-stop (micro pausa con Engine.time_scale) para dar peso a golpes.
##   - Transiciones fade: auto fade-in al entrar a cada escena, y `to_scene()`
##     opcional para fundir a negro antes de cambiar de escena.
##   - Flash de pantalla puntual (p. ej. dorado al ganar).
##
## Se engancha a las senales del autoload `Game` (player_died / level_won), asi
## que anade sensacion SIN modificar los niveles ni los scripts de gameplay.
## El flash rojo de derrota lo sigue haciendo Level.gd; aqui solo sumamos
## shake + hit-stop para no duplicar feedback.

var _shake: float = 0.0
var _shake_decay: float = 9.0
var _shaking: bool = false

var _fade: ColorRect
var _flash: ColorRect
var _last_scene: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	Game.player_died.connect(_on_player_died)
	Game.level_won.connect(_on_level_won)
	_fade_in()  # primer arranque


func _build_overlay() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 90  # debajo del menu de pausa (100), encima del juego
	add_child(cl)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(_fade)

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(_flash)


func _process(delta: float) -> void:
	# Auto fade-in cada vez que cambia la escena actual (transicion sin coordinar).
	var cur: Node = get_tree().current_scene
	if cur != _last_scene:
		_last_scene = cur
		_fade_in()

	# Screen shake: empuja el offset de la camara activa y decae a cero.
	if _shake > 0.05:
		_shaking = true
		var cam := get_viewport().get_camera_2d()
		if cam:
			cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
		_shake = lerpf(_shake, 0.0, clampf(_shake_decay * delta, 0.0, 1.0))
	elif _shaking:
		_shaking = false
		_shake = 0.0
		var cam := get_viewport().get_camera_2d()
		if cam:
			cam.offset = Vector2.ZERO


# ------------------------------------------------------------------ API publica
func shake(amount: float = 8.0) -> void:
	_shake = maxf(_shake, amount)


func hit_stop(scale: float = 0.05, duration: float = 0.08) -> void:
	Engine.time_scale = scale
	# Timer que ignora time_scale para restaurar aunque el juego este "congelado".
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


func flash(color: Color = Color(1, 1, 1, 0.5), duration: float = 0.25) -> void:
	_flash.color = Color(color.r, color.g, color.b, color.a)
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, duration)


## Cambia de escena con fundido a negro (opcional; los llamadores pueden usarlo
## en vez de get_tree().change_scene_to_file para transiciones suaves).
func to_scene(path: String, duration: float = 0.3) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, duration)
	await tw.finished
	get_tree().change_scene_to_file(path)  # _process hara el fade-in


# ------------------------------------------------------------------- reacciones
func _fade_in(duration: float = 0.35) -> void:
	_fade.color.a = 1.0
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, duration)


func _on_player_died() -> void:
	shake(11.0)
	hit_stop(0.02, 0.10)


func _on_level_won() -> void:
	hit_stop(0.12, 0.12)
	flash(Color(1.0, 0.82, 0.4, 0.35), 0.5)
