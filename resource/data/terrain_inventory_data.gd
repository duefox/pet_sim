## 仓库地形资源类，特殊资源
extends TerrainData
class_name TerrainInventoryData

## 仓库级别对应网格的大小
@export var inventory_sizes: Array = [Vector2i(16, 6), Vector2i(16, 9), Vector2i(16, 12), Vector2i(16, 15)]
