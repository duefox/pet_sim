# ExcretionComponent.gd
extends Node
class_name ExcretionComponent

var parent_pet: Pet
## 是否需要排泄的标记
var needs_to_excrete: bool = false:
	set(value):
		needs_to_excrete = value
		# 设置黑板数据关联行为树
		parent_pet.blackboard.set_var("needs_to_excrete", needs_to_excrete)

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
		needs_to_excrete = true
	else:
		needs_to_excrete = false


## 排泄组件状态清除
func clear_excrete_state() -> void:
	# 重置计时器
	_excretion_timer = _excretion_interval
