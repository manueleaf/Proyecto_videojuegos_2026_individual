extends CanvasLayer

## Autoload "PerfOverlay": medidor de rendimiento en pantalla. Toggle con F3.
## Muestra FPS, ms por frame, tiempos de CPU/física, memoria (RAM/VRAM),
## draw calls y objetos renderizados. Sirve para capturar los datos
## técnicos que pide el profesor (slides).

var _panel: ColorRect
var _label: Label
var _shown: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 128  # Por encima de todo

	_panel = ColorRect.new()
	_panel.color = Color(0, 0, 0, 0.55)
	_panel.position = Vector2(8, 8)
	_panel.size = Vector2(308, 176)
	_panel.visible = false
	add_child(_panel)

	_label = Label.new()
	_label.position = Vector2(16, 14)
	_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.72))
	_label.add_theme_font_size_override("font_size", 14)
	_label.visible = false
	add_child(_label)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_shown = not _shown
		_panel.visible = _shown
		_label.visible = _shown


func _process(_delta: float) -> void:
	if not _shown:
		return
	var fps: int = Engine.get_frames_per_second()
	var frame_ms: float = 1000.0 / float(max(fps, 1))
	var proc_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var phys_ms: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var ram_mb: float = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var vram_mb: float = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
	var draw_calls: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var objects: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))

	_label.text = "MAGNET-O - Rendimiento (F3)\n" \
		+ "FPS: %d\n" % fps \
		+ "Frame: %.2f ms\n" % frame_ms \
		+ "CPU (proceso): %.2f ms\n" % proc_ms \
		+ "Fisica: %.2f ms\n" % phys_ms \
		+ "RAM estatica: %.1f MB\n" % ram_mb \
		+ "VRAM: %.1f MB\n" % vram_mb \
		+ "Draw calls: %d\n" % draw_calls \
		+ "Objetos en frame: %d" % objects
