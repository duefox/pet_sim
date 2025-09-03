## 宠物状态处理
extends Node
class_name PetStateMachine

## 宠物的状态有待机、觅食、玩耍、睡觉、漫游、交配、排泄
enum State { IDLE, EATING, PLAYING, SLEEPING, WANDERING, MATING, EXCRETING }
## 宠物漫游的水域层级
enum WanderLayer { TOP, MIDDLE, BOTTOM, ALL }

# 将待机时间作为导出变量，默认值为3秒
@export var idle_duration: float = 1.5
# 排泄时的持续时间
@export var excreting_duration: float = 0.5
# 觅食时的加速倍率
@export var sprint_speed_multiplier: float = 2.0
@export var mating_duration: float = 5.0 # 交配持续时间，可按需修改

#region 共有变量
#当前宠物的状态
var current_state: int = State.WANDERING
# 待机计时器
var idle_timer: float = 0.0
#endregion

#region 私有变量
var _parent_pet: Pet
# 状态处理函数字典
var _state_functions: Dictionary[int,Callable] = {}
# 记录前一个状态
var _previous_state: int = State.IDLE
# 觅食最小距离
var _food_detection_distance: float = 200.0
var _excreting_timer: float = 0.0
# 交配计时器和持续时间
var _mating_timer: float = 0.0

#endregion


func _ready() -> void:
	# 订阅宠物状态切换事件
	pass


## 初始化
func initialize(pet_node: Pet):
	_parent_pet = pet_node
	_state_functions[State.IDLE] = _state_idle
	_state_functions[State.EATING] = _state_eating
	_state_functions[State.PLAYING] = _state_playing
	_state_functions[State.SLEEPING] = _state_sleeping
	_state_functions[State.WANDERING] = _state_wandering
	_state_functions[State.MATING] = _state_mating
	_state_functions[State.EXCRETING] = _state_excreting
	if _parent_pet and _parent_pet.pet_data:
		# 觅食最小距离是漫游范围的50%
		_food_detection_distance = _parent_pet.wander_rank.size.x * 0.5
		# 初始化：默认进入漫游状态，速度为正常速度
		_parent_pet.movement_comp.speed = _parent_pet.pet_data.speed


## 更新状态
func update_state(delta: float):
	var function_to_call = _state_functions.get(current_state)
	if function_to_call:
		function_to_call.call(delta)


## 状态切换
func change_state(new_state: int) -> void:
	# 容错，出错则默认切换到漫游状态
	if current_state == new_state:
		current_state = State.WANDERING
		_parent_pet.movement_comp.speed = _parent_pet.pet_data.speed
		return

	_previous_state = current_state
	current_state = new_state
	print("Pet %s changed state to: %s" % [_parent_pet.id, State.keys()[current_state]])

	match current_state:
		State.EATING:
			# 觅食时将速度设置为冲刺速度
			_parent_pet.movement_comp.speed = _parent_pet.pet_data.speed * sprint_speed_multiplier
		State.IDLE:
			# 进入待机状态时，重置待机计时器
			idle_timer = idle_duration
			_parent_pet.movement_comp.clear_target()
			_parent_pet.movement_comp.speed = 0
		State.WANDERING:
			# 从待机状态切换到漫游时，设置正常速度
			_parent_pet.movement_comp.speed = _parent_pet.pet_data.speed
		# 排泄状态
		State.EXCRETING:
			_excreting_timer = excreting_duration
			_parent_pet.movement_comp.clear_target()
		# 交配状态
		State.MATING:
			_parent_pet.movement_comp.speed = _parent_pet.pet_data.speed * sprint_speed_multiplier
			# 重置交配计时器
			_mating_timer = mating_duration 


## 恢复之前的状态
func recover_state() -> void:
	#增加检测判断，避免陷入死循环
	if current_state == _previous_state:
		change_state(State.WANDERING)
	else:
		change_state(_previous_state)


# --- 状态处理函数 ---


## 待机状态
func _state_idle(delta: float):
	# 处理待机计时器
	idle_timer -= delta
	if idle_timer <= 0:
		_parent_pet.pet_sprite.material["shader_parameter/outlineWidth"] = 0.0
		# 从待机状态切换到漫游前，设置正常速度
		_parent_pet.movement_comp.speed = _parent_pet.pet_data.speed
		recover_state()


## 漫游状态
## 漫游状态
func _state_wandering(delta: float):
	# 宠物漫游
	# 当运动目标为空时，每隔一段时间重新寻找目标
	if _parent_pet.movement_comp.is_target_invalid():
		_parent_pet.movement_comp.set_target(_parent_pet.create_position())

	# 检查是否需要交配
	if _parent_pet.mating_comp.can_mate():
		var closest_mate = _parent_pet.find_mate()
		if is_instance_valid(closest_mate):
			_parent_pet.mating_comp.start_mating(closest_mate)

	# 检查是否饥饿
	if _parent_pet.hunger_comp.hunger_level >= _parent_pet.hunger_comp.hunger_threshold:
		var closest_food = _parent_pet.find_closest_food()
		if is_instance_valid(closest_food):
			_parent_pet.target = closest_food
			change_state(State.EATING)
			#print("Pet is hungry and found food! Now going to eat.")

	#检查是否要排泄
	if _parent_pet.excretion_comp.needs_to_excrete:
		change_state(State.EXCRETING)
		print("Pet needs to poop! Now going to excrete.")


## 觅食状态
func _state_eating(delta: float):
	if _parent_pet.target and is_instance_valid(_parent_pet.target):
		_parent_pet.movement_comp.set_target(_parent_pet.target.position)
		# 检查是否到达食物位置
		if _parent_pet.position.distance_to(_parent_pet.target.position) < _parent_pet.target_collision_distance:
			# 喂食，增加饥饿度
			# 直接从 DroppableObject 获取 data
			_parent_pet.hunger_comp.feed(_parent_pet.target.data)
			# 宠物吃掉食物，移除食物节点
			_parent_pet.target.queue_free()
			_parent_pet.target = null
			# 宠物吃掉食物后还原速度
			_parent_pet.movement_comp.speed = _parent_pet.pet_data.speed
			# 吃完食物后，清空运动组件的目标位置
			_parent_pet.movement_comp.clear_target()
			# 修复：吃完食物后，直接切换回漫游状态，而不是上一个状态
			change_state(State.WANDERING)
	else:
		# 如果食物被其他宠物吃掉或已无效，切换回之前的状态
		_parent_pet.movement_comp.speed = _parent_pet.pet_data.speed
		# 吃完食物后，清空运动组件的目标位置
		_parent_pet.movement_comp.clear_target()
		_parent_pet.target = null
		# 修复：吃完食物后，直接切换回漫游状态，而不是上一个状态
		change_state(State.WANDERING)


## 排泄状态
func _state_excreting(delta: float):
	_excreting_timer -= delta
	if _excreting_timer <= 0:
		# 排泄时间到，生成排泄物并切换回漫游状态
		_parent_pet.spawn_excrement()
		change_state(State.WANDERING)


## 交配状态
## 交配状态
func _state_mating(delta: float):
	# 如果有交配目标，则向其移动
	if _parent_pet.mate_target and is_instance_valid(_parent_pet.mate_target):
		_parent_pet.movement_comp.set_target(_parent_pet.mate_target.position)
		
		# 检查是否到达配偶位置
		if _parent_pet.position.distance_to(_parent_pet.mate_target.position) < _parent_pet.target_collision_distance:
			# 停止移动，开始交配计时
			_parent_pet.movement_comp.clear_target()
			_parent_pet.movement_comp.speed = 0
			
			# 同时将配偶的速度也设为0
			if is_instance_valid(_parent_pet.mate_target.movement_comp):
				_parent_pet.mate_target.movement_comp.speed = 0

			_mating_timer -= delta
			if _mating_timer <= 0:
				# 交配计时结束
				if _parent_pet.gender == PetData.Gender.FEMALE:
					_parent_pet.spawn_egg()
				
				# 恢复速度
				_parent_pet.movement_comp.speed = _parent_pet.pet_data.speed
				if is_instance_valid(_parent_pet.mate_target.movement_comp):
					_parent_pet.mate_target.movement_comp.speed = _parent_pet.mate_target.pet_data.speed
					
				# 切换回漫游状态
				change_state(State.WANDERING)
				# 清除交配目标
				_parent_pet.mate_target = null 
	else:
		# 如果配偶消失，则切换回漫游状态
		_parent_pet.movement_comp.speed = _parent_pet.pet_data.speed
		change_state(State.WANDERING)


## 游玩状态
func _state_playing(delta: float):
	pass


## 睡觉状态
func _state_sleeping(delta: float):
	pass
