extends Control
class_name EquipmentBar

@onready var equipment_container: SingleGridContainer = %EquipmentContainer
@onready var equipment_bg: NinePatchRect = %EquipmentBG


func _ready() -> void:
	var grid_size: Vector2 = equipment_container.grid_size
	equipment_bg.custom_minimum_size = grid_size + Vector2(10.0, 2.0)


## 获取背包容器
func get_item_container() -> MultiGridContainer:
	return equipment_container


## 获取背包物品
func get_item() -> void:
	pass
