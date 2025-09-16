@tool
extends ButtonCustom
class_name ButtonSmall

var disabled_style = get_theme_stylebox("disabled", "button_small")
var over_style = get_theme_stylebox("hover", "button_small")
var pressed_style = get_theme_stylebox("pressed", "button_small")


func _ready() -> void:
	add_theme_stylebox_override("disabled", disabled_style)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	set_row(0)
	add_theme_stylebox_override("hover", over_style)
	add_theme_stylebox_override("pressed", pressed_style)

	#custom_minimum_size=Vector2(40.0,40.0)


## 设置按下状态贴图
func set_button_state(is_pressed: bool) -> void:
	if is_pressed:
		add_theme_stylebox_override("normal", pressed_style)
	else:
		set_row(0)


## 设置单双行
func set_row(index: int) -> void:
	var normal_style: StyleBox
	if index % 2 == 0:
		normal_style = get_theme_stylebox("double", "button_small")
	else:
		normal_style = get_theme_stylebox("normal", "button_small")

	add_theme_stylebox_override("normal", normal_style)
