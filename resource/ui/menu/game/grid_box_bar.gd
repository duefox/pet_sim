## 所有网格容器的父节点
extends Control
class_name GridBoxBar

@onready var w_inventory: WInventory = %WInventory
@onready var w_backpack: WBackpack = %WBackpack
@onready var w_quick_tools: WQuickTools = %WQuickTools

## 网格容器的节点显示模式：DEFAULT-只显示快捷栏，INVENTORY-显示仓库和背包，BACKPACK-显示背包和快捷栏
enum GridDisplayMode { DEFAULT, INVENTORY, BACKPACK }

## 设置网格容器的显示模式
var grid_mode: GridDisplayMode = GridDisplayMode.DEFAULT:
	set = set_grid_mode


func _ready() -> void:
	grid_mode = GridDisplayMode.DEFAULT
	# 订阅事件
	EventManager.subscribe(UIEvent.SUB_ITEM, _on_sub_item)
	pass


func _exit_tree() -> void:
	EventManager.unsubscribe(UIEvent.SUB_ITEM, _on_sub_item)
	pass


## 获得仓库容器
func get_inventory() -> MultiGridContainer:
	return w_inventory.get_grid_container()


## 获得背包容器
func get_backpack() -> MultiGridContainer:
	return w_backpack.get_grid_container()


## 获得快捷工具容器
func get_quick_tool() -> MultiGridContainer:
	return w_quick_tools.get_grid_container()


## 设置网格容器的显示模式
func set_grid_mode(value: GridDisplayMode) -> void:
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


## 分割物品
func _on_sub_item() -> void:
	# 默认快捷工具栏不能分割物品
	if grid_mode == GridDisplayMode.DEFAULT:
		return
	var cell_pos: Vector2 = MouseEvent.mouse_cell_pos
	var item_data: WItemData = GlobalData.previous_cell_matrix.get_grid_map_item(cell_pos)
	print(GlobalData.previous_cell_matrix.name)
	# 背包和工具的物品之间进行分割
	if grid_mode == GridDisplayMode.BACKPACK:
		pass
	# 背包和仓库的物品之间进行分割
	elif grid_mode == GridDisplayMode.INVENTORY:
		pass


## 打开背包（隐藏的按钮，方便绑定快捷键）
func _on_btn_bag_pressed() -> void:
	#print("_on_btn_bag_pressed")
	if grid_mode == GridDisplayMode.BACKPACK:
		grid_mode = GridDisplayMode.DEFAULT
	else:
		grid_mode = GridDisplayMode.BACKPACK


## 打开仓库（隐藏的按钮，方便绑定快捷键）
func _on_btn_inventory_pressed() -> void:
	#print("_on_btn_inventory_pressed")
	if grid_mode == GridDisplayMode.INVENTORY:
		grid_mode = GridDisplayMode.DEFAULT
	else:
		grid_mode = GridDisplayMode.INVENTORY
