# 音效、语言、画面
extends Control
class_name SettingsMemu

@onready var resolution_opt_btn: OptionButton = %ResolutionOptBtn
@onready var full_checked: CheckBox = %FullChecked
@onready var noborder_checked: CheckBox = %NoborderChecked
@onready var windows_check: CheckBox = %WindowsCheck
@onready var music_slider: HSlider = %MusicSlider
@onready var sound_slider: HSlider = %SoundSlider
@onready var language_opt_btn: OptionButton = %LanguageOptBtn



func _ready() -> void:
	#print("SoundSlider:",find_child("SoundSlider"))
	pass

func initialize() -> void:
	#print("initialize")
	pass


func _on_btn_back_pressed() -> void:
	# 恢复之前的状态
	GlobalData.menu.recover_state()
