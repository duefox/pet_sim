extends BaseMenu
class_name SaveLoadMenu

const SAVE_SLOTS_SCENE: PackedScene = preload("res://resource/ui/widgets/container/w_save_slots.tscn")

@onready var save_list: VBoxContainer = %SaveList
@onready var tips_label: Label = $MarginContainer/LabelMargin/TipsLabel
@onready var save_margin: MarginContainer = %SaveMargin
@onready var home_margin: MarginContainer = %HomeMargin

## 当前的存档名称
var _save_name: String = ""
## 当前选中的存档插槽
var _cur_save_slots: WSaveSlots


func _ready() -> void:
	super()
	SaveSystem.save_loaded.connect(_on_save_loaded)
	SaveSystem.save_deleted.connect(_on_save_deleted)
	#  更新存档列表
	#_update_save_list()


## 更新存档界面显示
func update_display() -> void:
	if state_machine.previous_state == state_machine.State.GAME_MENU:
		save_margin.visible = true
		home_margin.visible = true
	else:
		save_margin.visible = false
		home_margin.visible = false

	#  更新存档列表
	_update_save_list()


## 加载存档
func load_pressed() -> void:
	_on_btn_load_pressed()


## 保存存档
func save_pressed() -> void:
	_on_btn_save_pressed()


## 存档加载回调
func _on_save_loaded(save_name: String, metadata: Dictionary):
	print("_on_save_loaded->save_name:", save_name)
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
	var saves: Array[Dictionary] = await SaveSystem.get_save_list()
	var index: int = 0
	for save in saves:
		var save_slots: WSaveSlots = SAVE_SLOTS_SCENE.instantiate()
		save_list.add_child(save_slots)
		save_slots.update_info(save.save_name, save.metadata, index)
		if index == 0:
			_cur_save_slots = save_slots
			_cur_save_slots.is_button_pressed = true
			_save_name = save.save_name
		index += 1
		# 监听信号
		save_slots.checked_save.connect(_on_checked_save)
		save_slots.delete_save.connect(_on_delete_save)


## 加载存档
func _on_checked_save(node: WSaveSlots, save_name: String) -> void:
	_save_name = save_name
	if is_instance_valid(_cur_save_slots):
		_cur_save_slots.is_button_pressed = false
	_cur_save_slots = node
	_cur_save_slots.is_button_pressed = true


## 删除存档
func _on_delete_save(save_name: String) -> void:
	tips_label.text = "正在删除存档..."
	var success = SaveSystem.delete_save(save_name)
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
	state_machine.on_quit_pressed()


## 加载存档
func _on_btn_load_pressed() -> void:
	var success = await SaveSystem.load_save(_save_name)
	tips_label.text = "存档加载" + ("成功" if success else "失败")


## 存储存档
func _on_btn_save_pressed() -> void:
	# 覆盖存档需要二次确认
	if GlobalData.is_popup:
		# 关闭提示
		GlobalData.close_prompt()
		return
	# 弹出提示
	var success: bool = await GlobalData.prompt("确认覆盖当前游戏吗？")
	if success:
		SaveSystem.overwrite_save(_save_name)
	else:
		GlobalData.close_prompt()
