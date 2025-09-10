class_name WItem extends Control

@onready var item_container: MarginContainer = %ItemContainer
@onready var bg_color: ColorRect = %BGColor
@onready var texture_container: PanelContainer = %TextureContainer
@onready var item_texture: ItemTexture = %ItemTexture
@onready var item_num_label: Label = %ItemNumLabel
@onready var item_name_label: Label = %ItemNameLabel

#旋转方向
enum ORI { VER, HOR }  # 代表竖直方向  # 代表横向方向

#默认的背景颜色
const DEF_BG_COLOR: Color = Color(&"ffffff36")

var head_position: Vector2  # 首部坐标

#region 要和全局加载配置的字典key值对应
var id: String  # 唯一标识符
var item_name: String  # 物品名称
var descrip: String  # 物品描述
var width: int  # 物品的宽度
var height: int  # 物品的高度
var orientation: int = ORI.VER  # 初始方向为竖着
var stackable: bool  # 物品是否可堆叠
var num: int = 1  # 物品数量
var more_data: Resource  #更多详细数据
#endregion


func _ready() -> void:
	setup()


## 初始化设置
func setup() -> void:
	set_container_size()
	set_texture()
	set_label_data()


## 设置全部标签的数据
func set_label_data() -> void:
	item_name_label.text = item_name
	item_num_label.text = str(num)
	#如果物品不可堆叠，则不显示物品数量标签
	if !stackable:
		item_num_label.visible = false


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
func set_texture(_id: String = "0") -> void:
	var this_id: String
	if _id != "0":
		this_id = _id
	else:
		this_id = id
	var texture_data: Variant = GlobalData.get_texture_resources(this_id)

	if texture_data:
		item_texture.set_texture(texture_data)
	else:
		print(name, &"纹理设置失败")


## 设置基本数据
func set_data(data: Dictionary) -> void:
	for key in data:
		self[key] = data[key]


## 获取基本数据
func get_data() -> Dictionary:
	var result: Dictionary
	var data: Dictionary = GlobalData.find_item_data(id)
	for key in data.keys():
		result[key] = self[key]
	return result


## 增减物品数量(可堆叠的前提下)
func add_num(n: int) -> void:
	if stackable:
		num += n
		#更新标签数据
		set_label_data()


## 隐藏背景颜色
func hide_bg_color() -> void:
	bg_color.color = Color(&"ffffff00")


## 显示背景颜色
func show_bg_color() -> void:
	bg_color.color = WItem.DEF_BG_COLOR


## 适配容器大小，并缩放纹理
func fit_to_container(container_size: Vector2) -> void:
	# 调整物品自身大小以匹配容器
	self.custom_minimum_size = container_size
	self.size = container_size
	# 确保纹理容器和纹理节点也随之调整
	item_container.custom_minimum_size = container_size
	item_container.size = container_size
	texture_container.custom_minimum_size = container_size
	texture_container.size = container_size
	# ItemTexture 节点会根据其容器自动缩放，确保其 stretch_mode 正确设置
	item_texture.custom_minimum_size = container_size
	item_texture.size = container_size
	item_texture.item_texture.size = container_size
	item_texture.item_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# 缩放
	item_texture.scale_texture(container_size)
