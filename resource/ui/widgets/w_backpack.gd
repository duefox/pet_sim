## 人物背包
extends Control
class_name WBackpack

@onready var packback_bg: NinePatchRect = %PackbackBG
@onready var packback: MultiGridContainer = %Packback
@onready var trash: TrashGridContainer = %Trash


func _ready() -> void:
	# 设置多格容器的大小
	if GlobalData.player.player_info:
		var box_size: Vector2i = GlobalData.player.player_info.get("bag_size", Vector2i(2, 12))
		packback.grid_col = box_size.x
		packback.grid_row = box_size.y
	# 渲染格子
	packback.render_grid()
	trash.render_grid()
	var grid_size: Vector2 = packback.grid_size
	packback_bg.custom_minimum_size = grid_size + Vector2(0.0, 5.0)
	name = &"Backpack"


## 获取网格容器
func get_grid_container() -> MultiGridContainer:
	return packback


## 获取背包物品
func get_item() -> void:
	pass


## 整理物品
func _on_btn_sort_pressed() -> void:
	packback.auto_stack_existing_items()


## 清空垃圾箱
func _on_btn_clear_pressed() -> void:
	trash.clear_all_items()
