# ExcretionComponent.gd
extends Node
class_name ExcretionComponent

var parent_pet: Pet

# 排泄计时器
var _excretion_timer: float = 0.0

# 每隔多久排泄一次，这个值从 PetData 中获取
var _excretion_interval: float = 0.0


func initialize(pet_node: Pet):
	parent_pet = pet_node
	if parent_pet and parent_pet.pet_data is PetData:
		_excretion_interval = parent_pet.pet_data.excretion_interval
	
	# 初始化计时器
	_excretion_timer = _excretion_interval


func update_excretion(delta: float):
	_excretion_timer -= delta
	
	if _excretion_timer <= 0:
		# 计时器归零，宠物需要排泄
		EventManager.emit_event(GameEvent.PET_EXCRETE, parent_pet)
		# 重置计时器
		_excretion_timer = _excretion_interval
