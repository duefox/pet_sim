extends MultiGridContainer
class_name SingleGridContainer


## 重写父类的 set_scroll_container 方法
## 设置滚动区域
func set_scroll_container() -> void:
	grid_size = Vector2(grid_col, max_scroll_grid) * w_grid_size
	scroll_container.custom_minimum_size = grid_size


## 设置放置提示框数据
## 重写父类的 set_placement_overlay 方法，单格容器颜色提示区的大小为格子的大小
func set_placement_overlay(type: int, _item: WItem, cell_pos: Vector2) -> void:
	var placement_size: Vector2 = w_grid_size
	placement_size -= Vector2.ONE
	placement_overlay.color = get_type_color(type)
	placement_overlay.size = placement_size
	placement_overlay.position = get_comput_position(cell_pos)


## 重写父类的 add_item_at 方法
## 这个方法将处理单格物品的特殊放置和缩放
func add_item_at(cell_pos: Vector2, item: WItem) -> bool:
	var is_placed: bool = check_cell(cell_pos)
	## 格子为未被占用时
	if !is_placed:
		item.head_position = cell_pos
		# 重置物品的旋转为默认竖直方向
		item.orientation = WItem.ORI.VER
		# 把物品添加到items字典
		items.set(cell_pos, item)
		# 设置格子映射表的数据
		set_grid_map_item(cell_pos, item)
		# 将物品节点添加至多格子容器(显示层)
		append_item_in_cell_matrix(item)
		# 将显示层的对应物品位置进行调整，根据传入的格子坐标
		set_item_comput_position(cell_pos, item)
		# 调整物品纹理以适配单格大小，注意一定要在添加到渲染树之后调用这个方法
		item.fit_to_container(w_grid_size)
		# 测试
		#print("放下物品------------->")
		#_look_grip_map()
		return true

	return false


## 重写父类的 set_grid_map_item 方法，单格容器只需设置自己本身坐标格的信息
## 设置格子映射表的数据
func set_grid_map_item(cell_pos: Vector2, item: WItem) -> void:
	var temp: ItemData = grid_map.get(cell_pos)
	temp.is_placed = true
	temp.link_item = item
	# 更新相应格子的tool tips文本
	var link_grid: WGrid = temp.link_grid
	var bbcode_text: String = "[b]" + item.item_name + "[/b]\n" + item.descrip
	link_grid.update_tooltip(bbcode_text)


## 计算首部坐标的偏移
## 重写父类的 get_first_cell_pos_offset 方法
func get_first_cell_pos_offset(_item: WItem, cell_pos: Vector2) -> Vector2:
	return cell_pos


## 扫描物品映射表的某块矩形区域，查看是否符合放置条件
## 重写父类的 scan_grid_map_area 方法，单格容器只用判断当前坐标位置即可
func scan_grid_map_area(cell_pos: Vector2, _item: WItem) -> bool:
	## 判断是否超出背包格子的边界
	if !check_grid_map_item(cell_pos):
		return false
		## 判断该格子是不是已经被占用
	if check_cell(cell_pos):
		return false
	return true


## 将物品所对应的映射表格子占用进行更改
## 重写父类的 set_item_placed 方法，单格容器只用判断当前坐标位置即可
func set_item_placed(item: WItem, value: bool) -> void:
	var head: Vector2 = item.head_position
	get_grid_map_item(head).is_placed = value


## 移除物品
## 重写父类的 remove_item 方法，单格容器只用删掉当前坐标的物品即可
func remove_item(cur_item: WItem) -> void:
	## 移除背包物品记录
	for coords: Vector2 in items:
		var item: WItem = items[coords]
		if item == cur_item:
			items.erase(coords)
			break
	## 移除映射表的对应数据
	var item_data: ItemData = grid_map.get(cur_item.head_position)
	# 注意这里需要移除的是有链接对象但是空间未占用的映射对象
	if item_data and !item_data.is_placed:
		item_data.link_item = null
		item_data.is_placed = false
		item_data.link_grid.update_tooltip()
	## 释放该物品的实例化对象
	cur_item.queue_free()
	cur_item = null


## 检查一个物品是否可以放置在指定位置
## 重写父类的 can_place_item 方法，单格容器只用判定当前坐标即可
func can_place_item(_item: WItem, first_cell_pos: Vector2) -> bool:
	# 检查字典中是否已存在该位置的映射数据
	var item_data: ItemData = grid_map.get(first_cell_pos)
	# 如果该位置的is_placed为true，则表示格子被占用，不能放置
	if item_data and item_data.is_placed:
		return false
	return true
