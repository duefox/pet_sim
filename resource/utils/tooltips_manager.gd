# TooltipManager.gd
extends Node

const W_TOOLTIPS:PackedScene = preload("res://resource/ui/widgets/w_tooltips.tscn")

func create(info: Variant):
	var item_tips:WTooltips=W_TOOLTIPS.instantiate()
	item_tips.update_display(info)
	return item_tips
