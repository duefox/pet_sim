extends MarginContainer
class_name CMDLine

#region 命令行相关变量
## 当前要添加物品的背包
var _cur_index: int
## 物品id
var _item_id: String = ""
## 物品数量
var _item_num: int = 1
## 物品级别
var _item_level: int = 0
## 成长值
var _item_grow: float = 100.0

#endregion


func _ready() -> void:
	# 命令行设置为当前背包
	_cur_index = 1


#region 命令行事件


func _on_bag_option_item_selected(index: int) -> void:
	_cur_index = index


func _on_level_option_item_selected(index: int) -> void:
	_item_level = index


func _on_id_edit_text_changed(new_text: String) -> void:
	_item_id = new_text


func _on_num_spin_value_changed(value: float) -> void:
	_item_num = int(value)


func _on_grow_option_item_selected(index: int) -> void:
	if index == 0:
		_item_grow = 100.0
	else:
		_item_grow = 0.0


## enter提交命令
func submit_command() -> void:
	_on_btn_add_pressed()


## 提交命令行代码
func _on_btn_add_pressed() -> void:
	if not _item_id.length() == 4:
		print("无效代码，正在打印孤儿节点->")
		Window.print_orphan_nodes()
		return
	_cmd_add_item(_item_id, _item_num, _item_level, _item_grow)


#endregion


## 命令行添加物品
func _cmd_add_item(item_id: String, item_num: int, item_level: int, item_grow: float) -> void:
	# 附加额外属性
	var extra_args: Dictionary = {
		"item_level": item_level,
		"growth": item_grow,
	}
	if not GlobalData.player:
		return
		
	print("item_id:",item_id,",_cur_index:",_cur_index)

	if _cur_index == 0:
		GlobalData.player.quick_tools_comp.add_item(item_id, item_num, extra_args)
	elif _cur_index == 1:
		GlobalData.player.backpack_comp.add_item(item_id, item_num, extra_args)
	elif _cur_index == 2:
		GlobalData.player.inventory_comp.add_item(item_id, item_num, extra_args)
	elif _cur_index == 3:
		GlobalData.player.world_map_comp.add_item(item_id, item_num, extra_args)
	elif _cur_index == 4:
		GlobalData.player.landscape_comp.add_item(item_id, item_num, extra_args)
