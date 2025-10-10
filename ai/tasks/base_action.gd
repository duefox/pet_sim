extends BTAction
class_name BaseAction

var _pet: Pet


func _enter() -> void:
	_pet = agent as Pet
