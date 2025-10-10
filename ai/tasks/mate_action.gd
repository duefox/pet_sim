# mating_action.gd
extends BaseAction
class_name MatingAction

var _timer: float = 0.0
var _mate: Pet = null


func _enter() -> void:
	super._enter()
	_timer = _pet.mating_duration
	_mate = _pet.mate_target

	# 确保双方都停止移动 (雄性 MoveToMate 已停止，此处再次确认)
	_pet.movement_comp.clear_target()
	_pet.movement_comp.speed = 0.0
	if is_instance_valid(_mate):
		_mate.movement_comp.clear_target()
		_mate.movement_comp.speed = 0.0
		# 播放交配动画/特效
		_mate.show_mate_animate(true)
	

	# 播放交配动画/特效
	_pet.show_mate_animate(true)


func _tick(delta: float) -> Status:
	# 1. 检查配偶是否仍然有效
	if not is_instance_valid(_mate) or not _mate.mate_lock:
		# 配偶丢失或被解锁，流程中断
		_cleanup_task()
		return FAILURE

	# 2. 倒计时
	_timer -= delta

	if _timer <= 0.0:
		# 3. 时间到，调用 MatingComponent 完成交配
		# 【核心同步】：此方法必须重置双方的 mate_lock 和 _last_mating_timestamp
		_pet.mating_comp.complete_mating(_mate)
		_mate.bt_player.restart()
		# 清除任务
		_cleanup_task()
		return SUCCESS

	# 4. 正在进行中
	return RUNNING


func _cleanup_task() -> void:
	# 仅清理自身状态（配偶状态主要由 complete_mating 处理）
	_pet.movement_comp.speed = _pet.pet_data.speed
	_pet.mate_target = null
	_pet.mate_lock = false
