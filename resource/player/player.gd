extends Node2D
class_name Player

#背包数据组件
var backpack_comp: BackpackComponent
var inventory_comp: InventoryComponent
var quick_tools_comp: QuickToolsComponent


func _ready() -> void:
	# 设置全局玩家
	GlobalData.player = self
	# 数据组件
	backpack_comp = find_child("BackpackComponent")
	inventory_comp = find_child("InventoryComponent")
	quick_tools_comp = find_child("QuickToolsComponent")
	# 注册需要序列化的属性
	SaveSystem.register_saveable_node(backpack_comp)
	SaveSystem.register_saveable_node(inventory_comp)
	SaveSystem.register_saveable_node(quick_tools_comp)
	# 订阅事件
	EventManager.subscribe(UIEvent.ITEMS_CHANGED, _on_items_changed)


func _exit_tree() -> void:
	EventManager.unsubscribe(UIEvent.ITEMS_CHANGED, _on_items_changed)


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
