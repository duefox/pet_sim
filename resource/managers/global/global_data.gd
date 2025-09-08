extends Node

var cell_size: int = 64
var ui: Control  # UI节点的引用
var previous_item: WItem  # 上一次操作的物品节点(引用)
var previous_cell_matrix: MultiGridContainer  # 上一次操作的MultiGridContainer(引用)
var placement_overlay_type: int  # 放置提示框的颜色类型
var prent_cell_pos: Vector2  # 存储上一次的格子坐标
