extends Control
class_name WQuickTools

@onready var qtbg: NinePatchRect = %QTBG
@onready var quick_tools: SingleGridContainer = %QuickTools

signal next_day_pressed


func _ready() -> void:
	# 设置多格容器的大小
	if GlobalData.player.player_info:
		var box_size: Vector2i = GlobalData.player.player_info.get("qt_size", Vector2i(1, 10))
		quick_tools.grid_col = box_size.x
		quick_tools.grid_row = box_size.y
	# 渲染格子
	quick_tools.render_grid()
	var grid_size: Vector2 = quick_tools.grid_size
	qtbg.custom_minimum_size = grid_size + Vector2(0.0, 10.0)
	name = &"QuickTools"


## 获取背包容器
func get_grid_container() -> MultiGridContainer:
	return quick_tools


## 获取背包物品
func get_item() -> void:
	pass


## 发出下一天按钮信号
func _on_btn_next_day_pressed() -> void:
	next_day_pressed.emit()
