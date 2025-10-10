# mating_component.gd
extends Node
class_name MatingComponent

## 饥饿度低于此值（即很饱）才能交配，默认20 #### 测试
@export var mating_threshold: float = 100.0

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


## 核心方法：实时更新交配状态并设置黑板变量
## 应该在 Pet.gd 的 _process 或 _physics_process 中被调用
func update_mating(_delta: float):
	# 只有当宠物不处于交配锁定状态，才需要检查并设置黑板
	if not parent_pet.mate_lock:
		var can_pet_mate: bool = _check_all_mating_conditions()
		# 设置黑板变量，通知行为树
		parent_pet.blackboard.set_var("can_mate", can_pet_mate)


## 辅助方法：检查所有交配条件
func _check_all_mating_conditions() -> bool:
	return (
		# 1. 宠物必须处于成年阶段
		parent_pet.lifecycle_comp.life_stage == PetData.LifeStage.ADULT
		# 2. **【核心规则】饱食度检查：** 饥饿值必须低于阈值（即很饱）
		and parent_pet.hunger_comp.hunger_level < mating_threshold
		# 3. 冷却时间已过
		and (Time.get_unix_time_from_system() - _last_mating_timestamp) >= _mating_cooldown
	)


func can_mate() -> bool:
	# 检查自身是否满足条件，并且没有被交配锁定
	return _check_all_mating_conditions() and not parent_pet.mate_lock


## 开始交配
func start_mating(mate: Pet):
	# 重置冷却时间
	_last_mating_timestamp = Time.get_unix_time_from_system()

	# 设置交配目标并双向锁定
	parent_pet.mate_target = mate
	parent_pet.mate_lock = true

	# 确保配偶有效，并设置配偶的目标
	if is_instance_valid(mate):
		mate.mate_lock = true
		mate.mate_target = parent_pet

	print("Pet %s is starting to mate with Pet %s." % [parent_pet.private_id, mate.private_id])


## 设置上次交配时间，用于在交配完成时重置配偶冷却
func set_last_mating_timestamp(timestamp: float) -> void:
	_last_mating_timestamp = timestamp


## 完成交配 (更新逻辑，确保重置双方状态)
func complete_mating(mate: Pet):
	var current_time = Time.get_unix_time_from_system()

	# 1. 重置发起者（自己）的状态
	set_last_mating_timestamp(current_time)
	parent_pet.mate_lock = false
	parent_pet.mate_target = null
	parent_pet.show_mate_animate(false)

	# 2. 检查配偶并重置其状态
	if is_instance_valid(mate):
		# **【核心修复】** 重置配偶的冷却
		if mate.mating_comp:
			mate.mating_comp.set_last_mating_timestamp(current_time)

		# 重置配偶的锁和目标
		mate.mate_lock = false
		mate.mate_target = null
		mate.show_mate_animate(false)

		# 3. 雌性宠物产卵/生育 (mate 是雌性)
		mate.spawn_egg()

	# 4. 重置黑板变量
	parent_pet.blackboard.set_var("can_mate", false)
	if is_instance_valid(mate) and mate.blackboard:
		mate.blackboard.set_var("can_mate", false)
