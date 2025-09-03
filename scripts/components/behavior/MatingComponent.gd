# MatingComponent.gd
extends Node
class_name MatingComponent

var parent_pet: Pet

# 交配冷却时间，单位为秒，从 PetData 中获取
var _mating_cooldown: float = 0.0
# 上次交配的真实世界时间戳
var _last_mating_timestamp: float = 0.0


func initialize(pet_node: Pet):
	parent_pet = pet_node
	# 如果 parent_pet.pet_data 存在，从其中获取交配冷却时间
	if parent_pet and parent_pet.pet_data is PetData:
		_mating_cooldown = parent_pet.pet_data.mating_cooldown

	# 初始化时，将冷却时间设置为已冷却，方便宠物开始游戏时就能交配
	_last_mating_timestamp = -_mating_cooldown


func update_mating(delta: float):
	pass  # 该组件主要由状态机调用，无需每帧更新


func can_mate() -> bool:
	# 检查基本交配条件
	# 1. 宠物必须处于成年阶段
	# 2. 饥饿度低于 50%
	# 3. 冷却时间已过
	return (
		parent_pet.life_stage == PetData.LifeStage.ADULT
		and parent_pet.hunger_comp.hunger_level < 100.0
		and (Time.get_unix_time_from_system() - _last_mating_timestamp) >= _mating_cooldown
	)


func start_mating(mate: Pet):
	# 重置冷却时间
	_last_mating_timestamp = Time.get_unix_time_from_system()
	# 切换到交配状态
	parent_pet.state_machine.change_state(PetStateMachine.State.MATING)
	# 设置交配目标
	parent_pet.mate_target = mate
	print("Pet %s is starting to mate with Pet %s." % [parent_pet.id, mate.id])


func complete_mating(mate: Pet):
	# 交配成功，调用宠物的生成后代方法
	parent_pet.spawn_egg()

	# 切换回漫游状态
	parent_pet.state_machine.change_state(PetStateMachine.State.WANDERING)
	# 清除目标
	parent_pet.mate_target = null
	print("Pet %s has completed mating." % parent_pet.id)
