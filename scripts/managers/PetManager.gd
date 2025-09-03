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


## 取消订阅事件
func _exit_tree() -> void:
	EventManager.unsubscribe(GameEvent.PET_GROW_UP, _on_pet_grow_up)
	EventManager.unsubscribe(GameEvent.PET_DEATH, _on_pet_death)
	EventManager.unsubscribe(GameEvent.PET_SELECTED, _on_pet_selected)
	#
	for pet_id in pets:
		var pet = pets[pet_id]
		pet.set_meta("last_growth_timestamp", Time.get_unix_time_from_system())


## 创建宠物
## pet_container宠物所在的容器
## species_data宠物资源数据
## random_pos随机坐标
## wander_rank容器可漫游的范围
func create_pet(pet_container: PetContainer, species_data: Dictionary, random_pos: Vector2, wander_rank: Rect2) -> Node:
	var new_pet: Pet = pet_scene.instantiate()
	pet_id_counter += 1
	new_pet.position = random_pos
	pets[new_pet.id] = new_pet
	# 向宠物容器中添加宠物
	pet_container.add_pet(new_pet)
	new_pet.initialize_pet(pet_id_counter, species_data, randi() % 2, wander_rank)
	# 调用成长函数切换动画
	new_pet.grow_up()
	#设置宠物的初始状态为 WANDERING
	if new_pet.state_machine:
		new_pet.state_machine.change_state(new_pet.state_machine.State.WANDERING)

	return new_pet


## 喂食函数，由外部UI调用
func feed_pet(pet: Pet, food_data: FoodData):
	if pet and pet.hunger_comp:
		pet.hunger_comp.feed(food_data)
	else:
		print("Pet or hunger component not found for feeding.")


### 寻找最近的食物
#func find_closest_food(pet: Pet) -> Node2D:
## 假设所有食物节点都加入了 "food" 组
#var food_list = get_tree().get_nodes_in_group("food")
#
#var closest_food: Node2D = null
#var min_distance: float = INF
#
#for food_item in food_list:
#if is_instance_valid(food_item):
#var distance = pet.position.distance_to(food_item.position)
#if distance < min_distance:
#min_distance = distance
#closest_food = food_item
#
#return closest_food


## 根据id查找宠物
func get_pet_by_id(pet_id: int) -> Pet:
	return pets.get(pet_id)


## 选中宠物
func _on_pet_selected(pet: Pet) -> void:
	if not pet:
		return
	if _current_pet:
		#去掉描边
		_current_pet.pet_sprite.material["shader_parameter/outlineWidth"] = 0.0
		#恢复速度
		_current_pet.movement_comp.speed = _current_pet.pet_data.speed
	#
	_current_pet = pet
	_current_pet.pet_sprite.material["shader_parameter/outlineWidth"] = 2.0
	#显示宠物属性面板


## 宠物成长，由的宠物需要改变形态
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
