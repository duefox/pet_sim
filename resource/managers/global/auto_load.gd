extends Node

#物品所对应的纹理表
var textures: Array[Dictionary] = [];
#基础的物品数据
var data: Array[Dictionary] = [
	{
		&'id': 1,
		&'item_name': &'剑',
		&'width': 1,
		&'height': 4,
		&'orientation': 0,
		&'stackable': false,
		&'num': 1
	},
	{
		&'id': 2,
		&'item_name': &'斧',
		&'width': 2,
		&'height': 4,
		&'orientation': 0,
		&'stackable': false,
		&'num': 1
	},
	{
		&'id': 3,
		&'item_name': &'盾',
		&'width': 2,
		&'height': 3,
		&'orientation': 0,
		&'stackable': false,
		&'num': 1
	},
	{
		&'id': 4,
		&'item_name': &'药水',
		&'width': 1,
		&'height': 1,
		&'orientation': 0,
		&'stackable': true,
		&'num': 1
	},
];

#创建纹理表的内容单元
func _create_textures_item() -> Dictionary:
	return {
		&'id': 0,
		&'name': &'',
		&'texture': null
	}

func _init() -> void:
	for it in self.data:
		var obj: Dictionary = _create_textures_item();
		obj.name = it.item_name;
		obj.id = it.id;
		obj.texture = load('res://assets/textures/tests/%s.png' % it.item_name);
		textures.append(obj);
	pass

#根据物品id获取对应纹理
func get_texture_resources(id):
	for item in self.textures:
		if item.id == id:
			return item.texture;
	return null;
	
#根据物品id找对应的物品data
func find_item_data(id):
	for item in data:
		if item.id == id: return item;
	return false;
