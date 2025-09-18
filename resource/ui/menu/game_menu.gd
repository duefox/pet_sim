## 游戏主场景菜单，管理游戏内主场景内所有菜单栏，快捷栏，背包栏，仓库栏等等
extends BaseMenu
class_name GameMenu

@onready var grid_box_bar: GridBoxBar = %GridBoxBar
## 游戏主场景的二级状态机
@onready var bar_state_machine: BarStateMachine = %BarStateMachine

## held item场景
@export var held_scene: PackedScene

## 仓库的多格子容器
var inventory: MultiGridContainer
## 背包
var backpack: MultiGridContainer
## 快捷工具栏
var quick_tools: MultiGridContainer
## 抓取的物品
var held_item: WItem


func _ready() -> void:
	super()
	GlobalData.ui = self
	## 初始化抓取物品
	_init_held_item()
	# 订阅事件
	EventManager.subscribe(UIEvent.INVENTORY_FULL, _on_inventory_full)  # 物品、仓库栏满了


## 退出处理订阅事件
func _exit_tree() -> void:
	EventManager.unsubscribe(UIEvent.INVENTORY_FULL, _on_inventory_full)  # 物品、仓库栏满了


func initialize(my_state_machine: UIStateMachine) -> void:
	super(my_state_machine)
	## 二级状态机初始化
	bar_state_machine.initialize(state_machine)
	## 订阅多格容器的整理事件
	bar_state_machine.sort_backpack.connect(_on_sort_backpack)
	bar_state_machine.sort_inventory.connect(_on_sort_inventory)
	## 获得仓库的容器
	inventory = grid_box_bar.get_inventory()
	backpack = grid_box_bar.get_backpack()
	quick_tools = grid_box_bar.get_quick_tools()

	### 背包
	#backpack.add_item("1002")
	#backpack.add_item("2001")
	#backpack.add_item_with_merge("3001", 2)


## 设置抓取物品的坐标(中心点模式)
func set_held_item_position(p: Vector2) -> void:
	held_item.position = p - held_item.get_item_size() / 2


## 隐匿抓取的物品节点
func hide_held_item() -> void:
	held_item.visible = false
	held_item.position = Vector2(-900, -900)


## 设置抓取的物品节点数据
func set_held_item_data(data: Dictionary) -> void:
	held_item.set_data(data)
	held_item.setup()
	held_item.set_texture_container_offset_and_rotation()
	held_item.show_item_num()


## 将抓取的物品进行旋转同步(显示层)
func sync_held_item_rotation(org_item: WItem) -> void:
	var orientation: int = org_item.orientation
	if held_item.orientation != orientation:
		held_item.rotation_item()


## 放置提示框的处理逻辑(显示层)
func placement_overlay_process() -> void:
	#计算首部坐标偏移
	var hand_pos: Vector2 = MouseEvent.mouse_cell_matrix.get_first_cell_pos_offset(held_item, MouseEvent.mouse_cell_pos)
	#创建默认的放置提示颜色为红色
	var color_type: int = MultiGridContainer.TYPE_COLOR.ERROR

	#检查坐标是不是合法的，即不超出边界
	if MouseEvent.mouse_cell_matrix.check_grid_map_item(hand_pos):
		#检查坐标内的格子是不是空的
		if MouseEvent.mouse_cell_matrix.check_cell(hand_pos):
			#获取映射表中对应的单个格子数据
			var item_data: WItemData = MouseEvent.mouse_cell_matrix.get_grid_map_item(hand_pos)
			var item: WItem = item_data.link_item
			#先判断是不是可堆叠的物品
			var temp_bool: bool = item.stackable and held_item.stackable == item.stackable
			#抓取物品和目标物品id一致且都可堆叠并且没有达到最大堆叠数量，将放置提示设置为绿色
			if item.id == held_item.id and temp_bool and item.num < item.max_stack_size:
				color_type = MultiGridContainer.TYPE_COLOR.SUCCESS
		else:
			#如果格子是空的，则对 映射表 按照 首部坐标 和 物品的宽高 所形成的矩形进行范围内扫描
			if MouseEvent.mouse_cell_matrix.scan_grid_map_area(hand_pos, held_item):
				#扫描范围内的格子都为空，即代表允许放置物品，设提示为绿色
				color_type = MultiGridContainer.TYPE_COLOR.SUCCESS
	#设置对应inventory内的放置提示框
	MouseEvent.mouse_cell_matrix.set_placement_overlay(color_type, held_item, hand_pos)
	#显示该放置提示框
	MouseEvent.mouse_cell_matrix.startup_placement_overlay()
	#获取UI节点下的第一层子节点，遍历它们
	for child in get_children():
		#将与目标不一致的inventory节点的放置提示框设置为不可见
		if child != MouseEvent.mouse_cell_matrix && child is MultiGridContainer:
			child.off_placement_overlay()


## 鼠标移动事件
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		MouseEvent.mouse_position = event.position
		#当鼠标按下且鼠标状态为抓取物品时执行
		if MouseEvent.is_mouse_down and MouseEvent.is_mouse_drag():
			#将抓取物品的中心点与鼠标进行跟随(显示层)
			set_held_item_position(event.position)
			#set_held_item_position(event.global_position)
			#当鼠标所点击的地方是不是无物品的时候执行
			if MouseEvent.mouse_is_effective:
				#设置抓取物品的可视为真
				held_item.visible = true
				#隐藏抓取物品的背景颜色
				held_item.hide_bg_color()
				#当进入的inventory不一致或格子坐标和上一次不一致时，更新放置提示框(用于减少触发频率，显示层)
				var bool_value: bool = MouseEvent.mouse_cell_matrix != GlobalData.previous_cell_matrix
				if MouseEvent.mouse_cell_pos != GlobalData.prent_cell_pos || bool_value:
					GlobalData.prent_cell_pos = MouseEvent.mouse_cell_pos
					placement_overlay_process()


## 处理其他输入事件
func _input(event: InputEvent) -> void:
	# 处理键盘按键输入
	if event is InputEventKey && MouseEvent.is_mouse_drag():
		# 正在抓取物品时，按下键盘R键，进行旋转物品的操作
		#if event.pressed && event.keycode == 82:
		if event.is_action_pressed("keyboard_r"):
			held_item.rotation_item()
			set_held_item_position(MouseEvent.mouse_position)
			# 按下R键后更新放置提示框
			placement_overlay_process()
	# 当鼠标左键松开时，取消抓取状态，放下抓取物品
	#elif event is InputEventMouseButton && !event.is_pressed() && event.button_index == MOUSE_BUTTON_LEFT:
	elif Input.is_action_just_released("mouse_left"):
		# 重置鼠标按下状态
		MouseEvent.is_mouse_down = false
		# 关闭放置提示框
		MouseEvent.mouse_cell_matrix.off_placement_overlay()
		# 鼠标松开时，若状态为"默认"则直接返回，不执行后续操作
		if !MouseEvent.is_mouse_drag():
			hide_held_item()
			return
		MouseEvent.mouse_state = MouseEvent.CONTROLS_TYPE.DEF
		# 处理放置物品
		_handle_drop_item()
	# 当鼠标右键键松开时，重置右键状态值
	elif Input.is_action_just_released("mouse_right"):
		MouseEvent.is_mouse_right_down = false
		# 关闭放置提示框
		MouseEvent.mouse_cell_matrix.off_placement_overlay()


## 放置物品到多格容器
func _handle_drop_item(_mouse_cell_pos: Vector2 = Vector2.ZERO) -> void:
	# 获取上一次操作的物品节点
	var cur_item: WItem = GlobalData.previous_item
	# 获取鼠标进入的格子坐标
	var mouse_cell_pos: Vector2 = MouseEvent.mouse_cell_pos
	# 获取鼠标所在的格子容器节点
	var mouse_cell_matrix: MultiGridContainer = MouseEvent.mouse_cell_matrix
	# 获取鼠标所在的格子容器内的单个格子映射表数据
	var mouse_item_data: WItemData = mouse_cell_matrix.get_grid_map_item(mouse_cell_pos)
	# 物品堆叠判定
	if cur_item != null && mouse_item_data.link_item is WItem:
		var item: WItem = mouse_item_data.link_item
		# 上一个物品不能等于鼠标当前进入格子内的物品
		if !cur_item == item:
			var bool_value: bool = item.stackable && cur_item.stackable == item.stackable
			# 物品堆叠处理
			if cur_item.id == item.id && bool_value:
				# 调用 add_num 函数并获取剩余物品数量
				var remaining_items: int = item.add_num(cur_item.num)
				if remaining_items == 0:
					# 如果剩余数量为0，表示全部合并成功
					GlobalData.previous_cell_matrix.remove_item(cur_item)
					hide_held_item()
					return
				else:
					# 如果有剩余数量，更新原物品数量并将其放回原位
					cur_item.num = remaining_items
					cur_item.set_label_data()
					_item_put_back(cur_item)
					hide_held_item()
					return

	# 计算放置时的首部坐标偏移，得到置入坐标
	var first_cell_pos: Vector2 = mouse_cell_matrix.get_first_cell_pos_offset(held_item, mouse_cell_pos)

	# 鼠标松开时，尝试放置物品
	if mouse_cell_matrix.add_new_item_in_data(first_cell_pos, held_item.get_data()):
		var item_data: WItemData = mouse_cell_matrix.get_grid_map_item(first_cell_pos)
		# 放下后矫正该物品的纹理位置和旋转
		item_data.link_item.set_texture_container_offset_and_rotation()
		# 处理选中物品
		_handle_selected_item(item_data.link_item)
		# 放置成功后,移除原节点
		GlobalData.previous_cell_matrix.remove_item(cur_item)
		#print("pre_item:",cur_item)
		#print("当前被放置的对象:",GlobalData.previous_cell_matrix.get_item_at(first_cell_pos))
		## 测试映射表
		#print("重置映射表后------>first_cell_pos：",first_cell_pos,",mouse_cell_pos:",mouse_cell_pos)
		#GlobalData.previous_cell_matrix._look_grip_map()
	else:
		#放置失败时，将原物品可见设为真，且将其在映射表中的所在区域设置回"已占用"
		_item_put_back(cur_item)
	# 这行代码其实可以不要的，并不影响什么
	held_item.show_bg_color()
	# 隐藏抓取物品节点(显示层)
	hide_held_item()


## 物品摆放回原位
func _item_put_back(cur_item: WItem) -> void:
	#放置失败时，将原物品可见设为真，且将其在映射表中的所在区域设置回"已占用"
	if cur_item != null:
		cur_item.visible = true
		GlobalData.previous_cell_matrix.set_item_placed(cur_item, true)
		# 处理选中物品
		_handle_selected_item(cur_item)


## 处理选中物品的标记状态
func _handle_selected_item(item: WItem) -> void:
	if GlobalData.cur_selected_item:
		GlobalData.cur_selected_item.hide_bg_color()
	# 标记物品为选中状态
	GlobalData.cur_selected_item = item
	GlobalData.cur_selected_item.set_selected_bg_color()


## 初始化被抓取的物品
func _init_held_item() -> void:
	held_item = held_scene.instantiate()
	add_child(held_item)
	hide_held_item()
	# 设置一个默认值
	var tmp_data: Dictionary = GlobalData.find_item_data("999")
	held_item.set_data(tmp_data)
	held_item.setup()


## 背包整理
func _on_sort_backpack() -> void:
	backpack.auto_stack_existing_items()


## 仓库整理
func _on_sort_inventory() -> void:
	inventory.auto_stack_existing_items()


## 物品栏满了或者自动摆放不下了
func _on_inventory_full(container: MultiGridContainer) -> void:
	print(container, " is full")
	pass
