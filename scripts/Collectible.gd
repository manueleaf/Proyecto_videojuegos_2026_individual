extends Area2D

## Engranaje dorado: coleccionable. Al tocarlo el jugador suma al contador
## global (`Game`), suena un "ding" y desaparece con un pequeño pop.

@onready var sprite: Sprite2D = $Sprite
var _taken: bool = false


func _ready() -> void:
	add_to_group("gear")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	sprite.rotation += delta * 1.5  # gira lentamente


func _on_body_entered(body: Node) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	Game.collect_gear()
	Audio.play_sfx("gear")
	set_deferred("monitoring", false)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "scale", Vector2(1.9, 1.9), 0.18)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.18)
	tw.set_parallel(false)
	tw.tween_callback(queue_free)
