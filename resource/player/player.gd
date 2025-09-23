extends Node2D
class_name Player

#背包数据组件
var backpack_comp: BackpackComponent
var inventory_comp: InventoryComponent
var quick_tools_comp: QuickToolsComponent
var world_map_comp: WorldMapComponent


func _ready() -> void:
	# 设置全局玩家
	GlobalData.player = self
	# 数据组件
	backpack_comp = find_child("BackpackComponent")
	inventory_comp = find_child("InventoryComponent")
	quick_tools_comp = find_child("QuickToolsComponent")
	world_map_comp = find_child("WorldMapComponent")
	# 注册需要序列化的属性
	SaveSystem.register_saveable_node(backpack_comp)
	SaveSystem.register_saveable_node(inventory_comp)
	SaveSystem.register_saveable_node(quick_tools_comp)
	SaveSystem.register_saveable_node(world_map_comp)
	# 订阅事件
	EventManager.subscribe(UIEvent.ITEMS_CHANGED, _on_items_changed)
	EventManager.subscribe(UIEvent.CREATE_NEW_SAVE, _on_create_new_save)


func _exit_tree() -> void:
	EventManager.unsubscribe(UIEvent.ITEMS_CHANGED, _on_items_changed)
	EventManager.unsubscribe(UIEvent.CREATE_NEW_SAVE, _on_create_new_save)


## 清空所有序列化的数据
func clear_all() -> void:
	backpack_comp.clear_all_data()
	inventory_comp.clear_all_data()
	quick_tools_comp.clear_all_data()
	world_map_comp.clear_all_data()


## 创建存档成功
func _on_create_new_save() -> void:
	# 初始化默认物品
	if quick_tools_comp:
		quick_tools_comp.init_data()
	# 初始化默认地图
	if world_map_comp:
		world_map_comp.init_data()

	# 发送创建初始化地图成功信号
	EventManager.emit_event(UIEvent.CREATE_MAP_SUCCESS)


## 物品容器发生变化
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
