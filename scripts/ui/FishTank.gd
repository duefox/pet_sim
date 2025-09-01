# FishTank.gd
extends Node2D
class_name FishTank

@onready var water_rank: ColorRect = $WaterRank
@onready var fish_area: Node2D = $FishArea

@export var food_scene: PackedScene
@export var wander_rank: Rect2

# 食物列表，用于宠物寻找目标
var food_list: Array[Food] = []


func _ready() -> void:
	var wander_coords: Vector2 = water_rank.global_position
	wander_rank = Rect2(Vector2(wander_coords.x, wander_coords.y + water_rank.size.y * 0.1), Vector2(water_rank.size.x, water_rank.size.y * 0.9))


func _on_water_rank_gui_input(event: InputEvent) -> void:
	# 检查事件是否为定义的 "mouse_right" 动作
	if event.is_action_pressed("mouse_right"):
		# 获取鼠标在世界坐标系中的位置
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		# 创建食物实例
		var food: Food = food_scene.instantiate()
		food.position = mouse_pos

		# 将食物添加到主场景中，并加入食物列表
		fish_area.add_child(food)
		food_list.append(food)

		# 新增：将食物节点添加到 "food" 组
		food.add_to_group("food")


func remove_food(food: Food):
	if food in food_list:
		food_list.erase(food)
	food.queue_free()
