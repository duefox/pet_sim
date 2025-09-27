extends GameBar
class_name LayoutBar

@onready var builds_margin: MarginContainer = %BuildsMargin
@onready var btn_layout: ButtonSmall = %BtnLayout
@onready var landscape: MultiGridContainer = %Landscape
@onready var tab_bar_box: VBoxContainer = %TabBarBox
@onready var btn_landscape: ButtonSmall = %BtnLandscape
@onready var btn_device: ButtonSmall = %BtnDevice
@onready var btn_build: ButtonSmall = %BtnBuild
@onready var btn_sort: ButtonSmall = %BtnSort

## 布局容器是否显示
var builds_visible: bool = false:
	set = _setter_builds_visible


func _ready() -> void:
	super()
	## 设置多格容器的大小
	if GlobalData.player.player_info:
		var box_size: Vector2i = GlobalData.player.player_info.get("landscape_size", Vector2i(2, 16))
		landscape.grid_col = box_size.x
		landscape.grid_row = box_size.y
	# 渲染格子
	landscape.render_grid()
	var grid_size: Vector2 = landscape.grid_size
	var container_size: Vector2 = grid_size + Vector2(0.4, 0.4) * landscape.w_grid_size
	# 重置滚动条区域大小
	landscape.set_scroll_container(container_size)
	landscape.custom_minimum_size = container_size + Vector2(0.0, 0.0)

	# 设置ButtonGroup关联组
	var btn_group: ButtonGroup = ButtonGroup.new()
	for child: ButtonSmall in tab_bar_box.get_children():
		child.button_group = btn_group

	# 连接 ButtonGroup 的信号
	btn_group.pressed.connect(_on_btn_group_pressed)
	# 默认显示 btn_build 对应的页
	btn_build.button_pressed = true
	_switch_content(btn_build)

	## 事件订阅
	EventManager.subscribe(UIEvent.UPDATE_PLAYER_INFO, _on_update_player_info)
	EventManager.subscribe(UIEvent.LANDSCAPE_CHANGED, _on_landscape_changed)


func _exit_tree() -> void:
	EventManager.unsubscribe(UIEvent.UPDATE_PLAYER_INFO, _on_update_player_info)
	EventManager.unsubscribe(UIEvent.LANDSCAPE_CHANGED, _on_landscape_changed)


## 打开布局栏
func open_layout() -> void:
	builds_visible = not builds_visible


## 设置布局栏的显示和隐藏
func _setter_builds_visible(value: bool) -> void:
	builds_visible = value
	builds_margin.visible = builds_visible
	btn_sort.visible = builds_visible


## 物品更新
func _on_landscape_changed(data: Dictionary) -> void:
	# 当收到背包数据变化的事件时，调用UI的更新方法
	if landscape:
		landscape.update_view(data.get("items_data", []))


## 更新玩家布局栏
func _on_update_player_info() -> void:
	var player_info: Dictionary = GlobalData.player.player_info
	landscape.render_grid(player_info.get("landscape_size", Vector2i(landscape.grid_row, landscape.grid_col)))


## 按钮事件
func _on_btn_layout_pressed() -> void:
	state_machine.on_layout_pressed()


## 统一的 Tab 按钮切换信号处理函数
func _on_btn_group_pressed(button: ButtonSmall) -> void:
	_switch_content(button)


## 核心切换逻辑：只负责显示内容，不处理按钮状态
func _switch_content(_button: ButtonSmall) -> void:
	# 数据切换
	if _button == btn_build:
		pass
	elif _button == btn_device:
		pass
	elif _button == btn_landscape:
		pass
