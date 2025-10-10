## 游戏主场景菜单，管理游戏内主场景内所有菜单栏，快捷栏，背包栏，仓库栏等等
extends BaseMenu
class_name GameMenu

@onready var grid_box_bar: GridBoxBar = %GridBoxBar
@onready var gold_bar: GoldBar = %GoldBar
@onready var info_bar: InfoBar = %InfoBar
@onready var game_world: GameWorld = %GameWorld
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
## 抓取的物品的来源容器，可以是背包、仓库或世界建造菜单
var held_item_from: MultiGridContainer
## 滚动条的偏移量
var sroll_offset: Vector2 = Vector2.ZERO
## 建筑房间内部
var current_room: PetRoom

## 地形详细信息
var _terrian_attribute: WTerrianAttribute


func _ready() -> void:
	super()
	## 初始化抓取物品
	_init_held_item()
	# 订阅事件
	EventManager.subscribe(UIEvent.INVENTORY_FULL, _on_inventory_full)  # 物品、仓库栏满了
	EventManager.subscribe(UIEvent.OPEN_INVENTORY, _on_open_inventory)  # 打开仓库
	EventManager.subscribe(UIEvent.PUTBACK_TO_BLACKPACK, _on_putback_to_blackpack)  # 房间物品放回背包
	EventManager.subscribe(UIEvent.PUTBACK_TO_INVENTORY, _on_putback_to_inventory)  # 房间物品放回仓库
	## 连接鼠标操作相关的信号
	if not InputManager.mouse_left_released.is_connected(on_mouse_left_released):
		InputManager.mouse_left_released.connect(on_mouse_left_released)
	if not InputManager.mouse_right_released.is_connected(on_mouse_right_released):
		InputManager.mouse_right_released.connect(on_mouse_right_released)
	# 旋转物品
	if not InputManager.rotation_item_pressed.is_connected(on_rotation_item_pressed):
		InputManager.rotation_item_pressed.connect(on_rotation_item_pressed)

	# 二级菜单信号事件
	info_bar.reset_world_scale.connect(_on_reset_world_scale)


## 退出处理订阅事件
func _exit_tree() -> void:
	EventManager.unsubscribe(UIEvent.INVENTORY_FULL, _on_inventory_full)
	EventManager.unsubscribe(UIEvent.OPEN_INVENTORY, _on_open_inventory)
	EventManager.unsubscribe(UIEvent.PUTBACK_TO_BLACKPACK, _on_putback_to_blackpack)
	EventManager.unsubscribe(UIEvent.PUTBACK_TO_INVENTORY, _on_putback_to_inventory)


func initialize(my_state_machine: UIStateMachine) -> void:
	super(my_state_machine)
	## 二级状态机初始化
	bar_state_machine.initialize(state_machine)
	## 订阅多格容器的整理信号
	bar_state_machine.sort_backpack.connect(_on_sort_backpack)
	bar_state_machine.sort_inventory.connect(_on_sort_inventory)
	## 获得仓库的容器
	inventory = grid_box_bar.get_inventory()
	backpack = grid_box_bar.get_backpack()
	quick_tools = grid_box_bar.get_quick_tools()


## 关闭所有属性弹窗层
func close_all_popup() -> void:
	if _terrian_attribute:
		_terrian_attribute.queue_free()


## 设置抓取物品的坐标(中心点模式)
func set_held_item_position(p: Vector2) -> void:
	if MouseEvent.mouse_cell_matrix is SingleGridContainer:
		# 设置缩放
		var held_size: Vector2 = held_item.get_item_size()
		# held_item 的缩放比例
		var scale_factor = GlobalData.single_cell_size / max(held_size.x, held_size.y)
		# 将 held_item 缩放为一个统一的尺寸，例如最大 1.5 倍的 cell_size
		held_item.scale = Vector2.ONE * min(scale_factor, 1.5)  # 限制最大缩放倍数
	else:
		held_item.scale = Vector2.ONE

	# 跟随鼠标设置坐标
	held_item.position = p - held_item.get_item_size() / 2 * held_item.scale


## 隐匿抓取的物品节点
func hide_held_item() -> void:
	held_item.visible = false
	held_item.position = Vector2(-900, -900)
	held_item.scale = Vector2.ONE


## 设置抓取的物品节点数据以及来源
## @param data：物品数据
## @param item_from：物品来源
func set_held_item_data(data: Dictionary, item_from: MultiGridContainer = null) -> void:
	held_item.item_offset = Vector2(0.0, 0.0)
	held_item.set_data(data)
	held_item.setup()
	held_item.set_texture_container_offset_and_rotation()
	held_item.show_item_num()
	# 设置来源
	held_item_from = item_from
	# 设置拖动缩放，使得纹理略小于绿色区域
	held_item.drag_texture_scale()
	# 还原所有弹出层，除了布局栏
	bar_state_machine.reset_all_popup()


## 将抓取的物品进行旋转同步(显示层)
func sync_held_item_rotation(org_item: WItem) -> void:
	var orientation: int = org_item.orientation
	if held_item.orientation != orientation:
		held_item.rotation_item()


## 放置提示框的处理逻辑(显示层)
func placement_overlay_process() -> void:
	# 计算首部坐标偏移
	var hand_pos: Vector2 = MouseEvent.mouse_cell_matrix.get_first_cell_pos_offset(held_item, MouseEvent.mouse_cell_pos)
	#var hand_pos: Vector2 = MouseEvent.mouse_cell_matrix.get_first_cell_pos_offset(held_item, GlobalData.prent_cell_pos)
	# 创建默认的放置提示颜色为红色
	var color_type: int = MultiGridContainer.TYPE_COLOR.ERROR

	# 检查坐标是不是合法的，即不超出边界
	if MouseEvent.mouse_cell_matrix.check_grid_map_item(hand_pos):
		# 检查坐标内的格子是不是空的
		if MouseEvent.mouse_cell_matrix.check_cell(hand_pos):
			# 获取映射表中对应的单个格子数据
			var item_data: WItemData = MouseEvent.mouse_cell_matrix.get_grid_map_item(hand_pos)
			var item: WItem = item_data.link_item
			# 先判断是不是可堆叠的物品
			var temp_bool: bool = item.stackable and held_item.stackable == item.stackable
			# 判断是否同一种容器类型
			if not held_item_from.container_type == MouseEvent.mouse_cell_matrix.container_type:
				temp_bool = false
			# 抓取物品和目标物品id一致且都可堆叠,没有达到最大堆叠数量并且物品的级别一致，将放置提示设置为绿色
			if item.id == held_item.id and temp_bool and item.num < item.max_stack_size and item.item_level == held_item.item_level:
				color_type = MultiGridContainer.TYPE_COLOR.SUCCESS
		else:
			# 判断是否同一种容器类型
			# 如果格子是空的，则对 映射表 按照 首部坐标 和 物品的宽高 所形成的矩形进行范围内扫描
			if MouseEvent.mouse_cell_matrix.scan_grid_map_area(hand_pos, held_item) and held_item_from.container_type == MouseEvent.mouse_cell_matrix.container_type:
				# 扫描范围内的格子都为空，即代表允许放置物品，设提示为绿色
				color_type = MultiGridContainer.TYPE_COLOR.SUCCESS
	# 设置对应多格容器内的放置提示框
	MouseEvent.mouse_cell_matrix.set_placement_overlay(color_type, held_item, hand_pos)
	# 显示该放置提示框
	MouseEvent.mouse_cell_matrix.startup_placement_overlay()
	#获取UI节点下的第一层子节点，遍历它们
	for child in get_children():
		#将与目标不一致的inventory节点的放置提示框设置为不可见
		if child != MouseEvent.mouse_cell_matrix and child is MultiGridContainer:
			child.off_placement_overlay()


## 进入建筑内部
func enter_build(data: Dictionary, head_pos: Vector2) -> void:
	if data.is_empty() or not data.has("item_info"):
		return
	if not current_room:
		# 水族箱
		if data["item_info"].get("build_type", BuildData.BuildType.NONE) == BuildData.BuildType.AQUATIC:
			current_room = ResManager.get_cached_resource(ResPaths.SCENE_RES.aquatic_room).instantiate()
		# 生态缸
		elif data["item_info"].get("build_type", BuildData.BuildType.NONE) == BuildData.BuildType.ECOLOGICAL:
			pass
		# 鸟舍
		elif data["item_info"].get("build_type", BuildData.BuildType.NONE) == BuildData.BuildType.AVIARY:
			pass
		# 生态温室
		elif data["item_info"].get("build_type", BuildData.BuildType.NONE) == BuildData.BuildType.GREEN_HOUSE:
			pass
		# 添加到显示列表
		add_child(current_room)
		current_room.z_index = 19
	# 等一帧再执行，确保画面相关的参数已设定完成
	await get_tree().process_frame
	# 设置房间内的数据
	current_room.update_pet_view(data, head_pos)


## 显示地形详细数据
func show_terrian_attribute(data: Dictionary, mouse_position: Vector2) -> void:
	if not _terrian_attribute:
		_terrian_attribute = ResManager.get_cached_resource(ResPaths.SCENE_RES.terrian_attribute).instantiate()
		add_child(_terrian_attribute)
	# 获取面板的实际尺寸
	var panel_size: Vector2 = _terrian_attribute.get_real_size()
	var target_pos: Vector2 = Utils.get_target_coords(mouse_position, panel_size)
	# 设置坐标
	_terrian_attribute.global_position = target_pos
	# 更新属性显示
	_terrian_attribute.update_display(data)


## 拾取物品
func pick_up_item(data: Dictionary, cell_pos: Vector2, item_from: MultiGridContainer = null) -> void:
	if not item_from.name == "WorldGrid" or data.is_empty():
		return
	var output_items: Array[String] = data["item_info"]["output_items"]
	# 只有固定材料，要是多个材料请随机
	var item_id: String = output_items[0]
	# 随机获得材料的数量
	var item_num: int = randi_range(GlobalData.pick_up_range.x, GlobalData.pick_up_range.y)
	var success: bool = GlobalData.player.inventory_comp.add_item(item_id, item_num)
	if success:
		# 删除地图数据
		item_from.sub_item_at(cell_pos)
		# TO DO 动画+num和物品飞入仓库的动画

		# 发送地图容器物品变化的信号（同步数据）
		EventManager.emit_event(UIEvent.ITEMS_CHANGED, {"container": item_from})


## 旋转物品
func on_rotation_item_pressed() -> void:
	## 单格容器不让旋转
	#if MouseEvent.mouse_cell_matrix is SingleGridContainer:
	#return
	# 正在抓取物品时，按下键盘R键，进行旋转物品的操作
	held_item.rotation_item()
	set_held_item_position(MouseEvent.mouse_position)
	# 按下R键后更新放置提示框
	placement_overlay_process()


## 释放鼠标左键
func on_mouse_left_released() -> void:
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
	# 发送仓库容器物品变化的信号
	EventManager.emit_event(UIEvent.ITEMS_CHANGED, {"container": GlobalData.previous_cell_matrix})
	if not GlobalData.previous_cell_matrix == MouseEvent.mouse_cell_matrix:
		EventManager.emit_event(UIEvent.ITEMS_CHANGED, {"container": MouseEvent.mouse_cell_matrix})
	#print("_handle_drop_item->form:", GlobalData.previous_cell_matrix, ",to:", MouseEvent.mouse_cell_matrix)


## 释放鼠标右键
func on_mouse_right_released() -> void:
	MouseEvent.is_mouse_right_down = false
	# 关闭放置提示框
	MouseEvent.mouse_cell_matrix.off_placement_overlay()


## 鼠标移动事件
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		MouseEvent.mouse_position = event.position
		MouseEvent.global_position = event.global_position
		# 当鼠标按下且鼠标状态为抓取物品时执行
		if MouseEvent.is_mouse_down and MouseEvent.is_mouse_drag():
			# 将抓取物品的中心点与鼠标进行跟随(显示层)
			set_held_item_position(event.position)
			# 当鼠标所点击的地方是不是无物品的时候执行
			if MouseEvent.mouse_is_effective:
				# 设置抓取物品的可视为真
				held_item.visible = true
				# 隐藏抓取物品的背景颜色
				held_item.hide_bg_color()
				# 当进入的网格容器不一致或格子坐标和上一次不一致时，更新放置提示框(用于减少触发频率，显示层)
				var bool_value: bool = MouseEvent.mouse_cell_matrix != GlobalData.previous_cell_matrix
				# 获得当前鼠标所在格子的局部坐标
				var item_data: WItemData = MouseEvent.mouse_cell_matrix.get_grid_map_item(MouseEvent.mouse_cell_pos)
				var mouse_grid_offset: Vector2 = item_data.link_grid.get_local_mouse_position()
				var grid_center: Vector2 = item_data.link_grid.get_grid_size() / 2.0
				if MouseEvent.mouse_cell_pos != GlobalData.prent_cell_pos || bool_value:
					# 切换提示层根据中心点偏移来计算
					var can_switch: bool = false
					# 左上角 (X < Center, Y < Center)
					if mouse_grid_offset.x < grid_center.x and mouse_grid_offset.y < grid_center.y:
						GlobalData.prent_cell_pos = MouseEvent.mouse_cell_pos
						can_switch = true
					# 左下角 (X < Center, Y > Center)
					elif mouse_grid_offset.x < grid_center.x and mouse_grid_offset.y > grid_center.y:
						GlobalData.prent_cell_pos = MouseEvent.mouse_cell_pos + Vector2(0.0, -1.0)
						can_switch = true
					# 右上角 (X > Center, Y < Center)
					elif mouse_grid_offset.x > grid_center.x and mouse_grid_offset.y < grid_center.y:
						GlobalData.prent_cell_pos = MouseEvent.mouse_cell_pos + Vector2(-1.0, 0.0)
						can_switch = true
					# 右下角 (X > Center, Y > Center)
					elif mouse_grid_offset.x > grid_center.x and mouse_grid_offset.y > grid_center.y:
						GlobalData.prent_cell_pos = MouseEvent.mouse_cell_pos - Vector2.ONE
						can_switch = true
					else:
						can_switch = false
					# 切换
					if can_switch:
						placement_overlay_process()


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
	# 如果是房间内部
	if current_room and current_room.mouse_in_room:
		## 建筑内放置物品
		_drop_item_to_room(cur_item)
		return
	# 判定是否是否相同容器的来源
	if not held_item_from.container_type == mouse_cell_matrix.container_type:
		# 不同容器类型则放回原位
		_item_put_back(cur_item)
		return
	# 物品堆叠判定
	if cur_item != null and mouse_item_data.link_item is WItem:
		var item: WItem = mouse_item_data.link_item
		# 上一个物品不能等于鼠标当前进入格子内的物品
		if !cur_item == item:
			var bool_value: bool = item.stackable and cur_item.stackable == item.stackable
			# 物品堆叠处理
			if cur_item.id == item.id and bool_value and cur_item.item_level == item.item_level:
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

	# 假如有附加额外属性
	var extra_args: Dictionary = {}
	if not (held_item.item_level == 0 or held_item.growth == 0.0):
		extra_args.set("item_level", held_item.item_level)
		extra_args.set("growth", held_item.growth)
	# 鼠标松开时，尝试放置物品
	if mouse_cell_matrix.add_new_item_in_data(first_cell_pos, held_item.get_data(), extra_args):
		var item_data: WItemData = mouse_cell_matrix.get_grid_map_item(first_cell_pos)
		# 放下后矫正该物品的纹理位置和旋转
		item_data.link_item.set_texture_container_offset_and_rotation()
		# 处理选中物品
		_handle_selected_item(item_data.link_item)
		# 放置成功后,移除原节点
		GlobalData.previous_cell_matrix.remove_item(cur_item)
	else:
		#放置失败时，将原物品可见设为真，且将其在映射表中的所在区域设置回"已占用"
		_item_put_back(cur_item)
	# 这行代码其实可以不要的，并不影响什么
	held_item.show_bg_color()
	# 隐藏抓取物品节点(显示层)
	hide_held_item()


## 建筑内放置物品
func _drop_item_to_room(cur_item: WItem) -> void:
	var item_data: Dictionary = held_item.get_data(false)
	var success: bool = false
	var food_left: int = 0
	# 添加食物
	if item_data.get("item_type", BaseItemData.ItemType.OTHERS) == BaseItemData.ItemType.FOOD:
		food_left = GlobalData.player.world_map_comp.add_food(current_room.room_id, current_room.head_position, item_data)
		if food_left == item_data["num"]:
			_item_put_back(cur_item)
			# 提示房间满了
			print("放置失败，食物已达上限！")
		# 达到放置食物的上限后还剩余食物量
		elif food_left > 0:
			# 放回原出处并修改剩余数量
			_item_put_back(cur_item)
			cur_item.num = food_left
		# 放置成功后,没有任何剩余则移除原节点
		else:
			GlobalData.previous_cell_matrix.remove_item(cur_item)
			hide_held_item()

	# 添加宠物数据
	elif item_data.get("item_type", BaseItemData.ItemType.OTHERS) == BaseItemData.ItemType.ANIMAL:
		success = GlobalData.player.world_map_comp.add_pet(current_room.room_id, current_room.head_position, item_data)
		# 添加成功后
		if success:
			# 放置成功后,移除原节点
			GlobalData.previous_cell_matrix.remove_item(cur_item)
			hide_held_item()
			print("宠物放置成功")
			# 向房间添加实体
			current_room.append_pet(item_data, MouseEvent.global_position)

		else:
			_item_put_back(cur_item)
			# 提示房间满了
			print("宠物放置失败，房间满了")


## 物品摆放回原位
func _item_put_back(cur_item: WItem) -> void:
	print("_item_put_back,", GlobalData.previous_cell_matrix)
	#放置失败时，将原物品可见设为真，且将其在映射表中的所在区域设置回"已占用"
	if cur_item != null:
		cur_item.visible = true
		GlobalData.previous_cell_matrix.set_item_placed(cur_item, true)
		# 处理选中物品
		_handle_selected_item(cur_item)
		# 这行代码其实可以不要的，并不影响什么
		held_item.show_bg_color()
		# 隐藏抓取物品节点(显示层)
		hide_held_item()


## 处理选中物品的标记状态
func _handle_selected_item(item: WItem) -> void:
	if GlobalData.cur_selected_item:
		GlobalData.cur_selected_item.hide_bg_color()
	# 标记物品为选中状态
	GlobalData.cur_selected_item = item
	GlobalData.cur_selected_item.set_selected_bg_color()


## 初始化被抓取的物品
func _init_held_item(item_id: String = "999") -> void:
	held_item = held_scene.instantiate()
	add_child(held_item)
	held_item.z_index = 999
	hide_held_item()
	# 设置一个默认值
	var tmp_data: Dictionary = GlobalData.find_item_data(item_id)
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


## 打开仓库
func _on_open_inventory() -> void:
	bar_state_machine.on_inventory_pressed()


## 批量房间物品放回背包
func _on_putback_to_blackpack(msg: Dictionary) -> void:
	var pets_data: Array = msg.get("data", [])
	if pets_data.is_empty():
		return
	var extra_args: Dictionary = {
		"item_level": 0,
		"growth": 0.0,
	}
	for data: PetData in pets_data:
		extra_args["item_level"] = data.item_level
		extra_args["growth"] = data.growth
		GlobalData.player.backpack_comp.add_item(data.id, 1, extra_args)

	# 通知 PetRoom 移除该宠物的实体和面板
	if current_room:
		current_room.remove_pet(msg)


## 批量房间物品放回仓库
func _on_putback_to_inventory(msg: Dictionary) -> void:
	var pets_data: Array = msg.get("data", [])
	if pets_data.is_empty():
		return
	var extra_args: Dictionary = {
		"item_level": 0,
		"growth": 0.0,
	}
	for data: PetData in pets_data:
		extra_args["item_level"] = data.item_level
		extra_args["growth"] = data.growth
		GlobalData.player.inventory_comp.add_item(data.id, 1, extra_args)

	# 通知 PetRoom 移除该宠物的实体和面板
	if current_room:
		current_room.remove_pet(msg)


## 重置世界缩放
func _on_reset_world_scale() -> void:
	game_world.reset_scale()
