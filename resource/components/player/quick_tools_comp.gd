extends BaseBagComponent
class_name QuickToolsComponent

## 当数据发生变化时，通过事件总线通知所有订阅者
func emit_event(_data: Array[Dictionary]) -> void:
	EventManager.emit_event(UIEvent.QUICK_TOOLS_CHANGED, {"items_data": _data})
