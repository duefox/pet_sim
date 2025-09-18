extends BaseMenu
class_name NewGameMenu

@onready var w_btn_skip: WButtonSkip = $MarginContainer/WBtnSkip
@onready var status_label: Label = $StatusMargin/status_label


func _ready() -> void:
	super()
	w_btn_skip.long_press_over.connect(_on_long_press_over)
	GlobalData.save.save_created.connect(_on_save_created)


func _exit_tree() -> void:
	w_btn_skip.long_press_over.disconnect(_on_long_press_over)
	GlobalData.save.save_created.disconnect(_on_save_created)


func _on_long_press_over() -> void:
	w_btn_skip.long_press_over.disconnect(_on_long_press_over)
	_create_game()


func _on_save_created(save_name: String, metadata: Dictionary) -> void:
	await get_tree().create_timer(0.3).timeout
	GlobalData.save_name = save_name
	GlobalData.save_metadata = metadata
	state_machine.change_state(UIStateMachine.State.GAME_MENU)


func _create_game() -> void:
	var timestamp: float = Time.get_unix_time_from_system()
	var save_name: String = "save_%d" % timestamp
	status_label.text = "正在创建存档..."
	await get_tree().create_timer(0.5).timeout
	# 保存游戏
	_save_game(save_name)


func _save_game(save_name: String) -> void:
	var success = await GlobalData.save.create_save(save_name)
	status_label.text = "存档创建" + ("成功" if success else "失败")
