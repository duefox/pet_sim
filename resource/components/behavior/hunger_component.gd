## 饥饿度组件
extends Node
class_name HungerComponent

## 宠物对象
var parent_pet: Pet
## 当饥饿度超过此阈值，宠物会开始积极寻找食物
var hunger_threshold: float = 80.0
## 当饥饿度达到此阈值，宠物进入饥饿状态
var max_hunger_level: float = 100.0
## 饥饿度当前值，0为不饿，100为饥饿
var hunger_level: float = 0.0
## 是否饥饿
var is_hungry: bool = false:
	set(value):
		is_hungry = value
		# 设置黑板关联行为树
		parent_pet.blackboard.set_var("is_hungry", is_hungry)
## 饥饿度变化率
var _hunger_decrease_rate: float = 0.5
var _hunger_increase_amount: float = 10.0


# 在初始化时，从 PetData 中同步饥饿度
func initialize(pet_node: Pet) -> void:
	parent_pet = pet_node
	_hunger_decrease_rate = parent_pet.pet_data.hunger_decrease_rate
	_hunger_increase_amount = parent_pet.pet_data.hunger_restore_amount
	# 初始化就是饥饿状态（demo，正式这个值同步存档文件）
	hunger_level = max_hunger_level


# 每帧更新饥饿度，并且返回是否达到饥饿阈值
func update_hunger(delta: float) -> void:
	# 直接修改 Pet 实例中的 hunger_level
	hunger_level += _hunger_decrease_rate * delta
	hunger_level = clamp(hunger_level, 0.0, max_hunger_level)
	if hunger_level >= hunger_threshold:
		# 当饥饿度达到阈值
		is_hungry = true
	else:
		is_hungry = false


#feed函数接收食物数据
func feed(food_data: FoodData) -> void:
	hunger_level -= food_data.hunger_restore_amount
	hunger_level = max(hunger_level, 0.0)

	# 如果是幼年期，增加成长值
	if parent_pet.lifecycle_comp.life_stage == PetData.LifeStage.JUVENILE:
		parent_pet.lifecycle_comp.add_growth_points(food_data.growth_points)
