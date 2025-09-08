class_name ItemData extends Node

var cell_pos: Vector2;
var is_placed: bool; # 此空间是否已占用
var link_item: WItem;
var link_grid: WGrid;

func _init(_cell_pos: Vector2, cell: WGrid, item: WItem) -> void:
	self.cell_pos = _cell_pos;
	self.link_grid = cell;
	self.link_item = item;
	pass
