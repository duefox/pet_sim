extends RefCounted
class_name ResPaths

##场景资源
const SCENE_RES: Dictionary[StringName,String] = {
	#游戏CG场景
	"game_cg": "res://resource/ui/game_cg.tscn",
}

##音效资源
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
