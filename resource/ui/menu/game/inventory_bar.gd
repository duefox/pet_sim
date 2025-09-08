## pets,foods, tools,metarials,builds,landscape,others
extends Control
class_name InventoryBar

@onready var inventory_container: MultiGridContainer = %InventoryContainer
@onready var tab_container: TabContainer = %TabContainer



func _ready() -> void:
	var grid_size: Vector2 = inventory_container.grid_size
	for child in tab_container.get_children():
		child.custom_minimum_size = grid_size + Vector2(20, 84)


## 获取背包容器
func get_item_container() -> MultiGridContainer:
	return inventory_container


## 获取背包物品
func get_item() -> void:
	pass
