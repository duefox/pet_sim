class_name ItemTexture extends Control

@onready var item_texture: TextureRect = %ItemTexture


func set_texture(texture) -> void:
	item_texture.texture = texture
