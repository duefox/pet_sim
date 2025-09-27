extends GameBar
class_name TaskBar

@onready var btn_expand: ButtonExpand = %BtnExpand
@onready var task_container: VBoxContainer = %TaskContainer
@onready var task_margin: MarginContainer = %TaskMargin

## 是否展开
var is_expand: bool:
	set = _setter_is_expand

## 是否正在播放tween动画
var _is_tween: bool = false

## 任务栏的原始宽度
var _original_width: float


func _ready() -> void:
	super()
	btn_expand.toggle_mode = true
	# 获取任务栏的原始宽度，用于计算展开后的位置
	_original_width = size.x
	# 设置初始位置，使其处于收缩状态（在屏幕右侧之外）
	position.x = Utils.get_win_size().x
	# 默认隐藏
	is_expand = false


## 打开/关闭任务栏
func open_task() -> void:
	is_expand = not is_expand


## 设置任务栏的显示和隐藏
func _setter_is_expand(value: bool) -> void:
	# 如果正在播放动画，则直接返回，避免冲突
	if _is_tween:
		return
	is_expand = value
	btn_expand.button_pressed = is_expand
	# 获取视口（窗口）大小
	var win_size: Vector2 = Utils.get_win_size()
	# 创建一个 tween 动画
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT)
	# 标记动画正在播放
	_is_tween = true
	# 按钮 icon 切换
	var icon: AtlasTexture = btn_expand.icon
	if is_expand:
		# 展开动画：从右侧屏幕外滑入
		icon.region = Rect2(Vector2(192.0, 0.0), Vector2(64.0, 64.0))
		# 目标位置是窗口宽度减去任务栏宽度，使其正好显示在屏幕右侧
		tween.tween_property(self, "position:x", win_size.x - _original_width, 0.2)
	else:
		# 收缩动画：向右滑出屏幕外
		icon.region = Rect2(Vector2(256.0, 0.0), Vector2(64.0, 64.0))
		# 目标位置是窗口宽度，使其完全移出屏幕
		tween.tween_property(self, "position:x", win_size.x, 0.2)
	await tween.finished
	_is_tween = false


## 任务栏按钮事件
func _on_btn_expand_toggled(toggled_on: bool) -> void:
	is_expand = toggled_on
