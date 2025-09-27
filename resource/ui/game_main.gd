## 游戏场景主菜单容器，执行载入存档后才开始初始化
extends Control
class_name GameMain

const GAME_MENU_SCENE: PackedScene = preload("res://resource/ui/menu/game_menu.tscn")

var state_machine: UIStateMachine

var _game_menu: GameMenu = null


## 初始化父状态机
func initialize(my_state_machine: UIStateMachine) -> void:
	state_machine = my_state_machine


## 载入界面
func load_game_menu() -> void:
	# 已存在游戏菜单则返回
	if is_instance_valid(_game_menu):
		return
	_game_menu = GAME_MENU_SCENE.instantiate()
	add_child(_game_menu)
	# 给菜单的状态机初始
	_game_menu.initialize(state_machine)
	GlobalData.ui = _game_menu
	# 让玩家手动刷新数据
	await get_tree().physics_frame
	GlobalData.player.reflush_data()


## 退出节点
func exit_node() -> void:
	if is_instance_valid(_game_menu):
		_game_menu.queue_free()
