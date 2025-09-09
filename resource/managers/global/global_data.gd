## 全局资源和变量管理类
extends Node

var cell_size: int = 48
var ui: GameMenu  # 游戏中菜单UI节点的引用
var previous_item: WItem  # 上一次操作的物品节点(引用)
var previous_cell_matrix: MultiGridContainer  # 上一次操作的MultiGridContainer(引用)
var placement_overlay_type: int  # 放置提示框的颜色类型
var prent_cell_pos: Vector2  # 存储上一次的格子坐标

## 物品所对应的纹理表
var textures: Dictionary[String,Dictionary]
## 基础的物品数据，格式如下
var data: Dictionary[String,Dictionary]


## 创建纹理表的内容单元（这些数据用于背包显示）
func create_textures_item(res_data: Resource = null) -> void:
	# 只处理ItemBaseData类型的资源
	if not res_data or not (res_data is ItemBaseData):
		return
	# 资源数据
	res_data = res_data as ItemBaseData
	var texture_data: Dictionary = {
		#"id": res_data.id.to_int(),
		"name": res_data.nickname,
	}
	var space_width: int = res_data.width
	var space_height: int = res_data.height
	# 宠物有成长值，可能不同阶段的贴图不一样，体型和占用空间也不一样
	if res_data is PetData:
		res_data = res_data as PetData
		var initial_growth: float = res_data.initial_growth
		# 成年了
		if initial_growth == res_data.adult_growth_threshold:
			texture_data.set("texture", res_data.adult_texture)
		# 有的宠物有第二阶段，比如蝴蝶的虫蛹状态，这种动物的成年阈值为200
		elif initial_growth >= 100 and initial_growth < res_data.adult_growth_threshold:
			texture_data.set("texture", res_data.pupa_texture)
			# 重置占用空间大小
			space_width = _get_juvenile_space(res_data.width)
			space_height = _get_juvenile_space(res_data.height)

		# 默认贴图
		else:
			texture_data.set("texture", res_data.texture)
			# 重置占用空间大小
			space_width = _get_juvenile_space(res_data.width)
			space_height = _get_juvenile_space(res_data.height)

	texture_data.set("width", space_width)
	texture_data.set("height", space_height)
	textures[res_data.id] = texture_data
	# 属性数据
	var base_data: Dictionary = {
		"id": res_data.id,
		"item_name": res_data.nickname,
		"descrip": res_data.descrip,
		"width": space_width,
		"height": space_height,
		"orientation": res_data.orientation,
		"stackable": res_data.stackable,
		"num": 1,
		"more_data": res_data,
	}

	data[res_data.id] = base_data


## 根据物品id获取对应纹理
func get_texture_resources(id: String) -> Variant:
	if textures.has(id):
		return textures[id]
	return false


## 根据物品id找对应的物品data
func find_item_data(id: String) -> Variant:
	if data.has(id):
		return data[id]
	return false


## 计算占用空间大小,JUVENILE
## 规则是用成年的大小除以2向上取整
func _get_juvenile_space(space: int = 1) -> int:
	space = ceili(space / 2.0)
	return clamp(space, 1, 3)
