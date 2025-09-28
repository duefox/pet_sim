## 玩家背包数据层基类组件
extends Node
class_name BaseBagComponent

## 存储物品数据的数组，每个元素都只包含最少必要的数据
var items_data: Array[Dictionary] = []


## 添加带有额外参数的物品
## @param item_id: 物品id
## @param item_num: 物品数量
## @param extra_args: 物品额外参数
## @param head_pos: 物品坐标
func add_item(item_id: String, item_num: int, extra_args: Dictionary = {}, head_pos: Vector2 = -Vector2.ONE) -> bool:
	# 仅在此处调用一次，获取物品完整数据
	var item_dict = GlobalData.find_item_data(item_id)
	if item_dict.is_empty():
		return false
	#print("add_item:",extra_args)
	var remaining_num: int = item_num
	var added_success: bool = false

	# 确保extra_args中的item_level存在，默认item_dict的值，item_dict的值大于extra_args的键值也设置为默认
	if extra_args.is_empty():
		# 默认级别
		extra_args.set("item_level", item_dict.get("item_level", 0))
		# 默认成长值
		extra_args.set("growth", item_dict.get("growth", 0))
		# 默认方向
		extra_args.set("orientation", item_dict.get("orientation", 0))
		# 动物则随机性别，其他则默认无性别
		if item_dict.get("item_type", BaseItemData.ItemType.OTHERS) == BaseItemData.ItemType.ANIMAL:
			var rng: int = randi_range(BaseItemData.Gender.MALE, BaseItemData.Gender.FEMALE)
			extra_args.set("gender", rng)
		else:
			extra_args.set("gender", item_dict.get("gender", BaseItemData.Gender.NONE))
	else:
		if item_dict.get("item_level", 0) > extra_args.get("item_level", 0):
			extra_args.set("item_level", item_dict.get("item_level", 0))
		if item_dict.get("growth", 0) > extra_args.get("growth", 0):
			extra_args.set("growth", item_dict.get("growth", 0))
		# 方向设置
		if not extra_args.has("orientation"):
			extra_args.set("orientation", item_dict.get("orientation", 0))
		# 性别设置
		if not extra_args.has("gender"):
			# 动物则随机性别，其他则默认无性别
			if item_dict.get("item_type", BaseItemData.ItemType.OTHERS) == BaseItemData.ItemType.ANIMAL:
				var rng: int = randi_range(BaseItemData.Gender.MALE, BaseItemData.Gender.FEMALE)
				extra_args.set("gender", rng)
			else:
				extra_args.set("gender", item_dict.get("gender", BaseItemData.Gender.NONE))

	# 如果是可堆叠物品，先尝试堆叠
	if item_dict.stackable:
		# 调用堆叠方法，并将max_stack_size作为参数传递，返回值是堆叠满后剩余的值，##注意本函数会自动操作已有的数据。##
		remaining_num = _find_stackable_data(item_id, remaining_num, extra_args.get("item_level"), item_dict.max_stack_size)

	# 如果仍有剩余数量，将剩余物品作为新物品添加到背包
	while remaining_num > 0:
		var new_stack_size = min(remaining_num, item_dict.max_stack_size)
		remaining_num -= new_stack_size
		# 创建新物品数据字典
		var new_item_data_dict = {"id": item_id, "num": new_stack_size, "extra_args": extra_args, "head_position": Vector2(-1, -1)}
		if not head_pos == -Vector2.ONE:
			new_item_data_dict.set("head_position", head_pos)
		items_data.append(new_item_data_dict)
		added_success = true

	# 当数据发生变化时，通过事件总线通知所有订阅者
	emit_changed_event(items_data)
	# 如果所有物品都成功添加或堆叠，则返回true
	return added_success or remaining_num == 0


## 清空组件数据
func clear_all_data() -> void:
	items_data.clear()
	# 数据清空完毕后，也需要发出事件，让UI更新
	emit_changed_event(items_data)


## 手动刷新数据
func reflush_data() -> void:
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
		var extra_args: Dictionary = {
			"item_level": item.item_level,
			"growth": item.growth,
			"gender": item.gender,
			"orientation": item.orientation,
		}
		var item_data_dict = {
			"id": item.id,
			"num": item.num,
			"extra_args": extra_args,
			"head_position": item.head_position,
		}
		items_data.append(item_data_dict)


## 当数据发生变化时，通过事件总线通知所有订阅者
## 虚函数，具体实现见子类
func emit_changed_event(_data: Array[Dictionary]) -> void:
	pass


## 第一次创建存档的时候默认创建数据
## 虚函数，具体实现见子类
func init_data(_gird_size: Vector2 = Vector2.ZERO) -> void:
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
