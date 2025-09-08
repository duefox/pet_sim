# MatingComponent.gd
extends Node
class_name MatingComponent

@export var mating_threshold: float = 20.0

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
	# 4. 宠物当前状态不能是MATING
	# 5. 宠物当前的mate_lock不能锁定
	return (
		parent_pet.life_stage == PetData.LifeStage.ADULT
		and parent_pet.hunger_comp.hunger_level < 100.0
		and (Time.get_unix_time_from_system() - _last_mating_timestamp) >= _mating_cooldown
		and parent_pet.state_machine.current_state != PetStateMachine.State.MATING
		and not parent_pet.mate_lock
	)


## 开始交配
func start_mating(mate: Pet):
	# 重置冷却时间
	_last_mating_timestamp = Time.get_unix_time_from_system()

	# 设置交配目标
	parent_pet.mate_target = mate
	# 锁定自己和配偶
	parent_pet.mate_lock = true
	mate.mate_lock = true

	# 确保配偶有效
	if is_instance_valid(mate):
		# 让发起交配的宠物和它的配偶都切换到 MATING 状态
		parent_pet.state_machine.change_state(PetStateMachine.State.MATING)
		mate.state_machine.change_state(PetStateMachine.State.MATING)
		# 让配偶宠物的 mate_target 指向自己，形成双向锁定
		mate.mate_target = parent_pet

	print("Pet %s is starting to mate with Pet %s." % [parent_pet.id, mate.id])


## 完成交配
func complete_mating(mate: Pet):
	# 交配产生后代，仅限雌性
	if parent_pet.gender == PetData.Gender.FEMALE:
		parent_pet.spawn_egg()
	else:
		mate.spawn_egg()

	# 将自己的状态、目标和锁重置
	parent_pet.mate_target = null
	parent_pet.mate_lock = false
	parent_pet.state_machine.change_state(PetStateMachine.State.WANDERING)
	# 隐藏交配动画
	parent_pet.show_mate_animate(false)

	# 确保配偶也存在并重置其状态、目标和锁
	if is_instance_valid(mate):
		mate.mate_target = null
		mate.mate_lock = false
		mate.state_machine.change_state(PetStateMachine.State.WANDERING)
		# 隐藏交配动画
		mate.show_mate_animate(false)

	print("Pet %s has completed mating." % parent_pet.id)
