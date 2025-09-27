## 地图生成的地形资源类
extends BaseItemData
class_name TerrainData

## 地形枚举
enum Terrains {
	NONE,  # 空地
	# 大型地形
	MOON_LAKE,  # 月溪湖
	WET_LAND,  # 枯木湿地
	COLOR_ISLAND,  #彩贝礁
	HOT_RIFT,  # 热泉裂谷
	GROTTO,  # 地底溶洞
	SULPHUR_RIDGE,  # 硫磺山脊
	HIGH_FOREST,  # 高山云林
	THUNDER_PEAK,  # 雷鸣峰
	# 小型地形的基础资源
	WOOD,  # 水杉木
	SOIL,  # 腐质泥土
	CORAL,  # 海藻珊瑚
	ROCK,  # 沉积岩
	STONE,  # 石块
	SULPHUR,  # 硫磺
	FEATHER,  # 羽毛
	THUNDER_CRYSTAL,  # 碎雷晶
}

## 地形权重
@export var generate_weight: int
## 地形
@export var terrain_type: Terrains = Terrains.NONE
## 体型大小
@export var body_size: BodySize = BodySize.SMALL
## buffer辐射半径
@export var radius: int = 0
## 主要产出数组，值是材料的物品id
@export var output_items: Array[String] = []
## 升级对应获得buffer的id数组集合
@export var output_buffer: Array[String] = []
## 描述补充主要产出
@export var output_desc: String = ""
