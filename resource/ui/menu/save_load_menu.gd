extends BaseMenu
class_name SaveLoadMenu

const SAVE_SLOTS_SCENE: PackedScene = preload("res://resource/ui/widgets/container/w_save_slots.tscn")

@onready var save_list: VBoxContainer = %SaveList
@onready var tips_label: Label = $MarginContainer/LabelMargin/TipsLabel
@onready var btn_home: ButtonMiddle = %BtnHome


func _ready() -> void:
	super()
	GlobalData.save.save_loaded.connect(_on_save_loaded)
	GlobalData.save.save_deleted.connect(_on_save_deleted)
	#  更新存档列表
	_update_save_list()


## 更新存档界面显示
func update_display() -> void:
	#print(state_machine.previous_state,",update_display:", state_machine.previous_state == state_machine.State.GAME_MENU)
	if state_machine.previous_state == state_machine.State.GAME_MENU:
		btn_home.visible = true
	else:
		btn_home.visible = false


## 存档加载回调
func _on_save_loaded(save_name: String, metadata: Dictionary):
	GlobalData.save_name = save_name
	GlobalData.save_metadata = metadata
	state_machine.change_state(state_machine.State.GAME_MENU)


## 存档删除回调
func _on_save_deleted(save_name: String):
	print("存档已删除：%s" % save_name)


## 更新存档列表
func _update_save_list():
	# 清空save_list
	_clear_save_list()
	var saves: Array[Dictionary] = await GlobalData.save.get_save_list()
	for save in saves:
		var save_slots: WSaveSlots = SAVE_SLOTS_SCENE.instantiate()
		save_list.add_child(save_slots)
		save_slots.update_info(save.save_name, save.metadata)
		# 监听信号
		save_slots.load_save.connect(_on_load_save)
		save_slots.delete_save.connect(_on_delete_save)


## 加载存档
func _on_load_save(save_name: String) -> void:
	var success = await GlobalData.save.load_save(save_name)
	tips_label.text = "存档加载" + ("成功" if success else "失败")


## 删除存档
func _on_delete_save(save_name: String) -> void:
	tips_label.text = "正在删除存档..."
	var success = GlobalData.save.delete_save(save_name)
	tips_label.text = "存档删除" + ("成功" if success else "失败")
	if success:
		_update_save_list()


func _set_game_saves() -> void:
	for save_btn: ButtonSmall in save_list.get_children():
		var index: int = save_btn.get_index()
		save_btn.set_row(index)


## 清空存档列表
func _clear_save_list() -> void:
	for child in save_list.get_children():
		child.queue_free()


## 恢复之前的状态
func _on_btn_back_pressed() -> void:
	# 恢复之前的状态
	state_machine.recover_state()


## 返回主菜单
func _on_btn_home_pressed() -> void:
	print("_on_btn_home_pressed")
	state_machine.change_state(state_machine.State.MAIN_MENU)
