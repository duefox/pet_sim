## 世界地图数据
extends BaseBagComponent
class_name WorldMapComponent

## 8种大型资源点地形，key为ID，value为占用尺寸
const LARGE_TERRAINS: Dictionary = {
	"9001": {"range": Vector2(-1.0, -0.75), "size": Vector2(6, 4)},
	"9002": {"range": Vector2(-0.75, -0.5), "size": Vector2(5, 7)},
	"9003": {"range": Vector2(-0.5, -0.25), "size": Vector2(5, 5)},
	"9004": {"range": Vector2(-0.25, 0.0), "size": Vector2(8, 4)},
	"9005": {"range": Vector2(0.0, 0.25), "size": Vector2(6, 6)},
	"9006": {"range": Vector2(0.25, 0.5), "size": Vector2(7, 7)},
	"9007": {"range": Vector2(0.5, 0.75), "size": Vector2(6, 6)},
	"9008": {"range": Vector2(0.75, 1.0), "size": Vector2(5, 5)}
}

## 8种小型地形的ID列表
const SMALL_TERRAINS: Array = ["9009", "9010", "9011", "9012", "9013", "9014", "9015", "9015"]
## 固定的地形ID列表
const REGULAR_TERRAINS: Array = ["9017"]
## 固定仓库id
const INVENTORY_ID: String = "9018"

## 默认送的建筑物品（鱼缸等等）
@export var regular_build: Array = ["6001"]
## 固定送的大型资源点ID,新建世界用户的选择相关
@export var regular_terrains_id: String = "9001"
## 世界的大小
@export var world_size: Vector2i = Vector2i(38, 38)
## 小地形物品生成概率
@export var create_rate: float = 0.15

## 默认解锁区域
var unlock_arear: Array = [Rect2i(20, 0, 20, 20)]

## 噪声生成器
var noise = FastNoiseLite.new()
## 地形物品数据
var item_db: Dictionary[String,Dictionary] = {}
## 每种物品的最大生成数量限制
## 每种物品的最大生成数量限制
var item_max_counts: Dictionary = {
	"9001": 1,
	"9002": 1,
	"9003": 1,
	"9004": 1,
	"9005": 1,
	"9006": 1,
	"9007": 1,
	"9008": 1,
	"9009": 40,
	"9010": 40,
	"9011": 40,
	"9012": 40,
	"9013": 40,
	"9014": 40,
	"9015": 40,
	"9016": 40,
	"9017": 0,  # 接待前台，固定生成
	"9018": 0,  # 仓库，固定生成
}
## 实时追踪每种物品的已生成数量
var item_current_counts: Dictionary = {}
## 世界数据映射表，存储已放置物品
var world_map: Dictionary = {}


## 当数据发生变化时，通过事件总线通知所有订阅者
func emit_changed_event(_data: Array[Dictionary]) -> void:
	EventManager.emit_event(UIEvent.WORLD_MAP_CHANGED, {"items_data": _data})


## 第一次创建存档的时候默认创建数据
func init_data(gird_size: Vector2 = Vector2.ZERO) -> void:
	if not gird_size == Vector2.ZERO:
		world_size = gird_size
	# 获取创建文档时候的种子
	var map_seed: int = randi()
	# 初始化世界地图地形
	initialize(map_seed)


## 添加宠物（房间有大小，空间还有才能放下）
func add_pet(room_id: String, head_pos: Vector2, data: Dictionary) -> bool:
	var item_data: Dictionary = find_item_data(room_id, head_pos)
	var pets_data: Array = item_data["pets_data"]
	# 计算改房间还能放置宠物的空间大小
	var left_space: int = _comput_left_room_space(item_data)
	var space: int = data["width"] * data["height"]
	print("left_space:",left_space)
	if left_space >= space:
		pets_data.append(data)
		# 通知更新数据
		emit_changed_event(items_data)
		return true
	return false


## 添加食物（不能超过上限）
func add_food(room_id: String, head_pos: Vector2, data: Dictionary) -> int:
	var item_data: Dictionary = find_item_data(room_id, head_pos)
	var foods_data: Array = item_data["foods_data"]
	# 计算改房间还能放置食物的数量
	var left_count: int = _comput_food_left_count(item_data, data)
	data.set("num", data.get("num", 1) - left_count)
	foods_data.append(data)
	# 通知更新数据
	emit_changed_event(items_data)
	return left_count


func initialize(map_seed: int) -> void:
	noise.seed = map_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.05
	# 构建基础配置数据
	_generate_item_data()
	# 构建固定的世界物品
	_generate_regular_world()
	# 构建世界数据
	_generate_world()
	#print("World generation complete. Total items: ", items_data.size())
	# 通知地块更新数据
	emit_changed_event(items_data)


## 构建数据
func _generate_item_data() -> void:
	for item_id: String in item_max_counts:
		var dict: Dictionary = GlobalData.find_item_data(item_id)
		if not dict.is_empty():
			item_db.set(item_id, dict)


## 构建固定的世界物品
func _generate_regular_world() -> void:
	# 按x方向水平布局
	# 1.布局固定地形
	var coords_x: int = 0
	var coords_y: int = 0
	var world_center_top: Vector2i = Vector2i(int(world_size.x / 2.0), 0)
	var head_pos: Vector2 = Vector2.ZERO
	var item_data: Dictionary
	for item_id: String in REGULAR_TERRAINS:
		item_data = item_db[item_id]
		# 计算初始位置
		if head_pos == Vector2.ZERO:
			head_pos = Vector2(world_center_top) - Vector2(int(item_data.get("width", 0) / 2.0), 0.0)
		else:
			head_pos += Vector2(coords_x, 0.0)
		coords_x += item_data.get("width", 6)
		coords_y = max(item_data.get("heigjt", 6), coords_y)
		_try_add_new_data(item_data, head_pos)

	# 2.布局固定仓库，按默认解锁区域的一个元素位置开始
	var arear_rect: Rect2i = unlock_arear[0]
	item_data = item_db[INVENTORY_ID]
	_try_add_new_data(item_data, Vector2(arear_rect.position))

	# 3.布局初始送的鱼缸，按竖直方向布局
	coords_x = 0
	for item_id: String in regular_build:
		head_pos += Vector2(coords_x, coords_y)
		coords_y += 6
		# 添加建筑
		var success: bool = _try_place_item(GlobalData.find_item_data(item_id), head_pos)
		if success:
			add_item(item_id, 1, {}, head_pos)

	# 4.布局初始送的资源点，按竖直方向布局
	item_data = item_db[regular_terrains_id]
	# 随机位置
	head_pos = Vector2(randi_range(arear_rect.position.x, arear_rect.position.x + arear_rect.size.x), coords_y)
	_try_add_new_data(item_data, head_pos)


## 生成世界
func _generate_world() -> void:
	# 第一步：放置大型地形
	for item_id: String in LARGE_TERRAINS:
		var rank = LARGE_TERRAINS[item_id].range
		var item_data = item_db[item_id]
		_place_large_terrain(item_data, rank)

	# 第二步：用小型地形填充剩余的空位
	_place_small_terrains()


## 尝试在特定噪声值范围内放置一个大型地形
func _place_large_terrain(item_data: Dictionary, noise_range: Vector2) -> void:
	var candidates: Array = []
	# 遍历所有格子，找到符合噪声值范围的放置点
	for y in range(world_size.y):
		for x in range(world_size.x):
			var noise_val = noise.get_noise_2d(x, y)
			if noise_val >= noise_range.x and noise_val < noise_range.y:
				candidates.append(Vector2(x, y))

	if candidates.is_empty():
		return

	# 从候选项中随机选择一个位置
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var head_pos = candidates[rng.randi_range(0, candidates.size() - 1)]
	# 尝试放置大型地形
	var success: bool = _try_place_item(item_data, head_pos)
	if success:
		_add_new_item_data(item_data, head_pos)


## 尝试添加数据
func _try_add_new_data(item_data: Dictionary, current_pos: Vector2) -> void:
	var success: bool = _try_place_item(item_data, current_pos)
	if success:
		_add_new_item_data(item_data, current_pos)


## 添加数据
func _add_new_item_data(item_data: Dictionary, head_pos: Vector2) -> void:
	# 创建新物品数据字典
	var item_data_dict = {"id": item_data.id, "num": 1, "head_position": head_pos}
	# 放入待更新数组
	items_data.append(item_data_dict)


## 在剩余的空位上随机放置小型地形
func _place_small_terrains() -> void:
	var empty_cells: Array = []
	# 1. 找到所有空闲格子
	for y in range(int(world_size.y)):
		for x in range(int(world_size.x)):
			var current_pos = Vector2(x, y)
			if not world_map.has(current_pos):
				empty_cells.append(current_pos)

	# 2. 随机打乱空闲格子列表
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	empty_cells.shuffle()

	# 3. 遍历打乱后的列表，并尝试放置物品
	for current_pos in empty_cells:
		# 以一定概率生成小型物品
		if rng.randf() < create_rate:
			var small_item_id = SMALL_TERRAINS[rng.randi_range(0, SMALL_TERRAINS.size() - 1)]
			var item_data = item_db[small_item_id]

			if item_current_counts.get(small_item_id, 0) < item_max_counts.get(small_item_id, 9999):
				var success: bool = _try_place_item(item_data, current_pos)
				if success:
					_add_new_item_data(item_data, current_pos)


## 尝试在指定位置放置物品（大型和小型通用）
func _try_place_item(item_data: Dictionary, head_pos: Vector2) -> bool:
	var item_width: int = item_data.get("width", 1)
	var item_height: int = item_data.get("height", 1)

	# 检查物品占用区域是否都空闲
	for x in range(item_width):
		for y in range(item_height):
			var check_pos = head_pos + Vector2(x, y)
			if check_pos.x >= world_size.x or check_pos.y >= world_size.y or world_map.has(check_pos):
				return false

	# 标记所有被占用的格子
	for x in range(item_width):
		for y in range(item_height):
			var occupied_pos = head_pos + Vector2(x, y)
			world_map[occupied_pos] = item_data.id
			item_current_counts[item_data.id] = item_current_counts.get(item_data.id, 0) + 1

	return true


## 计算房间还可以放下宠物的空间大小
func _comput_left_room_space(item_data: Dictionary) -> int:
	var pets_data: Array = item_data.get("pets_data", [])
	var room_size: int = item_data["width"] * item_data["height"]
	print("room_size:",room_size)
	var left_space: int = room_size
	for data: Dictionary in pets_data:
		var space: int = data["width"] * data["height"]
		print("space:",space)
		left_space -= space

	return max(left_space, 0)


## 计算房间还可以放下食物后的剩余量
func _comput_food_left_count(item_data: Dictionary, place_data: Dictionary) -> int:
	var foods_data: Array = item_data.get("foods_data", [])
	var place_count: int = 0
	for data: Dictionary in foods_data:
		var num: int = data.get("num", 1)
		place_count += num
	# 还可以放置的数量
	var left_count: int = max(GlobalData.room_max_food - place_count, 0)
	if place_data.get("num", 1) > left_count:
		return place_data.get("num", 1) - left_count
	else:
		return 0
