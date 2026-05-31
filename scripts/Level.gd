extends Node2D

## Flujo del nivel: arranca la música y permite reiniciar (R) o
## volver al menú principal (Esc).

const MENU_PATH := "res://scenes/MainMenu.tscn"


func _ready() -> void:
	Audio.play_music()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		elif event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file(MENU_PATH)
