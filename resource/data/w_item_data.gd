## 背包物品关联类
extends RefCounted
class_name WItemData

var cell_pos: Vector2
var is_placed: bool  # 此空间是否已占用
var link_item: WItem
var link_grid: WGrid


func _init(_cell_pos: Vector2, cell: WGrid, item: WItem) -> void:
	cell_pos = _cell_pos
	link_grid = cell
	link_item = item
