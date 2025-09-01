extends Resource
class_name FoodData

#食性
enum FoodType {
	ALL,
	OMNIVORES,  #杂食性
	CARNIVORES,  #肉食性
	HERBIVORES,  #草食性
	SCAVENGERS,  #腐食性
}

@export_group("Base info")
@export var food_type: FoodType = FoodType.ALL

##动画贴图相关信息
@export_group("Texture & Aimate")
#贴图
@export var texture: Texture2D
@export var hframes: int = 4
@export var vframes: int = 4
@export var frame: int = 0
