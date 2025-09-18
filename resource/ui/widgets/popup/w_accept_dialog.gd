extends Control
class_name WAcceptDialog

@onready var tips_label: Label = %TipsLabel

## 信号
signal pressed_callback(success: bool)


func _ready() -> void:
	tips_label.text = ""


func prompt(text: String) -> void:
	tips_label.text = text


func _on_btn_ok_pressed() -> void:
	pressed_callback.emit(true)
	_exit_node()


func _on_btn_cancel_pressed() -> void:
	pressed_callback.emit(false)
	_exit_node()


func _exit_node() -> void:
	get_parent().queue_free()
	queue_free()
