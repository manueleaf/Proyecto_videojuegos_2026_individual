extends StaticBody2D

## Pared magnética con la que el jugador interactúa vía J (atraer) / K (repeler).
## No necesita lógica propia: el Player detecta este nodo por su MagnetZone
## (grupo "magnetic_wall_root") y aplica el impulso. Este script solo existe
## para exponer el punto de anclaje y, opcionalmente, feedback visual.

@export var debug_wall: bool = false

func get_anchor_position() -> Vector2:
	# Punto hacia el que se calcula la dirección del impulso.
	return global_position

func _ready() -> void:
	add_to_group("magnetic_wall_root")
