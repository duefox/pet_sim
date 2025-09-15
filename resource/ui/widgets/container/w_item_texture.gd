class_name ItemTexture extends Control

@onready var item_texture: TextureRect = %ItemTexture
@onready var texture_margin: MarginContainer = %TextureMargin


func set_texture(texture_data: Variant) -> void:
	#print(texture_data)
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
		var region: Rect2 = Rect2(region_coords, Vector2(texture_data.width, texture_data.height) * Vector2(cell_size, cell_size))
		atlas_texture.region = region

	elif texture_data is CompressedTexture2D:
		# 单图
		item_texture.texture = texture_data


## 缩放纹理贴图（适配多格物品拖放到单格容器中）
func scale_texture(container_size: Vector2, item: WItem) -> void:
	# 纹理实际的大小
	var real_size: Vector2 = item_texture.size * Vector2(item.width, item.height)
	# 等比缩放，取最小的一边
	var scale_size: Vector2 = container_size / real_size
	var min_size: float = minf(scale_size.x, scale_size.y)
	texture_margin.scale = Vector2(min_size, min_size)
	texture_margin.position = (container_size - real_size * texture_margin.scale) / 2.0
