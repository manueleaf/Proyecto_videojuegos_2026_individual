extends SceneTree

## Hornea las texturas de las capas de parallax con la API Image de Godot
## (sin depender de Python). Genera capas tileables horizontalmente para
## scenes/ui/ParallaxBg.tscn:
##   far.png  -> gradiente + engranajes lejanos (opaco, base del cielo/fabrica)
##   mid.png  -> rejilla de paneles + remaches (semi-transparente)
##   near.png -> tuberias y vigas en primer plano (semi-transparente)
##
## Uso (headless):
##   Godot ... --headless --path <proyecto> --script res://tools/bake_parallax.gd

const W := 1280
const H := 720
const OUT_DIR := "res://assets/sprites/parallax"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_bake_far()
	_bake_mid()
	_bake_near()
	print("[bake_parallax] listo -> ", OUT_DIR)
	quit()


# ------------------------------------------------------------------- helpers
func _new_img() -> Image:
	return Image.create(W, H, false, Image.FORMAT_RGBA8)


func _over(im: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= W or y >= H or c.a <= 0.0:
		return
	var b: Color = im.get_pixel(x, y)
	var oa: float = c.a + b.a * (1.0 - c.a)
	if oa <= 0.0:
		im.set_pixel(x, y, Color(0, 0, 0, 0))
		return
	im.set_pixel(x, y, Color(
		(c.r * c.a + b.r * b.a * (1.0 - c.a)) / oa,
		(c.g * c.a + b.g * b.a * (1.0 - c.a)) / oa,
		(c.b * c.a + b.b * b.a * (1.0 - c.a)) / oa,
		oa))


func _rect(im: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	for y in range(maxi(0, y0), mini(H, y1 + 1)):
		for x in range(maxi(0, x0), mini(W, x1 + 1)):
			_over(im, x, y, c)


func _disc(im: Image, cx: int, cy: int, r: int, c: Color) -> void:
	var r2: int = r * r
	for y in range(maxi(0, cy - r), mini(H, cy + r + 1)):
		for x in range(maxi(0, cx - r), mini(W, cx + r + 1)):
			var dx: int = x - cx
			var dy: int = y - cy
			if dx * dx + dy * dy <= r2:
				_over(im, x, y, c)


func _ring(im: Image, cx: int, cy: int, r_out: int, r_in: int, c: Color) -> void:
	var ro2: int = r_out * r_out
	var ri2: int = r_in * r_in
	for y in range(maxi(0, cy - r_out), mini(H, cy + r_out + 1)):
		for x in range(maxi(0, cx - r_out), mini(W, cx + r_out + 1)):
			var dx: int = x - cx
			var dy: int = y - cy
			var d2: int = dx * dx + dy * dy
			if d2 <= ro2 and d2 >= ri2:
				_over(im, x, y, c)


func _soft_glow(im: Image, cx: int, cy: int, r: int, c: Color) -> void:
	var r2: float = float(r * r)
	for y in range(maxi(0, cy - r), mini(H, cy + r + 1)):
		for x in range(maxi(0, cx - r), mini(W, cx + r + 1)):
			var dx: float = x - cx
			var dy: float = y - cy
			var d2: float = dx * dx + dy * dy
			if d2 <= r2:
				var f: float = 1.0 - sqrt(d2 / r2)
				_over(im, x, y, Color(c.r, c.g, c.b, c.a * f * f))


func _save(im: Image, name: String) -> void:
	var p := "%s/%s" % [OUT_DIR, name]
	var err := im.save_png(p)
	print("  %s -> %s" % [name, "OK" if err == OK else "ERR %d" % err])


# --------------------------------------------------------------------- capas
func _bake_far() -> void:
	var im := _new_img()
	# Gradiente vertical (mismo en cada columna -> tileable horizontalmente).
	var top := Color8(18, 20, 30)
	var bot := Color8(42, 33, 28)
	for y in H:
		var t: float = float(y) / float(H - 1)
		var c := top.lerp(bot, t)
		for x in W:
			im.set_pixel(x, y, c)
	# Engranajes lejanos (inset de los bordes para que el wrap no los corte).
	var gear := Color8(30, 30, 38, 255)
	var gear_hole := Color8(22, 22, 29, 255)
	for g in [[240, 250, 120], [620, 170, 90], [980, 300, 130], [1050, 120, 70]]:
		_disc(im, g[0], g[1], g[2], gear)
		_disc(im, g[0], g[1], int(g[2] * 0.45), gear_hole)
	# Resplandores tenues (verde de salida a la derecha, ambar).
	_soft_glow(im, 1120, 420, 220, Color8(60, 230, 120, 90))
	_soft_glow(im, 300, 520, 180, Color8(255, 180, 64, 60))
	_save(im, "far.png")


func _bake_mid() -> void:
	var im := _new_img()  # base transparente
	# Rejilla de paneles (periodo 160 divide 1280 -> sin costura).
	var line := Color8(70, 64, 70, 55)
	var step := 160
	for x in range(0, W + 1, step):
		_rect(im, x, 0, x + 1, H, line)
	for y in range(0, H + 1, step):
		_rect(im, 0, y, W, y + 1, line)
	# Remaches en las intersecciones.
	var rivet := Color8(96, 88, 82, 110)
	for x in range(0, W + 1, step):
		for y in range(0, H + 1, step):
			_disc(im, x, y, 3, rivet)
	# Un par de engranajes medios semitransparentes.
	var gear := Color8(52, 47, 55, 130)
	for g in [[420, 220, 70], [860, 480, 90]]:
		_ring(im, g[0], g[1], g[2], int(g[2] * 0.55), gear)
	_save(im, "mid.png")


func _bake_near() -> void:
	var im := _new_img()  # base transparente
	var pipe := Color8(48, 44, 52, 235)
	var pipe_hi := Color8(96, 100, 110, 235)
	var pipe_sh := Color8(26, 24, 30, 235)
	# Tuberias verticales (inset de bordes).
	for px in [180, 640, 1090]:
		_rect(im, px, 0, px + 26, H, pipe)
		_rect(im, px + 3, 0, px + 8, H, pipe_hi)
		_rect(im, px + 22, 0, px + 25, H, pipe_sh)
		# bridas
		for jy in range(60, H, 260):
			_rect(im, px - 5, jy, px + 31, jy + 16, Color8(38, 35, 43, 235))
	# Viga inferior con sombra (da suelo de primer plano).
	_rect(im, 0, H - 90, W, H, Color8(20, 18, 24, 235))
	_rect(im, 0, H - 90, W, H - 84, Color8(90, 70, 30, 235))  # borde ambar
	_save(im, "near.png")
