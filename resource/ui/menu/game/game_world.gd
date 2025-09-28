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
var _min_scale: float = 0.2
## 最大缩放值
var _max_scale: float = 2.0
## 当前缩放值
var _current_scale: float = 1.0
## 是否在当前世界的画布
var _is_in_world: bool = false
## 是否动画播放中
var _is_tween: bool = false


func _ready() -> void:
	# 更新世界地图网格
	update_world_size()
	# 连接鼠标操作相关的信号
	if not InputManager.zoom_in_pressed.is_connected(_on_zoom_in_pressed):
		InputManager.zoom_in_pressed.connect(_on_zoom_in_pressed)
	if not InputManager.zoom_out_pressed.is_connected(_on_zoom_out_pressed):
		InputManager.zoom_out_pressed.connect(_on_zoom_out_pressed)
	if not InputManager.pan_dragged.is_connected(_on_pan_dragged):
		InputManager.pan_dragged.connect(_on_pan_dragged)

	# 订阅地图更新的信号
	EventManager.subscribe(UIEvent.UPDATE_PLAYER_INFO, _on_update_player_info)
	EventManager.subscribe(UIEvent.WORLD_MAP_CHANGED, _on_world_map_changed)


func _exit_tree() -> void:
	EventManager.unsubscribe(UIEvent.UPDATE_PLAYER_INFO, _on_update_player_info)
	EventManager.unsubscribe(UIEvent.WORLD_MAP_CHANGED, _on_world_map_changed)


## 重置世界缩放
func reset_scale() -> void:
	scale = Vector2.ONE
	_current_scale = scale.x


## 重置世界初始坐标和缩放，访客快速定位
func reset_to_visitor(show_tween: bool = true) -> void:
	if _is_tween:
		return
	var win_size: Vector2 = Utils.get_win_size()
	var pos_x: float = (win_size.x - world_grid.grid_size.x) / 2.0
	var pos_y: float = world_grid.w_grid_size.y * 2.0
	if not show_tween:
		reset_scale()
		position = Vector2(pos_x, pos_y)
		return
	# tween 动画
	_is_tween = true
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.8)
	tween.tween_property(self, "position", Vector2(pos_x, pos_y), 0.8)
	_current_scale = 1.0
	await tween.finished
	_is_tween = false


## 更新世界网格
func update_world_size() -> void:
	if GlobalData.player.player_info:
		var box_size: Vector2i = GlobalData.player.player_info.get("map_size", Vector2i(38, 38))
		world_grid.grid_col = box_size.x
		world_grid.grid_row = box_size.y
		world_size = box_size
	# 渲染格子
	world_grid.render_grid(world_size, world_size.y)
	# 网格容器居中
	world_grid.position = Vector2(0.0, world_grid.w_grid_size.y / 2.0)
	# 初始化网格
	_init_map_grid()
	# 重置世界初始坐标和缩放，访客快速定位
	reset_to_visitor(false)


## 世界地图物品更新
func _on_world_map_changed(data: Dictionary) -> void:
	# 当收到背包数据变化的事件时，调用UI的更新方法
	if world_grid:
		world_grid.update_view(data.get("items_data", []))


## 加载后刷新地图
func _on_update_player_info() -> void:
	# 更新世界地图网格
	update_world_size()


func _init_map_grid() -> void:
	# 设置世界的大小
	world_grid.grid_row = world_size.x
	world_grid.grid_col = world_size.y
	world_grid.max_scroll_grid = world_size.y
	# 将 Control 节点的缩放中心设置为其自身大小的一半，实现居中缩放
	pivot_offset = size / 2
	scale = Vector2.ONE * _current_scale
	bg_texture.custom_minimum_size = world_grid.grid_size


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


func _on_pan_dragged2(delta: Vector2) -> void:
	if not _is_in_world:
		return

	# 1. 应用拖拽位移
	# GameWorld 的 position 是相对于其父节点（通常是 GameMenu/Viewport）的
	position += delta

	# 2. 获取关键尺寸
	var screen_size: Vector2 = Utils.get_win_size()

	# WorldGrid 的总大小（像素），并考虑当前的缩放比例
	# 注意：world_grid.size 应该在你初始化时已经计算了 grid_row * cell_size
	# multi_grid_container.gd 文件中的 size = Vector2(grid_col * GlobalData.cell_size, ...)
	var world_size_scaled: Vector2 = world_grid.size * scale

	# 3. 计算钳制边界 (1/3 屏幕大小)
	var margin: Vector2 = screen_size / 3.0

	# 4. 计算最小/最大可拖拽位置

	# 【最大拖拽位置 (Min_Pos)】: 地图左上角允许向右/向下移动的最大距离。
	# 这是地图原点（position = 0）向右下移动的最大值，即 margin。
	# 当 position 达到 margin 时，地图的左上角刚好在屏幕的 1/3 处。
	var max_pos: Vector2 = margin

	# 【最小拖拽位置 (Max_Pos)】: 地图原点允许向左/向上移动的最大距离。
	# 地图右下角不能超出屏幕右下 margin 处。
	# 计算公式：-(World_Size_Scaled - Screen_Size - Margin)
	# 简化：-(World_Size_Scaled - Screen_Size * 2/3)
	var min_pos: Vector2 = -(world_size_scaled - screen_size + margin)

	# 5. 钳制位置
	position.x = clampf(position.x, min_pos.x, max_pos.x)
	position.y = clampf(position.y, min_pos.y, max_pos.y)


func _on_pan_dragged(delta: Vector2) -> void:
	if not _is_in_world:
		return
	# 除以缩放值确保在不同缩放级别下拖动速度保持一致。
	#position += relative / _current_scale
	position += delta
	# 这里注意，需要钳制坐标的范围

	# 关闭所有弹窗
	GlobalData.ui.close_all_popup()


func _on_mouse_exited() -> void:
	_is_in_world = false


func _on_mouse_entered() -> void:
	_is_in_world = true
