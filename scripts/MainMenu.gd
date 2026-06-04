extends Control

## Menú principal: botones Jugar / Salir y arranque de la música.

const LEVEL_PATH := "res://scenes/Level1.tscn"


func _ready() -> void:
	$Play.pressed.connect(_on_play)
	$Quit.pressed.connect(_on_quit)
	$Play.grab_focus()
	Audio.play_music()


func _on_play() -> void:
	get_tree().change_scene_to_file(LEVEL_PATH)


func _on_quit() -> void:
	get_tree().quit()
