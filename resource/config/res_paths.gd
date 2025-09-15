extends RefCounted
class_name ResPaths

## 场景资源
const SCENE_RES: Dictionary[StringName,String] = {
	#主UI界面
	"main_ui": "res://resource/ui/ui_state_machine.tscn",
	# 食物场景
	"food": "res://resource/droppable/food.tscn",
	# 便便场景
	"excrement": "res://resource/droppable/excrement.tscn",
	# 蛋场景
	"egg": "res://resource/droppable/egg.tscn",
}

## 音效资源
const AUDIO_RES: Dictionary[StringName,Dictionary] = {
	##背景音乐
	"bgm":
	{
		"home": "res://assets/audio/music/home.ogg",
	},
	##音效
	"sfx":
	{
		"err": "res://assets/audio/sfx/err.ogg",
		"menu": "res://assets/audio/sfx/menu.ogg",
	},
}
