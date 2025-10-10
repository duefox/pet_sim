# move_to_excrete_action.gd
extends BaseAction
class_name MoveToExcreteAction


func _enter() -> void:
	super._enter()

	# 设置移动速度为漫游速度（或略低）
	_pet.movement_comp.speed = _pet.pet_data.speed

	# 将目标设置为宠物的当前位置（表示它到达一个可以排泄的地点，即停止），后续有的动物是直接排泄到特定点（设备）
	_pet.movement_comp.set_target(_pet.global_position)


func _tick(delta: float) -> Status:
	var movement_comp = _pet.movement_comp
	# 1. 持续更新移动，直到到达目标（当前位置）
	movement_comp.update_movement(delta)
	# 2. 检查是否到达目标位置（非常接近当前位置）
	if movement_comp.is_target_invalid() or _pet.position.distance_to(movement_comp.get_target()) < _pet.target_collision_distance:
		# 到达指定位置，准备开始排泄，返回 SUCCESS
		_pet.movement_comp.clear_target()
		return SUCCESS

	# 3. 正在移动中
	return RUNNING

# 不需要 _cleanup_task，因为成功时会自动进入下一个 Action
