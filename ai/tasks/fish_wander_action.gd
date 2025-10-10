# fish_wander_action.gd
extends BaseAction
class_name FishWanderAction

## 抢占检测的节流间隔
const PREEMPT_CHECK_INTERVAL: float = 0.5
## 移动组件
var _movement: MovementComponent


func _enter() -> void:
	super._enter()
	_movement = _pet.movement_comp

	# 设置漫游速度
	_movement.speed = _pet.pet_data.speed

	# 仅在进入时（或目标无效时）设置新的漫游目标
	if _movement.is_target_invalid():
		_movement.set_target(_pet.create_position())


## 节流函数调用的目标方法：执行昂贵的查找和目标设置。
func _preempt_check() -> void:
	# ---------------------------------------------
	# 1. 觅食抢占检测 (原逻辑)
	# ---------------------------------------------
	var is_hungry = blackboard.get_var("is_hungry", false)

	# 只有饥饿且食物目标尚未被设置时，才执行昂贵的查找
	if is_hungry and not is_instance_valid(_pet.food_target):
		# 执行昂贵的环境查找（例如，遍历所有食物节点）
		var food = _pet.find_closest_food()

		if is_instance_valid(food):
			# 找到食物，立即设置目标。
			_pet.food_target = food
			return  # 找到目标，立即返回

	# ---------------------------------------------
	# 2. 交配抢占检测
	# ---------------------------------------------
	# 只有当 pet 可以交配 (can_mate=true) 、雄性宠物且当前没有配偶目标时，才执行查找
	if _pet.mating_comp.can_mate() and not is_instance_valid(_pet.mate_target) and _pet.gender == BaseItemData.Gender.MALE:
		# 尝试查找最近的配偶并设置目标
		var mate = _pet.find_closest_mate()
		if is_instance_valid(mate):
			# 设置双方互为交配对象并锁定，防止第三者插足
			_pet.mate_target = mate
			_pet.mate_lock = true
			mate.mate_target = _pet
			mate.mate_lock = true
			return  # 找到更重要的目标，立即返回

	# ---------------------------------------------
	# 3. 排泄抢占检测（仅依赖黑板变量，无需查找目标）
	# ---------------------------------------------
	# 排泄是最高优先级，但它仅依赖黑板变量，行为树的 Selector 会在下一帧处理。
	# 我们只需要确保如果交配或觅食目标被设置，就抢占成功。


func _tick(delta: float) -> Status:
	var movement_comp = _pet.movement_comp

	# ===============================================
	# A. 抢占检测 (Throttle Preemption Check)
	# ===============================================
	# 使用 Utils.throttle 限制昂贵的环境查找频率。
	Utils.throttle("preempt_check_" + _pet.name, PREEMPT_CHECK_INTERVAL, _preempt_check)

	# 检查高优先级目标是否已被设置，如果是，则返回 FAILURE 触发 Sequence 切换

	# 优先级 1: 觅食
	if is_instance_valid(_pet.food_target):
		# 找到食物，放弃漫游，进入 FindFood Sequence
		_cleanup_task()
		return FAILURE

	# 优先级 2: 交配，雄性去寻找配偶，雌性继续漫游
	if is_instance_valid(_pet.mate_target) and _pet.gender == BaseItemData.Gender.MALE:
		# 找到配偶，放弃漫游，进入 MateSequence
		_cleanup_task()
		return FAILURE

	# 更新移动
	movement_comp.update_movement(delta)

	# 检查是否到达目标
	if movement_comp.is_target_invalid() or _pet.position.distance_to(movement_comp.get_target()) < _pet.target_collision_distance:
		# 到达目标，设置一个新的目标以保持移动
		movement_comp.set_target(_pet.create_position())
		# 返回 SUCCESS，通知 Selector 重新从头开始评估高优先级行为
		return SUCCESS

	# 持续漫游中
	return RUNNING


func _cleanup_task() -> void:
	# 确保清理目标，但不清理速度，让进入的新行为设置自己的速度
	_pet.movement_comp.clear_target()
