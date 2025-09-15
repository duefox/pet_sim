## 全局资源和变量管理类
extends Node

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
## 游戏中菜单UI节点的引用
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
func find_item_data(id: String) -> Variant:
	if data.has(id):
		return data[id]
	return false


## 计算占用空间大小,JUVENILE
## 规则是用成年的大小除以2向上取整
func _get_juvenile_space(space: int = 1) -> int:
	return Utils.get_juvenile_space(space)
