## 所有网格容器的父节点
extends Control
class_name GridBoxBar

@onready var w_inventory: WInventory = %WInventory
@onready var w_backpack: WBackpack = %WBackpack
@onready var w_quick_tools: WQuickTools = %WQuickTools


func get_inventory() -> MultiGridContainer:
	return w_inventory.get_grid_container()
	
func get_backpack() -> MultiGridContainer:
	return w_backpack.get_grid_container()
	
func get_quick_tool() -> MultiGridContainer:
	return w_quick_tools.get_grid_container()
