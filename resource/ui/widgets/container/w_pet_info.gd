extends MarginContainer
class_name  WPetInfo

@onready var bg_color_rect: ColorRect = %BGColorRect
@onready var item_texture: TextureRect = %ItemTexture
@onready var price_label: Label = %PriceLabel
@onready var nickname_label: Label = %NicknameLabel
@onready var growth_bar: ProgressBar = %GrowthBar
@onready var mood_bar: ProgressBar = %MoodBar


func _on_btn_to_backpack_pressed() -> void:
	pass # Replace with function body.


func _on_btn_to_inventory_pressed() -> void:
	pass # Replace with function body.
