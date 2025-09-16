extends MarginContainer
class_name WSaveSlots

@onready var btn_load: ButtonSmall = $BtnLoad

## 加载信号
signal load_save(save_name)
## 删除信号
signal delete_save(save_name)

## 存档名称
var _save_name: String


func update_info(save_name: String, metadata: Dictionary) -> void:
	_save_name = save_name
	btn_load.text = save_name.to_upper() + "  创建时间：" + (metadata.save_date as String).replace("T", " ")


func _on_btn_load_pressed() -> void:
	load_save.emit(_save_name)


func _on_btn_delete_pressed() -> void:
	delete_save.emit(_save_name)
