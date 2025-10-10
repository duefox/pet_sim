class_name ItemTexture extends Control

## 圆角着色器效果
const ROUNDED_SHDER = preload("res://shaders/rounded_rect.gdshader")

@onready var item_texture: TextureRect = %ItemTexture
@onready var texture_margin: MarginContainer = %TextureMargin
@onready var item_border: NinePatchRect = %ItemBorder

## 显示图片的真实大小
var real_size: Vector2

## 拖动缩放系数
var _drag_scale: float = 0.85


func _ready() -> void:
	item_border.visible = false


## 设置物品贴图
## @param texture_data ：贴图数据
## @param extra_param  ：额外参数
func set_texture(texture_data: Variant) -> void:
	#print("---------------->texture_data:", texture_data)
	# 设置贴图
	if texture_data is Dictionary:
		# 图集
		var atlas_texture: AtlasTexture = AtlasTexture.new()
		var texture: CompressedTexture2D = texture_data.get("texture", item_texture.texture)
		atlas_texture.atlas = texture
		item_texture.texture = atlas_texture
		var atlas_size: Vector2 = atlas_texture.get_size()
		var atlas_cell_size: int = int(atlas_size.x / texture_data.hframes)
		# 取其中较小的值作为系数
		var cell_size: int = mini(atlas_cell_size, GlobalData.cell_size)
		# 纹理裁剪位置
		var region_coords: Vector2 = Vector2(atlas_cell_size * (texture_data.frame % texture_data.hframes), atlas_cell_size * (texture_data.frame / texture_data.hframes))
		real_size = Vector2(texture_data.width, texture_data.height) * Vector2(cell_size, cell_size)
		var region: Rect2 = Rect2(region_coords, real_size)
		atlas_texture.region = region
	# 单图
	elif texture_data is CompressedTexture2D:
		item_texture.texture = texture_data


## 容器大小
func get_item_size() -> Vector2:
	return real_size


## 设置边框
func set_item_border(extra_param: Dictionary = {}) -> void:
	# 额外参数
	if extra_param.is_empty():
		return
	item_border.visible = true
	var item_type: int = extra_param.get("item_type", BaseItemData.ItemType.TERRIAIN)
	if item_type == BaseItemData.ItemType.TERRIAIN:
		set_terriain_border()
	elif item_type == BaseItemData.ItemType.BUILD:
		set_build_border(extra_param)


## 设置大地形物品的边框
func set_terriain_border() -> void:
	item_border.texture = ResManager.get_cached_resource(ResPaths.PIC_RES["terriain"])
	item_border.patch_margin_left = 10
	item_border.patch_margin_top = 16
	item_border.patch_margin_right = 10
	item_border.patch_margin_bottom = 8


## 设置大建筑物品的边框
func set_build_border(extra_param: Dictionary = {}) -> void:
	var item_level: int = extra_param.get("item_level", BaseItemData.ItemLevel.BASIC)
	var build_type: int = extra_param.get("build_type", BaseItemData.ItemLevel.BASIC)
	if build_type == BuildData.BuildType.AVIARY:
		build_type = 1
	var path: String = ResPaths.PIC_RES["tank" + str(build_type) + str(item_level)]
	item_border.texture = ResManager.get_cached_resource(path)
	item_border.patch_margin_left = item_level * 2
	item_border.patch_margin_top = item_level * 4
	item_border.patch_margin_right = item_level * 2
	item_border.patch_margin_bottom = item_level


## 设置着色器
func set_material_shader(extra_param: Dictionary = {}) -> void:
	# 额外参数
	if extra_param.is_empty():
		return
	# 圆角shader特效
	item_texture.material = ShaderMaterial.new()
	item_texture.material.shader = ROUNDED_SHDER
	var item_type: int = extra_param.get("item_type", BaseItemData.ItemType.TERRIAIN)
	# 地形
	if item_type == BaseItemData.ItemType.TERRIAIN:
		item_texture.material.set_shader_parameter("corner_radius", 8.0)
		item_texture.material.set_shader_parameter("margin_right", 3.0)
		item_texture.material.set_shader_parameter("margin_bottom", 6.0)
	# 建筑
	elif item_type == BaseItemData.ItemType.BUILD:
		#var item_level: int = extra_param.get("item_level", BaseItemData.ItemLevel.BASIC)
		item_texture.material.set_shader_parameter("corner_radius", 1.0)
		item_texture.material.set_shader_parameter("margin_top", 8.0)
		item_texture.material.set_shader_parameter("margin_bottom", 2.0)
		item_texture.material.set_shader_parameter("margin_left", 1.0)
		item_texture.material.set_shader_parameter("margin_right", 1.0)


## 缩放纹理贴图（适配多格物品拖放到单格容器中）
func scale_texture(container_size: Vector2, item: WItem) -> void:
	# 纹理实际的大小
	var item_size: Vector2 = item_texture.size * Vector2(item.width, item.height)
	# 等比缩放，取最小的一边
	var scale_size: Vector2 = container_size / item_size
	var min_size: float = minf(scale_size.x, scale_size.y)
	texture_margin.scale = Vector2(min_size, min_size)
	texture_margin.position = (container_size - item_size * texture_margin.scale) / 2.0


## 设置拖动缩放，使得纹理略小于绿色区域
func drag_texture_scale(item_type: int, orientation: int) -> void:
	# 注意这里一定要等一帧，先让item_texture渲染完成才去计算缩放
	await get_tree().process_frame
	var container_size: Vector2 = item_texture.size
	texture_margin.scale = Vector2.ONE * _drag_scale
	var offset: Vector2 = (1.0 - _drag_scale) * container_size / 2.0
	if orientation == WItem.ORI.HOR:
		texture_margin.position = offset * Vector2(1.0, -1.0)
	else:
		texture_margin.position = offset
	texture_margin.size = container_size * _drag_scale

	if item_type == BaseItemData.ItemType.BUILD or item_type == BaseItemData.ItemType.TERRIAIN:
		item_border.visible = true
	else:
		item_border.visible = false
