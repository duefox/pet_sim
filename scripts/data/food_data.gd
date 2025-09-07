extends DroppableData
class_name FoodData

#食性
enum FoodType {
	ALL,
	OMNIVORES,  #杂食性
	CARNIVORES,  #肉食性
	HERBIVORES,  #草食性
	SCAVENGERS,  #腐食性
}
#食物特有属性
@export_group("Special attribute")
#食物类型
@export var food_type: FoodType = FoodType.ALL
#食物饱食度
@export var hunger_restore_amount: float = 20.0
#每种食物提供的成长值
@export var growth_points: float = 10.0
