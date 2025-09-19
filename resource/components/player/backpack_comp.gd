## 玩家背包数据层组件
extends Node
class_name BackpackComponent

## 存储物品数据的数组
## 注意：这里只存储WItemData资源，不存储UI节点实例
var items_data: Array[WItemData] = []


## 初始化
func _ready():
	# 注册需要序列化的属性
	SaveSystem.register_saveable_node(self)
	# 示例：加载一些初始物品数据
	add_item_with_merge("1001", 3)
	add_item_with_merge("2001", 1)
	pass


## 添加带有额外参数的物品
## @param item_id: 物品id
## @param item_num: 物品数量
## @param extra_args: 物品额外参数
func add_item_with_merge(item_id: String, item_num: int, extra_args: Dictionary = {}) -> bool:
	var item_dict = GlobalData.find_item_data(item_id)
	if item_dict.is_empty():
		return false
	#
	
	

	# 假设您已将物品数据添加到 `items_data` 数组中
	# 当数据变化时，发出信号
	EventManager.emit_event(UIEvent.BACKPACK_CHANGED, items_data)
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
	EventManager.emit_event(UIEvent.BACKPACK_CHANGED, items_data)
