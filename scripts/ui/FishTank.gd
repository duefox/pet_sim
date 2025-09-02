# FishTank.gd
extends Node2D
class_name FishTank

@onready var water_rank: ColorRect = $WaterRank
@onready var fish_area: Node2D = $FishArea

@export var food_data: FoodData
@export var food_scene: PackedScene
@export var wander_rank: Rect2

var food_list: Array = []


func _ready() -> void:
	var wander_coords: Vector2 = water_rank.global_position
	wander_rank = Rect2(Vector2(wander_coords.x, wander_coords.y + water_rank.size.y * 0.1), Vector2(water_rank.size.x, water_rank.size.y * 0.9))
	EventManager.subscribe(GameEvent.FOOD_EATEN, _on_food_eaten)


func _exit_tree() -> void:
	EventManager.unsubscribe(GameEvent.FOOD_EATEN, _on_food_eaten)


func _on_water_rank_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_right"):
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		var food:Food = food_scene.instantiate()
		food.global_position = mouse_pos
		food.data = food_data
		fish_area.add_child(food)
		food_list.append(food)
		
		#将食物节点添加到 "food" 组
		food.add_to_group("food")


## 宠物吃掉食物
func _on_food_eaten(food: Node):
	if food in food_list:
		food_list.erase(food)
	food.queue_free()
