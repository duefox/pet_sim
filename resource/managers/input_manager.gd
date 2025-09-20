## UI界面中所有键盘事件管理
## 这是一个单例（Autoload）脚本，用于集中处理游戏中的所有键盘输入。
## 通过将输入管理和游戏逻辑解耦，可以方便地修改快捷键和响应事件。
extends Node

## Escape 返回信号
signal escape_pressed
## 空格 跳过信号
signal skip_pressed
## enter 确认信号
signal enter_pressed
## N 新建或者下一天信号
signal new_pressed
## L 加载或者布局信号
signal load_pressed
## S 设置信号
signal setting_pressed
## Q 退出信号
signal quit_pressed
## J 查看日志信号
signal journal_pressed
## M 户外探索地图信号
signal map_pressed
## T 查看任务信号
signal task_pressed
## V 查看来访者信号
signal visitor_pressed
## C 查看仓库信号
signal inventory_pressed
## B 查看背包信号
signal backpack_pressed
## R 背包整理信号
signal sort_pressed
## SHIFT+R 仓库背包整理信号
signal sort_inven_pressed
## 鼠标按下左键
signal mouse_left_pressed
## 鼠标按下右键
signal mouse_right_pressed
## 鼠标松开左键
signal mouse_left_released
## 鼠标松开右键
signal mouse_right_released
## 旋转物品，鼠标按下未释放前按住R键
signal rotation_item_pressed
## 鼠标滚轮向上，放大
signal zoom_in_pressed
## 鼠标滚轮向下，缩小
signal zoom_out_pressed
## 拖动信号，传递鼠标相对移动量
signal pan_dragged(relative_motion: Vector2)


## _input函数是Godot内置的，用于接收所有输入事件
func _input(event: InputEvent):
	# 如果是鼠标滚轮向上
	if event.is_action_pressed("mouse_wheel_up"):
		zoom_in_pressed.emit()
	# 如果是鼠标滚轮向下
	elif event.is_action_pressed("mouse_wheel_down"):
		zoom_out_pressed.emit()
	# 如果是鼠标中键按下
	elif event is InputEventMouseMotion:
		if Input.is_action_pressed("mouse_middle"):
			# 发出拖动信号，并传递鼠标的相对移动量
			pan_dragged.emit(event.relative)

	# 如果是Esc键，发出返回信号
	if Input.is_action_just_pressed("keyboard_esc"):
		escape_pressed.emit()
	# 如果是空格键，发出跳过信号
	elif Input.is_action_just_pressed("keyboard_space"):
		skip_pressed.emit()
	# 如果是Enter键，发出确认信号
	elif Input.is_action_just_pressed("keyboard_enter"):
		enter_pressed.emit()
	# 如果是N键，发出新建或下一天信号
	elif Input.is_action_just_pressed("keyboard_n"):
		new_pressed.emit()
	# 如果是L键，发出加载存储信号
	elif Input.is_action_just_pressed("keyboard_l"):
		load_pressed.emit()
	# 如果是S键，发出设置信号
	elif Input.is_action_just_pressed("keyboard_s"):
		setting_pressed.emit()
	# 如果是Q键，发出退出信号
	elif Input.is_action_just_pressed("keyboard_q"):
		quit_pressed.emit()
	# 如果是J键，发出日志信号
	elif Input.is_action_just_pressed("keyboard_j"):
		journal_pressed.emit()
	# 如果是M键，发出地图信号
	elif Input.is_action_just_pressed("keyboard_m"):
		map_pressed.emit()
	# 如果是T键，发出任务信号
	elif Input.is_action_just_pressed("keyboard_t"):
		task_pressed.emit()
	# 如果是V键，发出访客信号
	elif Input.is_action_just_pressed("keyboard_v"):
		visitor_pressed.emit()
	# 如果是C键，发出仓库信号
	elif Input.is_action_just_pressed("keyboard_c"):
		inventory_pressed.emit()
	# 如果是B键，发出背包信号
	elif Input.is_action_just_pressed("keyboard_b"):
		backpack_pressed.emit()
	# 如果是R键，发出整理信号
	elif Input.is_action_just_pressed("keyboard_r"):
		# 检查是否同时按下了其他键
		# `Input.is_action_pressed()` 在按键被按住时持续返回`true`
		if Input.is_action_pressed("keyboard_shift"):
			sort_inven_pressed.emit()
		elif Input.is_action_pressed("mouse_left"):
			rotation_item_pressed.emit()
		else:
			sort_pressed.emit()
	# 如果是鼠标左键按下，发出信号
	elif Input.is_action_just_pressed("mouse_left"):
		mouse_left_pressed.emit()
	# 如果是鼠标右键按下，发出信号
	elif Input.is_action_just_pressed("mouse_right"):
		mouse_right_pressed.emit()
	# 如果是鼠标左键松开，发出信号
	elif Input.is_action_just_released("mouse_left"):
		mouse_left_released.emit()
	# 如果是鼠标右键松开，发出信号
	elif Input.is_action_just_released("mouse_right"):
		mouse_right_released.emit()
