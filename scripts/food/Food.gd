# Food.gd
extends RigidBody2D
class_name Food

@export var food_data: FoodData
# 食物生命周期计时器，单位为秒
@export var lifetime: float = 200.0

#宠物贴图
var food_sprite: Sprite2D


func _ready():
	food_sprite = find_child("Sprite2D")
	food_sprite.texture = food_sprite.texture  #贴图和动画
	
	# 设置重力影响（Godot 默认重力为 980，这里使用一个更小的数值，看起来更像在水里）
	gravity_scale = 0.05
	
	# 确保刚体不会一开始就处于休眠状态
	sleeping = false


func _physics_process(delta: float) -> void:
	# 检查食物是否静止，如果是则开始计时
	if is_sleeping():
		lifetime -= delta
		if lifetime <= 0:
			queue_free()
