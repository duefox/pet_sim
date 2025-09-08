# ui_state_machine.gd
extends Node
class_name UIStateMachine

# 定义一个枚举来表示所有 UI 状态
enum State {
	NONE,       # 无 UI 状态
	MAIN_MENU,  # 主菜单
	SETTINGS,   # 设置菜单
	INVENTORY,  # 背包界面
	PAUSE       # 暂停菜单
}

@onready var main_bg: Control = $MainBG
@onready var main_menu: Control = $MainMenu



# 存储当前状态
var current_state = State.NONE
# 存储所有 UI 节点的引用
var ui_nodes = {}

func _ready():
	# 获取所有 UI 界面的引用
	ui_nodes[State.MAIN_MENU] = main_menu
	#ui_nodes[State.SETTINGS] = settings
	
	
	# 初始化时隐藏所有 UI
	for node in ui_nodes.values():
		node.hide()

## 切换 UI 状态的公共接口
## @param new_state: 目标状态
func transition_to(new_state: int):
	# 检查状态转换是否合法
	if not can_transition(new_state):
		push_warning("Invalid UI state transition from %s to %s" % [State.keys()[current_state], State.keys()[new_state]])
		return

	# 隐藏当前 UI
	if current_state != State.NONE:
		ui_nodes[current_state].hide()

	# 显示新 UI
	if new_state != State.NONE:
		ui_nodes[new_state].show()

	current_state = new_state
	
	print("UI State changed to: ", State.keys()[current_state])

## 判断是否可以进行状态转换
## 你可以在这里添加复杂的转换规则
func can_transition(new_state: int) -> bool:
	# 示例规则：不能从暂停菜单直接进入主菜单
	if current_state == State.PAUSE and new_state == State.MAIN_MENU:
		return false
	
	# 示例规则：只能从主菜单进入设置
	if current_state == State.MAIN_MENU and new_state == State.SETTINGS:
		return true

	# 默认允许所有转换
	return true
