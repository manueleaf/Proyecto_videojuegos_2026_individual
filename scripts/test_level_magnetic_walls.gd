extends Node2D

@onready var goal: Area2D = $Goal
@onready var win_label: Label = $WinCanvas/winlabel

func _ready() -> void:
	goal.reached.connect(_on_goal_reached)
	win_label.visible = false
	win_label.modulate = Color(1, 0, 0, 1)
	win_label.add_theme_font_size_override("font_size", 64)
	print("[TestLevel] win_label global_position: ", win_label.global_position)


func _on_goal_reached() -> void:
	print("[TestLevel] Mostrando win_label")
	win_label.visible = true
	win_label.position = Vector2(100, 100)
