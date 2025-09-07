extends PetData
class_name FishData

enum WanderLayer { TOP, MIDDLE, BOTTOM, ALL }
##特有的属性
@export_group("Special attribute")
#生活的水域层级
@export var live_layer: WanderLayer = WanderLayer.ALL
