extends CanvasLayer

## Autoload "PerfOverlay": información técnica EN EJECUCIÓN.
##
## - Lectura mini SIEMPRE visible (arriba a la derecha): FPS, ms/frame, RAM.
## - Panel completo que se muestra/oculta con la tecla grave (`) o F3.
##   (En macOS F3 lo intercepta Mission Control, por eso el acento grave es la
##    tecla principal.)
##
## Datos vía la API `Performance` de Godot: FPS, ms por frame, CPU/física,
## RAM estática, VRAM, draw calls y objetos en frame.

var _mini: Label
var _panel: ColorRect
var _label: Label
var _shown: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 128  # Por encima de todo

	# --- Lectura mini siempre visible (esquina superior derecha) ---
	_mini = Label.new()
	_mini.anchor_left = 1.0
	_mini.anchor_right = 1.0
	_mini.offset_left = -250.0
	_mini.offset_top = 6.0
	_mini.offset_right = -10.0
	_mini.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_mini.add_theme_color_override("font_color", Color(0.6, 1.0, 0.72))
	_mini.add_theme_font_size_override("font_size", 14)
	add_child(_mini)

	# --- Panel completo (oculto hasta activar) ---
	_panel = ColorRect.new()
	_panel.color = Color(0, 0, 0, 0.6)
	_panel.position = Vector2(8, 8)
	_panel.size = Vector2(312, 196)
	_panel.visible = false
	add_child(_panel)

	_label = Label.new()
	_label.position = Vector2(16, 14)
	_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.72))
	_label.add_theme_font_size_override("font_size", 14)
	_label.visible = false
	add_child(_label)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_QUOTELEFT or event.keycode == KEY_F3:
			_shown = not _shown
			_panel.visible = _shown
			_label.visible = _shown


func _process(_delta: float) -> void:
	var fps: int = Engine.get_frames_per_second()
	var frame_ms: float = 1000.0 / float(max(fps, 1))
	var ram_mb: float = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0

	# Mini lectura (siempre)
	_mini.text = "FPS %d   %.1f ms   RAM %d MB   [ ` ]" % [fps, frame_ms, int(ram_mb)]

	if not _shown:
		return

	# Panel completo
	var proc_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var phys_ms: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var vram_mb: float = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
	var draw_calls: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var objects: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))

	_label.text = "MAGNET-O - Rendimiento  ( ` / F3 )\n" \
		+ "FPS: %d\n" % fps \
		+ "Frame: %.2f ms\n" % frame_ms \
		+ "CPU (proceso): %.2f ms\n" % proc_ms \
		+ "Fisica: %.2f ms\n" % phys_ms \
		+ "RAM estatica: %.1f MB\n" % ram_mb \
		+ "VRAM: %.1f MB\n" % vram_mb \
		+ "Draw calls: %d\n" % draw_calls \
		+ "Objetos en frame: %d" % objects
