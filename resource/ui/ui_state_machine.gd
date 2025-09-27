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
@onready var new_game_menu: NewGameMenu = $NewGameMenu
@onready var game_main: GameMain = $GameMain
@onready var cmd_line: CMDLine = %CMDLine

# 存储当前状态
var current_state: int = State.NONE
# 存储所有 UI 节点的引用
var ui_nodes: Dictionary[int,Control] = {}
# 之前状态
var previous_state: int = State.NONE


func _ready():
	# 获取所有 UI 界面的引用
	ui_nodes[State.MAIN_MENU] = main_menu
	ui_nodes[State.SAVE_LOAD_MENU] = save_load_menu
	ui_nodes[State.SETTINGS] = settings_memu
	ui_nodes[State.GAME_MENU] = game_main
	ui_nodes[State.NEW_GAME_MENU] = new_game_menu
	# 初始化时隐藏所有 UI
	for node: Control in ui_nodes.values():
		# 初始自己的状态机
		node.initialize(self)
		# 隐藏UI
		node.hide()


## 切换 UI 状态的公共接口
## @param new_state: 目标状态
func change_state(new_state: int) -> void:
	#print("parent change state->new state:", new_state)
	# 弹窗下不切换状态
	if GlobalData.is_popup:
		return
	# 状态相同不切换
	if current_state == new_state:
		return
	# 检查状态转换是否合法
	if not transition_logic(new_state):
		push_warning("Invalid UI state transition from %s to %s" % [State.keys()[current_state], State.keys()[new_state]])
		return

	# 隐藏当前 UI
	if current_state != State.NONE:
		ui_nodes[current_state].hide()

	# 显示新 UI
	if new_state != State.NONE:
		ui_nodes[new_state].show()

	previous_state = current_state
	current_state = new_state

	# 更新加载菜单的按钮显示
	save_load_menu.update_display()
	# 显示游戏场景菜单
	if current_state == State.GAME_MENU:
		game_main.load_game_menu()
		cmd_line.visible = true
	else:
		cmd_line.visible = false


## 恢复之前的状态
func recover_state() -> void:
	#print("parent recover_state")
	change_state(previous_state)


## 判断是否可以进行状态转换
## 你可以在这里添加复杂的转换规则
## @param new_state: 新的状态
## @return bool: 如果转换合法，返回true；否则返回false
func transition_logic(new_state: int) -> bool:
	#print("transition_logic->current_state:", current_state, ",new_state:", new_state)
	if current_state == State.NONE:
		return true

	# 使用 match 语句处理所有状态转换的规则
	match current_state:
		State.MAIN_MENU:
			# 只能从主菜单进入：新游戏、加载存档、设置
			if new_state == State.NEW_GAME_MENU or new_state == State.SETTINGS:
				return true
			if new_state == State.SAVE_LOAD_MENU:
				return true
			# 任何其他转换都是非法的
			return false
		State.SAVE_LOAD_MENU:
			# 只能从加载菜单进入：游戏或返回上一状态
			if new_state == State.GAME_MENU or new_state == State.MAIN_MENU:
				return true
			# 允许返回上一状态，这解决了非主菜单都可以返回的问题
			if new_state == previous_state:
				return true
			# 任何其他转换都是非法的
			return false
		State.SETTINGS:
			# 只能从设置菜单返回上一状态
			if new_state == previous_state:
				return true
			# 任何其他转换都是非法的
			return false
		State.GAME_MENU:
			# 只能从游戏菜单进入：加载存档或返回上一状态
			if new_state == State.SAVE_LOAD_MENU:
				return true
			if new_state == previous_state:
				return true
			# 任何其他转换都是非法的
			return false
		State.NEW_GAME_MENU:
			# 只能从新游戏菜单进入：游戏或返回上一状态
			if new_state == State.GAME_MENU:
				return true
			if new_state == previous_state:
				return true
			# 任何其他转换都是非法的
			return false

	# 默认情况下，所有未定义的转换都是非法的
	return false


## 默认是返回上一状态，但是从游戏退出是到存档状态
func on_escape_pressed() -> void:
	# 处于游戏菜单状态时，将ESC事件处理权交给子状态机
	if current_state == State.GAME_MENU:
		return
	print("父状态机 on_escape_pressed->current_state:", current_state, ",previous_state:", previous_state)
	# 注意这里一定要等1帧，先让子状态机处理完成后才处理父状态机的状态
	await get_tree().process_frame
	# 主菜单下按esc弹窗二次确认是否退出游戏
	if current_state == State.MAIN_MENU:
		# 关闭提示
		if GlobalData.is_popup:
			GlobalData.close_prompt()
			return
		# 弹出提示
		var success: bool = await GlobalData.prompt("确认退出游戏吗？")
		if success:
			get_tree().quit()
		else:
			change_state(State.MAIN_MENU)
		return

	# 对于非主菜单、非游戏菜单状态，恢复到上一个状态
	# 这会处理从设置菜单、加载存档等状态返回的情况
	recover_state()


## 新建存档信号
func on_new_pressed() -> void:
	if not current_state == State.MAIN_MENU:
		return
	# 游戏主场景菜单退出，以便之后可以任意地方创建新存档
	game_main.exit_node()
	# 清空数据
	GlobalData.player.clear_all()
	# 切换状态
	change_state(State.NEW_GAME_MENU)


## 加载存档信号
func on_load_pressed() -> void:
	# 注意这里一定要等1帧，先让子状态机处理完成后才处理父状态机的状态
	await get_tree().process_frame
	# 处于游戏菜单状态时，将ESC事件处理权交给子状态机
	if current_state == State.GAME_MENU:
		return
	# 加载菜单下继续按下L键则加载默认的存档
	if current_state == State.SAVE_LOAD_MENU:
		save_load_menu.load_pressed()
	else:
		change_state(State.SAVE_LOAD_MENU)


## 设置信号
func on_setting_pressed() -> void:
	# 注意这里一定要等1帧，先让子状态机处理完成后才处理父状态机的状态
	await get_tree().process_frame
	# 加载菜单下继续按下S键则保存选定的存档
	if current_state == State.SAVE_LOAD_MENU:
		save_load_menu.save_pressed()
	else:
		change_state(State.SETTINGS)


## 确认信号
func on_enter_pressed() -> void:
	if current_state == State.MAIN_MENU:
		get_tree().quit()
	elif current_state == State.GAME_MENU:
		cmd_line.submit_command()


## 退回到主菜单
func on_quit_pressed() -> void:
	# 注意这里一定要等1帧，先让子状态机处理完成后才处理父状态机的状态
	await get_tree().process_frame
	if not current_state == State.SAVE_LOAD_MENU:
		return
	# 清空数据
	GlobalData.player.clear_all()
	game_main.exit_node()
	# 切换状态
	change_state(State.MAIN_MENU)
