extends BaseBagComponent
class_name LandscpeComponent


## 当数据发生变化时，通过事件总线通知所有订阅者
func emit_changed_event(_data: Array[Dictionary]) -> void:
	EventManager.emit_event(UIEvent.LANDSCAPE_CHANGED, {"items_data": _data})


## 第一次创建存档的时候默认创建数据
func init_data(_gird_size: Vector2 = Vector2.ZERO) -> void:
	pass
