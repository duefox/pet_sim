## 人物背包
extends Control
class_name WBackpack

@onready var packback_bg: NinePatchRect = %PackbackBG
@onready var packback_container: MultiGridContainer = %PackbackContainer


func _ready() -> void:
	var grid_size: Vector2 = packback_container.grid_size
	packback_bg.custom_minimum_size = grid_size + Vector2(0.0, 5.0)


## 获取网格容器
func get_grid_container() -> MultiGridContainer:
	return packback_container


## 获取背包物品
func get_item() -> void:
	pass


func _on_btn_sort_pressed() -> void:
	packback_container.auto_stack_existing_items()
