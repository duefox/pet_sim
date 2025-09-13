extends Node

## 节流时间字典
var _throttle_timers: Dictionary[String,float] = {}


## 节流函数
## @param key: 节流函数的唯一标识符
## @param delay: 冷却时间（秒）
## @param func: 待执行的函数
## @param args: 待执行函数的参数（可选）
func throttle(key: String, delay: float, cbk: Callable, args: Array = []) -> void:
	# 检查当前 key 是否存在于计时器中，并且是否还在冷却期
	if _throttle_timers.has(key) and Time.get_ticks_msec() < _throttle_timers[key]:
		return
	# 如果不在冷却期，执行函数
	cbk.callv(args)
	# 重置计时器
	_throttle_timers[key] = Time.get_ticks_msec() + delay * 1000
