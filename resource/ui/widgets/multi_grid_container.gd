extends Control
class_name MultiGridContainer

## 网格容器
@onready var grid_container: GridContainer = %GridContainer
## 摆放覆盖颜色区块
@onready var placement_overlay: ColorRect = %PlacementOverlay
## 滚动容器
@onready var scroll_container: ScrollContainer = %ScrollContainer
## 物品容器
@onready var item_container: Control = %ItemContainer

## 类型颜色枚举
enum TYPE_COLOR { SUCCESS, ERROR, DEF }  # 绿色，代表允许放置  # 红色，代表不允许放置  # 默认颜色

## 定义容器类型，用于验证
enum CONTAINER_TYPE { BACKPACK_INVENTORY_QT, WORLD_LAYOUT }  # 背包、仓库和快捷工具栏  # 世界布局

## 放置提示框显示模式枚举
enum MODE_PLACEMENT_OVERTLAY {
	DEF,  ## 默认模式(鼠标移出容器范围就消失)
	STAY,  ## 停留模式(鼠标移出容器范围后且未进入其他容器，在原容器内仍然保留显示)
}
##  容器的格子行数
@export var grid_row: int = 5
##  容器的格子列数
@export var grid_col: int = 6
##  最多显示多少格
@export var max_scroll_grid: int = 4
## 放置提示框显示模式
@export var placement_overlay_mode: MODE_PLACEMENT_OVERTLAY = MODE_PLACEMENT_OVERTLAY.DEF
## 格子场景
@export var grid_scene: PackedScene
## 物品场景
@export var item_scene: PackedScene
## 容器类型
@export var container_type: CONTAINER_TYPE = CONTAINER_TYPE.BACKPACK_INVENTORY_QT

var cell_size: int = 48  #  容器的格子尺寸
var grid_size: Vector2:  #  多格子容器的大小
	get():
		return Vector2(grid_col, max_scroll_grid) * w_grid_size
var w_grid_size: Vector2  # 格子的大小
## 在容器中的物品
var items: Array[WItem] = []
## 格子映射表, key为格子坐标，value为WItemData
var grid_map: Dictionary[Vector2, WItemData] = {}

## 整理的排序方法
var _sort_func: Dictionary
## 整理点击的次数
var _sort_timers: int = 0
## 缓存每次更新显示的数据，方便重新渲染格子的行列时候更新
var _buffer_items_data: Array[Dictionary] = []


#region 内部方法
func _ready() -> void:
	cell_size = GlobalData.cell_size
	# 整理的排序方法
	_sort_func = {
		0: _sort_by_id,
		1: _sort_by_price,
	}


## 鼠标离开
func _on_mouse_exited() -> void:
	if placement_overlay_mode == MultiGridContainer.MODE_PLACEMENT_OVERTLAY.DEF:
		off_placement_overlay()


## 处理其他输入事件
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton && !event.is_pressed() && event.button_index == MOUSE_BUTTON_LEFT:
		off_placement_overlay()


#endregion

#region 对外公开的方法


## 渲染格子数量
## @param bag_size:背包格子大小
func render_grid(bag_size: Vector2i = Vector2i.ONE, max_scroll: int = 0) -> void:
	#print(self.name, "->render_grid")
	if not bag_size == Vector2i.ONE:
		grid_col = bag_size.x
		grid_row = bag_size.y
	#
	if not max_scroll == 0:
		max_scroll_grid = max_scroll
	# 清空grid container
	_clear_grid_container()
	##  渲染格子
	_init_rend()
	# 获取格子场景的大小
	var w_grid: WGrid = grid_container.get_child(0)
	w_grid_size = w_grid.get_grid_size()
	##  设置滚动区域
	set_scroll_container()
	##  放置区的底色
	placement_overlay.color = _get_type_color()
	## 更新数据
	update_view(_buffer_items_data)


## 从数据组件接收数据并更新UI
## @param new_items_data: 最新的物品数据数组
func update_view(items_data: Array[Dictionary]) -> void:
	#print(self, ",items_data:", items_data)
	#print("------------------------")
	# 先清除当前显示的所有物品节点
	clear_all_items()
	# 数据为空不继续处理数据
	if items_data.is_empty():
		return
	# 缓存数据（引用）
	_buffer_items_data = items_data
	# 根据新的数据数组，重新创建并渲染所有物品节点
	for dict: Dictionary in items_data:
		var head_position: Vector2 = dict.get("head_position", -Vector2.ONE)
		var item_id: String = dict.get("id", "0")
		var item_num: int = dict.get("num", 1)
		var extra_args: Dictionary = dict.get("extra_args", {})
		if head_position == -Vector2.ONE:
			# 自动寻找位置添加
			add_item_with_extra(item_id, item_num, extra_args)
		else:
			# 指定位置添加
			add_new_item_at(head_position, item_id, item_num, extra_args)

	# 数据设置成功后发信号通知数据层
	#print("update_view->in:", self)
	EventManager.emit_event(UIEvent.ITEMS_CHANGED, {"container": self})


## 根据id新建物品并放置到指定坐标的多格子容器中
## @param cell_pos: 物品的网格位置
## @param item_id: 物品的id
## @param item_num: 物品的数量
## @param extra_args: 物品的额外属性
func add_new_item_at(cell_pos: Vector2, item_id: String, item_num: int = 1, extra_args: Dictionary = {}) -> bool:
	var item: WItem = _create_item()
	_set_item_data_at_id(item, item_id, item_num, extra_args)
	return _add_item_at(cell_pos, item)


## 新增一个物品，并自动查找最近的可用位置。
## 新增的个数固定为1个，一般用于不可堆叠物品，可堆叠物品请用add_item_with_merge
## @param item_id: 物品的唯一id
## @param extra_args: 物品的额外属性
func add_item(item_id: String, extra_args: Dictionary = {}) -> bool:
	var item_data: Variant = GlobalData.find_item_data(item_id)
	if not item_data:
		push_error("Item data not found for ID: " + item_id)
		return false
	# 新增的个数固定为1
	item_data.num = 1

	for y in range(grid_row):
		for x in range(grid_col):
			var first_cell_pos: Vector2 = Vector2(x, y)

			# 使用新函数检查该位置是否可以放置
			if _can_place_item(item_data, first_cell_pos):
				# 找到合适位置后，调用现有函数放置物品并返回
				add_new_item_in_data(first_cell_pos, item_data, extra_args)
				return true

	# 如果没有找到任何可用位置，发出信号
	EventManager.emit_event(UIEvent.INVENTORY_FULL, self)
	return false


## 新增物品，如果可合并则堆叠，不需要指定位置
## @param item_id: 物品的唯一id
## @param num: 物品的数量
## @param extra_args: 物品的额外属性
func add_item_with_merge(item_id: String, num: int = 1, extra_args: Dictionary = {}) -> bool:
	var remaining_items: int = num
	var success: bool = false
	# 默认是0级别普通物品
	var new_item_level: int = 0
	if not extra_args.is_empty() and extra_args.has("item_level"):
		new_item_level = extra_args["item_level"]

	# 步骤1: 遍历所有格子，尝试合并到现有物品堆叠中
	for item_data: WItemData in grid_map.values():
		# 如果有物品则堆叠
		if item_data and item_data.link_item:
			var item: WItem = item_data.link_item
			# 检查是否为同种物品、可堆叠且物品级别相同
			if item.id == item_id and item.stackable and item.item_level == new_item_level:
				remaining_items = item.add_num(remaining_items)
				if remaining_items == 0:
					success = true

	# 步骤2: 如果还有剩余物品，则寻找空位并添加新物品
	success = _add_remaining_item(item_id, remaining_items, extra_args)
	return success


## 命令行添加物品
## @param item_id: 物品id
## @param item_num: 物品数量
## @param extra_args: 物品额外参数
func cmd_add_item(item_id: String, item_num: int, extra_args: Dictionary = {}) -> void:
	add_item_with_extra(item_id, item_num, extra_args)


## 添加带有额外参数的物品
## @param item_id: 物品id
## @param item_num: 物品数量
## @param extra_args: 物品额外参数
func add_item_with_extra(item_id: String, item_num: int, extra_args: Dictionary = {}) -> void:
	var res_data: Dictionary = GlobalData.find_item_data(item_id)
	if res_data.is_empty():
		print("数据不能为空！")
		return
	if res_data.stackable:
		# 自动堆叠添加
		add_item_with_merge(item_id, item_num, extra_args)
	else:
		# 自动添加（不可堆叠物品）
		add_item(item_id, extra_args)


## 自动合并所有可堆叠的物品并重新排列
func auto_stack_existing_items() -> void:
	# 1. 临时存储合并后的物品数据，分别用两个变量存储
	var merged_stackable_items: Dictionary[String, Dictionary] = {}
	var non_stackable_items: Array[Dictionary] = []

	var items_cnt: int = item_container.get_child_count()
	if not items_cnt == items.size():
		print("before--->整理->items_cnt:", items_cnt, ",字典大小：", items.size())
		push_error("before物品数据和物品数量不正确！")

	for item: WItem in items:
		var item_data: Dictionary = item.get_data().duplicate(true)
		if item.stackable:
			# 构造唯一的复合键 (ID + 等级)
			var key: String = item.id + "_" + str(item.item_level)
			if not merged_stackable_items.has(key):
				merged_stackable_items[key] = item_data
			else:
				merged_stackable_items[key].num += item_data.num
		else:
			non_stackable_items.append(item_data)

	# 2. 清空当前容器的所有物品和映射表
	clear_all_items()
	# 3. 按照合并后的数据重新创建并放置物品
	var sorted_items: Array[Dictionary] = merged_stackable_items.values()
	sorted_items.append_array(non_stackable_items)
	# 4. 按id和级别排序，优先id是升序，相同id级别按降序排序
	#sorted_items.sort_custom(func(a, b): return int(a.id) * 10 - a.item_level < int(b.id) * 10 - b.item_level)
	_sort_timers += 1
	_sort_timers = _sort_timers % _sort_func.values().size()
	sorted_items.sort_custom(_sort_func[_sort_timers])
	# 5. 处理物品重新添加
	for sorted_item: Dictionary in sorted_items:
		# 6. 注意额外属性，级别和当前成长点
		var extra_args: Dictionary = {
			"item_level": sorted_item["item_level"],
			"growth": sorted_item["growth"],
		}
		if sorted_item.stackable:
			add_item_with_merge(sorted_item.id, sorted_item.num, extra_args)
		else:
			add_item(sorted_item.id, extra_args)

	# 6. 数据整理成功后发信号通知数据层
	print("auto_stack_existing_items->in:", self)
	EventManager.emit_event(UIEvent.ITEMS_CHANGED, {"container": self})


## 扣除指定id的物品数量
## @param item_id: 物品的id
## @param num: 扣除的数量，默认为1
func sub_item(item_id: String, num: int = 1) -> bool:
	# 遍历所有已放置的物品
	for item in items:
		# 检查物品ID是否匹配
		if item.id == item_id:
			item.num -= num
			if item.num <= 0:
				# 如果数量小于等于0，则移除物品
				remove_item(item)
			else:
				# 否则，更新物品标签显示
				item.set_label_data()
			return true  # 找到并扣除成功，返回真

	print("找不到指定ID的物品:", item_id)
	return false  # 没有找到该物品，返回假


## 扣除指定位置物品的数量
## @param cell_pos: 物品的网格位置
## @param num: 扣除的数量，默认为1
func sub_item_at(cell_pos: Vector2, num: int = 1) -> void:
	var item_data: WItemData = get_grid_map_item(cell_pos)
	if item_data and item_data.is_placed:
		var item: WItem = item_data.link_item
		item.num -= num
		# 如果数量小于等于0，则移除物品
		if item.num <= 0:
			# 设置映射数据为未被占用
			set_item_placed(item, false)
			remove_item(item)
		else:
			# 否则，更新物品标签显示
			item.set_label_data()


## 设置放置提示框数据
func set_placement_overlay(type: int, item: WItem, cell_pos: Vector2) -> Vector2:
	var placement_size: Vector2 = item.get_item_size()
	placement_size -= Vector2(item.width, item.height)
	placement_overlay.color = _get_type_color(type)
	placement_overlay.size = placement_size
	var offset: Vector2 = _get_scroll_offset()
	placement_overlay.position = _get_comput_position(cell_pos) - offset
	return placement_overlay.position
	#var global_transform: Transform2D = get_global_transform()
	#return global_transform * placement_overlay.position


## 启用放置提示框
func startup_placement_overlay() -> void:
	placement_overlay.visible = true


## 关闭放置提示框
func off_placement_overlay() -> void:
	placement_overlay.visible = false


## 检查格子是否已被占用
func check_cell(cell_pos: Vector2) -> bool:
	#print("grid_map:", grid_map.size())
	var item_data: WItemData = grid_map.get(cell_pos)
	return item_data.is_placed


## 扫描物品映射表的某块矩形区域，查看是否符合放置条件
func scan_grid_map_area(cell_pos: Vector2, item: WItem) -> bool:
	var width: int = item.width
	var height: int = item.height

	for row in range(height):
		for col in range(width):
			var temp: Vector2 = Vector2(col + cell_pos.x, row + cell_pos.y)
			## 判断是否超出背包格子的边界
			if !check_grid_map_item(temp):
				return false
			## 判断该格子是不是已经被占用
			if check_cell(temp):
				return false
	return true


## 检查坐标在映射表内是否合法
func check_grid_map_item(cell_pos: Vector2):
	if cell_pos.x > grid_col - 1 || cell_pos.y > grid_row - 1:
		return false
	elif cell_pos.x < 0 || cell_pos.y < 0:
		return false
	return true


## 获取格子数据映射表的某项数据
func get_grid_map_item(cell_pos: Vector2) -> WItemData:
	return grid_map.get(cell_pos)


## 设置格子映射表的数据
func set_grid_map_item(cell_pos: Vector2, item: WItem) -> void:
	var width: int = item.width
	var height: int = item.height

	for row in range(height):
		for col in range(width):
			var temp: WItemData = grid_map.get(Vector2(cell_pos.x + col, cell_pos.y + row))
			temp.is_placed = true
			temp.link_item = item
			# 更新相应格子的tool tips文本
			var link_grid: WGrid = temp.link_grid
			var bbcode_text: String = "[b]" + item.item_name + "[/b]\n" + item.descrip
			link_grid.update_tooltip(bbcode_text)


## 根据data新建一个物品并放置到多格子容器中
func add_new_item_in_data(cell_pos: Vector2, data: Dictionary, extra_args: Dictionary = {}) -> bool:
	# 检查格子是否已被占用
	var item_data: WItemData = grid_map.get(cell_pos)
	if item_data and item_data.is_placed:
		return false
	# 是否超边界
	if !check_grid_map_item(cell_pos):
		return false
	var item: WItem = _create_item()
	item.set_data(data, extra_args)

	return _add_item_at(cell_pos, item)


## 计算首部坐标的偏移
func get_first_cell_pos_offset(item: WItem, cell_pos: Vector2) -> Vector2:
	var width: int = item.width
	var height: int = item.height
	var offset: Vector2 = Vector2(cell_pos.x - floori(width / 2.0), cell_pos.y - floori(height / 2.0))
	return offset


## 移除物品
func remove_item(cur_item: WItem) -> void:
	if not is_instance_valid(cur_item):
		return
	#移除背包物品记录
	items.erase(cur_item)
	## 移除映射表的对应数据
	for y in range(int(cur_item.height)):
		for x in range(int(cur_item.width)):
			var cell_pos: Vector2 = cur_item.head_position + Vector2(x, y)
			var item_data: WItemData = grid_map.get(cell_pos)
			# 注意这里需要移除的是有链接对象但是空间未占用的映射对象
			if item_data and !item_data.is_placed:
				item_data.link_item = null
				item_data.is_placed = false
				item_data.link_grid.update_tooltip()
	## 释放该物品的实例化对象
	cur_item.queue_free()
	cur_item = null


## 将物品所对应的映射表格子占用进行更改
func set_item_placed(item: WItem, value: bool) -> void:
	var width: int = item.width
	var height: int = item.height
	var head: Vector2 = item.head_position

	for row in range(height):
		for col in range(width):
			grid_map.get(Vector2(col + head.x, row + head.y)).is_placed = value


## 清除所有物品节点和映射数据
func clear_all_items() -> void:
	for item: WItem in items:
		if is_instance_valid(item):
			item.queue_free()
	# 清空数组
	items.clear()

	# 移除映射表的对应数据
	for item_data in grid_map.values():
		if item_data:
			item_data.is_placed = false
			item_data.link_item = null
			if is_instance_valid(item_data.link_grid):
				item_data.link_grid.update_tooltip("")


##  设置滚动区域
func set_scroll_container(container_size: Vector2 = Vector2.ONE) -> void:
	if container_size == Vector2.ONE:
		container_size = grid_size
	# 有滚动条，则需要给滚动条留空间
	if grid_row > max_scroll_grid:
		scroll_container.custom_minimum_size = container_size + Vector2(0.5, 0.5) * w_grid_size
	else:
		scroll_container.custom_minimum_size = container_size - Vector2(grid_col, 0.0)


#endregion


## 获取背景颜色
func _get_type_color(type: int = 0) -> Color:
	var color_arr: Array[Color] = [Color(&"00be0b62"), Color(&"ff000063"), Color(&"989f9a62")]
	if type < 0 || type >= color_arr.size():
		return color_arr[MultiGridContainer.TYPE_COLOR.DEF]
	return color_arr[type]


## 查找下一个可用的空位
func _get_next_available_position(item_data: Dictionary) -> Vector2:
	# 遍历所有格子，寻找第一个is_placed为false的空位
	for y in range(grid_row):
		for x in range(grid_col):
			var cell_pos: Vector2 = Vector2(x, y)
			if _can_place_item(item_data, cell_pos):
				return cell_pos
	return -Vector2.ONE  # 没有找到可用的位置


## 如果还有剩余物品，则寻找空位并添加新物品
func _add_remaining_item(item_id: String, remaining_items: int, extra_args: Dictionary = {}) -> bool:
	# 添加一个物品，其他的递归添加
	if remaining_items > 0:
		var new_item_data: Variant = GlobalData.find_item_data(item_id)
		if not new_item_data:
			push_error("Item data not found for id: ", item_id)
			return false
		var empty_pos: Vector2 = _get_next_available_position(new_item_data)
		if empty_pos == -Vector2.ONE:
			# 如果没有找到任何可用位置，发出信号
			EventManager.emit_event(UIEvent.INVENTORY_FULL, self)
			return false  # 没有空位了
		new_item_data.num = 1

		# 放置新物品
		var success: bool = add_new_item_in_data(empty_pos, new_item_data, extra_args)
		if not success:
			print("放置失败，中断->empty_pos:", empty_pos)
			return false  # 放置失败，中断

		remaining_items -= 1

		# 步骤3：递归调用add_item_with_merge，直到剩余为0
		if remaining_items > 0:
			add_item_with_merge(item_id, remaining_items, extra_args)

	return true


## 根据坐标放置物品到多格子容器中
func _add_item_at(cell_pos: Vector2, item: WItem) -> bool:
	var is_placed: bool = check_cell(cell_pos)
	if !is_placed:
		## 格子为空时
		if scan_grid_map_area(cell_pos, item):
			# 矩形区域扫描通过时
			item.head_position = cell_pos
			# 把物品添加到items数组
			items.append(item)
			# 设置格子映射表的数据
			set_grid_map_item(cell_pos, item)
			# 将物品节点添加至多格子容器(显示层)
			_append_item_in_cell_matrix(item)
			# 将显示层的对应物品位置进行调整，根据传入的格子坐标
			_set_item_comput_position(cell_pos, item)
			return true
	return false


## 根据id给WItem设置基础数据
func _set_item_data_at_id(item: WItem, item_id: String, item_num: int = 1, extra_args: Dictionary = {}) -> void:
	# 获取基本数据，资源的原始数据，不可修改
	var data: Dictionary = GlobalData.find_item_data(item_id)
	# 最终数据需要从保存的数据中合并覆盖
	var latest_data: Dictionary = _get_latest_data(item_id)
	data.merge(latest_data, true)
	# 更新设置数量
	data.set("num", item_num)
	if data:
		item.set_data(data, extra_args)
	else:
		print("set item data at id 设置数据失败！")


## 从视觉数据中拿取最新数据
func _get_latest_data(item_id: String) -> Dictionary:
	for dict: Dictionary in _buffer_items_data:
		if dict["id"] == item_id:
			return dict.duplicate(true)
	return {}


## 将物品节点添加至多格子容器(显示层)
func _append_item_in_cell_matrix(item: WItem) -> void:
	item_container.add_child(item)
	# 校正旋转
	item.rotation_item(item.orientation)


## 将显示层的对应物品位置进行调整，根据传入的格子坐标
func _set_item_comput_position(cell_pos: Vector2, item: WItem) -> void:
	item.position = _get_comput_position(cell_pos) + item.item_offset / 6.0


## 获取对应格子坐标在显示层中的实际坐标
func _get_comput_position(cell_pos: Vector2) -> Vector2:
	var base: Vector2 = cell_pos * w_grid_size
	return Vector2(base.x - cell_pos.x, base.y - cell_pos.y)


## 检查一个物品是否可以放置在指定位置
func _can_place_item(item: Dictionary, first_cell_pos: Vector2) -> bool:
	# 检查所有被物品占用的格子
	for y in range(int(item.height)):
		for x in range(int(item.width)):
			var current_cell_pos: Vector2 = first_cell_pos + Vector2(x, y)

			# 检查坐标是否超出网格边界
			if current_cell_pos.x >= grid_col or current_cell_pos.y >= grid_row:
				return false

			# 检查字典中是否已存在该位置的映射数据
			var item_data: WItemData = grid_map.get(current_cell_pos)

			# 如果该位置的is_placed为true，则表示格子被占用，不能放置
			if item_data and item_data.is_placed:
				return false

	return true


## 创建实例化的WGrid
func _create_cell() -> WGrid:
	var cell: WGrid = grid_scene.instantiate()
	return cell


## 创建实例化的WItem
func _create_item() -> WItem:
	var item: WItem = item_scene.instantiate()
	item.parent_container = self
	return item


## 初始的格子渲染
func _init_rend() -> void:
	# 更新列数
	grid_container.columns = grid_col

	for i in range(grid_row * grid_col):
		var cell: WGrid = _create_cell()
		cell.parent_cell_matrix = self
		##  自动计算行和列
		var col: int = i % grid_col
		var row: int = floori(i / float(grid_col))

		##  设置格子的行列位置
		cell.cell_pos = Vector2(col, row)
		var item_data: WItemData = WItemData.new(cell.cell_pos, cell, null)

		##  存储格子引用到映射表
		grid_map.set(cell.cell_pos, item_data)

		##  添加到背包网格的节点中
		grid_container.add_child(cell)

	##  control节点不会自动更新，需手动更新size
	size = Vector2(grid_col * GlobalData.cell_size, grid_row * GlobalData.cell_size)


## 清空格子容器的格子
func _clear_grid_container() -> void:
	for child in grid_container.get_children():
		child.queue_free()


## 滚动条的偏移量
func _get_scroll_offset() -> Vector2:
	return Vector2(scroll_container.scroll_horizontal, scroll_container.scroll_vertical)


## 查看映射表
func _look_grip_map() -> void:
	for coords: Vector2 in grid_map:
		var item_data: WItemData = grid_map.get(coords)
		print("coords:", coords, ",cell_pos:", item_data.cell_pos)
		print("is_placed:", item_data.is_placed, ",item:", item_data.link_item)


## 按id升序排序
func _sort_by_id(a, b) -> bool:
	return int(a.id) * 10 - a.item_level < int(b.id) * 10 - b.item_level


## 按价格降序排序
func _sort_by_price(a, b) -> bool:
	return int(a.base_price) * (a.item_level + 1) > int(b.base_price) * (b.item_level + 1)
