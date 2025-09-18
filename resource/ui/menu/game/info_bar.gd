extends GameBar
class_name InfoBar

@onready var day_label: Label = %DayLabel
@onready var season_label: Label = %SeasonLabel
@onready var weather_texture: TextureRect = %WeatherTexture



func _on_btn_next_day_pressed() -> void:
	print("_on_btn_next_day_pressed")
