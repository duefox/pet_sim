extends CharacterBody2D
class_name Pet

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var mating: Node2D = $Mating


##描边着色器效果
const OUTLINE_SHDER = preload("res://shaders/outer_line.gdshader")

#region 导出变量区块
## 定义宠物的漫游范围
@export var wander_rank: Rect2
#endregion

#region 共有变量区块
#宠物状态机
var state_machine: PetStateMachine
#运动组件
var movement_comp: MovementComponent
#饥饿度组件
var hunger_comp: HungerComponent
#生命周期组件
var lifecycle_comp: LifecycleComponent
#排泄组件
var excretion_comp: ExcretionComponent
#交配组件
var mating_comp: MatingComponent
#心情组件
var mood_comp: MoodComponent
#宠物贴图
var pet_sprite: Sprite2D
#食物目标
var target: Food = null
#交配繁殖目标
var mate_target: Pet = null
#交配锁定
var mate_lock: bool = false
#交配的坐标
var mate_coords: Vector2 = Vector2.ZERO
#食物碰撞距离
var target_collision_distance: float = 24.0

#endregion

#方便显示信息
var info_label: Label

#region 需要存档的变量
#宠物id
var id: int
#资源属性集合
@export var pet_data: PetData
@export var excrement_scene: PackedScene
@export var excrement_data: DroppableData
#性别
@export var gender: PetData.Gender
#数据路径
var data_path: StringName
#成长时期标志，juvenile, adult
var life_stage: int = PetData.LifeStage.JUVENILE
# 宠物当前的成长值
var growth_points: float = 0.0
#endregion

#region 私有变量区块
# 上次成长的真实世界时间戳
var _last_growth_timestamp: float = 0.0
var _container_id: String
#endregion


func _ready():
	#行为组件
	movement_comp = find_child("MovementComponent")
	hunger_comp = find_child("HungerComponent")
	lifecycle_comp = find_child("LifecycleComponent")
	excretion_comp = find_child("ExcretionComponent")
	mating_comp = find_child("MatingComponent")
	mood_comp = find_child("MoodComponent")
	#宠物状态机
	state_machine = find_child("PetStateMachine")
	#宠物属性
	pet_sprite = find_child("Sprite2D")
	info_label = find_child("InfoLabel")
	# 描边shader特效
	pet_sprite.material = ShaderMaterial.new()
	pet_sprite.material.shader = OUTLINE_SHDER
	pet_sprite.material.set_shader_parameter("outlineWidth", 0.0)
	# 隐藏交配动画
	show_mate_animate()
	# 确保在首次运行时也保存时间戳
	_store_initial_timestamps()


func _exit_tree() -> void:
	# 在宠物被移除时，保存当前时间戳到元数据
	set_meta("last_growth_timestamp", Time.get_unix_time_from_system())


func _physics_process(delta: float) -> void:
	#更新移动
	if movement_comp:
		movement_comp.update_movement(delta)
	#更新饥饿度
	if hunger_comp:
		hunger_comp.update_hunger(delta)
	#更新排泄组件
	if excretion_comp:
		excretion_comp.update_excretion(delta)
	#更新状态机，它会决定宠物的行为
	if state_machine:
		state_machine.update_state(delta)
	#测试
	update_info()
	check_for_offline_growth()


# 处理输入事件
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# 检查事件是否为定义的 "mouse_left" 动作
	if event.is_action_pressed("mouse_left"):
		print("Pet clicked! Changing state to IDLE.")
		# 调用状态机的change_state函数，将状态切换为IDLE
		state_machine.change_state(state_machine.State.IDLE)
		# 设置待机时长
		state_machine.idle_timer = state_machine.idle_duration
		# 设置移动组件的速度为0
		movement_comp.speed = 0.0
		# 广播弹出宠物属性面板事件
		EventManager.emit_event(GameEvent.PET_SELECTED, self)


## 设置容器ID
func set_container_id(cid: String):
	_container_id = cid


## 显示一些信息，方便查看调试
func update_info() -> void:
	var state_label: String = str(state_machine.State.keys()[state_machine.current_state])
	state_label = state_label.to_lower()
	info_label.text = " g:" + str(gender) + " s:" + state_label


## 新的初始化函数
## @param assigned_id:宠物的id
## @param data:宠物数据字典，包含资源和资源的路径
## @param assigned_gender:宠物的性别
## @param wander_bounds:漫游范围
func initialize_pet(assigned_id: int, data: Dictionary, assigned_gender: PetData.Gender, wander_bounds: Rect2):
	#初始化数据
	id = assigned_id
	data_path = data["path"]
	pet_data = data["res"]
	gender = assigned_gender
	wander_rank = wander_bounds
	#贴图和动画
	pet_sprite.texture = pet_data.texture
	# 初始化成长值
	growth_points = pet_data.growth
	life_stage = PetData.LifeStage.JUVENILE

	#初始化运动组件
	if movement_comp:
		movement_comp.initialize(self)
	#初始化饥饿度组件
	if hunger_comp:
		hunger_comp.initialize(self)
	#初始生命周期组件
	if lifecycle_comp:
		lifecycle_comp.initialize(self)
	#初始化排泄组件
	if excretion_comp:
		excretion_comp.initialize(self)
	#初始化交配组件
	if mating_comp:
		mating_comp.initialize(self)
	#初始化心情组件
	if mood_comp:
		mood_comp.initialize(self)
	#初始化状态机
	if state_machine:
		state_machine.initialize(self)

	# 在创建新宠物时，保存初始时间戳到元数据
	set_meta("last_growth_timestamp", Time.get_unix_time_from_system())
	#在所有组件初始化后，检查离线成长
	check_for_offline_growth()


## 宠物成长动画,切换贴图
func grow_up() -> void:
	if life_stage == PetData.LifeStage.JUVENILE:
		pet_sprite.texture=pet_data.texture
	else:
		pet_sprite.texture=pet_data.adult_texture


## 是否显示交配动画
func show_mate_animate(show: bool = false) -> void:
	mating.visible = show


## 生成宠物坐标位置
func create_position() -> Vector2:
	var coords: Vector2
	# 水生动物
	if pet_data.species == PetData.MainCategory.AQUATIC:
		return _create_aquatic_coords()

	return coords


## 宠物死亡
func death() -> void:
	queue_free()


# 离线成长计算逻辑
func check_for_offline_growth():
	# 从父节点获取游戏天数时长，假设父节点是 PetManager
	if not PetManager:
		print("Warning: Pet not managed by a PetManager, offline growth may not work.")
		return

	var game_day_duration = PetManager.game_day_duration

	# 从元数据获取上次保存的时间戳，如果不存在则使用当前时间
	var last_timestamp = get_meta("last_growth_timestamp", Time.get_unix_time_from_system())
	var current_timestamp = Time.get_unix_time_from_system()

	var elapsed_time = current_timestamp - last_timestamp

	# 计算离线期间经过了多少个“游戏天”
	var days_passed = floor(elapsed_time / game_day_duration)

	if days_passed > 0:
		if life_stage == PetData.LifeStage.JUVENILE:
			var total_growth = days_passed * pet_data.daily_growth_points
			lifecycle_comp.add_growth_points(total_growth)
			print("Pet %s was offline for %d game days and gained %f growth points." % [id, days_passed, total_growth])
		# 更新元数据，记录新的时间戳，避免重复计算
		set_meta("last_growth_timestamp", last_timestamp + days_passed * game_day_duration)


# 处理饥饿事件，开始觅食
func on_pet_is_hungry():
	# 只有在漫游状态下才会去进食
	if state_machine.current_state == PetStateMachine.State.WANDERING:
		var closest_food = find_closest_food()
		if closest_food and is_instance_valid(closest_food):
			self.target = closest_food
			movement_comp.speed = pet_data.speed * state_machine.sprint_speed_multiplier
			state_machine.change_state(PetStateMachine.State.EATING)
			#print("Pet is hungry and found food!")
		else:
			#print("Pet is hungry but no food found in its container.")
			pass


## 查找范围限定在宠物所在的父节点（即容器）下
func find_closest_food() -> Node2D:
	if _container_id.is_empty():
		return null

	var food_group_name = "food_" + _container_id
	var food_list = get_tree().get_nodes_in_group(food_group_name)
	if food_list.is_empty():
		return null

	var closest_food: Node2D = null
	var min_distance: float = INF

	for food_item in food_list:
		if is_instance_valid(food_item):
			var distance = position.distance_to(food_item.position)
			if distance < min_distance:
				min_distance = distance
				closest_food = food_item

	return closest_food


## 宠物排泄逻辑
func on_pet_excrete():
	state_machine.change_state(PetStateMachine.State.EXCRETING)


## 排泄动作，由状态机调用
func spawn_excrement():
	# 使用容器的通用方法生成排泄物
	var container = get_parent().get_parent()  # 获取 PetContainer 节点
	if container is PetContainer:
		container.spawn_droppable_object(global_position, excrement_data)

	print("Pet %s just pooped!" % self.id)


## 查找容器内合适的交配对象
func find_mate() -> Pet:
	# 1. 确保自己能交配，并且没有被锁定
	if not mating_comp.can_mate() or mate_lock:
		return null

	# 2. 使用分组获取同容器内的所有宠物
	var pet_group_name = "pet_" + _container_id
	var all_pets = get_tree().get_nodes_in_group(pet_group_name)

	var closest_mate: Pet = null
	var min_distance: float = INF

	for pet_candidate: Pet in all_pets:
		# 3. 检查候选宠物是否为有效宠物，且满足交配条件
		if (
			pet_candidate != self
			and is_instance_valid(pet_candidate)
			and pet_candidate is Pet
			and pet_candidate.mating_comp.can_mate()
			and pet_candidate.gender != self.gender
			and pet_candidate.mate_target == null
			and pet_candidate.data_path == data_path  #物种相同，同一个资源
			and not pet_candidate.mate_lock
		):
			var distance = position.distance_to(pet_candidate.position)
			if distance < min_distance:
				min_distance = distance
				closest_mate = pet_candidate

	return closest_mate


## 产蛋动作
func spawn_egg():
	# 使用容器的通用方法生成后代
	var container = get_parent().get_parent()  # 获取 PetContainer 节点
	if container is PetContainer:
		container.spawn_droppable_object(global_position, pet_data.descendant_res, pet_data)

	print(">>>Pet %s is spawning an egg!" % self.id)


## 创建水生动物漫游位置
func _create_aquatic_coords() -> Vector2:
	var bounds = wander_rank
	var new_pos: Vector2
	# 根据当前漫游层级设置 Y 轴范围
	var y_min: float
	var y_max: float
	var height = bounds.size.y
	var start_y = bounds.position.y
	# 从 PetData 中获取 live_layer
	var wander_layer: int = (pet_data as FishData).live_layer
	match wander_layer:
		FishData.WanderLayer.TOP:
			y_min = start_y
			y_max = start_y + height * 0.33
		FishData.WanderLayer.MIDDLE:
			y_min = start_y + height * 0.34
			y_max = start_y + height * 0.67
		FishData.WanderLayer.BOTTOM:
			y_min = start_y + height * 0.68
			y_max = start_y + height
		FishData.WanderLayer.ALL:
			y_min = start_y
			y_max = start_y + height

	# 通过随机方向和距离计算新位置
	var random_angle = randf_range(-PI / 4, PI / 4)
	var n: int = randi_range(0, 2)  #默认1，4象限
	if n == 0:  #2象限
		random_angle = random_angle - PI
	elif n == 1:  #3象限
		random_angle = PI - random_angle
	var random_distance = randf_range(200, 400)
	var direction_vector = Vector2.from_angle(random_angle)
	new_pos = self.position + direction_vector * random_distance
	# 钳制新位置在 X 轴的全部范围内和 Y 轴的指定层级内
	new_pos.x = clamp(new_pos.x, bounds.position.x, bounds.position.x + bounds.size.x)
	new_pos.y = clamp(new_pos.y, y_min, y_max)
	return new_pos


# 当没有保存数据时，为宠物设置初始时间戳
func _store_initial_timestamps():
	if not has_meta("last_growth_timestamp"):
		set_meta("last_growth_timestamp", Time.get_unix_time_from_system())
