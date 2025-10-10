# find_mate_action.gd
extends BaseAction
class_name FindMateAction


func _tick(_delta: float) -> Status:
	# 雌性直接返回失败，只有雄性才要去找配偶
	if _pet.gender == BaseItemData.Gender.FEMALE:
		return FAILURE

	# 1. 查找配偶
	# 查找逻辑应排除自己，只找成年、饱食、冷却已过的异性。
	var mate: Pet = _pet.mate_target
	if not is_instance_valid(mate):
		mate = _pet.find_closest_mate()

	if is_instance_valid(mate):
		# 2. 设置交配目标和锁定
		_pet.mate_target = mate
		_pet.mate_lock = true

		# 3. 设置交配目标的交配对象为自己并且锁定
		mate.mate_target = _pet
		mate.mate_lock = true

		# 4. 设置冲刺速度 (交给 MoveToMate 移动)
		_pet.movement_comp.speed = _pet.pet_data.speed * _pet.sprint_speed_multiplier

		# 5. 查找成功，继续到下一个节点 (MoveToMate)
		return SUCCESS
	else:
		# 6. 找不到配偶，返回 FAILURE，终止 Mate Sequence
		_cleanup_task()
		return FAILURE


func _cleanup_task() -> void:
	# 查找失败或被中断，恢复默认状态
	_pet.movement_comp.speed = _pet.pet_data.speed
	_pet.mate_target = null
	_pet.mate_lock = false
