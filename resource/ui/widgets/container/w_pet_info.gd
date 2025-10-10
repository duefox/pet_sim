extends MarginContainer
class_name WPetInfo

@onready var bg_color_rect: ColorRect = %BGColorRect
@onready var item_texture: ItemTexture = %ItemTexture
@onready var price_label: Label = %PriceLabel
@onready var nickname_label: Label = %NicknameLabel
@onready var growth_bar: ProgressBar = %GrowthBar
@onready var mood_bar: ProgressBar = %MoodBar
@onready var btn_to_bag: ButtonSmall = %BtnToBag
@onready var item_panel: PanelContainer = %ItemPanel

## 放回模式
enum PUTBACK_MODE { INVENTORY, BLACKPACK }

## 当前的放回模式为放回仓库
var current_putback_mode: PUTBACK_MODE = PUTBACK_MODE.INVENTORY:
	set(value):
		current_putback_mode = value
		if current_putback_mode == PUTBACK_MODE.INVENTORY:
			btn_to_bag.text = "放回仓库"
		else:
			btn_to_bag.text = "放回背包"

## 宠物级别
var pet_level: int
## 宠物的成长值
var growth: float
## 当前宠物的信息
var pet_data: PetData
## 宠物内置id
var private_id: int


## 更新显示
func update_pet_info(data: PetData) -> void:
	if not is_instance_valid(data):
		return
	#print(data)
	pet_data = data
	private_id = data.private_id
	# nickname
	nickname_label.text = str(data.nickname)
	# current growth
	growth = float(data.growth)
	growth_bar.value = growth
	# current mood
	mood_bar.value = float(data.mood)
	# current price
	var data_dict: Dictionary = Utils.get_properties_from_res(data)
	var price: int = PriceManager.get_sale_price(data_dict)
	price_label.text = str(price)
	# 贴图
	_set_texture(_format_to_texture_data(data_dict))
	# 级别
	pet_level = int(data.item_level)
	if pet_level == 0:
		bg_color_rect.color = Color.WHITE
	else:
		bg_color_rect.color = GlobalData.LEVEL_BG_COLOR[pet_level]


## 宠物是否成年
func is_adult() -> bool:
	if growth >= pet_data.adult_growth_threshold:
		return true
	return false


## 切换放回模式
func toggle_putback_mode() -> void:
	if current_putback_mode == PUTBACK_MODE.INVENTORY:
		current_putback_mode = PUTBACK_MODE.BLACKPACK
	else:
		current_putback_mode = PUTBACK_MODE.INVENTORY


## 格式化贴图使用的字典类型
func _format_to_texture_data(data: Dictionary) -> Dictionary:
	var item_info: Dictionary = data["item_info"]
	# 设置默认纹理数据
	var texture_data: Dictionary = {
		"id": data.id,
		"hframes": item_info.hframes,  # 原始数据的行
		"vframes": item_info.vframes,  # 原始数据的列
		"frame": item_info.frame,  # 原始数据的所在帧的序号
		"width": item_info.width,  # 占用空间宽
		"height": item_info.height,  # 占用空间高度
		"texture": item_info.texture,  # 原始数据的纹理贴图
	}
	# 动物类型需要根据成长值显示不同的贴图
	var pet_texture_data: Dictionary = Utils.get_texture_by_growth(item_info, growth)
	texture_data = texture_data.merged(pet_texture_data, true)

	return texture_data


## 设置贴图
func _set_texture(texture_data: Dictionary) -> void:
	if texture_data.is_empty():
		return
	item_texture.set_texture(texture_data)
	item_panel.position -= item_texture.get_item_size() / 2.0


## 切换放回模式
func _on_btn_dir_left_pressed() -> void:
	toggle_putback_mode()


## 放回到背包或者仓库
func _on_btn_to_bag_pressed() -> void:
	if current_putback_mode == PUTBACK_MODE.INVENTORY:
		EventManager.emit_event(UIEvent.PUTBACK_TO_INVENTORY, {"data": [pet_data]})
	else:
		EventManager.emit_event(UIEvent.PUTBACK_TO_BLACKPACK, {"data": [pet_data]})


## 切换放回模式
func _on_btn_dir_right_pressed() -> void:
	toggle_putback_mode()


## 出售
func _on_btn_sell_pressed() -> void:
	pass  # Replace with function body.
