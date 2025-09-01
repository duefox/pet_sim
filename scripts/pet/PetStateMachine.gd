## 宠物状态处理
extends Node
class_name PetStateMachine

## 宠物的状态有待机、觅食、玩耍、睡觉、漫游、交配
enum State { IDLE, EATING, PLAYING, SLEEPING, WANDERING, MATING }
## 宠物漫游的水域层级
enum WanderLayer { TOP, MIDDLE, BOTTOM, ALL }

# 将待机时间作为导出变量，默认值为3秒
@export var idle_duration: float = 1.5
# 新增：觅食时的加速倍率
@export var sprint_speed_multiplier: float = 2.0

#region 共有变量
#当前宠物的状态
var current_state: int = State.WANDERING
#endregion

#region 私有变量
var _parent_pet: Pet
# 状态处理函数字典
var _state_functions: Dictionary[int,Callable] = {}
# 运动组件
var _movement_comp: MovementComponent
# 记录前一个状态
var _previous_state: int = State.IDLE
# 待机计时器
var _idle_timer: float = 0.0
# 觅食最小距离
var _food_detection_distance: float = 200.0
# 觅食冷却计时器
var _eat_cooldown_timer: float = 0.0

# 食物检测计时器
var _food_check_timer: float = 0.0
var _food_check_interval: float = 0.5

#endregion


func initialize(pet_node: Pet):
	_parent_pet = pet_node
	_state_functions[State.IDLE] = _state_idle
	_state_functions[State.EATING] = _state_eating
	_state_functions[State.PLAYING] = _state_playing
	_state_functions[State.SLEEPING] = _state_sleeping
	_state_functions[State.WANDERING] = _state_wandering
	_state_functions[State.MATING] = _state_mating
	#运动组件
	_movement_comp = _parent_pet.movement_comp
	#其他属性设定
	_food_detection_distance = _parent_pet.wander_rank.size.x * 0.5  #觅食最小距离是漫游范围的50%

	# 初始化：默认进入漫游状态，速度为正常速度
	_movement_comp.speed = _parent_pet.pet_data.speed


func update_state(delta: float):
	var function_to_call = _state_functions.get(current_state)
	if function_to_call:
		function_to_call.call(delta)


func change_state(new_state: int):
	# 这个函数只负责状态的纯粹切换，不处理任何行为
	if current_state != new_state:
		# 在状态切换前，将当前状态保存为前一个状态
		_previous_state = current_state
		current_state = new_state

		print("Pet state changed to: ", State.keys()[current_state])


# --- 状态处理函数 ---


#漫游状态
func _state_wandering(delta: float):
	# 更新觅食冷却计时器
	if _eat_cooldown_timer > 0:
		_eat_cooldown_timer -= delta
	# 如果冷却结束，则检查食物
	else:
		_check_food(delta)

	# 检查宠物是否已经到达了当前目标位置
	if _movement_comp and _movement_comp.target_pos.is_zero_approx():
		# 如果没有食物，执行正常的漫游逻辑
		var new_pos: Vector2 = PetManager.create_position(_parent_pet)
		_movement_comp.set_target(new_pos)
	# 检查其他状态转换条件


# 更新食物检测计时器
func _check_food(delta: float) -> void:
	_food_check_timer += delta
	# 每隔一段时间检查是否有食物，并优先处理
	if _food_check_timer >= _food_check_interval:
		_food_check_timer = 0
		var closest_food = find_closest_food()
		if closest_food and is_instance_valid(closest_food):
			_parent_pet.target = closest_food
			# 宠物发现食物后加速
			_movement_comp.speed = _parent_pet.pet_data.speed * sprint_speed_multiplier
			change_state(State.EATING)
			return  # 找到食物，直接返回，不执行当前状态的逻辑


# 觅食状态
func _state_eating(delta: float):
	# 如果有食物目标，则向其移动
	if _parent_pet.target and is_instance_valid(_parent_pet.target):
		_movement_comp.set_target(_parent_pet.target.position)

		# 检查是否到达食物位置
		if _parent_pet.position.distance_to(_parent_pet.target.position) < 20.0:
			# 宠物吃掉食物，移除食物节点
			_parent_pet.target.queue_free()
			_parent_pet.target = null
			# 宠物吃掉食物后还原速度
			_movement_comp.speed = _parent_pet.pet_data.speed
			# 重置觅食冷却计时器
			_eat_cooldown_timer = _parent_pet.pet_data.eat_cooldown_duration
			# 切换回之前的状态
			change_state(_previous_state)
	else:
		# 如果食物被其他宠物吃掉或已无效，切换回之前的状态
		_movement_comp.speed = _parent_pet.pet_data.speed
		# 没吃上重置觅食冷却计时器为0.0
		_eat_cooldown_timer = 0.0
		_parent_pet.target = null
		change_state(_previous_state)


func _state_idle(delta: float):
	# 检查饥饿度、配偶等条件，触发状态切换
	# 关键修改：处理待机计时器
	_idle_timer -= delta
	if _idle_timer <= 0:
		_parent_pet.pet_sprite.material["shader_parameter/outlineWidth"] = 0.0
		# 从待机状态切换到漫游前，设置正常速度
		_movement_comp.speed = _parent_pet.pet_data.speed
		change_state(_previous_state)

	pass


func _state_playing(delta: float):
	pass


func _state_sleeping(delta: float):
	pass


func _state_mating(delta: float):
	# 调用交配组件的更新方法
	pass


# 寻找最近的食物
func find_closest_food() -> Node2D:
	# 假设所有食物节点都加入了 "food" 组
	var food_list = get_tree().get_nodes_in_group("food")

	var closest_food: Node2D = null
	var min_distance: float = INF

	for food_item in food_list:
		if is_instance_valid(food_item):
			var distance = _parent_pet.position.distance_to(food_item.position)
			if distance < min_distance:
				min_distance = distance
				closest_food = food_item

	# 只有当食物在一定范围内才算找到
	if min_distance < _food_detection_distance:
		return closest_food

	return null
