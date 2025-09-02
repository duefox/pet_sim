extends CharacterBody2D
class_name Pet

@onready var animation_player: AnimationPlayer = $AnimationPlayer

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
#宠物贴图
var pet_sprite: Sprite2D
#食物目标
var target: Food = null
#食物碰撞距离
var target_collision_distance: float = 30.0

#endregion

#方便显示信息
var info_label: Label

#region 需要存档的变量
#宠物id
var id: int
#资源属性集合
@export var pet_data: PetData
#性别
@export var gender: PetData.Gender
#成长时期标志，juvenile, adult
var life_stage: int = PetData.LifeStage.JUVENILE
# 宠物当前的成长值
var growth_points: float = 0.0
#饥饿度当前值，0为不饿，100为饥饿
var hunger_level: float = 0.0
#endregion

#region 私有变量区块
# 上次成长的真实世界时间戳
var _last_growth_timestamp: float = 0.0
#endregion


func _ready():
	#行为组件
	movement_comp = find_child("MovementComponent")
	hunger_comp = find_child("HungerComponent")
	lifecycle_comp = find_child("LifecycleComponent")
	excretion_comp = find_child("ExcretionComponent")
	#宠物状态机
	state_machine = find_child("PetStateMachine")
	#宠物属性
	pet_sprite = find_child("Sprite2D")
	info_label = find_child("InfoLabel")
	# 描边shader特效
	pet_sprite.material = ShaderMaterial.new()
	pet_sprite.material.shader = OUTLINE_SHDER
	pet_sprite.material.set_shader_parameter("outlineWidth", 0.0)

	# 确保在首次运行时也保存时间戳
	_store_initial_timestamps()


func _exit_tree() -> void:
	# 在宠物被移除时，保存当前时间戳到元数据
	set_meta("last_growth_timestamp", Time.get_unix_time_from_system())


func _process(delta: float):
	#更新状态机，它会决定宠物的行为
	if state_machine:
		state_machine.update_state(delta)


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


## 显示一些信息，方便查看调试
func update_info() -> void:
	info_label.text = "h:" + str(floori(hunger_level)) + " sex:" + str(gender) + " g:" + str(floori(growth_points))


# 新的初始化函数
func initialize_pet(assigned_id: int, data: PetData, assigned_gender: PetData.Gender, wander_bounds: Rect2):
	#初始化数据
	id = assigned_id
	pet_data = data
	gender = assigned_gender
	wander_rank = wander_bounds
	#贴图和动画
	pet_sprite.texture = pet_data.texture
	# 初始化成长值
	growth_points = pet_data.initial_growth
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
	#初始化状态机
	if state_machine:
		state_machine.initialize(self)

	# 在创建新宠物时，保存初始时间戳到元数据
	set_meta("last_growth_timestamp", Time.get_unix_time_from_system())
	#在所有组件初始化后，检查离线成长
	check_for_offline_growth()


# 宠物成长动画切换
func grow_up() -> void:
	if life_stage == PetData.LifeStage.JUVENILE:
		animation_player.play("juvenile")
	else:
		animation_player.play("adult")


# 宠物死亡
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


# 当没有保存数据时，为宠物设置初始时间戳
func _store_initial_timestamps():
	if not has_meta("last_growth_timestamp"):
		set_meta("last_growth_timestamp", Time.get_unix_time_from_system())
