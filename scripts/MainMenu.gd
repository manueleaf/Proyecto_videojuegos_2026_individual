extends Control

## Menú principal:
##   Jugar     -> nueva partida desde el Nivel 1 (1 -> 2 -> 3)
##   Continuar -> retoma el último nivel guardado (solo si hay progreso)
##   Debug     -> menú de pruebas de mecánicas (lo construyen Integrante 1 e Integrante 3
##                en DebugMenu.tscn; aquí sólo queda el botón cableado con guard)
##   Salir     -> cierra el juego

const DEBUG_MENU_PATH := "res://scenes/DebugMenu.tscn"


func _ready() -> void:
	$Play.pressed.connect(func() -> void: Game.new_game())
	$Continue.pressed.connect(func() -> void: Game.continue_game())
	$Debug.pressed.connect(_on_debug)
	$Quit.pressed.connect(func() -> void: get_tree().quit())

	$Continue.disabled = not Game.has_save()  # sólo activo si hay partida guardada
	$Play.grab_focus()
	Audio.play_music()


func _on_debug() -> void:
	# El contenido del menú de debug (selección de niveles de prueba de mecánicas)
	# lo crean Integrante 1 e Integrante 3 en DebugMenu.tscn.
	if ResourceLoader.exists(DEBUG_MENU_PATH):
		get_tree().change_scene_to_file(DEBUG_MENU_PATH)
	else:
		push_warning("DebugMenu.tscn aún no existe (lo crean Integrante 1 / 3).")
