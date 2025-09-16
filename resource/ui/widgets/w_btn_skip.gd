extends Control
class_name WButtonSkip

@onready var btn_skip: ButtonSmall = $BtnSkip
@onready var skip_progress: TextureProgressBar = %SkipProgress
@onready var timer: Timer = $Timer

signal long_press_over

var _show_progress: bool = false
var _skip_pressed_time: float = 1.0


func _ready() -> void:
	timer.wait_time = _skip_pressed_time
	skip_progress.visible = _show_progress
	timer.timeout.connect(_on_timer_timeout)


func _process(_delta: float) -> void:
	if _show_progress:
		var left_time: float = timer.time_left
		skip_progress.value = (_skip_pressed_time - left_time) / _skip_pressed_time * 100
		if is_zero_approx(left_time):
			_show_progress = false
			skip_progress.visible = _show_progress

	# 检查空格键是否刚被按下
	if Input.is_action_just_pressed("long_press"):
		btn_skip.set_button_state(true)
		# 启动计时器
		_on_btn_skip_button_down()

	# 检查空格键是否刚被松开
	if Input.is_action_just_released("long_press"):
		btn_skip.set_button_state(false)
		# 停止计时器，这会阻止长按事件的触发
		_on_btn_skip_button_up()


func _on_timer_timeout() -> void:
	_on_btn_skip_button_up()
	timer.timeout.disconnect(_on_timer_timeout)
	#print("长按已触发！")
	long_press_over.emit()


func _on_btn_skip_button_down() -> void:
	#print("_on_btn_skip_button_down")
	timer.start()
	skip_progress.value = 0.0
	_show_progress = true
	skip_progress.visible = true


func _on_btn_skip_button_up() -> void:
	timer.stop()
	skip_progress.value = 100.0
	_show_progress = false
	skip_progress.visible = _show_progress
