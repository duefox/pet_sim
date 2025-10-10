extends GameBar
class_name InfoBar

@onready var day_label: Label = %DayLabel
@onready var weather_icon: ButtonEmpty = %WeatherIcon
@onready var scale_label: Label = %ScaleLabel


## 恢复缩放信号
signal reset_world_scale


## 重置世界缩放
func _on_btn_scale_pressed() -> void:
	reset_world_scale.emit()
