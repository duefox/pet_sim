extends RefCounted
class_name ResPaths

## 通用场景资源
const SCENE_RES: Dictionary[StringName,String] = {
	# 主UI界面
	"main_ui": "res://resource/ui/ui_state_machine.tscn",
	# 玩家场景
	"player": "res://resource/player/player.tscn",
	# 地形详细信息场景
	"terrian_attribute": "res://resource/ui/widgets/container/w_terrain_attribute.tscn",
	# 水生动物房间场景
	"aquatic_room": "res://resource/ui/container/aquatic_room.tscn",
	# 食物场景
	"food": "res://resource/droppable/food.tscn",
	# 便便场景
	"excrement": "res://resource/droppable/excrement.tscn",
	# 蛋场景
	"egg": "res://resource/droppable/egg.tscn",
}

## 图片资源
const PIC_RES: Dictionary[StringName,String] = {
	"tank10": "res://assets/textures/builds/borders/tank10.png",
	"tank11": "res://assets/textures/builds/borders/tank11.png",
	"tank12": "res://assets/textures/builds/borders/tank12.png",
	"tank13": "res://assets/textures/builds/borders/tank13.png",
	"tank20": "res://assets/textures/builds/borders/tank20.png",
	"tank21": "res://assets/textures/builds/borders/tank21.png",
	"tank22": "res://assets/textures/builds/borders/tank22.png",
	"tank23": "res://assets/textures/builds/borders/tank23.png",
	"tank40": "res://assets/textures/builds/borders/tank40.png",
	"tank41": "res://assets/textures/builds/borders/tank41.png",
	"tank42": "res://assets/textures/builds/borders/tank42.png",
	"tank43": "res://assets/textures/builds/borders/tank43.png",
	"terriain": "res://assets/textures/builds/borders/terriain.png",
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
