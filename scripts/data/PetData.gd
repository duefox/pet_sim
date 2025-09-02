extends Resource
class_name PetData

#region 枚举类型
#动物主类型
enum MainCategory {
	AQUATIC,  #水生动物
	TERRESTRIAL,  #陆生动物
}
#环境类型
enum EnvCategory {
	WATER,  #水里
	LAND,  #陆地
	AIR,  #空中
	UNDERGROUND,  #地下
	OTHERS,  #其它，如俩栖
}

#宠物生命阶段枚举
enum LifeStage { JUVENILE, ADULT, DEAD }

#物种级别
enum Level { ENTRY, MIDDLE, ADVANCED, TOP }

#体型大小
enum BodySize { SMALL, MIDDLE, BIG }

#灯光类型
enum LightCategory {
	ALL,  #所有
	WHITE,  #白光
	PINK,  #紫光
	BLUE,  #蓝光
	RED,  #红光
	DARKEN,  #暗光，无光
}
#食性
enum FoodCategory {
	ALL,
	OMNIVORES,  #杂食性
	CARNIVORES,  #肉食性
	HERBIVORES,  #草食性
	SCAVENGERS,  #腐食性
}
#性别
enum Gender {
	MALE,  #雄性
	FEMALE,  #雌性
}
#endregion

##基本信息
@export_group("Base Info")
#昵称
@export var nickname: String
#种类
@export var species: MainCategory
#物种级别，入门级，中级，高级，顶级
@export var level: Level = Level.ENTRY
#颜色，同种类型繁殖出来的动物有4种级别，普通级白色，稀有蓝色，罕见紫色，珍藏七彩色
@export var color: Color
#坐标
@export var coords: Vector2
#速度
@export var speed: float = 100.0
#体型大小
@export var max_size: BodySize = BodySize.SMALL
#性别
@export var gender: Gender
#角度
@export var initial_angle: float = randf() * PI * 2.0
#转向率
@export var turn_rate: float = 0.05
#食性
@export var food_habit: FoodCategory = FoodCategory.ALL
#饥饿度变化率
@export var hunger_decrease_rate: float = 1.0
#食量，每次进食消耗量克/次，如食量是20，需要进食5次才能到100%不饿状态
@export var hunger_restore_amount: float = 10.0

##动画贴图相关信息
@export_group("Texture & Aimate")
#贴图
@export var texture: Texture2D
@export var hframes: int = 6
@export var vframes: int = 1
@export var frame: int = 4

##排泄和繁殖
@export_group("Waste & Mating")
#排泄间隔，单位为秒，60秒
@export var excretion_interval: float = 100.0
#是否交配
@export var is_mating: bool = false
#交配时间
@export var mating_timer: int = 0
#交配所需时间单位毫秒
@export var mating_duration: int = 1200
#交配冷却
@export var mating_cooldown: int = 0
@export var mating_cooldown_duration: int = 1200
#孵化时间
@export var egg_timer: int = 0
#孵化周期，单位毫秒,动画播放相关，实际值是按过天后这个值乘以成年动物数量来计算，分雌雄
@export var egg_interval: int = 1200

##成长
@export_group("Grow up")
#生命周期参数，初始成长度，0~100，100表示成年
@export var initial_growth: float = 0.0
#成长值阈值
@export var adult_growth_threshold: float = 100.0
#每日自动增加的成长值
@export var daily_growth_points: float = 5.0

##生存相关
@export_group("Live evnironment")
#环境类型
@export var env_catgory: EnvCategory
#舒适温度40°~60°
@export var suitable_temperature: Vector2 = Vector2(40.0, 60.0)
#生存温度0°~100°
@export var live_temperature: Vector2 = Vector2(0.0, 100.0)
#灯光
@export var light_catgory: LightCategory = LightCategory.ALL
#心情
@export var mood: int = 0
#变异条件，包含多种因素
@export var variation: Dictionary
