extends MarginContainer
class_name WSaveSlots

@onready var btn_load: ButtonEmpty = $MarginContainer/BtnLoad
@onready var bg_margin: MarginContainer = $BGMargin

## 选中信号
signal checked_save(node, save_name)
## 删除信号
signal delete_save(save_name)

## 是否按下
var is_button_pressed: bool:
	set = _setter_button_pressed

## 存档名称
var _save_name: String
## 奇数偶数行
var _index: int


## 更新显示信息
func update_info(save_name: String, metadata: Dictionary, index: int = 0) -> void:
	_index = index % 2
	_save_name = save_name
	btn_load.text = save_name.to_upper() + "  创建时间：" + (metadata.save_date as String).replace("T", " ")
	_set_box_style(_index)


## 更新按下状态
func _setter_button_pressed(value: bool) -> void:
	is_button_pressed = value
	if is_button_pressed:
		_set_box_style(2)
	else:
		_set_box_style(_index)


## 设置样式
func _set_box_style(index: int) -> void:
	for child: NinePatchRect in bg_margin.get_children():
		child.visible = false
	bg_margin.get_child(index).visible = true


func _on_btn_delete_pressed() -> void:
	delete_save.emit(_save_name)


func _on_btn_load_pressed() -> void:
	if is_button_pressed:
		return
	is_button_pressed = true
	checked_save.emit(self, _save_name)
