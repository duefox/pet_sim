extends Control
class_name PetRoom

## 墙纸
@onready var wall_paper: NinePatchRect = %WallPaper
## 可以用空间
@onready var space_label: Label = %SpaceLabel
## 动物面板容器
@onready var pets_container: VBoxContainer = %PetsContainer
## buffer容器
@onready var buffers_container: HBoxContainer = %BuffersContainer
## 建筑边框
@onready var build_border: NinePatchRect = %BuildBorder
## 放置宠物的节点
@onready var contents_node: Node2D = %ContentsNode
## 放置宠物的前置玻璃层或者水层
@onready var contents_rank: ColorRect = %ContentsRank
## 激活清洁环境
@onready var btn_clean: ButtonSmall = %BtnClean
## 漫游范围形状
@onready var wander_shape: CollisionShape2D = %WanderShape
## 批量放回按钮
@onready var btn_to_bag: ButtonSmall = %BtnToBag

## 宠物信息场景
const PET_INFO_SCENE: PackedScene = preload("res://resource/ui/widgets/container/w_pet_info.tscn")
## 放回模式
enum PUTBACK_MODE { INVENTORY, BLACKPACK }

## 宠物的场景资源
@export var pet_scene: PackedScene
## 掉落物场景（食物）
@export var drop_scene: PackedScene
## 掉落物资源（食物资源，根据玩家选择切换）
@export var drop_data: DroppableData
## 动物漫游的范围
@export var wander_area: Rect2
## 房间id
var room_id: String = ""
## 首部坐标
var head_position: Vector2
## 容器唯一ID
var container_id: String
## 鼠标是否进入房间
var mouse_in_room: bool = false

## 当前的放回模式为放回仓库
var current_putback_mode: PUTBACK_MODE = PUTBACK_MODE.INVENTORY:
	set(value):
		current_putback_mode = value
		if current_putback_mode == PUTBACK_MODE.INVENTORY:
			btn_to_bag.text = "批量放回仓库"
		else:
			btn_to_bag.text = "批量放回背包"

## 缓存一下房间数据
var _cache_room_data: Dictionary
## 点击的位置
var _mouse_coords: Vector2
## 宠物筛选过滤，默认都显示
var _filter_states: Array = [true, true, true, true, true, true]
## 宠物面板数据字典
var _pets_info: Dictionary[int,WPetInfo]


func _ready():
	await get_tree().process_frame
	# 为每个容器实例分配一个唯一的ID
	container_id = str(hash(self.get_path()))
	var form: Vector2 = Vector2.ZERO
	wander_area = Rect2(form, wander_shape.shape.get_rect().size)

	# 订阅事件


func _exit_tree() -> void:
	pass


## 更新视觉
func update_pet_view(data: Dictionary = {}, head_pos: Vector2 = -Vector2.ONE) -> void:
	if data.is_empty() or not data.has("item_info"):
		return
	# 清空房间所有物品和状态
	_clear_all_items()
	# 缓存数据
	_cache_room_data = data.duplicate(true)
	# 等一帧再执行，确保画面相关的参数已设定完成
	await get_tree().process_frame
	room_id = data["id"]
	head_position = head_pos
	# 根据设置的初始数量创建鱼，房间内的物品在字典内
	# 4层数据，分别是wall_paper墙纸，landscape_data造景数据,pets_data动物数据和foods_data食物数据
	if data.has("wall_paper"):
		# 更新墙纸
		update_wall_paper(data["wall_paper"])
	if data.has("landscape_data"):
		# 更新墙纸
		update_landscape(data["landscape_data"])
	if data.has("pets_data"):
		# 更新宠物
		update_pets(data["pets_data"])
	if data.has("foods_data"):
		# 更新宠物
		update_foods(data["foods_data"])

	await get_tree().process_frame
	# 更新左侧显示列表，注意这里是根据PetManager中已经添加的pets来显示
	_update_left_pets_list(PetManager.pets)
	# 更新房间的空间占用显示
	space_label.text = _comput_room_space(data)


## 更新宠物
func update_pets(pets_data: Array = []) -> void:
	init_pets(pets_data)


## 新增宠物
func append_pet(item_data: Dictionary, mouse_pos: Vector2) -> void:
	init_pets([item_data], contents_node.to_local(mouse_pos))
	# 更新宠物面板列表
	_update_left_pets_list(PetManager.pets)


## 更新食物
func update_foods(foods_data: Array = []) -> void:
	if foods_data.is_empty():
		return


## 更新造景
func update_landscape(landscape_data: Array = []) -> void:
	if landscape_data.is_empty():
		return


## 更新墙纸
func update_wall_paper(paper: Texture2D) -> void:
	if is_instance_valid(paper):
		wall_paper.texture = paper


## 初始化所有宠物
## 具体请在子类实现
func init_pets(pets_data: Array = [], _coords: Vector2 = Vector2.ZERO) -> void:
	if pets_data.is_empty():
		return


## 添加宠物实体到房间
func add_pet(pet_instance: Pet):
	if contents_node:
		contents_node.add_child(pet_instance)
		# 设置自己的顶层容器（房间）
		pet_instance.pet_room = self
		# 将容器ID传递给宠物，以便它知道在哪里查找食物
		pet_instance.set_container_id(container_id)
		# 将宠物添加到以容器ID命名的组中
		pet_instance.add_to_group("pet_" + container_id)


## 移除该宠物的实体和面板（包含批量操作）
func remove_pet(msg: Dictionary) -> void:
	var pets_data: Array = msg.get("data", [])
	if pets_data.is_empty():
		return
	for data: PetData in pets_data:
		var private_id: int = data.private_id
		# 删除面板
		if _pets_info.has(private_id):
			_pets_info.erase(private_id)
		# 删除实体
		PetManager.remove_pet(private_id)

	# 更新宠物面板列表
	_update_left_pets_list(PetManager.pets)

	# 同步更新world map的数据
	var info: Dictionary = {
		"room_id": room_id,
		"head_position": head_position,
		"pets": PetManager.pets,
	}
	EventManager.emit_event(UIEvent.ROOM_ITEM_CHANGED, info)


## 在容器内生成掉落物（如食物排泄物）
## [coords] 掉落物的位置
## [data] 掉落物的资源属性，食物和排泄物都是DroppableData类型，蛋是PetData类型
func spawn_droppable_object(coords: Vector2, data: DroppableData, pet_data: PetData = null):
	if not drop_scene:
		push_error("Food scene not set in PetRoom.")
		return null

	# 掉落物实列和场景
	var droppable_instance: DroppableObject
	var droppable_scene: PackedScene

	# 根据类型和容器ID将掉落物添加到对应的组
	var group_name = ""
	match data.kind:
		DroppableData.Kind.FOOD:
			droppable_scene = ResManager.get_cached_resource(ResPaths.SCENE_RES.food)
			droppable_instance = droppable_scene.instantiate()
			group_name = "food_" + container_id
		DroppableData.Kind.EXCREMENT:
			droppable_scene = ResManager.get_cached_resource(ResPaths.SCENE_RES.excrement)
			droppable_instance = droppable_scene.instantiate()
			group_name = "excrement_" + container_id
		DroppableData.Kind.EGG:
			droppable_scene = ResManager.get_cached_resource(ResPaths.SCENE_RES.egg)
			droppable_instance = droppable_scene.instantiate()
			group_name = "egg_" + container_id
			#蛋的孵化信息为宠物的信息
			droppable_instance.hatch_data = pet_data

	# 添加到对应的组
	droppable_instance.add_to_group(group_name)
	# 掉落位置和信息
	droppable_instance.data = data
	droppable_instance.global_position = coords
	contents_node.add_child(droppable_instance)

	return droppable_instance


## 切换放回模式
func toggle_putback_mode() -> void:
	if current_putback_mode == PUTBACK_MODE.INVENTORY:
		current_putback_mode = PUTBACK_MODE.BLACKPACK
	else:
		current_putback_mode = PUTBACK_MODE.INVENTORY


## 世界数据更新事件
func _on_world_map_changed(data: Dictionary = {}) -> void:
	var room_data: Dictionary = GlobalData.player.world_map_comp.find_item_data(room_id, head_position, data.get("items_data", []))
	# 数据没变化直接返回
	if room_data == _cache_room_data:
		return
	# 获得差异的数据
	# 更新墙纸
	if room_data.get("wall_paper", null) == _cache_room_data["wall_paper"]:
		update_wall_paper(room_data.get("wall_paper", null))
	# 更新造景
	var append_landscape: Array = Utils.get_array_difference(room_data.get("landscape_data", []), _cache_room_data["landscape_data"])
	update_landscape(append_landscape)
	# 更新宠物
	var append_pets: Array = Utils.get_array_difference(room_data.get("pets_data", []), _cache_room_data["pets_data"])
	update_pets(append_pets)
	# 更新食物
	var tmp_food: Array = Utils.get_array_difference(room_data.get("foods_data", []), _cache_room_data["foods_data"])
	# 食物是可以堆叠的物品，需要求原房间相同食物的数量差值
	var append_food: Array = _get_append_food_in_room(_cache_room_data["foods_data"], tmp_food)
	update_foods(append_food)

	## 更新缓存数据
	_cache_room_data = room_data.duplicate(true)


## 食物是可以堆叠的物品，需要求原房间相同食物的数量差值
func _get_append_food_in_room(room_food: Array, diff_food: Array) -> Array:
	var room_dict: Dictionary
	var diff_dict: Dictionary
	for food: Dictionary in room_food:
		room_dict[food["id"]] = food
	for food: Dictionary in diff_food:
		diff_dict[food["id"]] = food

	for id: String in diff_dict:
		# 相同id的食物
		if room_dict.has(id):
			# 更新食物的数量
			var num: int = int(diff_dict.get("num", 0)) - int(room_dict.get("num", 0))
			num = max(0, num)
			if num == 0:
				diff_dict.erase(id)
			else:
				diff_dict.set("num", num)

	return diff_dict.keys()


## 更新左侧宠物信息的显示列表
func _update_left_pets_list(pets_data: Dictionary) -> void:
	# 清空宠物面板列表
	for child in pets_container.get_children():
		child.queue_free()
	# 添加宠物面板
	for pet: Pet in pets_data.values():
		var pet_info: WPetInfo = PET_INFO_SCENE.instantiate()
		pets_container.add_child(pet_info)
		pet_info.update_pet_info(pet.pet_data)
		_pets_info[pet_info.private_id] = pet_info


## 计算房间还可以放下宠物的空间大小
func _comput_room_space(item_data: Dictionary) -> String:
	var pets_data: Array = item_data.get("pets_data", [])
	var room_size: int = item_data["width"] * item_data["height"]
	var use_space: int = 0
	for data: Dictionary in pets_data:
		var space: int = data["width"] * data["height"]
		use_space += space

	return str(use_space) + "/" + str(room_size)


## 清理房间旧的物品和状态
func _clear_all_items() -> void:
	# 清空房间容器的宠物
	for child in contents_node.get_children():
		child.queue_free()
	# 清空buffers
	#for child in buffers_container.get_children():
	#child.queue_free()


## 筛选显示隐藏宠物面板
func _filter_pets() -> void:
	# 遍历宠物面板容器中的所有子节点
	for pet_info: WPetInfo in pets_container.get_children():
		var pet_level: int = pet_info.pet_level  # 从 WPetInfo 获取宠物等级
		var is_audlt: bool = pet_info.is_adult()  # 宠物是否成年
		var is_show1: bool = false  # 等级筛选结果
		var is_show2: bool = false  # 成长阶段筛选结果

		# 检查宠物等级是否匹配当前开启的过滤器 (is_show1)
		# 1. 宠物等级 0 (普通 - BASIC)
		if pet_level == BaseItemData.ItemLevel.BASIC and _filter_states[0]:
			is_show1 = true
		# 2. 宠物等级 1 (稀有 - MAGIC)
		elif pet_level == BaseItemData.ItemLevel.MAGIC and _filter_states[1]:
			is_show1 = true
		# 3. 宠物等级 2 (罕见 - EPIC)
		elif pet_level == BaseItemData.ItemLevel.EPIC and _filter_states[2]:
			is_show1 = true
		# 4. 宠物等级 3 (传说 - MYTHIC)
		elif pet_level == BaseItemData.ItemLevel.MYTHIC and _filter_states[3]:
			is_show1 = true

		# 检查宠物成长值是否匹配当前开启的过滤器 (is_show2)
		# 1. 幼年 (索引 4)
		if not is_audlt and _filter_states[4]:
			is_show2 = true
		# 2. 成年 (索引 5)
		elif is_audlt and _filter_states[5]:
			is_show2 = true

		# 设置宠物信息面板的可见性，必须同时满足 等级筛选 (is_show1) 和 成长阶段筛选 (is_show2)
		pet_info.visible = is_show1 and is_show2

		#print("private_id:", pet_info.pet_data.private_id, ",pet_level:", pet_level, ",is_audlt:", is_audlt, ",is_show:", is_show1 and is_show2)


func _on_btn_back_pressed() -> void:
	PetManager.clear_pets()
	queue_free()


func _on_btn_clean_toggled(_toggled_on: bool) -> void:
	pass  # Replace with function body.


## 鼠标进入房间
func _on_rank_mouse_entered() -> void:
	mouse_in_room = true


## 鼠标离开房间
func _on_rank_mouse_exited() -> void:
	mouse_in_room = false


## 监听用户输入以生成掉落物
func _on_contents_rank_gui_input(event: InputEventMouse) -> void:
	if event.is_action_pressed("mouse_right"):
		# 注意掉落物是添加到contents_node，需要转换坐标
		_mouse_coords = contents_node.to_local(event.global_position)
		spawn_droppable_object(_mouse_coords, drop_data)


## 模式切换
func _on_btn_dir_left_pressed() -> void:
	toggle_putback_mode()


## 模式切换
func _on_btn_dir_right_pressed() -> void:
	toggle_putback_mode()


## 批量放回仓库或背包
func _on_btn_to_bag_pressed() -> void:
	# 获取显示列表的所有WPetInfo
	var pets_data: Array = []
	for pet_info: WPetInfo in pets_container.get_children():
		pets_data.append(pet_info.pet_data)

	# 发送信号
	if current_putback_mode == PUTBACK_MODE.INVENTORY:
		EventManager.emit_event(UIEvent.PUTBACK_TO_INVENTORY, {"data": pets_data})
	else:
		EventManager.emit_event(UIEvent.PUTBACK_TO_BLACKPACK, {"data": pets_data})


## 批量出售
func _on_btn_sell_pressed() -> void:
	pass  # Replace with function body.


## 过滤切换 普通
func _on_basic_check_toggled(toggled_on: bool) -> void:
	_filter_states[0] = toggled_on
	_filter_pets()


## 过滤切换 稀有
func _on_magic_check_toggled(toggled_on: bool) -> void:
	_filter_states[1] = toggled_on
	_filter_pets()


## 过滤切换 罕见
func _on_epic_check_toggled(toggled_on: bool) -> void:
	_filter_states[2] = toggled_on
	_filter_pets()


## 过滤切换 传说
func _on_mythic_check_toggled(toggled_on: bool) -> void:
	_filter_states[3] = toggled_on
	_filter_pets()


## 过滤切换 幼小
func _on_young_check_toggled(toggled_on: bool) -> void:
	_filter_states[4] = toggled_on
	_filter_pets()


## 过滤切换 成年
func _on_adult_check_toggled(toggled_on: bool) -> void:
	_filter_states[5] = toggled_on
	_filter_pets()
