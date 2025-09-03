extends Node
class_name MovementComponent

# 移动速度
@export var speed: float = 100.0:
	set(value):
		speed = value
		#print("update speed:", speed)

var parent_pet: Pet  #宠物对象
var target_pos: Vector2  #移动的目标位置
var current_angle: float = 0  #当前角度速度


## 初始化
func initialize(pet_node: Pet):
	parent_pet = pet_node
	if parent_pet and parent_pet.pet_data:
		current_angle = parent_pet.pet_data.initial_angle
		speed = parent_pet.pet_data.speed


# 运动更新函数
func update_movement(delta: float):
	# 确保父节点已初始化
	if not parent_pet or not parent_pet.pet_data:
		return
	# 如果已经到达目标，立即重置目标
	if target_pos != Vector2.ZERO and parent_pet.position.distance_to(target_pos) < parent_pet.target_collision_distance:
		# 修复：到达目标后，调用 clear_target 清空目标
		clear_target()
	# 根据是否有目标来选择转向行为
	if target_pos != Vector2.ZERO:
		_steer_towards(delta)
	# 基础运动
	_baisc_movement(delta)


# 设定移动目标
func set_target(pos: Vector2):
	#print("new positon:", pos)
	target_pos = pos


## 清空移动目标
func clear_target():
	target_pos = Vector2.ZERO


## 目标位置是否无效
func is_target_invalid() -> bool:
	return target_pos.is_zero_approx()


## 钳制角度到指定范围
func clamp_angle_to_valid_ranges(angle: float, clamp_size: float = PI / 4) -> float:
	# 将角度标准化到 -PI 到 PI
	var normalized_angle = fmod(angle + PI, 2 * PI) - PI

	# 定义有效区间（弧度）
	# -45 到 45 度: [-PI/4, PI/4]
	# 135 到 180 度: [3PI/4, PI]
	# -180 到 -135 度: [-PI, -3PI/4]

	if normalized_angle >= -clamp_size and normalized_angle <= clamp_size:
		# 在第一个有效区间
		return normalized_angle
	elif normalized_angle >= PI - clamp_size and normalized_angle <= PI:
		# 在第二个有效区间
		return normalized_angle
	elif normalized_angle >= -PI and normalized_angle <= clamp_size - PI:
		# 在第三个有效区间
		return normalized_angle
	else:
		# 否则，找到最近的边界角度并返回
		var dist_a = abs(normalized_angle - clamp_size)
		var dist_b = abs(normalized_angle - PI + clamp_size)
		var dist_c = abs(normalized_angle + clamp_size)
		var dist_d = abs(normalized_angle + PI - clamp_size)
		var dist_e = abs(normalized_angle - PI)
		var dist_f = abs(normalized_angle - (-PI))

		var min_dist = min(dist_a, dist_b, dist_c, dist_d, dist_e, dist_f)

		if min_dist == dist_a:
			return clamp_size
		if min_dist == dist_b:
			return PI - clamp_size
		if min_dist == dist_c:
			return -clamp_size
		if min_dist == dist_d:
			return clamp_size - PI
		if min_dist == dist_e:
			return PI
		if min_dist == dist_f:
			return -PI

	return normalized_angle


## 虚函数--基础运动
func _baisc_movement(_delta: float) -> void:
	pass


## 虚函数--平滑转向运动
func _steer_towards(_delta: float) -> void:
	pass
