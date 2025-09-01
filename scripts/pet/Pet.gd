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
#宠物id
var id: int
#宠物状态机
var state_machine: PetStateMachine
#运动组件
var movement_comp: MovementComponent
#饥饿度组件
var hunger_comp: HungerComponent
#生命周期组件
var lifecycle_comp: LifecycleComponent
#宠物贴图
var pet_sprite: Sprite2D
#食物目标
var target: Food = null
#食物碰撞距离
var target_collision_distance: float = 28.0
#成长时期标志，juvenile, adult, old
var life_stage: PetData.LifeStage
#endregion

#方便显示信息
var info_label: Label

#region 需要存档的变量
#资源属性集合
@export var pet_data: PetData
#性别
@export var gender: PetData.Gender
#饥饿度当前值，0为不饿，100为饥饿
var hunger_level: float = 0.0
#年龄
var age: float = 0.0
#endregion

#region 私有变量区块

#endregion


func _ready():
	movement_comp = find_child("MovementComponent")
	hunger_comp = find_child("HungerComponent")
	lifecycle_comp = find_child("LifecycleComponent")
	state_machine = find_child("PetStateMachine")
	pet_sprite = find_child("Sprite2D")
	info_label = find_child("InfoLabel")
	# 描边shader特效
	pet_sprite.material = ShaderMaterial.new()
	pet_sprite.material.shader = OUTLINE_SHDER
	pet_sprite.material.set_shader_parameter("outlineWidth", 0.0)


func _physics_process(delta: float) -> void:
	#更新移动
	if movement_comp:
		movement_comp.update_movement(delta)
	#更新饥饿度
	if hunger_comp:
		hunger_comp.update_hunger(delta)
	#更新生命周期组件
	if lifecycle_comp:
		lifecycle_comp.update_age(delta)


func _process(delta: float):
	#更新状态机，它会决定宠物的行为
	if state_machine:
		state_machine.update_state(delta)


## 显示一些信息，方便查看调试
func update_info(info: Variant) -> void:
	info_label.text = str(info)


# 新的初始化函数
func initialize_pet(assigned_id: int, data: PetData, assigned_gender: PetData.Gender, wander_bounds: Rect2):
	#初始化数据
	id = assigned_id
	pet_data = data
	gender = assigned_gender
	wander_rank = wander_bounds
	#贴图和动画
	pet_sprite.texture = pet_data.texture
	# 初始化年龄
	age = pet_data.initial_age
	# 初始化生命阶段
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
	#初始化状态机
	if state_machine:
		state_machine.initialize(self)


#宠物成长
func grow_up() -> void:
	if life_stage == PetData.LifeStage.JUVENILE:
		animation_player.play("juvenile")
	else:
		animation_player.play("adult")


#宠物死亡
func death() -> void:
	queue_free()


# 处理输入事件
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# 检查事件是否为定义的 "mouse_left" 动作
	if event.is_action_pressed("mouse_left"):
		print("Pet clicked! Changing state to IDLE.")
		# 调用状态机的change_state函数，将状态切换为IDLE
		state_machine.change_state(state_machine.State.IDLE)
		# 广播弹出宠物属性面板事件
		EventManager.emit_event(GameEvent.PET_SELECTED, self)
