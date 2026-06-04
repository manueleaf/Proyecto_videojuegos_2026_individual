extends Node2D

## Flujo del nivel: música, contador de engranajes, feedback de derrota
## (flash + "¡REINICIANDO!") y pantalla de victoria. Reiniciar (R) / menú (Esc).

const MENU_PATH := "res://scenes/MainMenu.tscn"

@onready var _gear_label: Label = $HUD/GearLabel
@onready var _defeat: ColorRect = $HUD/DefeatFlash
@onready var _victory: Label = $HUD/Victory
@onready var _victory_sub: Label = $HUD/VictorySub


func _ready() -> void:
	Audio.play_music()

	var total: int = get_tree().get_nodes_in_group("gear").size()
	Game.reset_level(total)
	Game.gears_changed.connect(_on_gears_changed)
	Game.player_died.connect(_on_player_died)
	Game.level_won.connect(_on_level_won)

	_on_gears_changed(0, total)
	_defeat.visible = false
	_victory.visible = false
	_victory_sub.visible = false


func _on_gears_changed(collected: int, total: int) -> void:
	_gear_label.text = "Engranajes: %d / %d" % [collected, total]


func _on_player_died() -> void:
	_defeat.modulate = Color(1, 1, 1, 1)
	_defeat.visible = true
	var tw := create_tween()
	tw.tween_property(_defeat, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void: _defeat.visible = false)


func _on_level_won() -> void:
	_victory.visible = true
	_victory_sub.visible = true
	_victory_sub.text = "Engranajes: %d / %d        R: reiniciar        Esc: menu" % [Game.gears_collected, Game.gears_total]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		elif event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file(MENU_PATH)
