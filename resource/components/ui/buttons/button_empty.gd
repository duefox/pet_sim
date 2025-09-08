@tool
extends ButtonCustom 
class_name ButtonEmpty

func _ready() -> void:
	add_theme_stylebox_override("disabled",StyleBoxEmpty.new())
	add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	add_theme_stylebox_override("hover",StyleBoxEmpty.new())
	add_theme_stylebox_override("pressed",StyleBoxEmpty.new())
