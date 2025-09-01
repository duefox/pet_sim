extends Node

var pets: Dictionary = {}  # 使用字典存储宠物，方便通过ID查找
var pet_scene = preload("res://scenes/pet/aquatic_fish.tscn")
var pet_id_counter = 0

## 当前选中的宠物
var _current_pet: Pet


func _ready():
	# 连接到事件总线，监听UI发出的事件
	EventManager.subscribe(GameEvent.PET_DEATH, _on_pet_death)  #宠物死亡
	EventManager.subscribe(GameEvent.PET_SELECTED, _on_pet_selected)  #宠物被点击选中
	EventManager.subscribe(GameEvent.PET_IS_HUNGRY, _on_pet_hungry)  #宠物饥饿了


## 取消订阅事件
func _exit_tree() -> void:
	EventManager.unsubscribe(GameEvent.PET_DEATH, _on_pet_death)
	EventManager.unsubscribe(GameEvent.PET_SELECTED, _on_pet_selected)
	EventManager.unsubscribe(GameEvent.PET_IS_HUNGRY, _on_pet_hungry) 


# --- 运行时逻辑 ---
func _process(_delta: float):
	# 遍历所有宠物并执行高级行为决策
	for pet_id in pets:
		var pet = pets[pet_id]
		if pet.state_machine.current_state == pet.state_machine.State.IDLE:
			# 在空闲状态下寻找目标
			var target = find_closest_target(pet)
			if target:
				pet.target = target
				pet.state_machine.change_state(pet.state_machine.State.WANDERING)  # 或者其他合适的行为状态


## 创建宠物
func create_pet(species_data: Resource, random_pos: Vector2, wander_rank: Rect2) -> Node:
	var new_pet: Pet = pet_scene.instantiate()
	pet_id_counter += 1
	new_pet.position = random_pos
	pets[new_pet.id] = new_pet
	# 将新宠物添加到场景
	get_tree().get_root().get_node("MainScene").find_child("FishArea").add_child(new_pet)
	new_pet.initialize_pet(pet_id_counter, species_data, ["male", "female"][randi() % 2], wander_rank)
	#设置宠物的初始状态为 WANDERING
	if new_pet.state_machine:
		new_pet.state_machine.change_state(new_pet.state_machine.State.WANDERING)

	return new_pet


## 生成宠物坐标位置
func create_position(pet: Pet) -> Vector2:
	if !pet:
		return Vector2.ZERO
	var coords: Vector2
	# 水生动物
	if pet.pet_data.species == PetData.MainCategory.AQUATIC:
		return _create_aquatic_coords(pet)

	return coords


## 创建水生动物漫游位置
func _create_aquatic_coords(pet: Pet) -> Vector2:
	var bounds = pet.wander_rank
	var new_pos: Vector2
	# 根据当前漫游层级设置 Y 轴范围
	var y_min: float
	var y_max: float
	var height = bounds.size.y
	var start_y = bounds.position.y
	var wander_layer: int = FishData.WanderLayer.ALL
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

	# 关键修复：按照你的思路，通过随机方向和距离计算新位置
	var random_angle = randf_range(-PI / 4, PI / 4)
	var n: int = randi_range(0, 2)  #默认1，4象限
	if n == 0:  #2象限
		random_angle = random_angle - PI
	elif n == 1:  #3象限
		random_angle = PI - random_angle
	var random_distance = randf_range(200, 400)
	var direction_vector = Vector2.from_angle(random_angle)
	new_pos = pet.position + direction_vector * random_distance
	# 钳制新位置在 X 轴的全部范围内和 Y 轴的指定层级内
	new_pos.x = clamp(new_pos.x, bounds.position.x, bounds.position.x + bounds.size.x)
	new_pos.y = clamp(new_pos.y, y_min, y_max)
	return new_pos


func find_closest_target(_pet: Node) -> Node:
	pass
	return null


## 宠物饥饿了
func _on_pet_hungry(pet: Pet) -> void:
	pass


## 选中宠物
func _on_pet_selected(pet: Pet) -> void:
	if _current_pet:
		#去掉描边
		_current_pet.pet_sprite.material["shader_parameter/outlineWidth"] = 0.0
	_current_pet = pet
	_current_pet.pet_sprite.material["shader_parameter/outlineWidth"] = 2.0
	#更新宠物属性面板


## 宠物死亡
func _on_pet_death(pet_id: int):
	if pets.has(pet_id):
		var pet = pets.get(pet_id)
		pets.erase(pet_id)
		pet.queue_free()
