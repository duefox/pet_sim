extends Node
class_name BarStateMachine

@onready var bg_color: ColorRect = %BGColor
## 金币栏
@onready var gold_bar: Control = %GoldBar
## 使用@onready获取所有二级菜单节点的引用
#region 所有二级菜单节点的引用
## 当天信息栏
@onready var info_bar: InfoBar = %InfoBar
## 导航栏
@onready var navigation_bar: NavigationBar = %NavigationBar
## 用户资料栏（内包含个人信息，图鉴，成就等tab页）
@onready var profile_bar: ProfileBar = %ProfileBar
## 户外探索地图
@onready var map_bar: MapBar = %MapBar
## 任务列表栏
@onready var task_bar: TaskBar = %TaskBar
## 建造布局栏（包含建造布局，造景摆放等）
@onready var layout_bar: LayoutBar = %LayoutBar
## 3个主要仓库容器栏（包含快捷工具，背包，仓库）
@onready var grid_box_bar: GridBoxBar = %GridBoxBar
#endregion

## 定义二级菜单的状态
enum State {
	NONE,  #什么都不显示
	DEFAULT,  # 默认布局，显示导航栏，当天信息栏，金币栏，容器栏的快捷工具栏
	PROFILE,  # 默认布局+半透明背景之上显示用户资料栏
	MAP,  # 仅显示当天信息栏，金币栏，户外探索地图
}

#TASK,  # 默认布局+侧边显示任务栏
#BACKPACK,  # 显示导航栏，当天信息栏，金币栏，容器栏的背包界面栏
#INVENTORY,  # 显示导航栏，当天信息栏，金币栏，容器栏的仓库界面栏
#VISITOR,  # 默认布局+视觉相机移动到大厅的前台
#LAYOUT,  #默认布局+建造布局栏

#region 信号
## 整理背包
signal sort_backpack
## 整理仓库
signal sort_inventory
#endregion

# 存储当前状态
var current_state: int = State.NONE
# 存储所有 UI 节点的引用，将状态与节点关联起来
var ui_nodes: Dictionary = {}
# 记录前一个状态
var previous_state: int
# 父状态机
var parent_state_machine: UIStateMachine

# 状态处理函数字典
var _state_functions: Dictionary[int,Callable] = {}


## 初始化
func initialize(state_machine: UIStateMachine):
	# 设置自己的父状态机
	parent_state_machine = state_machine
	# 隐藏所有节点
	hide_all()
	# 给节点设置自己的二级状态机
	for child in self.get_parent().get_children():
		if child is GameBar:
			child = child as GameBar
			child.state_machine = self

	# 状态函数
	_state_functions[State.NONE] = hide_all
	_state_functions[State.DEFAULT] = _state_default
	_state_functions[State.PROFILE] = _state_profile
	_state_functions[State.MAP] = _state_map

	# 显示默认界面
	change_state(State.DEFAULT)


## 切换二级菜单状态的公共接口
## @param new_state: 目标状态 (使用 State 枚举)
func change_state(new_state: int) -> void:
	if new_state == current_state:
		return  # 避免重复切换

	# 检查状态转换是否合法
	if not transition_logic(new_state):
		push_warning("Invalid UI state transition from %s to %s" % [State.keys()[current_state], State.keys()[new_state]])
		return
	# 状态切换
	previous_state = current_state
	current_state = new_state

	# 调用对应状态的函数
	var func_to_call: Callable = _state_functions.get(current_state)
	func_to_call.call()


## 恢复之前的状态
func recover_state() -> void:
	#print("recover_state")
	change_state(previous_state)


## 判断是否可以进行状态转换
## 你可以在这里添加复杂的转换规则
## @param new_state: 新的状态
## @return bool: 如果转换合法，返回true；否则返回false
func transition_logic(new_state: int) -> bool:
	#print("current_state:", current_state, ",new_state:", new_state)
	# 默认状态下可以进入任何状态
	if current_state == State.DEFAULT or current_state == State.NONE:
		return true
	# 只能从打开的菜单返回上一状态
	if new_state == previous_state:
		return true
	# 任何其他转换都是非法的
	return false


## 隐藏所有UI节点
func hide_all() -> void:
	for child in self.get_parent().get_children():
		if child is Control:
			child.hide()


#region 状态函数


func _state_default() -> void:
	bg_color.visible = false
	gold_bar.visible = true
	info_bar.visible = true
	navigation_bar.visible = true
	profile_bar.visible = false
	map_bar.visible = false
	task_bar.visible = true
	layout_bar.visible = true
	layout_bar.builds_visible = false
	grid_box_bar.visible = true


func _state_profile() -> void:
	_state_default()
	grid_box_bar.grid_mode = GridBoxBar.GridDisplayMode.DEFAULT
	profile_bar.visible = true
	bg_color.visible = true


func _state_map() -> void:
	_state_default()
	bg_color.visible = true
	map_bar.visible = true


#endregion


func _handle_task() -> void:
	task_bar.visible = true


func _handle_backpack() -> void:
	grid_box_bar.grid_mode = GridBoxBar.GridDisplayMode.BACKPACK


func _handle_inventory() -> void:
	grid_box_bar.grid_mode = GridBoxBar.GridDisplayMode.INVENTORY


func _handle_visitor() -> void:
	# 移动摄像机到前台
	print("_state_visitor")


func _handle_layout() -> void:
	layout_bar.show_builds()


#region 状态处理
## 默认是返回上一状态
func on_escape_pressed() -> void:
	# 检查是否处于父状态机的游戏菜单状态
	if not _is_in_game_state():
		return
	print("子状态机 on_escape_pressed->current_state:", current_state, ",previous_state:", previous_state)
	# 如果子状态机处于默认状态，说明已经没有二级菜单打开
	if current_state == State.DEFAULT:
		# 通知父状态机切换到加载存档菜单
		parent_state_machine.change_state(parent_state_machine.State.SAVE_LOAD_MENU)
		return

	# 如果不是默认状态，则恢复到子状态机的上一状态（比如从背包返回到默认游戏界面）
	recover_state()


## 查看日志信号
func on_journal_pressed() -> void:
	if not _is_in_game_state():
		return
	# 按俩次或esc都可以返回
	if current_state == State.PROFILE:
		change_state(State.DEFAULT)
	else:
		change_state(State.PROFILE)


## 户外探索地图信号
func on_map_pressed() -> void:
	if not _is_in_game_state():
		return
	# 按俩次或esc都可以返回
	if current_state == State.PROFILE:
		change_state(State.DEFAULT)
	else:
		change_state(State.MAP)


#endregion


## 查看任务信号
func on_task_pressed() -> void:
	if not _is_in_default_state():
		return
	task_bar.open_task()


## 下一天信号
func on_new_pressed() -> void:
	if not _is_in_default_state():
		return
	print("game,on_new_pressed")


## 查看来访者信号
func on_visitor_pressed() -> void:
	if not _is_in_default_state():
		return


## 布局建筑、设备和造景
func on_layout_pressed() -> void:
	if not _is_in_default_state():
		return
	layout_bar.open_layout()
	grid_box_bar.grid_mode = GridBoxBar.GridDisplayMode.DEFAULT


## 查看仓库信号
func on_inventory_pressed() -> void:
	if not _is_in_default_state():
		return
	grid_box_bar.open_inventory()
	layout_bar.builds_visible = false
	# 控制信息栏的显示和隐藏，避免和仓库ui重叠
	if grid_box_bar.grid_mode == GridBoxBar.GridDisplayMode.DEFAULT:
		info_bar.visible = true
	else:
		info_bar.visible = false


## 查看背包信号
func on_backpack_pressed() -> void:
	if not _is_in_default_state():
		return
	grid_box_bar.open_backpack()
	layout_bar.builds_visible = false


## 背包整理信号
func on_sort_pressed() -> void:
	if not _is_in_default_state():
		return
	# 仓库和背包状态下才能触发整理
	if not (grid_box_bar.grid_mode == GridBoxBar.GridDisplayMode.BACKPACK or grid_box_bar.grid_mode == GridBoxBar.GridDisplayMode.INVENTORY):
		return
	# 发出整理背包信号
	sort_backpack.emit()


## 仓库背包整理信号
func on_sort_inven_pressed() -> void:
	if not _is_in_default_state():
		return
	# 仓库状态下才能触发仓库整理
	if not grid_box_bar.grid_mode == GridBoxBar.GridDisplayMode.INVENTORY:
		return
	# 发送整理仓库信号
	sort_inventory.emit()


## 确认信号
func on_enter_pressed() -> void:
	if not _is_in_game_state():
		return


## 判断是否在游戏场景中的状态
func _is_in_game_state() -> bool:
	return parent_state_machine.current_state == parent_state_machine.State.GAME_MENU


## 判断是否在游戏主场景的默认状态
func _is_in_default_state() -> bool:
	return _is_in_game_state() and current_state == State.DEFAULT
