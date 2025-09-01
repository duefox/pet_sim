@tool
extends Button 
class_name ButtonSmall

func _ready() -> void:
	var disabled_style=get_theme_stylebox("disabled","button_small")
	var normal_style=get_theme_stylebox("normal","button_small")
	var over_style=get_theme_stylebox("hover","button_small")
	var pressed_style=get_theme_stylebox("pressed","button_small")
	
	add_theme_stylebox_override("disabled",disabled_style)
	add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	add_theme_stylebox_override("normal",normal_style)
	add_theme_stylebox_override("hover",over_style)
	add_theme_stylebox_override("pressed",pressed_style)
	
	custom_minimum_size=Vector2(40.0,40.0)
