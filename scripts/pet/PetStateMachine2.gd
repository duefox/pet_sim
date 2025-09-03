## 宠物状态处理
extends Node
class_name PetStateMachine2

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
@export var mating_duration: float = 4.0  # 交配持续时间，可按需修改
@export var mating_timeout: float = 8.0  # 交配超时时间，防止卡死，时长至少大于mating_duration的2倍

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
var _mating_timeout_timer: float = 0.0
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
	#print("Pet %s changed state to: %s" % [_parent_pet.id, State.keys()[current_state]])
	#默认情况下达到目标后自动清理
	_parent_pet.movement_comp.clear_on_arrival = true

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
			# 从待机状态切换到漫游时，设置正常速度，清空交配锁和交配目标
			_parent_pet.mate_lock = false
			_parent_pet.mate_target = null
			_parent_pet.movement_comp.speed = _parent_pet.pet_data.speed
		# 排泄状态
		State.EXCRETING:
			_excreting_timer = excreting_duration
			_parent_pet.movement_comp.clear_target()
		# 交配状态
		State.MATING:
			_parent_pet.movement_comp.speed = _parent_pet.pet_data.speed * sprint_speed_multiplier
			# 重置交配计时器和超时计时器
			_mating_timer = mating_duration
			_mating_timeout_timer = mating_timeout
			# 交配时不需要自动清除
			_parent_pet.movement_comp.clear_on_arrival = false
			# 如果由交配对象則计算双向奔赴的坐标
			if is_instance_valid(_parent_pet.mate_target):
				# 只在进入交配状态时计算一次中心点，而不是每帧都计算
				var mate_coords: Vector2 = (_parent_pet.position + _parent_pet.mate_target.position) / 2.0
				_parent_pet.mate_coords = mate_coords
				_parent_pet.mate_target.mate_coords = mate_coords


## 恢复之前的状态
func recover_state() -> void:
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
func _state_wandering(delta: float):
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
			# 吃完食物后，直接切换回漫游状态，而不是上一个状态
			change_state(State.WANDERING)
	else:
		# 如果食物被其他宠物吃掉或已无效，切换回之前的状态
		_parent_pet.movement_comp.speed = _parent_pet.pet_data.speed
		# 吃完食物后，清空运动组件的目标位置
		_parent_pet.movement_comp.clear_target()
		_parent_pet.target = null
		# 吃完食物后，直接切换回漫游状态，而不是上一个状态
		change_state(State.WANDERING)


## 排泄状态
func _state_excreting(delta: float):
	_excreting_timer -= delta
	if _excreting_timer <= 0:
		# 排泄时间到，生成排泄物并切换回漫游状态
		_parent_pet.spawn_excrement()
		change_state(State.WANDERING)


## 交配状态
func _state_mating(delta: float):
	# 检查交配目标是否有效，以及是否超时
	_mating_timeout_timer -= delta
	if not _parent_pet.mate_target or not is_instance_valid(_parent_pet.mate_target) or _mating_timeout_timer <= 0:
		# 如果目标或坐标无效，立即返回漫游状态
		_parent_pet.mate_lock = false
		_parent_pet.mate_target = null
		_parent_pet.mate_coords = Vector2.ZERO
		_parent_pet.show_mate_animate(false)
		change_state(State.WANDERING)
		print("mating_timeout_timer----------parent_pet.velocity:", _parent_pet.velocity)
		return

	# 双向奔赴，求俩只宠物的向量中心点
	var male_pet: Pet = _parent_pet
	var female_pet: Pet = _parent_pet.mate_target
	if _parent_pet.gender == PetData.Gender.FEMALE:
		#交换雌雄
		var tmp_pet: Pet = _parent_pet
		male_pet = tmp_pet.mate_target
		female_pet = tmp_pet

	# 假如交配对象不是交配状态则置为MATING
	if not _parent_pet.mate_target.state_machine.current_state == State.MATING:
		_parent_pet.mate_target.state_machine.change_state(State.MATING)

	# 向双向奔赴的交配坐标移动
	if is_instance_valid(male_pet) and is_instance_valid(female_pet):
		male_pet.movement_comp.set_target(male_pet.mate_coords)
		female_pet.movement_comp.set_target(female_pet.mate_coords)

	# 检查是否到达配偶位置
	var distance: float = male_pet.position.distance_to(female_pet.position)
	#print("distance:", distance)
	# 修复：增加距离判断的容错性，使用更大的阈值
	#if distance < _parent_pet.target_collision_distance * 1.5:
	if distance < _parent_pet.target_collision_distance:
		# 停止移动并开始动画
		_stop_and_animate(male_pet)
		_stop_and_animate(female_pet)
		# 开始交配计时
		_mating_timer -= delta
		if _mating_timer <= 0:
			male_pet.mate_coords = Vector2.ZERO
			female_pet.mate_coords = Vector2.ZERO
			# 调用 MatingComponent 的 complete_mating 方法，由它来处理后续的逻辑
			_parent_pet.mating_comp.complete_mating(_parent_pet.mate_target)


## 停止移动并显示交配动画的私有函数
func _stop_and_animate(pet: Pet):
	pet.movement_comp.clear_target()
	pet.movement_comp.speed = 0
	pet.show_mate_animate(true)


## 游玩状态
func _state_playing(delta: float):
	pass


## 睡觉状态
func _state_sleeping(delta: float):
	pass
