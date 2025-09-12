## pets,foods, tools,metarials,builds,landscape,others
extends Control
class_name WInventory

@onready var tab_container: TabContainer = %TabContainer
@onready var inventory_all: MultiGridContainer = %InventoryAll
@onready var inventory_pets: MultiGridContainer = %InventoryPets
@onready var inventory_foods: MultiGridContainer = %InventoryFoods
@onready var inventory_materisal: MultiGridContainer = %InventoryMaterisal
@onready var inventory_others: MultiGridContainer = %InventoryOthers

## 当前仓库
var cur_inventory: MultiGridContainer


func _ready() -> void:
	var grid_size: Vector2 = inventory_all.grid_size
	for child in tab_container.get_children():
		child.custom_minimum_size = grid_size + Vector2(20, 100)
	#
	cur_inventory = inventory_all


## 获取网格容器
func get_grid_container() -> MultiGridContainer:
	return inventory_all


## 获取背包物品
func get_item() -> void:
	pass


func _on_btn_sort_pressed() -> void:
	cur_inventory.auto_stack_existing_items()
