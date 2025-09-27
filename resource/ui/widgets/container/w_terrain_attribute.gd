extends Control
class_name WTerrianAttribute

@onready var main_margin: MarginContainer = $MainMargin
@onready var nickname: Label = %Nickname
@onready var decrip: Label = %Decrip
@onready var output_descrip: Label = %OutputDescrip
@onready var buffers_container: HBoxContainer = %BuffersContainer
@onready var upgrade_materials: HBoxContainer = %UpgradeMaterials


func update_display(data: Dictionary) -> void:
	if data.is_empty():
		return
	nickname.text = data["item_name"]
	decrip.text = data["descrip"]
	output_descrip.text = data["item_info"]["output_desc"]


## 获得容器的实际大小
func get_real_size() -> Vector2:
	return main_margin.size


## 拆除地形建筑
func _on_btn_delete_pressed() -> void:
	pass  # Replace with function body.


## 升级地形建筑
func _on_btn_upgrade_pressed() -> void:
	pass  # Replace with function body.


## 关闭窗口
func _on_btn_close_pressed() -> void:
	queue_free()
