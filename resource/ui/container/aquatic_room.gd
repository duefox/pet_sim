## 子类通过PetManager添加宠物，注意每个子类场景继承后的场景要重新设置一下改类的pet_scene
## 该pet_scene关联了宠物的limboai和行为组件（组合模式）
extends PetRoom
class_name AquaticRoom


## 初始化所有宠物
func init_pets(pets_data: Array = [], coords: Vector2 = Vector2.ZERO) -> void:
	super()
	print("init_pets---->",pets_data)
	for pet_data: Dictionary in pets_data:
		# 漫游的范围
		var area: Rect2 = wander_area
		# 随机生成一个位置
		var random_pos: Vector2
		if coords == Vector2.ZERO:
			random_pos = Vector2(randf_range(area.position.x, area.position.x + area.size.x), randf_range(area.position.y, area.position.y + area.size.y))
		else:
			random_pos = coords
		PetManager.create_pet(self, pet_scene, pet_data, random_pos, area)
