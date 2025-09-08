extends Control
@onready var game_saved_box: VBoxContainer = %GameSavedBox
@onready var tips_label: Label = $MarginContainer/LabelMargin/TipsLabel


func _ready() -> void:
	_set_game_saves()


func _set_game_saves() -> void:
	for save_btn: ButtonSmall in game_saved_box.get_children():
		var index: int = save_btn.get_index()
		save_btn.set_row(index)
