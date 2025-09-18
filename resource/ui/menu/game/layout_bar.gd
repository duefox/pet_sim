extends GameBar
class_name LayoutBar

@onready var builds_margin: MarginContainer = %BuildsMargin
@onready var btn_layout: ButtonSmall = %BtnLayout

var builds_visible: bool = false:
	set = _setter_builds_visible


func _ready() -> void:
	super()
	btn_layout.set_pressed_no_signal(true)


## 打开布局栏
func open_layout() -> void:
	builds_visible = not builds_visible


## 设置布局栏的显示和隐藏
func _setter_builds_visible(value: bool) -> void:
	builds_visible = value
	builds_margin.visible = builds_visible
	btn_layout.button_pressed = builds_visible


## 按钮事件
func _on_btn_layout_toggled(toggled_on: bool) -> void:
	builds_visible = toggled_on
