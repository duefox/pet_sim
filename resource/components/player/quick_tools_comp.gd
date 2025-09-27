extends BaseBagComponent
class_name QuickToolsComponent


## 当数据发生变化时，通过事件总线通知所有订阅者
func emit_changed_event(_data: Array[Dictionary]) -> void:
	EventManager.emit_event(UIEvent.QUICK_TOOLS_CHANGED, {"items_data": _data})


## 第一次创建存档的时候默认创建数据
func init_data(_gird_size: Vector2 = Vector2.ZERO) -> void:
	# 默认送俩种鱼饲料
	add_item("3001", 9)
	add_item("3002", 9)
	# 默认送俩条鱼（1雄鱼，1雌鱼）
	add_item("1001", 2)
