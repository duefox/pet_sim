extends DroppableData
class_name EggData

## 蛋的专属数据，目前只继承 DroppableData
## 可以在未来添加其他蛋特有的属性，比如孵化所需的热量或水分
## 成长
@export_group("Grow up")
## 生命周期参数，初始成长度，0~100，100表示成年
@export var initial_growth: float = 0.0
## 成长值阈值
@export var adult_growth_threshold: float = 100.0
## 每日自动增加的成长值
@export var daily_growth_points: float = 5.0
