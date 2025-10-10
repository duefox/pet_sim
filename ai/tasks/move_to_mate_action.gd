# move_to_mate_action.gd
extends BaseAction
class_name MoveToMateAction

func _tick(delta: float) -> Status:
	var mate: Pet = _pet.mate_target
	
	# 1. 检查配偶是否仍然有效和锁定 (防止被其他逻辑解锁或删除)
	if not is_instance_valid(mate) or not mate.mate_lock:
		# 配偶丢失或被解锁，交配失败
		_cleanup_task()
		return FAILURE

	# 2. 【核心追踪逻辑】每帧更新目标位置
	var mate_current_pos: Vector2 = mate.position
	_pet.movement_comp.set_target(mate_current_pos) 

	# 3. 持续更新移动
	_pet.movement_comp.update_movement(delta)

	# 4. 检查是否到达配偶位置（接近目标，可以交配）
	if _pet.position.distance_to(mate_current_pos) < _pet.target_collision_distance:
		# 到达目标，继续到下一个节点 (Mating)
		return SUCCESS

	# 5. 正在进行中
	return RUNNING

func _cleanup_task() -> void:
	_pet.movement_comp.speed = _pet.pet_data.speed
	_pet.movement_comp.clear_target()
	_pet.mate_target = null
	_pet.mate_lock = false
