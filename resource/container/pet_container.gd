# PetContainer.gd
extends Node2D
class_name PetContainer

@onready var contents_node: Node2D = $ContentsNode
@onready var contents_rank: ColorRect = $ContentsRank

@export var drop_scene: PackedScene
@export var drop_data: DroppableData
@export var wander_rank: Rect2

var container_id: String


func _ready():
	# 为每个容器实例分配一个唯一的ID
	container_id = str(hash(self.get_path()))
	var wander_coords: Vector2 = contents_rank.global_position
	wander_rank = Rect2(Vector2(wander_coords.x, wander_coords.y + contents_rank.size.y * 0.1), Vector2(contents_rank.size.x, contents_rank.size.y * 0.9))

	# 关键修复：直接将GUI输入信号绑定到ContentsRank
	contents_rank.gui_input.connect(_on_gui_input)


# 添加宠物到容器
func add_pet(pet_instance: Pet):
	if contents_node:
		contents_node.add_child(pet_instance)
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
		push_error("Food scene not set in PetContainer.")
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


# 监听用户输入以生成掉落物
func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		#var local_pos = contents_rank.get_local_mouse_position()
		var local_pos: Vector2 = get_viewport().get_mouse_position()
		spawn_droppable_object(local_pos, drop_data)
