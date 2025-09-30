## 全局资源和变量管理类
extends Node

## 物品级别背景色
const LEVEL_BG_COLOR: Dictionary = {
	0: Color("ffffff00"),  # 普通
	1: Color("F0C050"),  # 稀有  #FFFF00
	2: Color("00BFFF"),  # 罕见
	3: Color("A335EE"),  # 传说
}

## 游戏玩家
var player: Player
## 当前使用的存档名称
var save_name: String
## 当前使用存档的元数据
var save_metadata: Dictionary
## 是否已弹窗
var is_popup: bool = false
## 材料拾取获得值的范围
var pick_up_range: Vector2i = Vector2i(6, 10)
## 单格房间食物最大放置量
var room_max_food: int = 99

#region 预加载资源相关变量
## @param StringName 物品的唯一id
## @param String 物品的资源路径
## 除宠物之外的所有物品资源
var all_res: Dictionary[StringName,String] = {}
## 宠物资源
var pet_res: Dictionary[StringName,String] = {}
## 建筑边框
var border_res: Dictionary[StringName,String] = {}
#endregion

#region 背包容器相关变量

## 全局多格容器的格子大小
var cell_size: int = 48
## 全局单格容器的格子大小
var single_cell_size: int = 64
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
## 物品的资源数据
var items_res: Dictionary[String,Resource]

#endregion

## 弹窗场景
var _confirm: WConfirm


## 创建纹理表的内容单元（这些数据用于背包显示）
func create_textures_item(res_data: Resource = null) -> void:
	# 只处理BaseItemData类型的资源
	if not res_data or not (res_data is BaseItemData):
		return
	# 资源数据
	res_data = res_data as BaseItemData
	var space_width: int = res_data.width
	var space_height: int = res_data.height
	# 属性数据
	var base_data: Dictionary = {
		"id": res_data.id,  # id
		"item_name": res_data.nickname,  # 昵称
		"item_type": res_data.item_type,  # 类型
		"item_level": res_data.item_level,  # 级别
		"growth": res_data.growth,  # 成长度
		"gender": res_data.gender,  # 性别
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
	# 基础数据
	data[res_data.id] = base_data
	items_res[res_data.id] = res_data


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
