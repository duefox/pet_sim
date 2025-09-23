## 游戏世界模块，格子地图区块
extends GameBar
class_name GameWorld

## 世界地图的多格容器
@onready var world_grid: MultiGridContainer = %WorldGrid
## ## 世界地图的背景
@onready var bg_texture: NinePatchRect = $BGTexture

## 世界的大小 ###这里有bug
@export var world_size: Vector2i = Vector2i(38, 38)

## 缩放率
var _scale_rate: float = 0.05
## 最小缩放值
var _min_scale: float = 0.5
## 最大缩放值
var _max_scale: float = 2.0
## 当前缩放值
var _current_scale: float = 1.0
## 是否在当前世界的画布
var _is_in_world: bool = false


func _ready() -> void:
	# 设置世界的大小
	world_grid.grid_row = world_size.x
	world_grid.grid_col = world_size.y
	world_grid.max_scroll_grid = world_size.y
	# 将 Control 节点的缩放中心设置为其自身大小的一半，实现居中缩放
	pivot_offset = size / 2
	scale = Vector2.ONE * _current_scale
	var grid_size: Vector2 = world_grid.grid_size
	bg_texture.custom_minimum_size = grid_size + Vector2(0.0, 96.0)
	# 连接鼠标操作相关的信号
	if not InputManager.zoom_in_pressed.is_connected(_on_zoom_in_pressed):
		InputManager.zoom_in_pressed.connect(_on_zoom_in_pressed)
	if not InputManager.zoom_out_pressed.is_connected(_on_zoom_out_pressed):
		InputManager.zoom_out_pressed.connect(_on_zoom_out_pressed)
	if not InputManager.pan_dragged.is_connected(_on_pan_dragged):
		InputManager.pan_dragged.connect(_on_pan_dragged)

	# 定于地图更新的信号
	EventManager.subscribe(UIEvent.WORLD_MAP_CHANGED, _on_world_map_changed)


## 重置世界缩放
func reset_scale() -> void:
	scale = Vector2.ONE


## 重置世界坐标
func reset_coords() -> void:
	position = Vector2.ZERO


## 世界地图物品更新
func _on_world_map_changed(data: Dictionary) -> void:
	# 当收到背包数据变化的事件时，调用UI的更新方法
	if world_grid:
		world_grid.update_view(data.get("items_data", []))


## 向下滚动，缩小
func _on_zoom_out_pressed() -> void:
	if not _is_in_world:
		return
	_current_scale = max(_min_scale, _current_scale - _scale_rate)
	# 直接缩放 GameWorld 本身
	scale = Vector2(_current_scale, _current_scale)


## 向上滚动，放大
func _on_zoom_in_pressed() -> void:
	if not _is_in_world:
		return
	_current_scale = min(_max_scale, _current_scale + _scale_rate)
	# 直接缩放 GameWorld 本身
	scale = Vector2(_current_scale, _current_scale)


func _on_pan_dragged(relative: Vector2) -> void:
	if not _is_in_world:
		return
	# 除以缩放值确保在不同缩放级别下拖动速度保持一致。
	position += relative / _current_scale


func _on_mouse_exited() -> void:
	_is_in_world = false


func _on_mouse_entered() -> void:
	_is_in_world = true
