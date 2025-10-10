extends Node

## 节流时间字典
var _throttle_timers: Dictionary[String,float] = {}


## 获取窗口的大小
func get_win_size() -> Vector2:
	var viewport_width: int = ProjectSettings.get_setting("display/window/size/viewport_width", 1152)
	var viewport_height: int = ProjectSettings.get_setting("display/window/size/viewport_height", 648)
	var viewport_scale: float = ProjectSettings.get_setting("display/window/stretch/scale", 1.0)
	return Vector2(viewport_width, viewport_height) / viewport_scale


## 计算属性弹窗的屏幕坐标
func get_target_coords(mouse_position: Vector2, panel_size: Vector2) -> Vector2:
	# 设置坐标
	var viewport_size: Vector2 = Utils.get_win_size()
	var center_x: float = viewport_size.x / 2.0
	const OFFSET: float = 48.0  # 距离鼠标的偏移量
	var target_pos_x: float
	var target_pos_y: float

	# a) 决定 X 轴位置 (左右居中策略)
	if mouse_position.x > center_x:
		# 点击在右半部分 -> 面板显示在鼠标左侧 (往左偏移)
		target_pos_x = mouse_position.x - panel_size.x - OFFSET
	else:
		# 点击在左半部分 -> 面板显示在鼠标右侧 (往右偏移)
		target_pos_x = mouse_position.x + OFFSET

	# b) 决定 Y 轴位置 (上下自动调整)
	# 默认：显示在鼠标下方
	target_pos_y = mouse_position.y + OFFSET
	# 如果面板底部超出屏幕，则改为显示在鼠标上方
	if target_pos_y + panel_size.y > viewport_size.y:
		target_pos_y = mouse_position.y - panel_size.y - OFFSET
	# c) 边界检查和钳制 (Clamping)
	# 钳制 X 轴：确保面板完全在屏幕内 (X >= 0 且 X + width <= viewport.width)
	target_pos_x = clampf(target_pos_x, 0.0, viewport_size.x - panel_size.x)
	# 钳制 Y 轴：确保面板完全在屏幕内 (Y >= 0 且 Y + height <= viewport.height)
	target_pos_y = clampf(target_pos_y, 0.0, viewport_size.y - panel_size.y)

	return Vector2(target_pos_x, target_pos_y)


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


## 根据成长值获取贴图
## @param data_info: 宠物信息
## @param pet_growth: 宠物成长值
## return 返回一个数据字典
func get_texture_by_growth(data_info: Dictionary, pet_growth: float) -> Dictionary:
	var result_dic: Dictionary = {}
	# 贴图和占用空间
	var adult_threshold: float = data_info.adult_growth_threshold
	var space_width: int = data_info.width
	var space_height: int = data_info.height
	# 默认贴图
	var default_texture: CompressedTexture2D = data_info.texture
	# 成年了
	if pet_growth == adult_threshold:
		default_texture = data_info.adult_texture
	# 有的宠物有第二阶段，比如蝴蝶的虫蛹状态，这种动物的成年阈值为200
	elif pet_growth >= 100 and pet_growth < adult_threshold:
		default_texture = data_info.pupa_texture
		## 重置占用空间大小
		space_width = Utils.get_juvenile_space(data_info.width)
		space_height = Utils.get_juvenile_space(data_info.height)
	# 幼年
	else:
		default_texture = data_info.texture
		## 重置占用空间大小
		space_width = Utils.get_juvenile_space(data_info.width)
		space_height = Utils.get_juvenile_space(data_info.height)

	result_dic.set("width", space_width)
	result_dic.set("height", space_height)
	result_dic.set("texture", default_texture)

	return result_dic


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


## 获取两个数组的“多重集合对称差集” (Symmetric Multiset Difference)。
## 元素满足：在 A 和 B 中数量不一致的所有元素。
## 示例：A=[1, 2], B=[1, 2, 2] -> [2]
## 示例：A=[1, 2, 2], B=[1, 3, 3, 3] -> [2, 2, 3, 3, 3]
func get_array_difference(array_a: Array, array_b: Array) -> Array:
	# 1. 统计 array_a 中每个元素的数量
	var count_a: Dictionary = {}
	for item in array_a:
		# 使用 get(key, default) 确保安全地增加计数
		count_a[item] = count_a.get(item, 0) + 1

	# 2. 统计 array_b 中每个元素的数量
	var count_b: Dictionary = {}
	for item in array_b:
		count_b[item] = count_b.get(item, 0) + 1

	var result_array: Array = []

	# 3. 找出所有唯一的元素（A 和 B 中出现过的所有键）
	var unique_elements: Dictionary = count_a.duplicate()
	for key in count_b.keys():
		unique_elements[key] = true  # 只需要收集键，值不重要

	# 4. 遍历所有唯一元素，计算绝对差值
	for item in unique_elements.keys():
		var count_in_a: int = count_a.get(item, 0)
		var count_in_b: int = count_b.get(item, 0)

		# 绝对差值就是该元素在结果中需要保留的数量
		var diff_count: int = abs(count_in_a - count_in_b)

		# 5. 将该元素添加 diff_count 次到结果数组
		for _i in range(diff_count):
			result_array.append(item)

	return result_array
