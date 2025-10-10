# excrete_action.gd
extends BaseAction
class_name ExcreteAction

var _timer: float = 0.0


func _enter() -> void:
	super._enter()
	# 重置计时器
	_timer = _pet.excreting_duration
	# 确保宠物停止移动
	_pet.movement_comp.speed = 0.0
	_pet.movement_comp.clear_target()
	# TODO: 播放排泄动画 (这里暂时跳过，只专注于逻辑)
	# _pet.animation_player.play("excrete")


func _tick(delta: float) -> Status:
	# 1. 倒计时
	_timer -= delta

	if _timer <= 0.0:
		# 2. 时间到，执行排泄逻辑

		# 3. 调用 Pet 上的方法生成便便实体
		_pet.spawn_excrement()
		# 4. 清理排泄状态
		_cleanup_task()
		# 5. 告诉行为树排泄完成，返回 SUCCESS
		return SUCCESS

	# 6. 正在排泄中
	return RUNNING


func _cleanup_task() -> void:
	# 重置黑板变量
	blackboard.set_var("needs_to_excrete", false)
	# 恢复漫游速度
	_pet.movement_comp.speed = _pet.pet_data.speed
	# 通知排泄组件状态已清除
	_pet.excretion_comp.clear_excrete_state()
