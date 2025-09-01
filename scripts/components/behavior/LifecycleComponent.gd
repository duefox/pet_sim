extends Node
class_name LifecycleComponent

var parent_pet: Pet


# 初始化生命周期组件
func initialize(pet_node: Pet):
	parent_pet = pet_node
	if parent_pet and parent_pet.pet_data is PetData:
		var pet_data: PetData = parent_pet.pet_data
		if parent_pet.age >= pet_data.old_age:
			parent_pet.life_stage = PetData.LifeStage.OLD
		elif parent_pet.age >= pet_data.adult_age:
			parent_pet.life_stage = PetData.LifeStage.ADULT
		else:
			parent_pet.life_stage = PetData.LifeStage.JUVENILE

	print("adult:",parent_pet.pet_data.adult_age)

# 每帧更新年龄
func update_age(delta: float):
	# 增加年龄
	parent_pet.age += delta
	parent_pet.update_info(floori(parent_pet.age))
	# 检查并更新生命阶段
	var pet_data: PetData = parent_pet.pet_data
	var new_stage: int = parent_pet.life_stage

	if parent_pet.age >= pet_data.death_age:
		new_stage = PetData.LifeStage.DEAD
		print("Pet %s has died of old age." % parent_pet.id)
		EventManager.emit_event(GameEvent.PET_DEATH, parent_pet)
	elif parent_pet.age >= pet_data.old_age:
		new_stage = PetData.LifeStage.OLD
	elif parent_pet.age >= pet_data.adult_age:
		new_stage = PetData.LifeStage.ADULT

	# 如果阶段发生变化，打印信息并更新阶段
	if new_stage != parent_pet.life_stage:
		parent_pet.life_stage = new_stage
		print("Pet %s has entered the %s stage." % [parent_pet.id, PetData.LifeStage.keys()[parent_pet.life_stage]])
		EventManager.emit_event(GameEvent.PET_GROW_UP, parent_pet)
