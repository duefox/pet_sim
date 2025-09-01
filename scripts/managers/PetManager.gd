extends Node

var pets: Dictionary = {}  # 使用字典存储宠物，方便通过ID查找
var pet_scene = preload("res://scenes/pet/aquatic_fish.tscn")
var pet_id_counter = 0

## 当前选中的宠物
var _current_pet: Pet


func _ready():
	# 连接到事件总线，监听UI发出的事件
	EventManager.subscribe(GameEvent.PET_GROW_UP, _on_pet_grow_up)  #宠物成长
	EventManager.subscribe(GameEvent.PET_DEATH, _on_pet_death)  #宠物死亡
	EventManager.subscribe(GameEvent.PET_SELECTED, _on_pet_selected)  #宠物被点击选中
	EventManager.subscribe(GameEvent.PET_IS_HUNGRY, _on_pet_hungry)  #宠物饥饿了


## 取消订阅事件
func _exit_tree() -> void:
	EventManager.unsubscribe(GameEvent.PET_GROW_UP, _on_pet_grow_up)
	EventManager.unsubscribe(GameEvent.PET_DEATH, _on_pet_death)
	EventManager.unsubscribe(GameEvent.PET_SELECTED, _on_pet_selected)
	EventManager.unsubscribe(GameEvent.PET_IS_HUNGRY, _on_pet_hungry)


# --- 运行时逻辑 ---
func _process(_delta: float):
	# 遍历所有宠物并执行高级行为决策
	for pet_id in pets:
		var pet = pets[pet_id]
		# 修复：只在漫游状态下寻找新目标
		if pet.state_machine.current_state == pet.state_machine.State.WANDERING:
			# 如果宠物已经到达目标位置，则生成新的漫游位置
			if pet.movement_comp.target_pos.is_zero_approx():
				var new_pos: Vector2 = _create_aquatic_coords(pet)
				pet.movement_comp.set_target(new_pos)


## 创建宠物
func create_pet(species_data: Resource, random_pos: Vector2, wander_rank: Rect2) -> Node:
	var new_pet: Pet = pet_scene.instantiate()
	pet_id_counter += 1
	new_pet.position = random_pos
	pets[new_pet.id] = new_pet
	# 将新宠物添加到场景
	get_tree().get_root().get_node("MainScene").find_child("FishArea").add_child(new_pet)
	new_pet.initialize_pet(pet_id_counter, species_data, randi() % 2, wander_rank)
	# 调用成长函数切换动画
	new_pet.grow_up()
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


## 寻找最近的食物
func find_closest_food(pet: Pet) -> Node2D:
	# 假设所有食物节点都加入了 "food" 组
	var food_list = get_tree().get_nodes_in_group("food")

	var closest_food: Node2D = null
	var min_distance: float = INF

	for food_item in food_list:
		if is_instance_valid(food_item):
			var distance = pet.position.distance_to(food_item.position)
			if distance < min_distance:
				min_distance = distance
				closest_food = food_item

	return closest_food


# 新增：创建水生动物漫游位置
func _create_aquatic_coords(pet: Pet) -> Vector2:
	var bounds = pet.wander_rank
	var new_pos: Vector2
	# 根据当前漫游层级设置 Y 轴范围
	var y_min: float
	var y_max: float
	var height = bounds.size.y
	var start_y = bounds.position.y
	# 修复：从 PetData 中获取 live_layer
	var wander_layer: int = (pet.pet_data as FishData).live_layer
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
	new_pos = pet.position + direction_vector * random_distance
	# 钳制新位置在 X 轴的全部范围内和 Y 轴的指定层级内
	new_pos.x = clamp(new_pos.x, bounds.position.x, bounds.position.x + bounds.size.x)
	new_pos.y = clamp(new_pos.y, y_min, y_max)
	return new_pos


func find_closest_target(_pet: Node) -> Node:
	pass
	return null


# 饥饿度事件处理函数
func _on_pet_hungry(pet: Pet):
	# 如果宠物当前不是在进食状态，则让它去觅食
	if pet.state_machine.current_state != pet.state_machine.State.EATING:
		# 修复：直接调用 PetManager 中的 find_closest_food 函数
		var closest_food = find_closest_food(pet)
		if closest_food and is_instance_valid(closest_food):
			pet.target = closest_food
			# 宠物发现食物后加速
			pet.movement_comp.speed = pet.pet_data.speed * pet.state_machine.sprint_speed_multiplier
			pet.state_machine.change_state(pet.state_machine.State.EATING)
			print("Pet is hungry and found food!")
		else:
			#print("Pet is hungry but no food found.")
			pass


# 根据id查找宠物
func get_pet_by_id(pet_id: int) -> Pet:
	return pets.get(pet_id)


## 选中宠物
func _on_pet_selected(pet: Pet) -> void:
	if not pet:
		return
	if _current_pet:
		#去掉描边
		_current_pet.pet_sprite.material["shader_parameter/outlineWidth"] = 0.0
	_current_pet = pet
	_current_pet.pet_sprite.material["shader_parameter/outlineWidth"] = 2.0
	#更新宠物属性面板


#宠物成长，由的宠物需要改变形态
func _on_pet_grow_up(pet: Pet) -> void:
	if not pet:
		return
	pet.grow_up()


## 宠物死亡
func _on_pet_death(pet: Pet) -> void:
	if not pet:
		return
	var pet_id: int = pet.id
	pets.erase(pet_id)
	pet.death()
