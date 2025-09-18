extends Node2D

@onready var fps_label: Label = %FPSLabel
@onready var fish_tank: PetContainer = $FishTank
@onready var ui: CanvasLayer = $UI

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


## 预加载资源文件
func preload_res() -> void:
	GlobalData.pet_res = _get_res_to_dic("res://data/pet_data/")
	GlobalData.drop_res = _get_res_to_dic("res://data/drop_data/")

	var res_normal: Array = [GlobalData.pet_res, GlobalData.drop_res, ResPaths.SCENE_RES]
	# 处理加载资源文件
	var res: Array = []
	for res_dic: Dictionary in res_normal:
		for i: String in res_dic:
			var res_path: String = res_dic[i]
			res.append(res_path)
	_count = res.size()
	# 加载资源文件
	for j in res:
		ResManager.load_resource(j)


## 获得目录资源并整理成符合要求的字典数据
func _get_res_to_dic(path_folder: String) -> Dictionary[StringName,String]:
	var tmp_dic: Dictionary[StringName,String] = {}
	var files: PackedStringArray = Utils.get_files(path_folder)
	if files.is_empty():
		return {}
	for file: String in files:
		var file_name: String = file.split(".")[0]
		tmp_dic.set(file_name, path_folder + file)
	return tmp_dic


## 资源加载完成
func _on_resource_loaded(_path: String, _resource: Resource) -> void:
	_complete_count += 1
	if _complete_count >= _count:
		_complete_count = 0
		# 预设纹理资源
		_preset_all_textures()
		# 设置UI
		_init_game_ui()
		# 调用 PetManager 创建初始鱼群
		#initialize_fish_population()
	else:
		#更新资源加载进度条
		#print("load:", _complete_count)
		pass


## 设置挂载游戏界面到UI节点
func _init_game_ui() -> void:
	print("_init_game_ui")
	var ui_scene: PackedScene = ResManager.get_cached_resource(ResPaths.SCENE_RES.main_ui)
	var ui_state_machine: UIStateMachine = ui_scene.instantiate()
	ui.add_child(ui_state_machine)
	# 默认切换到首页菜单
	ui_state_machine.change_state(ui_state_machine.State.MAIN_MENU)


## 预加载资源文件中所有的纹理文件（在item_base_data定义了对应的变量）
func _preset_all_textures() -> void:
	# 宠物，掉落物，建筑，造景等资源归一化纹理数据
	var res_normal: Array = [GlobalData.pet_res, GlobalData.drop_res]
	for res_dic: Dictionary in res_normal:
		for i: String in res_dic:
			var res_path: String = res_dic[i]
			var res: Resource = ResManager.get_cached_resource(res_path)
			GlobalData.create_textures_item(res)


func initialize_fish_population():
	#print(ResManager.get_cached_resource(ResPaths.SCENE_RES.food))
	# 把所有宠物资源都取出来
	for path in GlobalData.pet_res.values():
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
