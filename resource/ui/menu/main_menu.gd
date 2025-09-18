extends BaseMenu
class_name MainMenu

func _ready() -> void:
	super()

func _on_btn_info_pressed() -> void:
	pass  # Replace with function body.


func _on_btn_new_pressed() -> void:
	state_machine.change_state(state_machine.State.NEW_GAME_MENU)


func _on_btn_load_pressed() -> void:
	state_machine.change_state(state_machine.State.SAVE_LOAD_MENU)


func _on_btn_setting_pressed() -> void:
	state_machine.change_state(state_machine.State.SETTINGS)


func _on_btn_exit_pressed() -> void:
	get_tree().quit()
