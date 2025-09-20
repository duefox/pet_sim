## 玩家背包数据层基类组件
extends Node
class_name BaseBagComponent

## 存储物品数据的数组，每个元素都只包含最少必要的数据
var items_data: Array[Dictionary] = []


## 添加带有额外参数的物品
## @param item_id: 物品id
## @param item_num: 物品数量
## @param extra_args: 物品额外参数
func add_item(item_id: String, item_num: int, extra_args: Dictionary = {}) -> bool:
	# 仅在此处调用一次，获取物品完整数据
	var item_dict = GlobalData.find_item_data(item_id)
	if item_dict.is_empty():
		return false

	var remaining_num: int = item_num
	var added_successfully: bool = false

	# 如果是可堆叠物品，先尝试堆叠
	if item_dict.stackable:
		# 确保extra_args中的item_level存在，否则默认为0
		if extra_args.is_empty() or not extra_args.has("item_level"):
			extra_args.set("item_level", 0)

		# 调用堆叠方法，并将max_stack_size作为参数传递
		remaining_num = _find_stackable_data(item_id, remaining_num, extra_args.get("item_level"), item_dict.max_stack_size)

	# 如果仍有剩余数量，将剩余物品作为新物品添加到背包
	while remaining_num > 0:
		var new_stack_size = min(remaining_num, item_dict.max_stack_size)
		remaining_num -= new_stack_size

		# 创建新物品数据字典
		var new_item_data_dict = {
			"id": item_id,
			"num": new_stack_size,
			"extra_args": extra_args,
			# 将head_position设置为占位符，UI层会根据此值来寻找空位
			"head_position": Vector2(-1, -1)
		}

		items_data.append(new_item_data_dict)
		added_successfully = true

	# 当数据发生变化时，通过事件总线通知所有订阅者
	emit_changed_event(items_data)

	# 如果所有物品都成功添加或堆叠，则返回true
	return added_successfully or item_num == 0


## 清空组件数据
func clear_all_data() -> void:
	print("clear_all_data")
	items_data.clear()
	# 数据清空完毕后，也需要发出事件，让UI更新
	emit_changed_event(items_data)


## 用于存档的序列化方法
func save() -> Dictionary:
	#print("正在存档中...")
	var save_data: Dictionary = {}
	save_data["items"] = items_data
	return save_data


## 用于读档的反序列化方法
func load_data(data: Dictionary) -> void:
	#print("已加载存档...")
	items_data = data.get("items", [])
	# 数据加载完毕后，也需要发出事件，让UI更新
	emit_changed_event(items_data)


## 更新数据
func update_items_data(items: Array[WItem]) -> void:
	# 清空数据
	items_data.clear()
	# 从items中更新items_data
	for item: WItem in items:
		# 数据字典
		var item_data_dict = {"id": item.id, "num": item.num, "extra_args": {"item_level": item.item_level, "growth": item.growth}, "head_position": item.head_position}
		items_data.append(item_data_dict)


## 当数据发生变化时，通过事件总线通知所有订阅者
## 虚函数，具体实现见子类
func emit_changed_event(_data: Array[Dictionary]) -> void:
	pass


## 查找可堆叠的数据
## @param item_id: 物品id
## @param num_to_add: 物品数量
## @param item_level: 物品级别
## @param max_stack_size: 最大堆叠数，直接从add_item传递过来
## @return int: 堆叠后剩余的数量
func _find_stackable_data(item_id: String, num_to_add: int, item_level: int, max_stack_size: int) -> int:
	var remaining_num: int = num_to_add

	# 遍历背包中的所有物品数据
	for item in items_data:
		# 检查是否为同一种物品且级别相同
		if item.get("id") == item_id and item.get("extra_args").get("item_level", 0) == item_level:
			var current_num = item.get("num")
			var space_left = max_stack_size - current_num

			# 如果该堆栈还有空间
			if space_left > 0:
				var amount_to_add = min(remaining_num, space_left)
				item["num"] = current_num + amount_to_add
				remaining_num -= amount_to_add

				# 如果所有数量都已添加，则直接返回
				if remaining_num <= 0:
					return 0

	# 返回处理后剩余的数量
	return remaining_num
