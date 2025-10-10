extends BaseAction
class_name EatAction


func _enter() -> void:
	super._enter()
	# 确保宠物在进食时停止移动（假如后期需要增加吃食物的动画）
	#_pet.movement_comp.speed = 0.0


func _tick(_delta: float) -> Status:
	# 1. 进食逻辑（可以是一个瞬时消耗，也可以是基于时间的动画）
	if not is_instance_valid(_pet.food_target):
		# 即使到达了，食物也可能被销毁，返回 FAILURE 重新查找或回退
		_cleanup_task()
		return FAILURE

	# 执行喂食和消耗逻辑
	_perform_eating_logic()

	# 2. 检查是否吃饱
	if _pet.hunger_comp.hunger_level < _pet.hunger_comp.hunger_threshold:
		# 吃饱了，清理并返回成功
		_cleanup_task()
		blackboard.set_var("is_hungry", false)  # 通知黑板，不再饥饿
		return SUCCESS
	else:
		# 还没饱，但食物已经吃完了，返回 FAILURE，让行为树重新查找食物（回到 ActionFindFood）
		_cleanup_task()
		return FAILURE


# 辅助函数：执行喂食和移除食物
func _perform_eating_logic() -> void:
	# 喂食，增加饥饿度
	_pet.hunger_comp.feed(_pet.food_target.data)

	# 移除食物实体
	_pet.food_target.queue_free()
	_pet.food_target = null


func _cleanup_task() -> void:
	_pet.movement_comp.speed = _pet.pet_data.speed  # 恢复默认速度
	_pet.movement_comp.clear_target()
	_pet.food_target = null
