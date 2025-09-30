# LifecycleComponent.gd
extends Node
class_name LifecycleComponent

var parent_pet: Pet


# 初始化生命周期组件
func initialize(pet_node: Pet):
	parent_pet = pet_node
	# 检查并更新生命阶段
	check_for_life_stage_change()


# 添加成长值并检查生命阶段
func add_growth_points(points: float):
	parent_pet.growth_points += points
	check_for_life_stage_change()


# 检查并更新生命阶段
func check_for_life_stage_change():
	var pet_data: PetData = parent_pet.pet_data
	var new_stage: int = parent_pet.life_stage

	if parent_pet.life_stage == PetData.LifeStage.JUVENILE and parent_pet.growth_points >= pet_data.adult_growth_threshold:
		new_stage = PetData.LifeStage.ADULT
		print("Pet %s has grown into an adult!" % parent_pet.pet_id)

	# 如果阶段发生变化，打印信息并更新阶段
	if new_stage != parent_pet.life_stage:
		parent_pet.life_stage = new_stage
		print("Pet %s has entered the %s stage." % [parent_pet.pet_id, PetData.LifeStage.keys()[parent_pet.life_stage]])
		EventManager.emit_event(GameEvent.PET_GROW_UP, parent_pet)


# 新增：预留死亡条件检查函数，请在此处添加你的死亡逻辑
# 触发条件可以是超出水温、酸碱度等
func _check_survival_conditions():
	# TODO: 实现宠物生存条件检查
	pass
