# Main.gd
extends Node

func _ready():
	# 预加载或加载你的自定义资源
	var my_resource = preload("res://data/items/default.tres")
	
	# 获取资源的属性列表
	var properties: Array = my_resource.get_property_list()

	print("--- 正在遍历资源变量 ---")
	
	for prop in properties:
		# 只遍历导出的变量
		# `PROPERTY_USAGE_SCRIPT_VARIABLE` 表示它是脚本中的变量
		# `PROPERTY_USAGE_EDITOR` 表示它在编辑器中可见
		if (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) and (prop.usage & PROPERTY_USAGE_EDITOR):
			var name = prop.name
			var value = my_resource.get(name)
			var type_name = typeof(value)
			
			print("变量名称: ", name)
			print("变量值: ", value)
			print("变量类型: ", type_name)
