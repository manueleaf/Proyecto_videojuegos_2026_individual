extends ParallaxBackground

## Fondo con parallax reutilizable (Rol C - UI/UX).
## En un nivel con Camera2D activa, ParallaxBackground usa el scroll de la camara
## automaticamente. Donde NO hay camara (menu principal, creditos), derivamos el
## scroll nosotros para que las capas se muevan solas y el fondo tenga vida.

@export var auto_drift: float = 16.0  # px/seg cuando no hay camara


func _process(delta: float) -> void:
	if get_viewport().get_camera_2d() == null:
		scroll_offset.x += auto_drift * delta
