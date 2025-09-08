extends RefCounted
class_name ResPaths

## 宠物资源
const PET_RES: Dictionary[StringName,String] = {
	"angelfish": "res://data/pet_data/angelfish.tres",
	"goldfish": "res://data/pet_data/goldfish.tres",
}

## 场景资源
const SCENE_RES: Dictionary[StringName,String] = {
	#食物
	"food": "res://resource/droppable/food.tscn",
	#便便
	"excrement": "res://resource/droppable/excrement.tscn",
	#蛋
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
