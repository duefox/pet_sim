## 菜单的基类
extends Control
class_name BaseMenu

var state_machine: UIStateMachine


func _ready() -> void:
	# TODO
	pass


## 初始化父状态机
func initialize(my_state_machine: UIStateMachine) -> void:
	state_machine = my_state_machine
	# 连接输入管理器的信号到状态机的方法
	if not InputManager.escape_pressed.is_connected(state_machine.on_escape_pressed):
		InputManager.escape_pressed.connect(state_machine.on_escape_pressed)

	if not InputManager.enter_pressed.is_connected(state_machine.on_enter_pressed):
		InputManager.enter_pressed.connect(state_machine.on_enter_pressed)

	if not InputManager.new_pressed.is_connected(state_machine.on_new_pressed):
		InputManager.new_pressed.connect(state_machine.on_new_pressed)

	if not InputManager.load_pressed.is_connected(state_machine.on_load_pressed):
		InputManager.load_pressed.connect(state_machine.on_load_pressed)

	if not InputManager.setting_pressed.is_connected(state_machine.on_setting_pressed):
		InputManager.setting_pressed.connect(state_machine.on_setting_pressed)

	if not InputManager.quit_pressed.is_connected(state_machine.on_quit_pressed):
		InputManager.quit_pressed.connect(state_machine.on_quit_pressed)
