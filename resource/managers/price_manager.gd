## 价格管理器，市场波动，优惠，好感度影响价格
extends Node

## key: 物品级别, value: 基础价格的倍数
const SALE_PRICES_MULTIPLE: Dictionary = {
	0: 1,  # 普通
	1: 2,  # 稀有
	2: 3,  # 罕见
	3: 4,  # 传说
}

## 全局市场波动值 (例如每小时更新一次)
var market_fluctuation: float = 1.0

## 模拟全局活动折扣，例如周年庆打折
var global_activity_discount: float = 0.0


## 构造函数，在单例加载时调用
func _init() -> void:
	# 初始化市场波动值，可以在这里启动一个定时器来定期更新
	update_market_fluctuation()


## 更新市场波动
func update_market_fluctuation() -> void:
	# 随机生成一个 -20% 到 +20% 的波动值
	market_fluctuation = 1.0 + randf_range(-0.2, 0.2)
	print("市场波动已更新至：", market_fluctuation)


## 计算物品的购买价格
## @param item_info: 物品的原始数据字典，包含基础价格、类型等
## @param player_info: 玩家数据字典，包含好感度等信息
## @return int 最终的购买价格
func get_purchase_price(item_info: Dictionary, player_info: Dictionary = {}) -> int:
	# 物品的基础购买价格
	var base_price: int = item_info.get("purchase_price", 1)

	# 1. 玩家好感度折扣 (示例：好感度每100点提供1%的额外折扣)
	var favorability: float = player_info.get("favorability", 0)
	var favorability_discount: float = favorability / 10000.0

	# 2. 全球活动折扣 (如果存在)
	var final_activity_discount: float = global_activity_discount

	# 3. 随机波动（确保每次购买价格都略有不同）
	var random_fluctuation: float = randf_range(-0.02, 0.02)

	var final_price: float = base_price * (1.0 - final_activity_discount) * (1.0 - favorability_discount) * (1.0 + random_fluctuation)

	return round(final_price)


## 计算物品的出售价格
## @param item_data: 物品的当前数据字典，包含等级、成长值等
## @return int 最终的出售价格
func get_sale_price(item_data: Dictionary) -> int:
	# 获取物品等级
	var item_level: int = item_data.get("item_level", 0)
	# 获取物品的成长值
	var growth: float = item_data.get("growth", 0.0)
	# 确保包含原始数据（item_info就是原始数据）
	if not item_data.has("item_info"):
		var origin_data: Dictionary = GlobalData.find_item_data(item_data["id"])
		var item_info: Dictionary = Utils.get_properties_from_res(origin_data["item_info"]).duplicate(true)
		item_data.set("item_info", item_info)
	# 1. 根据级别获取基础出售价格，根据BASE_SALE_PRICES
	var base_price: int = int(item_data["item_info"].get("base_price", 1)) * SALE_PRICES_MULTIPLE.get(item_level, 0)
	# 2. 根据成长值增加价格（假设成长值与价格线性相关）
	var growth_bonus: float = 0.0
	# 如果物品有成长值属性
	if item_data["item_info"].get("item_type") == 2:  # 2 代表动物类型
		var adult_threshold: float = item_data["item_info"].get("adult_growth_threshold", 100.0)
		# 成年动物出售价格翻倍
		if growth >= adult_threshold:
			growth_bonus = base_price
		# 未成年动物根据成长比例增加价格
		else:
			growth_bonus = base_price * (growth / adult_threshold)

	# 3. 结合市场波动
	var final_price: float = (base_price + growth_bonus) * market_fluctuation

	# 确保价格不低于0，并返回整数
	return max(0, floor(final_price))
