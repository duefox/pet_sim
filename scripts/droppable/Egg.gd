extends DroppableObject
class_name Egg

# pet_data是资源，和它的生产者的pet_data关联
@export var pet_data: PetData
# 当前孵化级别
@export var hatch_level: float = 0.0
var hatch_timer: float = 0.0


# 当蛋被放置时，初始化
func _ready():
	if pet_data:
		hatch_level = pet_data.hatch_level


# 每帧更新孵化度
func _process(delta: float):
	pass


# 孵化方法
func hatch():
	pass
