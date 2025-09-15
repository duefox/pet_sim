extends Control
class_name WItem

@onready var item_container: MarginContainer = %ItemContainer
@onready var bg_color: ColorRect = %BGColor
@onready var texture_container: PanelContainer = %TextureContainer
@onready var item_texture: ItemTexture = %ItemTexture
@onready var item_num_label: Label = %ItemNumLabel
@onready var item_name_label: Label = %ItemNameLabel

## 旋转方向
enum ORI { VER, HOR }  # 代表竖直方向  # 代表横向方向

## 物品级别背景色
const LEVEL_BG_COLOR: Dictionary = {
	0: Color("ffffff80"),  # 普通
	1: Color("F0C05080"),  # 稀有  #FFFF00
	2: Color("00BFFF80"),  # 罕见
	3: Color("A335EE80"),  # 传说
}

## 默认的选中颜色
const SELECTED_BG_COLOR: Color = Color(&"91d553")
## 首部坐标
var head_position: Vector2

#region 要和全局加载配置的字典key值对应
var id: String  # 唯一标识符
var item_name: String  # 物品名称
var item_type: int  # 物品类型
var item_level: int = 0  # 物品级别
var descrip: String  # 物品描述
var width: int  # 物品的宽度
var height: int  # 物品的高度
var orientation: int = ORI.VER  # 初始方向为竖着
var stackable: bool  # 物品是否可堆叠
var num: int = 1:  # 物品数量
	set = _setter_num
var max_stack_size: int = 1  # 物品最大堆叠数量
var more_data: ItemBaseData  #更多详细数据
#endregion

## 默认背景颜色
var _def_bg_color: Color = LEVEL_BG_COLOR[0]
var _texture_data: Variant = null


func _ready() -> void:
	setup()


## 初始化设置
func setup() -> void:
	# 设置物品稀有度色值，级别颜色值
	if more_data:
		_def_bg_color = LEVEL_BG_COLOR[more_data.item_level]
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
	return Vector2(width * GlobalData.cell_size, height * GlobalData.cell_size)


## 设置纹理
func set_texture(item_id: String = "0") -> void:
	var this_id: String
	if item_id != "0":
		this_id = item_id
	else:
		this_id = id
	var texture_data: Variant
	if _texture_data:
		texture_data = _texture_data
	else:
		texture_data = GlobalData.get_texture_resources(this_id)

	if texture_data:
		item_texture.set_texture(texture_data)
	else:
		print(name, &"纹理设置失败")


## 设置基本数据
## @param data: 基本数据
## @param extra_args: 额外数据，当额外数据不为空时候需要覆盖基础数据
func set_data(data: Dictionary, extra_args: Dictionary = {}) -> void:
	# 设置基本数据
	for key in data:
		self[key] = data[key]

	# 当额外数据不为空时候需要覆盖基础数据
	if not extra_args.is_empty():
		#print("extra_args:", extra_args)
		# 稀有度级别覆盖重置
		if extra_args.has("item_level"):
			more_data.item_level = extra_args["item_level"]
			item_level = extra_args["item_level"]
			_def_bg_color = LEVEL_BG_COLOR[item_level]

		# TO DO 其他属性覆盖

		# 是动物并且有成长值，需要重置占用宽和高和纹理贴图
		if extra_args.has("initial_growth") and more_data.item_type == ItemBaseData.ItemType.ANIMAL:
			var initial_growth: float = extra_args["initial_growth"]
			var adult_threshold: float = more_data.adult_growth_threshold
			var space_width: int = more_data.width
			var space_height: int = more_data.height
			var texture_data: Variant = GlobalData.get_texture_resources(id)
			# 默认贴图
			texture_data.set("texture", more_data.texture)
			if not texture_data:
				push_error("not found this id's texture.")
				return
			# 成年了
			if initial_growth == adult_threshold:
				texture_data.set("texture", more_data.adult_texture)
			# 有的宠物有第二阶段，比如蝴蝶的虫蛹状态，这种动物的成年阈值为200
			elif initial_growth >= 100 and initial_growth < adult_threshold:
				texture_data.set("texture", more_data.pupa_texture)
				## 重置占用空间大小
				space_width = Utils.get_juvenile_space(more_data.width)
				space_height = Utils.get_juvenile_space(more_data.height)
			# 幼年
			else:
				## 重置占用空间大小
				space_width = Utils.get_juvenile_space(more_data.width)
				space_height = Utils.get_juvenile_space(more_data.height)
			# 更新物品的占用空间大小,纹理
			width = space_width
			height = space_height
			texture_data.set("width", space_width)
			texture_data.set("height", space_height)
			_texture_data = texture_data


## 获取基本数据
func get_data() -> Dictionary:
	var result: Dictionary
	var data: Dictionary = GlobalData.find_item_data(id)
	for key in data.keys():
		result[key] = self[key]
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
	bg_color.color = _def_bg_color


## 显示背景颜色
func show_bg_color() -> void:
	bg_color.color = _def_bg_color


## 设置选中颜色
func set_selected_bg_color() -> void:
	bg_color.color = WItem.SELECTED_BG_COLOR


## 适配容器大小，并缩放纹理
func fit_to_container(container_size: Vector2) -> void:
	# 物品容器大小等同于真实格子大小
	item_container.size = container_size
	# 缩放纹理
	item_texture.scale_texture(container_size, self)


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
