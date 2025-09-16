## 菜单主UI状态机，控制菜单的显示和隐藏
extends Node
class_name UIStateMachine

# 定义一个枚举来表示所有 UI 状态
enum State {
	NONE,  # 无 UI 状态
	MAIN_MENU,  # 主菜单
	SAVE_LOAD_MENU,  # 存储加载菜单
	SETTINGS,  # 设置菜单
	GAME_MENU,  # 游戏菜单界面
	NEW_GAME_MENU,  # 游戏菜单界面
}

@onready var main_bg: Control = $MainBG
@onready var main_menu: MainMenu = $MainMenu
@onready var save_load_menu: SaveLoadMenu = $SaveLoadMenu
@onready var settings_memu: SettingsMemu = $SettingsMemu
@onready var game_menu: GameMenu = $GameMenu
@onready var new_game_menu: NewGameMenu = $NewGameMenu

# 存储当前状态
var current_state: int = State.NONE
# 存储所有 UI 节点的引用
var ui_nodes: Dictionary[int,Control] = {}

# 之前状态
var _previous_state: int = State.NONE


func _ready():
	# 获取所有 UI 界面的引用
	ui_nodes[State.MAIN_MENU] = main_menu
	ui_nodes[State.SAVE_LOAD_MENU] = save_load_menu
	ui_nodes[State.SETTINGS] = settings_memu
	ui_nodes[State.GAME_MENU] = game_menu
	ui_nodes[State.NEW_GAME_MENU] = new_game_menu
	# 初始化时隐藏所有 UI
	for node in ui_nodes.values():
		# 隐藏UI
		node.hide()


## 切换 UI 状态的公共接口
## @param new_state: 目标状态
func change_state(new_state: int) -> void:
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

	_previous_state = current_state
	current_state = new_state

## 恢复之前的状态
func recover_state() -> void:
	change_state(_previous_state)

## 判断是否可以进行状态转换
## 你可以在这里添加复杂的转换规则
func can_transition(new_state: int) -> bool:
	# 只能从主菜单进入设置
	if current_state == State.MAIN_MENU and new_state == State.SETTINGS:
		return true
	# 只能从存储加载菜单进入游戏
	if current_state == State.SAVE_LOAD_MENU and new_state == State.GAME_MENU:
		return true
	# 能从游戏主场景菜单或者主菜单进入存储加载
	if (current_state == State.MAIN_MENU or current_state == State.GAME_MENU) and new_state == State.SAVE_LOAD_MENU:
		return true

	# 默认允许所有转换
	return true
