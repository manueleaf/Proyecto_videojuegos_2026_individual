extends Control

## Pantalla de creditos (Rol C - UI/UX). Desplaza los textos de abajo hacia
## arriba y al terminar muestra el boton "Volver". Esc regresa al menu en
## cualquier momento.

const MENU_PATH := "res://scenes/MainMenu.tscn"

@onready var _roll: VBoxContainer = $Roll
@onready var _back: Button = $Back


func _ready() -> void:
	Audio.play_music()
	_back.visible = false
	_back.pressed.connect(_to_menu)
	# Esperamos un frame para que el VBox calcule su altura real.
	await get_tree().process_frame
	var vh: float = get_viewport_rect().size.y
	_roll.position = Vector2(0, vh)
	var end_y: float = -_roll.size.y - 40.0
	var tw := create_tween()
	tw.tween_property(_roll, "position:y", end_y, 24.0)
	tw.tween_callback(func() -> void:
		_back.visible = true
		_back.grab_focus())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_to_menu()


func _to_menu() -> void:
	get_tree().change_scene_to_file(MENU_PATH)
