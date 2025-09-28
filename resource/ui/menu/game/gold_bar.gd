extends GameBar
class_name GoldBar

@onready var scale_label: Label = %ScaleLabel
@onready var gold_label: Label = %GoldLabel

## 恢复缩放信号
signal reset_world_scale


## 重置世界缩放
func _on_btn_scale_pressed() -> void:
	reset_world_scale.emit()
