extends Node

## Autoload "Game": estado de la partida (engranajes, muertes) y señales
## globales para que el HUD reaccione sin acoplarse a cada objeto.

signal gears_changed(collected: int, total: int)
signal player_died()
signal level_won()

var gears_collected: int = 0
var gears_total: int = 0
var deaths: int = 0


func reset_level(total: int) -> void:
	gears_collected = 0
	gears_total = total
	deaths = 0
	gears_changed.emit(gears_collected, gears_total)


func collect_gear() -> void:
	gears_collected += 1
	gears_changed.emit(gears_collected, gears_total)


func notify_death() -> void:
	deaths += 1
	player_died.emit()


func notify_win() -> void:
	level_won.emit()
