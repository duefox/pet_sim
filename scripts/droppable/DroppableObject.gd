# DroppableObject.gd
extends RigidBody2D
class_name DroppableObject

@export var data: DroppableData

var _sprite: Sprite2D
var _lifetime: float = 0.0


func _ready():
	_sprite = find_child("Sprite2D")
	if data:
		_sprite.texture = data.texture
		_sprite.hframes = data.hframes
		_sprite.vframes = data.vframes
		_sprite.frame = data.frame
		_lifetime = data.lifetime

	# 设置重力影响（Godot 默认重力为 980，这里使用一个更小的数值，看起来更像在水里）
	gravity_scale = 0.05
	# 确保刚体不会一开始就处于休眠状态
	sleeping = false


func _physics_process(delta: float) -> void:
	# 检查食物是否静止，如果是则开始计时
	if is_sleeping():
		# 当 lifetime 为 -1 时，不进行倒计时和删除
		if _lifetime >= 0:
			_lifetime -= delta
			if _lifetime <= 0:
				queue_free()
