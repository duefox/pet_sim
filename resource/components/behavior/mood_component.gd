# MoodComponent.gd
extends Node
class_name MoodComponent

# 拥有该组件的宠物
var parent_pet: Pet

# 心情值，范围从0.0到100.0
var mood_level: float = 0.0


# 初始化组件，由 Pet 类在 _ready() 中调用
func initialize(pet_node: Pet):
	parent_pet = pet_node
	# 可以根据宠物的初始状态设置一个基础心情值
	mood_level = 50.0


# 增加心情值的公共函数，外部可以调用
# @param amount: 要增加的心情值，例如 10.0
func increase_mood(amount: float):
	mood_level += amount
	# 将心情值限制在0到100之间，防止超出范围
	mood_level = clamp(mood_level, 0.0, 100.0)
	print("Pet %s's mood has increased to %s." % [parent_pet.private_id, mood_level])
