extends ItemBaseData
class_name DroppableData

## 类型
enum Kind { FOOD, EXCREMENT, EGG }

@export_group("Base info")
## 种类
@export var kind: Kind
## 保留时间
@export var lifetime: float = 15.0
