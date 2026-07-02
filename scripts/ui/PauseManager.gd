extends Node

## Autoload "Pause" (Rol C - UI/UX).
## Maneja la pausa global con Esc de forma NO destructiva: instancia el overlay
## PauseMenu.tscn y escucha Esc en `_input`, consumiendo el evento para que la
## logica del nivel (Level.gd, que lee Esc en `_unhandled_input`) no dispare
## tambien su "Esc -> menu". La unica excepcion es cuando el nivel ya se gano:
## ahi dejamos pasar Esc para conservar el comportamiento de victoria (-> menu).

const PAUSE_MENU := preload("res://scenes/ui/PauseMenu.tscn")
const MENU_PATH := "res://scenes/MainMenu.tscn"

var _menu: CanvasLayer
var _can_pause: bool = true
var _last_scene: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_menu = PAUSE_MENU.instantiate()
	add_child(_menu)
	_menu.resume_requested.connect(_resume)
	_menu.restart_requested.connect(_restart)
	_menu.menu_requested.connect(_to_menu)
	# Al ganar, el nivel toma control de Esc (victoria -> menu): desactivamos la pausa.
	Game.level_won.connect(func() -> void: _can_pause = false)


func _process(_delta: float) -> void:
	# Al entrar a una escena nueva reseteamos el estado (y salimos de pausa por si acaso).
	var cur: Node = get_tree().current_scene
	if cur != _last_scene:
		_last_scene = cur
		_can_pause = true
		if get_tree().paused:
			_resume()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not _pausable():
			return  # dejamos que el nivel maneje Esc (p. ej. victoria -> menu)
		_toggle()
		get_viewport().set_input_as_handled()


func _pausable() -> bool:
	var cur: Node = get_tree().current_scene
	if cur == null:
		return false
	if cur.name == "MainMenu":
		return false          # en el menu Esc no pausa
	if get_tree().paused:
		return true           # si ya esta pausado, permitir reanudar con Esc
	return _can_pause


func _toggle() -> void:
	if get_tree().paused:
		_resume()
	else:
		get_tree().paused = true
		_menu.open()


func _resume() -> void:
	get_tree().paused = false
	_menu.close()


func _restart() -> void:
	get_tree().paused = false
	_menu.close()
	get_tree().reload_current_scene()


func _to_menu() -> void:
	get_tree().paused = false
	_menu.close()
	get_tree().change_scene_to_file(MENU_PATH)
