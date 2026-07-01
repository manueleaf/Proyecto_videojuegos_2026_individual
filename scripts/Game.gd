extends Node

## Autoload "Game": estado de la partida (engranajes, muertes), progresión de
## niveles y guardado. Señales globales para que el HUD reaccione sin acoplarse.

signal gears_changed(collected: int, total: int)
signal player_died()
signal level_won()

# --- Progresión y guardado ---
const SAVE_PATH := "user://magneto_save.cfg"
const LEVELS := [
	"res://scenes/Level1.tscn",
	"res://scenes/Level2.tscn",
	"res://scenes/Level3.tscn",
]
const MENU_PATH := "res://scenes/MainMenu.tscn"

var current_level: int = 0
var gears_collected: int = 0
var gears_total: int = 0
var deaths: int = 0


func _ready() -> void:
	_load()


# ---------------------------------------------------------------- guardado
func _load() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) == OK:
		current_level = int(cf.get_value("progress", "level", 0))


func _save() -> void:
	var cf := ConfigFile.new()
	cf.set_value("progress", "level", current_level)
	cf.save(SAVE_PATH)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


# ---------------------------------------------------------- flujo de niveles
func new_game() -> void:
	current_level = 0
	_save()
	get_tree().change_scene_to_file(LEVELS[0])


func continue_game() -> void:
	_load()
	var i: int = clampi(current_level, 0, LEVELS.size() - 1)
	get_tree().change_scene_to_file(LEVELS[i])


func set_current_level(index: int) -> void:
	# Lo llama cada nivel al cargar, para que "Continuar" recuerde dónde estabas.
	current_level = clampi(index, 0, LEVELS.size() - 1)
	_save()


func advance_level() -> void:
	var nxt: int = current_level + 1
	if nxt < LEVELS.size():
		current_level = nxt
		_save()
		get_tree().change_scene_to_file(LEVELS[nxt])
	else:
		get_tree().change_scene_to_file(MENU_PATH)  # juego completado


func is_last_level() -> bool:
	return current_level >= LEVELS.size() - 1


# ---------------------------------------------------------- estado por nivel
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
