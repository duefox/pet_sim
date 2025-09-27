extends Control
class_name WItem

@onready var item_container: MarginContainer = %ItemContainer
@onready var bg_color: ColorRect = %BGColor
@onready var level_color: ColorRect = %LevelColor
@onready var texture_container: PanelContainer = %TextureContainer
@onready var item_texture: ItemTexture = %ItemTexture
@onready var item_num_label: Label = %ItemNumLabel
@onready var item_name_label: Label = %ItemNameLabel

## 旋转方向
enum ORI { VER, HOR }  # 代表竖直方向  # 代表横向方向

## 默认的选中颜色
const SELECTED_BG_COLOR: Color = Color(&"91d553")
## 父容器
var parent_container: MultiGridContainer = null
## 首部坐标
var head_position: Vector2
## 偏移量，大型物品有边框，需要使得物品在格子内，设置一个偏移量来居中并缩放
var item_offset: Vector2 = Vector2(0.0, 0.0)

#region 要和全局加载配置的字典key值对应
var id: String  # 唯一标识符
var item_name: String  # 物品名称
var item_type: int  # 物品类型
var item_level: int = 0  # 物品级别
var growth: float = 0.0  # 物品的成长值
var base_price: float = 1.0  # 物品的基础价格
var descrip: String  # 物品描述
var width: int  # 物品的宽度
var height: int  # 物品的高度
var orientation: int = ORI.VER  # 初始方向为竖着
var stackable: bool  # 物品是否可堆叠
var num: int = 1:  # 物品数量
	set = _setter_num
var max_stack_size: int = 1  # 物品最大堆叠数量
var item_info: Dictionary  #更多详细的物品原始信息数据
#endregion
## 物品贴图数据
var texture_data: Dictionary = {}
## 物品购买价格，和活动以及人物好感相关（具体表现为打折优惠度）
var purchase_price: int = 1:
	get = _getter_purchase_price
## 物品出售价格，和物品的级别、成长度相关
var sale_price: int = 1:
	get = _getter_sale_price

## 默认背景颜色
var _def_bg_color: Color = GlobalData.LEVEL_BG_COLOR[0]
## 透明底色
var _alpha_bg_color: Color = Color("ffffff00")


func _ready() -> void:
	setup()


## 初始化设置
func setup() -> void:
	# 设置物品稀有度色值，级别颜色值
	if item_info:
		_def_bg_color = GlobalData.LEVEL_BG_COLOR[item_info.item_level]
	# 初始化设置
	set_container_size()
	set_texture()
	set_label_data()
	show_bg_color()


## 设置全部标签的数据
func set_label_data() -> void:
	item_name_label.text = item_name
	item_num_label.text = str(num)
	# 如果物品不可堆叠，则不显示物品数量标签
	if !stackable:
		item_num_label.visible = false


## 强制显示数量
func show_item_num() -> void:
	if stackable:
		item_num_label.visible = true


## 旋转物品
func rotation_item() -> void:
	if orientation == WItem.ORI.HOR:
		orientation = WItem.ORI.VER
	else:
		orientation = WItem.ORI.HOR
	swap_width_and_height()
	set_texture_container_offset_and_rotation()
	set_container_size()


## 根据物品方向来设置坐标偏移和旋转
func set_texture_container_offset_and_rotation() -> void:
	if orientation == WItem.ORI.HOR:
		texture_container.rotation_degrees = 90
		texture_container.position = Vector2(width * GlobalData.cell_size, 0)
	else:
		texture_container.rotation_degrees = 0
		texture_container.position = Vector2(0, 0)


## 交换宽高
func swap_width_and_height() -> void:
	var temp: int = width
	width = height
	height = temp


## 设置容器的大小
func set_container_size() -> void:
	var _size: Vector2 = get_item_size()
	_size.x -= width
	_size.y -= height
	item_container.size = _size
	texture_container.size = _size


## 获取物品纹理的大小
func get_item_size() -> Vector2:
	var real_size: Vector2 = Vector2(width * GlobalData.cell_size, height * GlobalData.cell_size)
	return real_size


## 设置纹理
func set_texture() -> void:
	var extra_param: Dictionary = {}
	# 显示大型物品贴图的边框
	var body_size: int = item_info.get("body_size", BaseItemData.BodySize.SMALL)
	if body_size == BaseItemData.BodySize.BIG:
		extra_param.set("item_type", item_type)
		extra_param.set("build_type", item_info.get("build_type", 1))
		extra_param.set("item_level", item_level)
		# 设置物品边框
		item_texture.set_item_border(extra_param)
		level_color.visible = false
		# 大型物品稍微缩放，使得边框在格子内
		item_offset = Vector2(12.0, 12.0)
		item_texture.scale_texture(get_item_size() - item_offset, self)

	# 设置贴图
	if not texture_data.is_empty():
		item_texture.set_texture(texture_data)
	else:
		print(name, &"纹理设置失败")

	# 设置着色器
	item_texture.set_material_shader(extra_param)


## 设置拖动缩放，使得纹理略小于绿色区域
func drag_texture_scale() -> void:
	item_texture.drag_texture_scale(get_item_size())


## 设置基本数据
## @param data: 基本数据
## @param extra_args: 额外数据，当额外数据不为空时候需要覆盖基础数据
func set_data(data: Dictionary, extra_args: Dictionary = {}) -> void:
	if data.is_empty():
		return
	# 拷贝一份数据
	data = data.duplicate()
	# 详细信息数据字典
	var item_info_dic: Dictionary
	if data["item_info"] is Resource:
		# 第一次载入是资源的话标准化为字典
		item_info_dic = Utils.get_properties_from_res(data["item_info"]).duplicate()
	else:
		# 拖拽过来的物品数据
		item_info_dic = data["item_info"].duplicate()

	# 设置基本数据
	for key: String in data:
		if key == "item_info":
			# 原始数据字典
			item_info = item_info_dic
		else:
			# 物品当前数据
			self[key] = data[key]

	# 设置默认纹理数据
	texture_data = {
		"id": id,
		"hframes": item_info.hframes,  # 原始数据的行
		"vframes": item_info.vframes,  # 原始数据的列
		"frame": item_info.frame,  # 原始数据的所在帧的序号
		"width": width,  # 占用空间宽
		"height": height,  # 占用空间高度
		"texture": item_info.texture,  # 原始数据的纹理贴图
	}

	# 动物类型需要根据成长值显示不同的贴图
	if item_info.item_type == BaseItemData.ItemType.ANIMAL:
		var pet_growth: float = growth
		if not extra_args.is_empty() and extra_args.has("growth"):
			pet_growth = extra_args["growth"]
		var pettexture_data: Dictionary = _get_texture_by_growth(item_info, pet_growth)
		texture_data = texture_data.merged(pettexture_data, true)
		# 设置成长值
		growth = pet_growth
		# 重置物品的宽高
		width = texture_data["width"]
		height = texture_data["height"]

	if extra_args.is_empty():
		return
	# 当额外数据不为空时候需要覆盖基础数据
	#print("extra_args:", extra_args)
	# 稀有度级别覆盖重置
	if extra_args.has("item_level"):
		item_info["item_level"] = extra_args["item_level"]
		item_level = extra_args["item_level"]
		_def_bg_color = GlobalData.LEVEL_BG_COLOR[item_level]

	# TO DO 其他属性覆盖


## 获取基本数据
func get_data() -> Dictionary:
	var result: Dictionary = {
		"id": id,  # 唯一标识符
		"item_name": item_name,  # 物品名称
		"item_type": item_type,  # 物品类型
		"item_level": item_level,  # 物品级别
		"growth": growth,  # 物品的成长值
		"base_price": base_price,  # 物品的基础价格
		"descrip": descrip,  # 物品描述
		"width": width,  # 物品的宽度
		"height": height,  # 物品的高度
		"orientation": orientation,  # 初始方向为竖着
		"stackable": stackable,  # 物品是否可堆叠
		"num": num,  # 物品数量
		"max_stack_size": max_stack_size,  # 物品最大堆叠数量
		"item_info": item_info,  #更多详细的物品信息数据
		"texture_data": texture_data,  #更多详细的物品信息数据
	}
	return result


## 增减物品数量(可堆叠的前提下)
## @return int 返回堆叠后剩余的数量，如果全部堆叠成功则返回0
func add_num(n: int) -> int:
	if not stackable:
		return n

	# 剩余可叠加的数量
	var remaining_space: int = max_stack_size - num
	if n <= remaining_space:
		# 如果新增数量未超过剩余空间，则全部堆叠
		num += n
		set_label_data()
		return 0
	else:
		# 如果新增数量超过了剩余空间，则填满当前堆叠，并返回剩余数量
		var remaining_items: int = n - remaining_space
		num = max_stack_size
		set_label_data()
		return remaining_items


## 隐藏背景颜色
func hide_bg_color() -> void:
	if item_type == BaseItemData.ItemType.BUILD or item_type == BaseItemData.ItemType.TERRIAIN:
		bg_color.color = _alpha_bg_color
		level_color.color = _alpha_bg_color
	else:
		bg_color.color = _def_bg_color
		level_color.color = _def_bg_color


## 显示背景颜色
func show_bg_color() -> void:
	if item_type == BaseItemData.ItemType.BUILD or item_type == BaseItemData.ItemType.TERRIAIN:
		bg_color.color = _alpha_bg_color
		level_color.color = _alpha_bg_color
	else:
		bg_color.color = _def_bg_color
		level_color.color = _def_bg_color


## 设置选中颜色
func set_selected_bg_color() -> void:
	bg_color.color = SELECTED_BG_COLOR
	level_color.color = _def_bg_color


## 适配容器大小，并缩放纹理
func fit_to_container(container_size: Vector2) -> void:
	# 物品容器大小等同于真实格子大小
	item_container.size = container_size
	# 缩放纹理
	item_offset = Vector2(8.0, 8.0)
	item_texture.scale_texture(container_size - item_offset, self)


## 根据成长值获取贴图
func _get_texture_by_growth(data_info: Dictionary, pet_growth: float) -> Dictionary:
	var result_dic: Dictionary = {}
	# 贴图和占用空间
	var adult_threshold: float = data_info.adult_growth_threshold
	var space_width: int = data_info.width
	var space_height: int = data_info.height
	# 默认贴图
	var default_texture: CompressedTexture2D = data_info.texture
	# 成年了
	if pet_growth == adult_threshold:
		default_texture = data_info.adult_texture
	# 有的宠物有第二阶段，比如蝴蝶的虫蛹状态，这种动物的成年阈值为200
	elif pet_growth >= 100 and pet_growth < adult_threshold:
		default_texture = data_info.pupa_texture
		## 重置占用空间大小
		space_width = Utils.get_juvenile_space(data_info.width)
		space_height = Utils.get_juvenile_space(data_info.height)
	# 幼年
	else:
		default_texture = data_info.texture
		## 重置占用空间大小
		space_width = Utils.get_juvenile_space(data_info.width)
		space_height = Utils.get_juvenile_space(data_info.height)

	result_dic.set("width", space_width)
	result_dic.set("height", space_height)
	result_dic.set("texture", default_texture)

	return result_dic


## 改变num的值
func _setter_num(value) -> void:
	num = value
	if not is_instance_valid(item_num_label) or num == max_stack_size:
		return
	# 字体动画
	var tween: Tween = create_tween()
	tween.tween_property(item_num_label, "theme_override_font_sizes/font_size", 22, 0.08)
	tween.tween_interval(0.05)
	tween.tween_property(item_num_label, "theme_override_font_sizes/font_size", 20, 0.08)


## 获取购买价格
func _getter_purchase_price() -> int:
	return PriceManager.get_purchase_price(get_data())


## 获取出售价格
func _getter_sale_price() -> int:
	return PriceManager.get_sale_price(get_data())
