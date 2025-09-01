extends MovementComponent
class_name FishMovementComp

##组件模拟鱼类运动的轨迹

#碰撞冷却时间变量
var _collision_cooldown_duration: float = 0.2
var _collision_cooldown_timer: float = 0.0


## 平滑转向运动
func _steer_towards(delta: float) -> void:
	super(delta)
	var target_angle: float = (target_pos - parent_pet.position).angle()
	current_angle = lerp_angle(current_angle, target_angle, parent_pet.pet_data.turn_rate)
	#钳制角度在 -PI 和 PI 之间
	current_angle = wrapf(current_angle, -PI, PI)
	#限制旋转的角度，优雅转向
	var diff_angle: float = clamp_angle_to_valid_ranges(current_angle, PI / 10)
	# 根据当前角度旋转精灵图
	if parent_pet.pet_sprite:
		parent_pet.pet_sprite.rotation = diff_angle
		#-90°~90°，-180°~-90°，90°~180°
		if current_angle > -PI / 2 and current_angle < PI / 2:
			parent_pet.pet_sprite.flip_v = false
		else:
			parent_pet.pet_sprite.flip_v = true


## 基础运动
func _baisc_movement(delta: float) -> void:
	super(delta)
	# 始终根据当前角度计算速度
	parent_pet.velocity.x = cos(current_angle) * speed
	parent_pet.velocity.y = sin(current_angle) * speed
	# 执行物理移动
	var collision_info: KinematicCollision2D = parent_pet.move_and_collide(parent_pet.velocity * delta)
	# 减少碰撞冷却计时器
	if _collision_cooldown_timer > 0:
		_collision_cooldown_timer -= delta
	# 处理物理碰撞
	if collision_info:
		_handle_collision(collision_info)


## 物理碰撞检测
func _handle_collision(collision: KinematicCollision2D) -> void:
	# 当冷却计时器结束时才进行碰撞处理
	if _collision_cooldown_timer <= 0:
		#宠物的反弹线速度
		var reflected: Vector2 = parent_pet.velocity.bounce(collision.get_normal())
		#碰到墙壁
		if collision.get_collider() is StaticBody2D:
			_handle_static_body(reflected)
			# 重置碰撞冷却计时器
			_collision_cooldown_timer = _collision_cooldown_duration
		elif collision.get_collider() is RigidBody2D:
			_handle_rigid_body(collision)


## 处理与碰到静态刚体的碰撞（墙壁等等）
func _handle_static_body(reflected: Vector2) -> void:
	current_angle = reflected.angle()
	target_pos = Vector2.ZERO


## 处理与碰到动态刚体的碰撞（玩具）
func _handle_rigid_body(collision: KinematicCollision2D) -> void:
	print(collision)
	pass
