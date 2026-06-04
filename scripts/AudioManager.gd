extends Node

## Autoload "Audio": gestiona efectos de sonido y música de fondo.
## Carga los WAV generados, mantiene un pool de reproductores para SFX,
## un canal dedicado para la música y otro para el zumbido del imán.

const PATHS := {
	"jump": "res://assets/audio/jump.wav",
	"magnet": "res://assets/audio/magnet.wav",
	"music": "res://assets/audio/music.wav",
	"gear": "res://assets/audio/gear.wav",
	"hurt": "res://assets/audio/hurt.wav",
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
	_music.volume_db = -10.0
	add_child(_music)

	_magnet = AudioStreamPlayer.new()
	_magnet.volume_db = -12.0
	add_child(_magnet)

	for key in PATHS:
		_streams[key] = load(PATHS[key])
	_make_loop(_streams.get("magnet"))
	_make_loop(_streams.get("music"))


func _make_loop(stream) -> void:
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
	for p in _sfx_pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.play()
			return
	# Todos ocupados: reusa el primero.
	_sfx_pool[0].stream = stream
	_sfx_pool[0].volume_db = volume_db
	_sfx_pool[0].play()


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
