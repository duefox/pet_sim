class_name ItemTexture extends Control

@onready var item_texture: TextureRect = %ItemTexture


func set_texture(texture_data: Variant) -> void:
	if texture_data is Dictionary:
		# 图集
		var atlas_texture: AtlasTexture = AtlasTexture.new()
		var texture: CompressedTexture2D = texture_data.get("texture", item_texture.texture)
		atlas_texture.atlas = texture
		item_texture.texture = atlas_texture
		var region: Rect2 = Rect2(Vector2(0.0, 0.0), Vector2(texture_data.width, texture_data.height) * GlobalData.cell_size)
		atlas_texture.region = region

	elif texture_data is CompressedTexture2D:
		# 单图
		item_texture.texture = texture_data
