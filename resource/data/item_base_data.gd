## 物品的基础属性,唯一id，贴图和动画相关
extends Resource
class_name ItemBaseData

## 物品类型
enum ItemType {
	ANIMAL,  # 动物
	ANIMALEGG,  # 动物蛋
	FOOD,  # 食物
	EQUIPMENT,  # 装备
	MATERIAL,  # 材料
	BUILD,  # 建造
	DEVICE,  # 设备
	LANDSCAPE,  # 造景
	OTHERS,  # 其他，如便便，废物之类
}
## 物品级别
enum ItemLevel {
	BASIC,  # 普通
	MAGIC,  # 稀有
	EPIC,  # 罕见
	MYTHIC,  # 传说
}

## 唯一id
@export var id: StringName = &"1000"
## 物品类型
@export var item_type: ItemType
## 物品级别
@export var item_level: ItemLevel = ItemLevel.BASIC
## 昵称
@export var nickname: String
## 描述
@export var descrip: String
## 生命周期参数，初始成长度，0~100，100表示成年
@export var growth: float = 0.0
## 物品基础价格，实际出售价格和级别、成长度相关
@export var base_price: float = 1.0

##  动画贴图相关信息
@export_group("Texture & Aimate")
##  基础贴图，默认
@export var texture: Texture2D
##  宠物虫蛹形变贴图（部分宠物有形变的中间态）
@export var pupa_texture: Texture2D
##  宠物成年后的贴图
@export var adult_texture: Texture2D
##  动画帧设置
@export var hframes: int = 3
@export var vframes: int = 1
##  当前帧序号
@export var frame: int = 1
##  成年占用空间的大小，非成年用成年占用空间除以2向上取整
@export var width: int = 1
@export var height: int = 1
##  方向，默认水平0
@export var orientation: int = 0
##  是否可堆叠
@export var stackable: bool = false
##  最大堆叠数量
@export var max_stack_size: int = 1
