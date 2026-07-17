extends Node

## Autoload "Audio": gestiona efectos de sonido y música de fondo.
## Carga los WAV generados, mantiene un pool de reproductores para SFX,
## un canal dedicado para la música y otro para el zumbido del imán.

const PATHS := {
	"jump": "res://assets/audio/saltos.mp3",
	"magnet": "res://assets/audio/magnet.wav",
	"music": "res://assets/audio/fondo_musical.mp3",
	"gear": "res://assets/audio/gear.wav",
	"hurt": "res://assets/audio/hurt.wav",
	"enemy_death": "res://assets/audio/destruccion_enemigos.wav",
}

## Recorte de SFX largos: algunos clips (p. ej. saltos.mp3 dura ~4.8s) traen cola
## o silencio y "arrastran". Los cortamos a un golpe breve ligado a la acción.
const MAX_SEC := {
	"jump": 0.5,
}

var _sfx_pool: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _magnet: AudioStreamPlayer
var _streams := {}


func _ready() -> void:
	# Sigue sonando aunque el árbol esté en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i in range(6):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)

	_music = AudioStreamPlayer.new()
	_music.volume_db = -16.0   # música de fondo más baja para no tapar los SFX
	add_child(_music)

	_magnet = AudioStreamPlayer.new()
	_magnet.volume_db = -4.0   # zumbido del imán más presente (antes quedaba tapado)
	add_child(_magnet)

	for key in PATHS:
		_streams[key] = load(PATHS[key])
	_make_loop(_streams.get("magnet"))
	_make_loop(_streams.get("music"))


func _make_loop(stream) -> void:
	if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.loop = true
		return
	if stream is AudioStreamWAV:
		var w: AudioStreamWAV = stream
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		var frame_bytes: int = 2 if w.format == AudioStreamWAV.FORMAT_16_BITS else 1
		if w.stereo:
			frame_bytes *= 2
		w.loop_end = int(w.data.size() / frame_bytes)


func play_sfx(sfx_name: String, volume_db: float = 0.0) -> void:
	var stream = _streams.get(sfx_name)
	if stream == null:
		return
	# Elige un reproductor libre (o reusa el primero si todos están ocupados).
	var player: AudioStreamPlayer = null
	for p in _sfx_pool:
		if not p.playing:
			player = p
			break
	if player == null:
		player = _sfx_pool[0]
	player.stream = stream
	player.volume_db = volume_db
	player.play()
	# Recorta clips largos (p. ej. el salto) para que suenen breves y a tiempo.
	var cap: float = MAX_SEC.get(sfx_name, 0.0)
	if cap > 0.0:
		_stop_after(player, stream, cap)


func _stop_after(player: AudioStreamPlayer, stream: AudioStream, secs: float) -> void:
	await get_tree().create_timer(secs).timeout
	if is_instance_valid(player) and player.playing and player.stream == stream:
		player.stop()


func play_music() -> void:
	var stream = _streams.get("music")
	if stream == null:
		return
	if _music.stream == stream and _music.playing:
		return
	_music.stream = stream
	_music.play()


func stop_music() -> void:
	_music.stop()


func set_magnet_active(active: bool) -> void:
	var stream = _streams.get("magnet")
	if stream == null:
		return
	if active and not _magnet.playing:
		_magnet.stream = stream
		_magnet.play()
	elif not active and _magnet.playing:
		_magnet.stop()
