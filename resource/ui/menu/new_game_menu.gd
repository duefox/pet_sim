extends BaseMenu
class_name NewGameMenu

@onready var w_btn_skip: WButtonSkip = $MarginContainer/WBtnSkip
@onready var status_label: Label = $StatusMargin/status_label


func _ready() -> void:
	super()
	w_btn_skip.long_press_over.connect(_on_long_press_over)
	SaveSystem.save_created.connect(_on_save_created)


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


func _on_save_created(save_name: String, metadata: Dictionary) -> void:
	await get_tree().create_timer(0.1).timeout
	# 重新连接信号
	w_btn_skip.long_press_over.connect(_on_long_press_over)
	# 切换状态
	GlobalData.save_name = save_name
	GlobalData.save_metadata = metadata
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
	print("_on_visibility_changed")
	set_skip_active(self.visible)
