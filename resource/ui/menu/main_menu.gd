extends Control
class_name MainMenu


func _ready() -> void:
	pass


func initialize() -> void:
	#print("initialize")
	pass


func _on_btn_info_pressed() -> void:
	pass  # Replace with function body.


func _on_btn_new_pressed() -> void:
	GlobalData.menu.change_state(UIStateMachine.State.NEW_GAME_MENU)


func _on_btn_load_pressed() -> void:
	GlobalData.menu.change_state(UIStateMachine.State.SAVE_LOAD_MENU)


func _on_btn_setting_pressed() -> void:
	GlobalData.menu.change_state(UIStateMachine.State.SETTINGS)


func _on_btn_exit_pressed() -> void:
	get_tree().quit()
