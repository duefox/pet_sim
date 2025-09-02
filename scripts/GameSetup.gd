extends Node2D

@onready var fish_tank: FishTank = $FishTank
@onready var fps_label: Label = $UI/Control/MarginContainer/FPSLabel


@export var init_fish_cout: int = 1
# 预加载不同鱼类的数据资源
# 在编辑器中，你可以将这些资源文件拖入到导出的变量中
@export var goldfish_data: Resource = preload("res://data/pet_data/goldfish.tres")
@export var angelfish_data: Resource = preload("res://data/pet_data/angelfish.tres")

# 存放所有鱼类数据资源的数组
var all_fish_data: Array


func _ready():
	# 确保所有单例都已加载
	await get_tree().process_frame

	# 将所有鱼类数据添加到数组中
	all_fish_data = [goldfish_data, angelfish_data]

	# 调用 PetManager 创建初始鱼群
	initialize_fish_population()

	#var abc: Vector2 = Vector2(0, 1).reflect(Vector2(0.0, -1.0))
	#print("abc:",abc.normalized())


func _process(_delta: float) -> void:
	fps_label.text = "FPS:" + str(floori(Engine.get_frames_per_second()))


func initialize_fish_population():
	# 根据设置的初始数量创建鱼
	for i in range(init_fish_cout):
		# 随机选择一个鱼类数据
		var random_data = all_fish_data[randi() % all_fish_data.size()]
		# 漫游的范围
		var bounds: Rect2 = fish_tank.wander_rank
		# 随机生成一个位置
		var random_pos = Vector2(randf_range(bounds.position.x, bounds.position.x + bounds.size.x), randf_range(bounds.position.y, bounds.position.y + bounds.size.y))
		# 调用 PetManager 的方法创建宠物
		PetManager.create_pet(random_data, random_pos, bounds)

	print("Initial fish population created: ", init_fish_cout)
