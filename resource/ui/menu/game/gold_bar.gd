extends GameBar
class_name GoldBar

@onready var scale_label: Label = %ScaleLabel
@onready var gold_label: Label = %GoldLabel

signal reset_world_scale
signal reset_world_coords


## 重置世界缩放
func _on_btn_scale_pressed() -> void:
	reset_world_scale.emit()


## 重置世界坐标
func _on_btn_coords_pressed() -> void:
	reset_world_coords.emit()
