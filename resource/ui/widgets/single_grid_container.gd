extends MultiGridContainer
class_name SingleGridContainer


## 重写父类的 set_scroll_container 方法
## 设置滚动区域
func set_scroll_container() -> void:
	grid_size = Vector2(grid_col, max_scroll_grid) * w_grid_size
	scroll_container.custom_minimum_size = grid_size


## 设置放置提示框数据
## 重写父类的 set_placement_overlay 方法，单格容器颜色提示区的大小为格子的大小
func set_placement_overlay(type: int, item: WItem, cell_pos: Vector2) -> void:
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
		# 矩形区域扫描通过时
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
		item.fit_to_container(Vector2(64.0, 64.0))
		return true
	return false


## 重写父类的 set_grid_map_item 方法，单格容器只需设置自己本身坐标格的信息
## 设置格子映射表的数据
func set_grid_map_item(cell_pos: Vector2, item: WItem) -> void:
	var temp: ItemData = get_grid_map_item(cell_pos)
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
