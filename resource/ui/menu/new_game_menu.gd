extends BaseMenu
class_name NewGameMenu

@onready var w_btn_skip: WButtonSkip = $MarginContainer/WBtnSkip
@onready var status_label: Label = $StatusMargin/status_label


func _ready() -> void:
	super()
	# 定义信号
	w_btn_skip.long_press_over.connect(_on_long_press_over)
	SaveSystem.save_created.connect(_on_save_created)
	EventManager.subscribe(UIEvent.CREATE_MAP_SUCCESS, _on_create_map_success)


func _exit_tree() -> void:
	w_btn_skip.long_press_over.disconnect(_on_long_press_over)
	SaveSystem.save_created.disconnect(_on_save_created)


# 切换跳过按钮激活状态的公共方法
func set_skip_active(value: bool) -> void:
	if w_btn_skip:
		w_btn_skip.set_active(value)


## 长按跳过后创建存档
func _on_long_press_over() -> void:
	# 先解了信号连接，避免一次长按触发（创建存档要一定时间）
	w_btn_skip.long_press_over.disconnect(_on_long_press_over)
	_create_game()


## 空存档创建成功
func _on_save_created(save_name: String, metadata: Dictionary) -> void:
	if not w_btn_skip.is_active:
		return
	GlobalData.save_name = save_name
	GlobalData.save_metadata = metadata
	SaveSystem.save_created.disconnect(_on_save_created)
	# 发送第一次创建新档信号
	EventManager.emit_event(UIEvent.CREATE_NEW_SAVE)


## 存档初始化数据成功，需要覆盖空存档
func _on_create_map_success() -> void:
	if not w_btn_skip.is_active:
		return
	await get_tree().create_timer(0.1).timeout
	# 重新连接信号
	if not w_btn_skip.long_press_over.is_connected(_on_long_press_over):
		w_btn_skip.long_press_over.connect(_on_long_press_over)
	# 覆盖空存档
	var save_name: String = await SaveSystem.overwrite_save(GlobalData.save_name)
	if save_name.is_empty():
		push_error("创建存档出错！")
		return
	GlobalData.save_name = save_name
	# 重新连接
	if not SaveSystem.save_created.is_connected(_on_save_created):
		SaveSystem.save_created.connect(_on_save_created)
	# 切换状态
	state_machine.change_state(UIStateMachine.State.GAME_MENU)
	# 还原文本
	status_label.text = ""


func _create_game() -> void:
	var timestamp: float = Time.get_unix_time_from_system()
	var save_name: String = "save_%d" % timestamp
	status_label.text = "正在创建存档..."
	await get_tree().create_timer(0.5).timeout
	# 保存游戏
	_save_game(save_name)


func _save_game(save_name: String) -> void:
	var success = await SaveSystem.create_save(save_name)
	status_label.text = "存档创建" + ("成功" if success else "失败")


## 根据自身的显示和隐藏来激活是否开启长按跳过
func _on_visibility_changed() -> void:
	#print("_on_visibility_changed")
	set_skip_active(self.visible)
