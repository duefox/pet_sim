extends GameBar
class_name NavigationBar


func _on_btn_profile_pressed() -> void:
	state_machine.on_journal_pressed()


func _on_btn_map_pressed() -> void:
	state_machine.on_map_pressed()


func _on_btn_task_pressed() -> void:
	state_machine.on_task_pressed()


func _on_btn_visitor_pressed() -> void:
	state_machine.on_visitor_pressed()
