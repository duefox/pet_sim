extends TextureRect
class_name WGrid

var cell_pos: Vector2  # 格子的网格内坐标
var parent_cell_matrix: MultiGridContainer  # 格子所属的MultiGridContainer(引用)


func _ready() -> void:
	MouseEvent.mouse_cell_matrix = parent_cell_matrix


## 更新tooltips文本
func update_tooltip(text: String) -> void:
	tooltip_text = text


## 鼠标进入事件
func _on_mouse_entered() -> void:
	## 向鼠标事件实例对象传递信息
	MouseEvent.mouse_cell_pos = cell_pos
	MouseEvent.mouse_cell_matrix = parent_cell_matrix


## 该节点的输入事件处理，抓取格子上被放置的物品
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		## 鼠标在物品节点范围内，按下左键，则更改鼠标的状态为抓取物品
		if event.is_action_pressed("mouse_left") and not MouseEvent.is_mouse_drag():
			#if event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed() && !MouseEvent.is_mouse_drag():
			GlobalData.previous_cell_matrix = parent_cell_matrix
			var cur_item_data: ItemData = parent_cell_matrix.get_grid_map_item(cell_pos)
			MouseEvent.is_mouse_down = true
			MouseEvent.mouse_is_effective = cur_item_data.is_placed

			## 鼠标点击的格子内，如果是"已占用"，才执行下面代码
			if cur_item_data.is_placed:
				MouseEvent.mouse_state = MouseEvent.CONTROLS_TYPE.DRAG
				var cur_item: WItem = cur_item_data.link_item
				## 将自身的引用传递到上一次点击的物品属性中
				GlobalData.previous_item = cur_item
				## 同步抓取物品的旋转状态
				GlobalData.ui.sync_held_item_rotation(cur_item)
				## 同步抓取物品的数据
				GlobalData.ui.set_held_item_data(cur_item.get_data())
				## 将抓取物品中心移至鼠标坐标点
				GlobalData.ui.set_held_item_position(MouseEvent.mouse_position)
				## 隐藏抓取物品的背景颜色
				GlobalData.ui.held_item.hide_bg_color()
				## 将抓取物品节点设置为可见
				GlobalData.ui.held_item.visible = true
				## 对应物品自身设置为不可见
				cur_item.visible = false
				## 将原来的物品在映射表中的所占区域暂时设置为"空(未占用)"
				parent_cell_matrix.set_item_placed(cur_item, false)
				## 设置放置提示框，并显示
				GlobalData.ui.placement_overlay_process()


## 自定义tooltips窗口
func _make_custom_tooltip(for_text: String) -> Control:
	return Tooltips.create(for_text)
