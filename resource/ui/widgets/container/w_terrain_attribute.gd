extends Control
class_name WTerrianAttribute

@onready var main_margin: MarginContainer = $MainMargin
@onready var nickname: Label = %Nickname
@onready var decrip: RichTextLabel = %Decrip
@onready var output_descrip: RichTextLabel = %OutputDescrip
@onready var buffers_container: HBoxContainer = %BuffersContainer
@onready var upgrade_materials: HBoxContainer = %UpgradeMaterials
@onready var btn_delete: ButtonSmall = %BtnDelete
@onready var btn_open: ButtonSmall = %BtnOpen


func update_display(data: Dictionary) -> void:
	if data.is_empty():
		return
	nickname.text = data["item_name"]
	decrip.text = str(data["descrip"])
	output_descrip.text = str(data["item_info"]["output_desc"])
	var can_delete: bool = data["item_info"].get("can_delete", false)
	btn_delete.visible = can_delete
	# 特殊，只有仓库等才有打开按钮
	if data["item_info"].has("inventory_sizes"):
		btn_open.visible = true
	else:
		btn_open.visible = false


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


## 打开仓库
func _on_btn_open_pressed() -> void:
	queue_free()
	EventManager.emit_event(UIEvent.OPEN_INVENTORY)
