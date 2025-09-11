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
enum TYPE_COLOR { SUCCESS, ERROR, DEF }  ## 绿色，代表允许放置  ## 红色，代表不允许放置  ## 默认颜色

## 放置提示框显示模式枚举
enum MODE_PLACEMENT_OVERTLAY {
	DEF,  ## 默认模式(鼠标移出容器范围就消失)
	STAY,  ## 停留模式(鼠标移出容器范围后且未进入其他容器，在原容器内仍然保留显示)
}

@export var grid_row: int = 5  ##  容器的格子行数
@export var grid_col: int = 6  ##  容器的格子列数

@export var max_scroll_grid: int = 4  ##  最多显示多少格
@export var placement_overlay_mode: MODE_PLACEMENT_OVERTLAY = MODE_PLACEMENT_OVERTLAY.DEF  ## 放置提示框显示模式
@export var grid_scene: PackedScene
@export var item_scene: PackedScene

var cell_size: int = 48  #  容器的格子尺寸
var grid_size: Vector2  #  多格子容器的大小
var w_grid_size: Vector2  # 格子的大小
var items: Dictionary[Vector2,WItem] = {}
##  格子映射表, key为格子坐标，value为WItemData
var grid_map: Dictionary[Vector2, WItemData] = {}


func _ready() -> void:
	cell_size = GlobalData.cell_size
	##  渲染格子
	_init_rend()
	# 获取格子场景的大小
	var w_grid: WGrid = grid_container.get_child(0)
	w_grid_size = w_grid.get_grid_size()
	##  设置滚动区域
	set_scroll_container()
	##  放置区的底色
	placement_overlay.color = get_type_color()


## 鼠标离开
func _on_mouse_exited() -> void:
	if placement_overlay_mode == MultiGridContainer.MODE_PLACEMENT_OVERTLAY.DEF:
		off_placement_overlay()


## 处理其他输入事件
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton && !event.is_pressed() && event.button_index == MOUSE_BUTTON_LEFT:
		off_placement_overlay()


## 获取背景颜色
func get_type_color(type: int = 0) -> Color:
	var color_arr: Array[Color] = [Color(&"00be0b62"), Color(&"ff000063"), Color(&"989f9a62")]
	if type < 0 || type >= color_arr.size():
		return color_arr[MultiGridContainer.TYPE_COLOR.DEF]
	return color_arr[type]


## 设置放置提示框数据
func set_placement_overlay(type: int, item: WItem, cell_pos: Vector2) -> void:
	var placement_size: Vector2 = item.get_item_size()
	placement_size -= Vector2(item.width, item.height)
	placement_overlay.color = get_type_color(type)
	placement_overlay.size = placement_size
	placement_overlay.position = get_comput_position(cell_pos)


## 启用放置提示框
func startup_placement_overlay() -> void:
	placement_overlay.visible = true


## 关闭放置提示框
func off_placement_overlay() -> void:
	placement_overlay.visible = false


##  设置滚动区域
func set_scroll_container() -> void:
	grid_size = Vector2(grid_col + 0.3, max_scroll_grid + 0.5) * w_grid_size
	scroll_container.custom_minimum_size = grid_size


## 自动合并所有可堆叠的物品并重新排列
func auto_stack_existing_items() -> void:
	# 1. 临时存储合并后的物品数据，分别用两个变量存储
	var merged_stackable_items: Dictionary[String, Dictionary] = {}
	var non_stackable_items: Array[Dictionary] = []

	for item_coords in items:
		var item: WItem = items[item_coords]
		var item_data: Dictionary = item.get_data().duplicate(true)
		if item.stackable:
			if not merged_stackable_items.has(item.id):
				merged_stackable_items[item.id] = item_data
			else:
				merged_stackable_items[item.id].num += item_data.num
		else:
			non_stackable_items.append(item_data)

	# 2. 清空当前容器的所有物品和映射表
	_clear_all_items()

	# 3. 按照合并后的数据重新创建并放置物品
	var sorted_stackable_items: Array[Dictionary] = merged_stackable_items.values()
	# 4. 按id排序
	sorted_stackable_items.sort_custom(func(a, b): return a.id > b.id)
	#print("sorted_stackable_items:", sorted_stackable_items)
	#print("non_stackable_items:", non_stackable_items)
	# 5. 调用add_item_with_merge添加到容器中
	# 5.1 处理可堆叠物品
	for stack_item: Dictionary in sorted_stackable_items:
		add_item_with_merge(stack_item.id, stack_item.num)
	# 5.2 处理不可堆叠物品
	for no_stack_item: Dictionary in non_stackable_items:
		add_item_with_merge(no_stack_item.id, no_stack_item.num)


## 新增物品，如果可合并则堆叠，不需要指定位置
## @param item_id: 物品的唯一id
## @param num: 物品的数量
func add_item_with_merge(item_id: String, num: int = 1) -> bool:
	var remaining_items: int = num

	# 步骤1: 遍历所有格子，尝试合并到现有物品堆叠中
	for item_data in grid_map.values():
		if item_data and item_data.link_item:
			var item: WItem = item_data.link_item
			# 检查是否为同种物品且可堆叠
			if item.id == item_id and item.stackable:
				remaining_items = item.add_num(remaining_items)
				if remaining_items == 0:
					return true  # 全部合并成功

	# 步骤2: 如果还有剩余物品，则寻找空位并添加新物品
	while remaining_items > 0:
		var empty_pos: Vector2 = get_next_available_position()
		if empty_pos == -Vector2.ONE:
			return false  # 没有空位了

		var new_item_data: Dictionary = GlobalData.find_item_data(item_id)
		if not new_item_data:
			push_error("Item data not found for id: ", item_id)
			return false

		var num_to_add: int = min(remaining_items, WItem.new().max_stack_size)
		new_item_data.num = num_to_add

		# 放置新物品
		var success: bool = add_new_item_in_data(empty_pos, new_item_data)
		if not success:
			return false  # 放置失败，中断

		remaining_items -= num_to_add

	return true


## 查找下一个可用的空位
func get_next_available_position() -> Vector2:
	# 遍历所有格子，寻找第一个is_placed为false的空位
	for y in range(grid_row):
		for x in range(grid_col):
			var cell_pos: Vector2 = Vector2(x, y)
			var item_data: WItemData = get_grid_map_item(cell_pos)
			if item_data and not item_data.is_placed:
				return cell_pos
	return -Vector2.ONE  # 没有找到可用的位置


## 新增物品，并自动查找最近的可用位置
func add_new_item(item_id: String) -> bool:
	var item_data: Dictionary = GlobalData.find_item_data(item_id)

	if not item_data:
		push_error("Item data not found for ID: " + item_id)
		return false

	# 模拟创建一个临时的 WItem 实例以获取其尺寸，之后不会添加到场景中
	var temp_item: WItem = item_scene.instantiate()
	temp_item.set_data(item_data)

	for y in range(grid_row):
		for x in range(grid_col):
			var first_cell_pos: Vector2 = Vector2(x, y)

			# 使用新函数检查该位置是否可以放置
			if can_place_item(temp_item, first_cell_pos):
				# 找到合适位置后，调用现有函数放置物品并返回
				add_new_item_at(first_cell_pos, item_id)
				temp_item.queue_free()
				return true

	temp_item.queue_free()
	# 如果没有找到任何可用位置，发出信号
	EventManager.emit_event(UIEvent.INVENTORY_FULL, self)
	return false


## 检查格子是否已被占用
func check_cell(cell_pos: Vector2) -> bool:
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


## 获取坐标空间的物品
func get_item_at(cell_pos: Vector2) -> WItem:
	if items.has(cell_pos):
		return items[cell_pos]
	return null


## 根据坐标放置物品到多格子容器中
func add_item_at(cell_pos: Vector2, item: WItem) -> bool:
	var is_placed: bool = check_cell(cell_pos)
	if !is_placed:
		## 格子为空时
		if scan_grid_map_area(cell_pos, item):
			# 矩形区域扫描通过时
			item.head_position = cell_pos
			# 把物品添加到items字典
			items.set(cell_pos, item)
			# 设置格子映射表的数据
			set_grid_map_item(cell_pos, item)
			# 将物品节点添加至多格子容器(显示层)
			append_item_in_cell_matrix(item)
			# 将显示层的对应物品位置进行调整，根据传入的格子坐标
			set_item_comput_position(cell_pos, item)
			return true
	return false


## 根据id新建物品并放置到多格子容器中
func add_new_item_at(cell_pos: Vector2, item_id: String) -> bool:
	var item: WItem = _create_item()
	set_item_data_at_id(item, item_id)
	return add_item_at(cell_pos, item)


## 根据data新建一个物品并放置到多格子容器中
func add_new_item_in_data(cell_pos: Vector2, data: Dictionary) -> bool:
	# 检查格子是否已被占用
	var item_data: WItemData = grid_map.get(cell_pos)
	if item_data and item_data.is_placed:
		return false
	# 是否超边界
	if !check_grid_map_item(cell_pos):
		return false
	var item: WItem = _create_item()
	item.set_data(data)
	return add_item_at(cell_pos, item)


## 根据id给WItem设置基础数据
func set_item_data_at_id(item: WItem, item_id: String) -> void:
	var data: Dictionary = GlobalData.find_item_data(item_id)
	if data:
		item.set_data(data)
	else:
		print(&"set_item_data_at_id 设置数据失败！")


## 将物品节点添加至多格子容器(显示层)
func append_item_in_cell_matrix(item: WItem) -> void:
	item_container.add_child(item)


## 将显示层的对应物品位置进行调整，根据传入的格子坐标
func set_item_comput_position(cell_pos: Vector2, item: WItem) -> void:
	item.position = get_comput_position(cell_pos)


## 获取对应格子坐标在显示层中的实际坐标
func get_comput_position(cell_pos: Vector2) -> Vector2:
	var base: Vector2 = cell_pos * w_grid_size
	return Vector2(base.x - cell_pos.x, base.y - cell_pos.y)


## 计算首部坐标的偏移
func get_first_cell_pos_offset(item: WItem, cell_pos: Vector2) -> Vector2:
	var width: int = item.width
	var height: int = item.height
	return Vector2(cell_pos.x - floori(width / 2.0), cell_pos.y - floori(height / 2.0))


## 移除物品
func remove_item(cur_item: WItem) -> void:
	if not is_instance_valid(cur_item):
		return

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
	## 移除背包物品记录
	items.erase(cur_item.head_position)
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


## 检查一个物品是否可以放置在指定位置
func can_place_item(item: WItem, first_cell_pos: Vector2) -> bool:
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
	return item


## 初始的格子渲染
func _init_rend() -> void:
	# 清空grid container
	_clear_grid_container()
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


## 查看映射表
func _look_grip_map() -> void:
	for coords: Vector2 in grid_map:
		var item_data: WItemData = grid_map.get(coords)
		print("coords:", coords, ",cell_pos:", item_data.cell_pos)
		print("is_placed:", item_data.is_placed, ",item:", item_data.link_item)


## 清除所有物品节点和数据
func _clear_all_items() -> void:
	for item in items.values():
		if is_instance_valid(item):
			item.queue_free()

	items.clear()

	# 移除映射表的对应数据
	for item_data in grid_map.values():
		if item_data:
			item_data.is_placed = false
			item_data.link_item = null
			if is_instance_valid(item_data.link_grid):
				item_data.link_grid.update_tooltip("")
