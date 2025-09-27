extends Node2D
class_name Player

## 网格容器数据组件
var backpack_comp: BackpackComponent
var inventory_comp: InventoryComponent
var quick_tools_comp: QuickToolsComponent
var world_map_comp: WorldMapComponent
var landscape_comp: LandscpeComponent
## 游戏玩家数据，测试：map_size先写到这里，正式添加player时候需要根据用户选择的地图大小设定
var player_info: Dictionary[String,Variant] = {
	"qt_size": Vector2i(10, 1),
	"bag_size": Vector2i(12, 6),
	"inven_size": Vector2i(16, 10),
	"map_size": Vector2i(38, 38),
	"landscape_size": Vector2i(2, 10),
}


func _ready() -> void:
	# 设置全局玩家
	GlobalData.player = self
	# 数据组件
	backpack_comp = find_child("BackpackComponent")
	inventory_comp = find_child("InventoryComponent")
	quick_tools_comp = find_child("QuickToolsComponent")
	world_map_comp = find_child("WorldMapComponent")
	landscape_comp = find_child("LandscpeComponent")
	# 注册需要序列化的属性
	SaveSystem.register_saveable_node(self)
	SaveSystem.register_saveable_node(backpack_comp)
	SaveSystem.register_saveable_node(inventory_comp)
	SaveSystem.register_saveable_node(quick_tools_comp)
	SaveSystem.register_saveable_node(world_map_comp)
	SaveSystem.register_saveable_node(landscape_comp)
	# 订阅事件
	EventManager.subscribe(UIEvent.ITEMS_CHANGED, _on_items_changed)
	EventManager.subscribe(UIEvent.CREATE_NEW_SAVE, _on_create_new_save)


func _exit_tree() -> void:
	EventManager.unsubscribe(UIEvent.ITEMS_CHANGED, _on_items_changed)
	EventManager.unsubscribe(UIEvent.CREATE_NEW_SAVE, _on_create_new_save)


## 用于存档的序列化方法
func save() -> Dictionary:
	var save_data: Dictionary = {}
	save_data["info"] = player_info
	return save_data


## 用于读档的反序列化方法
func load_data(data: Dictionary) -> void:
	player_info = data.get("info", {})
	# 数据加载完毕后，也需要发出事件，让UI更新
	EventManager.emit_event(UIEvent.UPDATE_PLAYER_INFO)


## 清空所有序列化的数据
func clear_all() -> void:
	backpack_comp.clear_all_data()
	inventory_comp.clear_all_data()
	quick_tools_comp.clear_all_data()
	world_map_comp.clear_all_data()
	landscape_comp.clear_all_data()


## 玩家手动刷新数据
func reflush_data() -> void:
	backpack_comp.reflush_data()
	inventory_comp.reflush_data()
	quick_tools_comp.reflush_data()
	world_map_comp.reflush_data()
	landscape_comp.reflush_data()


## 创建存档成功
func _on_create_new_save() -> void:
	# 初始化默认物品
	if quick_tools_comp:
		quick_tools_comp.init_data()
	# 初始化默认地图
	if world_map_comp:
		# 初始化地图数据
		world_map_comp.init_data(player_info.get("map_size", Vector2i(38, 38)))
		pass

	# 发送创建初始化地图成功信号
	EventManager.emit_event(UIEvent.CREATE_MAP_SUCCESS)


## 物品容器发生变化，同步数据给玩家的数据组件（保证玩家数据的一致性）
func _on_items_changed(msg: Dictionary) -> void:
	if msg.is_empty():
		return
	if not msg.has("container"):
		return
	var container: MultiGridContainer = msg.get("container")
	var items: Array[WItem] = container.items
	# 更新数据
	if container.name == "Packback":
		backpack_comp.update_items_data(items)
	elif container.name == "Inventory":
		inventory_comp.update_items_data(items)
	elif container.name == "QuickTools":
		quick_tools_comp.update_items_data(items)
	elif container.name == "WorldGrid":
		world_map_comp.update_items_data(items)
	elif container.name == "Landscpe":
		world_map_comp.update_items_data(items)
