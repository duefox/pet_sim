extends BaseAction
class_name FindFoodAction


func _tick(_delta: float) -> Status:
	# 1. 查找食物
	if not is_instance_valid(_pet.food_target):
		_pet.food_target = _pet.find_closest_food()

	if is_instance_valid(_pet.food_target):
		# 2. 设置冲刺速度和目标位置 (交给 MoveToTarget 移动)
		_pet.movement_comp.speed = _pet.pet_data.speed * _pet.sprint_speed_multiplier
		# 确保没有旧的静态目标
		_pet.movement_comp.clear_target()

		# 3. 查找成功，继续到下一个节点 (MoveToTarget)
		return SUCCESS
	else:
		# 4. 找不到食物，返回 FAILURE，终止觅食 Sequence，回退到漫游
		_cleanup_task()
		return FAILURE


func _cleanup_task() -> void:
	_pet.movement_comp.speed = _pet.pet_data.speed
	_pet.movement_comp.clear_target()
	_pet.food_target = null
