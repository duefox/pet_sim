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


## 递归获取指定目录下所有文件的路径
## @param path: 要扫描的目录路径
## @return: 包含所有文件路径的PackedStringArray
func get_all_files(path: String) -> PackedStringArray:
	var files: PackedStringArray = []
	var dir: DirAccess = DirAccess.open(path)

	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()

		while file_name != "":
			if dir.current_is_dir():
				# 这是一个子目录，递归调用自身
				files.append_array(get_all_files(path.path_join(file_name)))
			else:
				# 这是一个文件，添加到列表中
				files.append(path.path_join(file_name))

			file_name = dir.get_next()
	else:
		push_warning("An error occurred when trying to access the path: ", path)

	return files


## 获得目录资源并整理成符合要求的字典数据
## @param path_folder: 目录路径
## @return: 文件名-文件路径 字典
func get_res_to_dic(path_folder: String) -> Dictionary[StringName,String]:
	var tmp_dic: Dictionary[StringName,String] = {}
	# 调用 get_all_files 函数，它会递归地获取所有文件
	var files: PackedStringArray = get_all_files(path_folder)

	if files.is_empty():
		return {}

	for file: String in files:
		# 获取不带扩展名的文件名
		var file_name: String = file.get_file().get_basename()
		# 将文件名作为键，完整路径作为值
		tmp_dic.set(file_name, file)

	return tmp_dic
