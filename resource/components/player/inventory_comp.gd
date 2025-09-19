extends Node
class_name InventoryComponent

## 信号：当物品数据发生变化时发出，UI会监听此信号进行更新
signal inventory_changed(items_data: Array)

## 存储物品数据的数组
## 注意：这里只存储WItemData资源，不存储UI节点实例
var items_data: Array[WItemData] = []
var grid_col: int = 6
var grid_row: int = 5

## 初始化
func _ready():
	# 示例：加载一些初始物品数据
	add_item_with_merge("1001", 3)
	add_item_with_merge("2001", 1)


## 增删改查物品的方法
## (示例方法，您可以根据需要实现更多)
## @param item_id: 物品ID
## @param num: 数量
func add_item_with_merge(item_id: String, num: int = 1) -> bool:
	var item_dict = GlobalData.find_item_data(item_id)
	if not item_dict:
		return false
	
	# 实现物品查找、堆叠、放置等核心逻辑
	# ... (逻辑省略)
	
	# 假设您已将物品数据添加到 `items_data` 数组中
	# 当数据变化时，发出信号
	emit_signal("inventory_changed", items_data)
	return true


## 用于存档的序列化方法
func save() -> Dictionary:
	var save_data: Dictionary = {}
	save_data["items"] = items_data
	return save_data


## 用于读档的反序列化方法
func load_save_data(data: Dictionary) -> void:
	items_data = data.get("items", [])
	# 当数据加载完毕后，发出信号以通知UI更新
	emit_signal("inventory_changed", items_data)
