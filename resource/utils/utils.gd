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


## 计算占用空间大小,JUVENILE
## 规则是用成年的大小除以2向上取整
## @param space: 占用空间的大小
## @param max_space: 最大占用空间的大小
func get_juvenile_space(space: int = 1, max_space: int = 4) -> int:
	space = ceili(space / 2.0)
	return clamp(space, 1, max_space)


## 读取文件夹
## [param:path] 文件夹路径
## [return] 所有文件的数组
func get_files(path: String) -> PackedStringArray:
	var dir = DirAccess.open(path)
	if dir:
		return dir.get_files()
	return []


## 从资源中把属性赋值给节点
## @param resource: 属性的资源来源
## @return 返回资源导出变量为key对应的字典
func get_properties_from_res(resource: Resource) -> Dictionary:
	var dic: Dictionary[String,Variant] = {}
	# 获取资源的属性列表
	var properties: Array = resource.get_property_list()
	for prop in properties:
		# 只遍历导出的变量
		# `PROPERTY_USAGE_SCRIPT_VARIABLE` 表示它是脚本中的变量
		# `PROPERTY_USAGE_EDITOR` 表示它在编辑器中可见
		if (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) and (prop.usage & PROPERTY_USAGE_EDITOR):
			var key_name = prop.name
			var key_value = resource.get(key_name)
			dic.set(key_name, key_value)
	return dic
