extends PathFollow2D

@onready var sprite_2d: Sprite2D = $Sprite2D


func _process(delta: float) -> void:
	progress_ratio += delta
	sprite_2d.self_modulate = Color(1.0, 1.0, 1.0, 1.0 - progress_ratio)
