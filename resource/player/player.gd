extends Node2D
class_name Player

#背包数据组件
var backpack_comp: BackpackComponent
var inventory_comp: InventoryComponent


func _ready() -> void:
	# 设置全局玩家
	GlobalData.player = self
	# 数据组件
	backpack_comp = find_child("BackpackComponent")
	inventory_comp = find_child("InventoryComponent")
