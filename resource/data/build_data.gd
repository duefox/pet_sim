## 世界地图的建筑资源类
extends BaseItemData
class_name BuildData

## 建筑类型
enum BuildType {
	NONE,  # 空的
	AQUATIC,  # 水族箱
	ECOLOGICAL,  # 生态箱
	AVIARY,  # 鸟舍
	GREEN_HOUSE,  # 生态温室
	OTHERS,  # 其他类型
}

## 建筑类型
@export var build_type: BuildType = BuildType.NONE
## 体型大小
@export var body_size: BodySize = BodySize.BIG
