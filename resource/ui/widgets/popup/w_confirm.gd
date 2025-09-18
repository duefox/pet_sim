extends CanvasLayer
class_name WConfirm

const DIALOG_SCENE: PackedScene = preload("res://resource/ui/widgets/popup/w_accept_dialog.tscn")

var _dialog: WAcceptDialog


func _ready() -> void:
	self.layer = 999

func prompt(text: String) -> bool:
	# 弹出层场景
	_dialog = DIALOG_SCENE.instantiate()
	add_child(_dialog)
	_dialog.prompt(text)
	# 等待信号
	var success: bool = await _dialog.pressed_callback
	return success
