extends Control
class_name PetRoom

## 墙纸
@onready var wall_paper: NinePatchRect = %WallPaper
## 可以用空间
@onready var space_label: Label = %SpaceLabel
## 动物面板容器
@onready var pets_container: VBoxContainer = %PetsContainer
## 建筑边框
@onready var build_border: NinePatchRect = %BuildBorder
## 放置宠物的节点
@onready var contents_node: Node2D = %ContentsNode
## 放置宠物的前置玻璃层或者水层
@onready var contents_rank: ColorRect = %ContentsRank
## 激活清洁环境
@onready var btn_clean: ButtonSmall = %BtnClean

## 宠物的场景资源
@export var pet_scene: PackedScene
## 掉落物场景（食物）
@export var drop_scene: PackedScene
## 掉落物资源（食物资源，根据玩家选择切换）
@export var drop_data: DroppableData
## 动物漫游的范围
@export var wander_rank: Rect2
## 房间id
var room_id: String = ""
## 首部坐标
var head_position: Vector2
## 容器唯一ID
var container_id: String
## 鼠标是否进入房间
var mouse_in_room: bool = false

## 缓存一下房间数据
var _cache_room_data: Dictionary
## 点击的位置
var _mouse_coords: Vector2


func _ready():
	await get_tree().process_frame
	# 为每个容器实例分配一个唯一的ID
	container_id = str(hash(self.get_path()))
	var wander_pos: Vector2 = contents_node.position
	var form: Vector2 = Vector2(wander_pos.x, wander_pos.y + GlobalData.cell_size)
	wander_rank = Rect2(form, Vector2(contents_rank.size.x - form.x * 2, contents_rank.size.y - form.y * 2))

	# 订阅事件
	EventManager.subscribe(UIEvent.WORLD_MAP_CHANGED, _on_world_map_changed)


func _exit_tree() -> void:
	EventManager.unsubscribe(UIEvent.WORLD_MAP_CHANGED, _on_world_map_changed)


## 更新视觉
func update_pet_view(data: Dictionary = {}, head_pos: Vector2 = -Vector2.ONE) -> void:
	if data.is_empty() or not data.has("item_info"):
		return
	_cache_room_data = data
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


## 更新宠物
func update_pets(pets_data: Array = []) -> void:
	init_pets(pets_data)
	return
	#if mouse_in_room:
	#init_pets(pets_data, _mouse_coords)
	#else:
	#init_pets(pets_data)


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


## 添加宠物到容器
func add_pet(pet_instance: Pet):
	if contents_node:
		contents_node.add_child(pet_instance)
		# 设置自己的顶层容器（房间）
		pet_instance.pet_room = self
		# 将容器ID传递给宠物，以便它知道在哪里查找食物
		pet_instance.set_container_id(container_id)
		# 将宠物添加到以容器ID命名的组中
		pet_instance.add_to_group("pet_" + container_id)


# 从容器移除宠物
func remove_pet(pet_instance: Pet):
	if contents_node and pet_instance.get_parent() == contents_node:
		pet_instance.get_parent().remove_child(pet_instance)


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


## 世界数据更新事件
func _on_world_map_changed(_data: Dictionary = {}) -> void:
	print("_on_world_map_changed")
	var room_data: Dictionary = GlobalData.player.world_map_comp.find_item_data(room_id, head_position)
	# 数据没变化直接返回
	if room_data == _cache_room_data:
		return
	# 获得差异的数据
	# 更新墙纸
	if room_data.get("wall_paper", null) == _cache_room_data["wall_paper"]:
		update_wall_paper(room_data.get("wall_paper", null))
	# 更新造景
	update_landscape(Utils.get_array_difference(room_data.get("landscape_data", []), _cache_room_data["landscape_data"]))
	# 更新宠物
	update_pets(Utils.get_array_difference(room_data.get("pets_data", []), _cache_room_data["pets_data"]))
	# 更新食物
	update_foods(Utils.get_array_difference(room_data.get("foods_data", []), _cache_room_data["foods_data"]))


func _on_btn_back_pressed() -> void:
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
func _on_contents_rank_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_right"):
		var local_pos = contents_rank.get_local_mouse_position() - Vector2(contents_rank.position.x, contents_rank.position.y / 2.0)
		_mouse_coords = local_pos
		spawn_droppable_object(local_pos, drop_data)
