extends Control
class_name WQuickTools

@onready var qtbg: NinePatchRect = %QTBG
@onready var qt_container: SingleGridContainer = %QTContainer


func _ready() -> void:
	var grid_size: Vector2 = qt_container.grid_size
	qtbg.custom_minimum_size = grid_size + Vector2(0.0, 10.0)


## 获取背包容器
func get_grid_container() -> MultiGridContainer:
	return qt_container


## 获取背包物品
func get_item() -> void:
	pass
