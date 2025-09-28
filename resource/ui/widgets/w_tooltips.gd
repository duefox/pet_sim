extends MarginContainer
class_name WTooltips
@onready var simple_label: RichTextLabel = %SimpleLabel


func update_display(info: Variant) -> void:
	await ready
	if not info:
		return
	if info is String:
		simple_label.text = str(info)
	elif info is Dictionary:
		pass
