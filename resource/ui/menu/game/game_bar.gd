## 游戏主场景各个栏的基类
extends Control
class_name GameBar

var state_machine: BarStateMachine

func _ready() -> void:
	await get_tree().process_frame
	if not is_instance_valid(state_machine):
		push_warning("state_machine is null")
		return
	# 连接输入管理器的信号到状态机的方法
	if not InputManager.escape_pressed.is_connected(state_machine.on_escape_pressed):
		InputManager.escape_pressed.connect(state_machine.on_escape_pressed)

	if not InputManager.enter_pressed.is_connected(state_machine.on_enter_pressed):
		InputManager.enter_pressed.connect(state_machine.on_enter_pressed)

	if not InputManager.new_pressed.is_connected(state_machine.on_new_pressed):
		InputManager.new_pressed.connect(state_machine.on_new_pressed)

	if not InputManager.journal_pressed.is_connected(state_machine.on_journal_pressed):
		InputManager.journal_pressed.connect(state_machine.on_journal_pressed)

	if not InputManager.map_pressed.is_connected(state_machine.on_map_pressed):
		InputManager.map_pressed.connect(state_machine.on_map_pressed)

	if not InputManager.task_pressed.is_connected(state_machine.on_task_pressed):
		InputManager.task_pressed.connect(state_machine.on_task_pressed)

	if not InputManager.visitor_pressed.is_connected(state_machine.on_visitor_pressed):
		InputManager.visitor_pressed.connect(state_machine.on_visitor_pressed)

	if not InputManager.inventory_pressed.is_connected(state_machine.on_inventory_pressed):
		InputManager.inventory_pressed.connect(state_machine.on_inventory_pressed)

	if not InputManager.backpack_pressed.is_connected(state_machine.on_backpack_pressed):
		InputManager.backpack_pressed.connect(state_machine.on_backpack_pressed)
		
	if not InputManager.load_pressed.is_connected(state_machine.on_layout_pressed):
		InputManager.load_pressed.connect(state_machine.on_layout_pressed)

	if not InputManager.sort_pressed.is_connected(state_machine.on_sort_pressed):
		InputManager.sort_pressed.connect(state_machine.on_sort_pressed)

	if not InputManager.sort_inven_pressed.is_connected(state_machine.on_sort_inven_pressed):
		InputManager.sort_inven_pressed.connect(state_machine.on_sort_inven_pressed)
