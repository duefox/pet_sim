extends Node

#游戏天数计时器
@export var game_day_duration: float = 60.0  # 60秒为1游戏天

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
	EventManager.subscribe(GameEvent.PET_EXCRETE, _on_pet_excrete) #宠物排泄


## 取消订阅事件
func _exit_tree() -> void:
	EventManager.unsubscribe(GameEvent.PET_GROW_UP, _on_pet_grow_up)
	EventManager.unsubscribe(GameEvent.PET_DEATH, _on_pet_death)
	EventManager.unsubscribe(GameEvent.PET_SELECTED, _on_pet_selected)
	EventManager.unsubscribe(GameEvent.PET_IS_HUNGRY, _on_pet_hungry)
	EventManager.unsubscribe(GameEvent.PET_EXCRETE, _on_pet_excrete)


# --- 帧更新 ---
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
	#测试
	#_check_for_offline_growth()


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


## 喂食函数，由外部UI调用
func feed_pet(pet: Pet, food_data: FoodData):
	if pet and pet.hunger_comp:
		pet.hunger_comp.feed(food_data)
	else:
		print("Pet or hunger component not found for feeding.")


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


## 根据id查找宠物
func get_pet_by_id(pet_id: int) -> Pet:
	return pets.get(pet_id)


#创建水生动物漫游位置
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


## 饥饿度事件处理函数
func _on_pet_hungry(pet: Pet):
	if pet.state_machine.current_state != pet.state_machine.State.EATING:
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


## 选中宠物
func _on_pet_selected(pet: Pet) -> void:
	if not pet:
		return
	if _current_pet:
		#去掉描边
		_current_pet.pet_sprite.material["shader_parameter/outlineWidth"] = 0.0
		#恢复速度
		_current_pet.movement_comp.speed = _current_pet.pet_data.speed
		#之前的选中宠物恢复原来状态
		_current_pet.state_machine.recover_state()

	_current_pet = pet
	_current_pet.pet_sprite.material["shader_parameter/outlineWidth"] = 2.0
	#显示宠物属性面板


## 宠物成长，由的宠物需要改变形态
func _on_pet_grow_up(pet: Pet) -> void:
	if not pet:
		return
	pet.grow_up()


## 处理排泄事件
func _on_pet_excrete(pet: Pet) -> void:
	# 检查宠物当前状态，避免在关键状态下排泄（如进食、交配等）
	if pet.state_machine.current_state != PetStateMachine.State.EATING and \
	   pet.state_machine.current_state != PetStateMachine.State.MATING:
		pet.state_machine.change_state(PetStateMachine.State.EXCRETING)
		# 发出信号，通知环境处理排泄物
		#EventManager.emit_event(GameEvent.EXCREMENT_CREATED, pet.global_position)
		print("Pet %s just pooped, environment needs to update!" % pet.id)


## 宠物死亡
func _on_pet_death(pet: Pet) -> void:
	if not pet:
		return
	var pet_id: int = pet.id
	pets.erase(pet_id)
	pet.death()
