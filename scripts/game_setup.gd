extends Node2D

@onready var fps_label: Label = %FPSLabel
@onready var fish_tank: PetContainer = $FishTank

@export var init_fish_cout: int = 13
# 存放所有鱼类数据资源的数组
var all_fish_data: Array

##加载总数
var _count: int = 0
##加载完成计数
var _complete_count: int = 0


func _ready():
	# 确保所有单例都已加载
	await get_tree().process_frame
	#监听资源加载完成事件
	ResManager.resource_loaded.connect(_on_resource_loaded)
	#加载资源
	preload_res()

func _process(_delta: float) -> void:
	fps_label.text = "FPS:" + str(floori(Engine.get_frames_per_second()))


func preload_res() -> void:
	var res_normal: Array = [ResPaths.PET_RES, ResPaths.SCENE_RES]
	#加载普通资源
	var res: Array = []
	for res_dic: Dictionary in res_normal:
		for i: String in res_dic:
			var res_path: String = res_dic[i]
			res.append(res_path)
	_count = res.size()
	for j in res:
		ResManager.load_resource(j)


##资源加载完成
func _on_resource_loaded(_path: String, _resource: Resource) -> void:
	_complete_count += 1
	if _complete_count >= _count:
		_complete_count = 0
		# 调用 PetManager 创建初始鱼群
		initialize_fish_population()
	else:
		#更新资源加载进度条
		pass


func initialize_fish_population():
	#print(ResManager.get_cached_resource(ResPaths.SCENE_RES.food))
	# 把所有宠物资源都取出来
	for path in ResPaths.PET_RES.values():
		var res: Resource = ResManager.get_cached_resource(path)
		var dic: Dictionary = {"path": path, "res": res}
		all_fish_data.append(dic)

	# 根据设置的初始数量创建鱼
	for i in range(init_fish_cout):
		# 随机选择一个鱼类数据
		var random_data = all_fish_data[randi() % all_fish_data.size()]
		# 漫游的范围
		var bounds: Rect2 = fish_tank.wander_rank
		# 随机生成一个位置
		var random_pos = Vector2(randf_range(bounds.position.x, bounds.position.x + bounds.size.x), randf_range(bounds.position.y, bounds.position.y + bounds.size.y))
		# 调用 PetManager 的方法创建宠物
		PetManager.create_pet(fish_tank, random_data, random_pos, bounds)

	print("Initial fish population created: ", init_fish_cout)
