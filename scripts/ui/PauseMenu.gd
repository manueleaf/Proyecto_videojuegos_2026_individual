extends CanvasLayer

## Overlay del menu de pausa (Rol C - UI/UX).
## No decide *cuando* aparecer: eso lo maneja el autoload `Pause`
## (scripts/ui/PauseManager.gd). Aqui solo se muestra/oculta y avisa
## que boton se pulso mediante senales, para no acoplarse al flujo del nivel.

signal resume_requested
signal restart_requested
signal menu_requested


func _ready() -> void:
	visible = false
	$Center/Menu/Resume.pressed.connect(func() -> void: resume_requested.emit())
	$Center/Menu/Restart.pressed.connect(func() -> void: restart_requested.emit())
	$Center/Menu/ToMenu.pressed.connect(func() -> void: menu_requested.emit())


func open() -> void:
	visible = true
	$Center/Menu/Resume.grab_focus()


func close() -> void:
	visible = false
