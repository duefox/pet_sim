# Food.gd
extends DroppableObject
class_name Food


func _ready() -> void:
	super()
	#食物特有属性
	data = data as FoodData
