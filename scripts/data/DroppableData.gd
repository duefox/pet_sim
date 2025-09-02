extends Resource
class_name DroppableData

enum Kind { FOOD, EXCREMENT }

@export_group("Base info")
#种类
@export var kind: Kind
#昵称
@export var name: String
#保留时间
@export var lifetime: float = 15.0

##动画贴图相关信息
@export_group("Texture & Aimate")
#贴图
@export var texture: Texture2D
@export var hframes: int = 4
@export var vframes: int = 4
@export var frame: int = 0
