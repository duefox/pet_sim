extends CharacterBody2D
class_name Pet

##描边着色器效果
const OUTLINE_SHDER = preload("res://shaders/outer_line.gdshader")

#region 导出变量区块
@export var pet_data: PetData
@export var gender: String
## 定义宠物的漫游范围
@export var wander_rank: Rect2
#觅食目标
@export var food_target: Food = null
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
#宠物贴图
var pet_sprite: Sprite2D
#食物目标
var target: Node2D
#endregion

#region 私有变量区块

#endregion


func _ready():
	movement_comp = find_child("MovementComponent")
	hunger_comp = find_child("HungerComponent")
	state_machine = find_child("PetStateMachine")
	pet_sprite = find_child("Sprite2D")
	# 描边shader特效
	pet_sprite.material = ShaderMaterial.new()
	pet_sprite.material.shader = OUTLINE_SHDER
	pet_sprite.material.set_shader_parameter("outlineWidth", 0.0)


# 新的初始化函数
func initialize_pet(assigned_id: int, data: PetData, assigned_gender: String, wander_bounds: Rect2):
	#初始化数据
	id = assigned_id
	pet_data = data
	gender = assigned_gender
	wander_rank = wander_bounds
	pet_sprite.texture = pet_data.texture  #贴图和动画

	#初始化运动组件
	if movement_comp:
		movement_comp.initialize(self)
	#初始化饥饿度组件
	if hunger_comp:
		hunger_comp.initialize(self)
	#初始化状态机
	if state_machine:
		state_machine.initialize(self)


func _physics_process(delta: float) -> void:
	#更新移动，它会执行状态机决定的行为
	if movement_comp:
		movement_comp.update_movement(delta)
	#更新饥饿度
	if hunger_comp:
		hunger_comp.update_hunger(delta)


func _process(delta: float):
	#更新状态机，它会决定宠物的行为
	if state_machine:
		state_machine.update_state(delta)


# 处理输入事件
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# 检查事件是否为定义的 "mouse_left" 动作
	if event.is_action_pressed("mouse_left"):
		print("Pet clicked! Changing state to IDLE.")
		# 调用状态机的change_state函数，将状态切换为IDLE
		state_machine.change_state(state_machine.State.IDLE)
		# 广播弹出宠物属性面板事件
		EventManager.push_event(GameEvent.PET_SELECTED, self)
