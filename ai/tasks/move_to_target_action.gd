# move_to_target_action.gd (实现追踪逻辑)
extends BaseAction
class_name MoveToTargetAction

func _tick(delta: float) -> Status:
	# 1. 检查食物是否仍然有效
	if not is_instance_valid(_pet.food_target):
		# 食物目标丢失（可能已落地或被其他宠物吃掉）
		_cleanup_task()
		return FAILURE

	# 2. 【核心追踪逻辑】每帧更新目标位置
	# 即使食物在移动，宠物也会追逐其当前位置
	var food_current_pos: Vector2 = _pet.food_target.position
	_pet.movement_comp.set_target(food_current_pos) 

	# 3. 持续更新移动
	_pet.movement_comp.update_movement(delta)

	# 4. 检查是否到达食物位置（接近目标，可以吃）
	if _pet.position.distance_to(food_current_pos) < _pet.target_collision_distance * 1.5:
		# 到达目标，继续到下一个节点 (Eat)
		return SUCCESS

	# 5. 正在进行中
	return RUNNING

func _cleanup_task() -> void:
	_pet.movement_comp.speed = _pet.pet_data.speed
	_pet.movement_comp.clear_target()
	_pet.food_target = null
