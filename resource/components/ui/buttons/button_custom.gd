@tool
extends Button
class_name ButtonCustom

## 自定义tooltips窗口
func _make_custom_tooltip(for_text: String) -> Control:
	return Tooltips.create(for_text)
