## 全局资源和变量管理类
extends Node

## 默认数据（方便调试）
const DEFAULT_RES: Resource = preload("res://data/default.tres")

## 游戏玩家
var player: Player
## 当前使用的存档名称
var save_name: String
## 当前使用存档的元数据
var save_metadata: Dictionary

## 是否已弹窗
var is_popup: bool = false

#region 预加载资源相关变量
## @param StringName 物品的唯一id
## @param String 物品的资源路径
var pet_res: Dictionary[StringName,String] = {}
## 食物，便便，蛋之类的掉落物资源
var drop_res: Dictionary[StringName,String] = {}
#endregion

#region 背包容器相关变量

## 全局多格容器的格子大小
var cell_size: int = 48
## 游戏主场景中菜单UI节点的引用
var ui: GameMenu
## 上一次操作的物品节点(引用)
var previous_item: WItem
## 上一次操作的MultiGridContainer(引用)
var previous_cell_matrix: MultiGridContainer
## 放置提示框的颜色类型
var placement_overlay_type: int
## 存储上一次的格子坐标
var prent_cell_pos: Vector2
## 当前选中的物品(引用)
var cur_selected_item: WItem
## 基础的物品数据，格式如下
var data: Dictionary[String,Dictionary]
#endregion

## 弹窗场景
var _confirm: WConfirm


func _ready() -> void:
	# 加载一个id为999的默认数据(方便F6调试）
	create_textures_item(DEFAULT_RES)


## 创建纹理表的内容单元（这些数据用于背包显示）
func create_textures_item(res_data: Resource = null) -> void:
	# 只处理ItemBaseData类型的资源
	if not res_data or not (res_data is ItemBaseData):
		return
	# 资源数据
	res_data = res_data as ItemBaseData
	var space_width: int = res_data.width
	var space_height: int = res_data.height
	# 属性数据
	var base_data: Dictionary = {
		"id": res_data.id,  # id
		"item_name": res_data.nickname,  # 昵称
		"item_type": res_data.item_type,  # 类型
		"item_level": res_data.item_level,  # 级别
		"growth": res_data.growth,  # 成长度
		"base_price": res_data.base_price,  # 基础价格
		"descrip": res_data.descrip,  # 描述
		"width": space_width,  # 占用宽度
		"height": space_height,  # 占用高度
		"orientation": res_data.orientation,  # 方向
		"stackable": res_data.stackable,  # 是否可堆叠
		"num": 1,  # 数量
		"max_stack_size": res_data.max_stack_size,  # 最大堆叠数
		"item_info": res_data,  # 详细数据（包含以上）
	}

	data[res_data.id] = base_data


## 根据物品id找对应的物品data
func find_item_data(id: String) -> Dictionary:
	if data.has(id):
		return data[id]
	return {}


## 全局弹窗
func prompt(text: String = "") -> bool:
	is_popup = true
	#二次弹窗确认
	_confirm = WConfirm.new()
	add_child(_confirm)
	var success: bool = await _confirm.prompt(text)
	is_popup = false
	return success


## 关闭弹窗
func close_prompt() -> void:
	if is_popup:
		is_popup = false
		if is_instance_valid(_confirm):
			_confirm.queue_free()


## 获取窗口的大小
func get_win_size() -> Vector2:
	var viewport_width: int = ProjectSettings.get_setting("display/window/size/viewport_width", 1152)
	var viewport_height: int = ProjectSettings.get_setting("display/window/size/viewport_height", 648)
	var viewport_scale: float = ProjectSettings.get_setting("display/window/stretch/scale", 1.0)
	return Vector2(viewport_width, viewport_height) / viewport_scale
