extends Node

#游戏天数计时器
@export var game_day_duration: float = 60.0  # 60秒为1游戏天

var pets: Dictionary[int,Pet] = {}  # 使用字典存储宠物，方便通过ID查找
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
	for private_id in pets:
		var pet = pets[private_id]
		pet.set_meta("last_growth_timestamp", Time.get_unix_time_from_system())


## 创建宠物
## pet_container宠物所在的容器
## species_data宠物资源数据
## random_pos随机坐标
## wander_area容器可漫游的范围
func create_pet(pet_container: PetRoom, pet_scene: PackedScene, pet_data: Dictionary, random_pos: Vector2, wander_area: Rect2) -> Node:
	var new_pet: Pet = pet_scene.instantiate()
	pet_id_counter += 1
	new_pet.position = random_pos
	pets[pet_id_counter] = new_pet
	# 向宠物容器中添加宠物
	pet_container.add_pet(new_pet)
	new_pet.initialize_pet(pet_id_counter, pet_data, wander_area)
	# 调用成长函数切换动画
	new_pet.grow_up()

	return new_pet


## 通过private_id删除宠物
func remove_pet(private_id: int) -> void:
	if pets.has(private_id):
		var pet: Pet = pets.get(private_id, null)
		if is_instance_valid(pet):
			pet.queue_free()
		pets.erase(private_id)


## 喂食函数，由外部UI调用
func feed_pet(pet: Pet, food_data: FoodData):
	if pet and pet.hunger_comp:
		pet.hunger_comp.feed(food_data)
	else:
		print("Pet or hunger component not found for feeding.")


## 根据id查找宠物
func get_pet_by_id(private_id: int) -> Pet:
	return pets.get(private_id)


## 清空宠物
func clear_pets() -> void:
	pets.clear()
	pet_id_counter = 0
	_current_pet = null


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
	var private_id: int = pet.private_id
	pets.erase(private_id)
	pet.death()
