## 仓库组件
extends Control
class_name WInventory

@onready var inven_tab_bar: TabBar = %InvenTabBar
@onready var inventory: MultiGridContainer = %Inventory
@onready var tips_label: Label = %TipsLabel
@onready var error_label: Label = %ErrorLabel


func _ready() -> void:
	var grid_size: Vector2 = inventory.grid_size
	inventory.custom_minimum_size = grid_size + Vector2(0.0, 24.0)
	name = &"Inventory"


## 获取网格容器
func get_grid_container() -> MultiGridContainer:
	return inventory


## 获取背包物品
func get_item() -> void:
	pass


#region 按钮事件


## 整理按钮
func _on_btn_sort_pressed() -> void:
	inventory.auto_stack_existing_items()


## tab页切换
func _on_inven_tab_changed(tab: int) -> void:
	# check box 显示更新
	
	# 仓库容器中的items过滤更新
	pass  # Replace with function body.


## 全部切换
func _on_all_check_toggled(toggled_on: bool) -> void:
	pass  # Replace with function body.


## 水生动物切换
func _on_aqua_check_toggled(toggled_on: bool) -> void:
	pass  # Replace with function body.


## 陆生动物切换
func _on_land_check_toggled(toggled_on: bool) -> void:
	pass  # Replace with function body.


## 空中动物切换
func _on_air_check_toggled(toggled_on: bool) -> void:
	pass  # Replace with function body.


## 普通类型切换
func _on_basic_check_toggled(toggled_on: bool) -> void:
	pass  # Replace with function body.


## 稀有类型切换
func _on_magic_box_toggled(toggled_on: bool) -> void:
	pass  # Replace with function body.


## 罕见类型切换
func _on_epic_check_toggled(toggled_on: bool) -> void:
	pass  # Replace with function body.


## 传说类型切换
func _on_mythic_check_toggled(toggled_on: bool) -> void:
	pass  # Replace with function body.
#endregion
