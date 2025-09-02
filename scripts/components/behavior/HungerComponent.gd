## 饥饿度组件
extends Node
class_name HungerComponent

# 当饥饿度超过此阈值，宠物会开始积极寻找食物
var hunger_threshold: float = 80.0
# 当饥饿度达到此阈值，宠物进入饥饿状态
var max_hunger_level: float = 100.0
# 饥饿度变化率
var _hunger_decrease_rate: float = 0.5
var _hunger_increase_amount: float = 10.0

var parent_pet: Pet  #宠物对象


# 在初始化时，从 PetData 中同步饥饿度
func initialize(pet_node: Pet):
	parent_pet = pet_node
	_hunger_decrease_rate = parent_pet.pet_data.hunger_decrease_rate
	_hunger_increase_amount = parent_pet.pet_data.hunger_restore_amount
	# 初始化就是饥饿状态（demo，正式这个值同步存档文件）
	parent_pet.hunger_level = max_hunger_level


# 每帧更新饥饿度
func update_hunger(delta: float):
	# 修复：直接修改 Pet 实例中的 hunger_level
	parent_pet.hunger_level += _hunger_decrease_rate * delta
	parent_pet.hunger_level = clamp(parent_pet.hunger_level, 0.0, max_hunger_level)
	if parent_pet.hunger_level >= hunger_threshold:
		# 当饥饿度达到阈值，通过事件总线通知 PetManager
		EventManager.emit_event(GameEvent.PET_IS_HUNGRY, parent_pet)

#feed函数接收食物数据
func feed(food_data: FoodData):
	parent_pet.hunger_level -= food_data.hunger_restore_amount
	parent_pet.hunger_level = max(parent_pet.hunger_level, 0.0)

	# 如果是幼年期，增加成长值
	if parent_pet.life_stage == PetData.LifeStage.JUVENILE:
		parent_pet.lifecycle_comp.add_growth_points(food_data.growth_points)
