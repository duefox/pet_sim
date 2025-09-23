## 所有网格容器的父节点
extends GameBar
class_name GridBoxBar

const W_INVEN_SCENE: PackedScene = preload("res://resource/ui/widgets/w_inventory.tscn")
const W_BACKPACK_SCENE: PackedScene = preload("res://resource/ui/widgets/w_backpack.tscn")
const W_QT_SCENE: PackedScene = preload("res://resource/ui/widgets/w_quick_tools.tscn")

@onready var inventory_margin: MarginContainer = $InventoryMargin
@onready var backpack_margin: MarginContainer = $BackpackMargin
@onready var quick_tool_margin: MarginContainer = $QuickToolMargin

## 网格容器的节点显示模式：DEFAULT-只显示快捷栏，INVENTORY-显示仓库和背包，BACKPACK-显示背包和快捷栏
enum GridDisplayMode { DEFAULT, INVENTORY, BACKPACK }

var w_inventory: WInventory
var w_backpack: WBackpack
var w_quick_tools: WQuickTools

## 仓库容器
var _inventory: MultiGridContainer
## 背包容器
var _backpack: MultiGridContainer
## 快捷栏容器
var _quick_tools: MultiGridContainer

#region 命令行相关变量
## 当前要添加物品的背包
var _cur_bag: MultiGridContainer
## 物品id
var _item_id: String = ""
## 物品数量
var _item_num: int = 1
## 物品级别
var _item_level: int = 0
## 成长值
var _item_grow: float = 100.0

#endregion

## 设置网格容器的显示模式
var grid_mode: GridDisplayMode:
	set = _setter_grid_mode


func _ready() -> void:
	super()
	# 初始化3个背包
	w_inventory = W_INVEN_SCENE.instantiate()
	inventory_margin.add_child(w_inventory)
	w_backpack = W_BACKPACK_SCENE.instantiate()
	backpack_margin.add_child(w_backpack)
	w_quick_tools = W_QT_SCENE.instantiate()
	quick_tool_margin.add_child(w_quick_tools)
	initialize()
	# 订阅总线事件
	EventManager.subscribe(UIEvent.SUB_ITEM, _on_sub_item)
	EventManager.subscribe(UIEvent.BACKPACK_CHANGED, _on_backpack_changed)
	EventManager.subscribe(UIEvent.INVENTORY_CHANGED, _on_inventory_changed)
	EventManager.subscribe(UIEvent.QUICK_TOOLS_CHANGED, _on_quick_tools_changed)
	# 内部信号事件
	w_quick_tools.next_day_pressed.connect(_on_next_day_pressed)


func _exit_tree() -> void:
	EventManager.unsubscribe(UIEvent.SUB_ITEM, _on_sub_item)
	EventManager.unsubscribe(UIEvent.BACKPACK_CHANGED, _on_backpack_changed)
	EventManager.unsubscribe(UIEvent.INVENTORY_CHANGED, _on_inventory_changed)
	EventManager.unsubscribe(UIEvent.QUICK_TOOLS_CHANGED, _on_quick_tools_changed)


func initialize() -> void:
	grid_mode = GridDisplayMode.DEFAULT
	_inventory = get_inventory()
	_backpack = get_backpack()
	_quick_tools = get_quick_tools()
	# 命令行设置快捷栏为当前背包
	_cur_bag = _backpack


## 获得仓库容器
func get_inventory() -> MultiGridContainer:
	return w_inventory.get_grid_container()


## 获得背包容器
func get_backpack() -> MultiGridContainer:
	return w_backpack.get_grid_container()


## 获得快捷工具容器
func get_quick_tools() -> MultiGridContainer:
	return w_quick_tools.get_grid_container()


## 设置网格容器的显示模式
func _setter_grid_mode(value: GridDisplayMode) -> void:
	grid_mode = value
	if grid_mode == GridDisplayMode.DEFAULT:
		w_inventory.visible = false
		w_backpack.visible = false
		w_quick_tools.visible = true
	elif grid_mode == GridDisplayMode.INVENTORY:
		w_inventory.visible = true
		w_backpack.visible = true
		w_quick_tools.visible = false
	elif grid_mode == GridDisplayMode.BACKPACK:
		w_inventory.visible = false
		w_backpack.visible = true
		w_quick_tools.visible = true
	# 发送信号
	#state_switch.emit(self, grid_mode)


## 下一天
func _on_next_day_pressed() -> void:
	state_machine.on_new_pressed()


## 背包物品更新
func _on_backpack_changed(data: Dictionary) -> void:
	# 当收到背包数据变化的事件时，调用UI的更新方法
	if _backpack:
		_backpack.update_view(data.get("items_data", []))


## 仓库物品更新
func _on_inventory_changed(data: Dictionary) -> void:
	# 当收到背包数据变化的事件时，调用UI的更新方法
	if _inventory:
		_inventory.update_view(data.get("items_data", []))


## 快捷栏物品更新
func _on_quick_tools_changed(data: Dictionary) -> void:
	# 当收到背包数据变化的事件时，调用UI的更新方法
	if _quick_tools:
		_quick_tools.update_view(data.get("items_data", []))


## 分割物品
func _on_sub_item() -> void:
	if GlobalData.previous_cell_matrix is TrashGridContainer:
		print("TrashGridContainer can't sub.")
		return
	# 默认快捷工具栏不能分割物品
	if grid_mode == GridDisplayMode.DEFAULT:
		return
	var cell_pos: Vector2 = MouseEvent.mouse_cell_pos
	var item_data: WItemData = GlobalData.previous_cell_matrix.get_grid_map_item(cell_pos)
	var item: WItem = item_data.link_item
	var succ: bool = false
	var extra_args: Dictionary = {
		"item_level": item.item_level,
		"growth": item.growth,
	}
	# 背包和工具的物品之间进行分割
	if grid_mode == GridDisplayMode.BACKPACK:
		if GlobalData.previous_cell_matrix.name == "QuickTools":
			# 快捷栏物品分隔到背包
			succ = _backpack.add_item_with_merge(item.id, 1, extra_args)
			if succ:
				_quick_tools.sub_item_at(cell_pos)
			else:
				push_warning("add_item_with_merge failed")
			emit_changed_event(_quick_tools, _backpack)
		else:
			# 背包物品分割到快捷栏
			succ = _quick_tools.add_item_with_merge(item.id, 1, extra_args)
			if succ:
				_backpack.sub_item_at(cell_pos)
			else:
				push_warning("add_item_with_merge failed")
			emit_changed_event(_backpack, _quick_tools)
	# 背包和仓库的物品之间进行分割
	elif grid_mode == GridDisplayMode.INVENTORY:
		if GlobalData.previous_cell_matrix.name == "Packback":
			# 背包物品分割到仓库
			succ = _inventory.add_item_with_merge(item.id, 1, extra_args)
			if succ:
				_backpack.sub_item_at(cell_pos)
			else:
				push_warning("add_item_with_merge failed")
			emit_changed_event(_backpack, _inventory)
		else:
			# 仓库物品分割到背包
			succ = _backpack.add_item_with_merge(item.id, 1, extra_args)
			if succ:
				_inventory.sub_item_at(cell_pos)
			else:
				push_warning("add_item_with_merge failed")
			emit_changed_event(_inventory, _backpack)


## 发送物品更新信息信号
func emit_changed_event(from: MultiGridContainer, to: MultiGridContainer) -> void:
	#print("sub_item->form:", from, ",to:", to)
	EventManager.emit_event(UIEvent.ITEMS_CHANGED, {"container": from})
	EventManager.emit_event(UIEvent.ITEMS_CHANGED, {"container": to})


#region 网格容器操作方法


## 打开背包
func open_backpack() -> void:
	#print("_on_btn_bag_pressed")
	if grid_mode == GridDisplayMode.BACKPACK:
		grid_mode = GridDisplayMode.DEFAULT
	else:
		grid_mode = GridDisplayMode.BACKPACK


## 打开仓库
func open_inventory() -> void:
	#print("_on_btn_inventory_pressed")
	if grid_mode == GridDisplayMode.INVENTORY:
		grid_mode = GridDisplayMode.DEFAULT
	else:
		grid_mode = GridDisplayMode.INVENTORY


#endregion

#region 命令行事件


func _on_bag_option_item_selected(index: int) -> void:
	if index == 0:
		_cur_bag = _quick_tools
	elif index == 1:
		_cur_bag = _backpack
	elif index == 2:
		_cur_bag = _inventory


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
	#_cur_bag.cmd_add_item(item_id, item_num, extra_args)
	if not GlobalData.player:
		return
		
	if _cur_bag == _backpack:
		GlobalData.player.backpack_comp.add_item(item_id, item_num, extra_args)
	elif _cur_bag == _inventory:
		GlobalData.player.inventory_comp.add_item(item_id, item_num, extra_args)
	elif _cur_bag == _quick_tools:
		GlobalData.player.quick_tools_comp.add_item(item_id, item_num, extra_args)
