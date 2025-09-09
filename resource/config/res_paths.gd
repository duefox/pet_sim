extends RefCounted
class_name ResPaths

## 宠物资源
## @param StringName 物品的唯一id
## @param String 物品的资源路径
const PET_RES: Dictionary[StringName,String] = {
	"bubblefish": "res://data/pet_data/bubblefish.tres",
	"swordtail": "res://data/pet_data/swordtail.tres",
}

## 食物，便便，蛋之类的掉落物资源
const DROP_RES: Dictionary[StringName,String] = {
	# 食物
	"fish_food0": "res://data/drop_data/fish_food0.tres",
	# 便便
	"fish_excrement00": "res://data/pet_data/swordtail.tres",
	# 蛋
	"fish_egg0": "res://data/drop_data/fish_egg0.tres",
	"fish_egg1": "res://data/drop_data/fish_egg1.tres",
}

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
