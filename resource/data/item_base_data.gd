## 物品的基础属性,唯一id，贴图和动画相关
extends Resource
class_name ItemBaseData

## 唯一id
@export var id: StringName = &"1000"
#昵称
@export var nickname: String
#描述
@export var descrip: String

## 动画贴图相关信息
@export_group("Texture & Aimate")
# 基础贴图，默认
@export var texture: Texture2D
# 宠物虫蛹形变贴图（部分宠物有形变的中间态）
@export var pupa_texture: Texture2D
# 宠物成年后的贴图
@export var adult_texture: Texture2D
# 动画帧设置
@export var hframes: int = 3
@export var vframes: int = 1
# 当前帧序号
@export var frame: int = 1
# 成年占用空间的大小，非成年用成年占用空间除以2向上取整
@export var width: int = 1
@export var height: int = 1
# 方向，默认水平0
@export var orientation: int = 0
# 是否可堆叠
@export var stackable: bool = true
# 最大堆叠数量
@export var max_stack_size: int = 9
