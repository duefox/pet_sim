## 饥饿度组件
extends Node
class_name HungerComponent

# 饥饿度当前值，0为不饿，100为饥饿
var hunger_level: float = 0.0

# 当饥饿度超过此阈值，宠物会开始积极寻找食物
var hunger_threshold: float = 80.0
# 当饥饿度达到此阈值，宠物进入饥饿状态
var max_hunger_level: float = 100.0

# 饥饿度变化率，由 PetData 提供
var _hunger_decrease_rate: float = 0.5
var _hunger_increase_amount: float = 10.0

var parent_pet: Pet  #宠物对象


func initialize(pet_node: Pet):
	parent_pet = pet_node
	_hunger_decrease_rate = parent_pet.pet_data.hunger_decrease_rate
	_hunger_increase_amount = parent_pet.pet_data.hunger_restore_amount

# 每帧更新饥饿度
func update_hunger(delta: float):
	hunger_level += _hunger_decrease_rate * delta
	hunger_level = clamp(hunger_level, 0.0, max_hunger_level)

	# 当饥饿度达到阈值，通过事件总线通知 PetManager
	if hunger_level >= hunger_threshold:
		EventManager.emit_event(GameEvent.PET_IS_HUNGRY, parent_pet)


func feed():
	hunger_level -= _hunger_increase_amount
	hunger_level = max(hunger_level, 0.0)
