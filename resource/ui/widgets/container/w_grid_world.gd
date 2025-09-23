extends WGrid
class_name WorldGrid

@onready var color_rect: ColorRect = $ColorRect


func _ready() -> void:
	super()
	if is_zero_approx(fmod(cell_pos.x + cell_pos.y, 2.0)):
		color_rect.visible = false
	else:
		color_rect.visible = true
