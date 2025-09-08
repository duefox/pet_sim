extends Control

@onready var gold_label: Label = %GoldLabel
@onready var date_label: Label = %DateLabel
@onready var icon_season: TextureRect = %IconSeason
@onready var weather_label: Label = %WeatherLabel
@onready var icon_weather: TextureRect = %IconWeather
@onready var left_button_expand: ButtonEmpty = %LeftButtonExpand
@onready var right_button_expand: ButtonExpand = %RightButtonExpand
@onready var backpack_box: Control = $UI/BackpackBox
@onready var info_box: Control = $UI/InfoBox


var _leftMenuExpanded: bool = true
var _rightMenuExpanded: bool = true
var _isRightTween: bool = false
var _isLeftTween: bool = false



func _ready() -> void:
	
	#订阅UI事件
	#EventManager.subscribe(UIEvent.PACK_EXPAND,_on_pack_expand)
	#EventManager.subscribe(UIEvent.PACK_CONTRACT,_on_pack_contract)
	

	pass
	
func _exit_tree() -> void:
	#EventManager.unsubscribe(UIEvent.PACK_EXPAND,_on_pack_expand)
	#EventManager.unsubscribe(UIEvent.PACK_CONTRACT,_on_pack_contract)
	pass


#region 按钮事件

func _on_button_profile_pressed() -> void:
	pass  # Replace with function body.


func _on_button_map_pressed() -> void:
	pass  # Replace with function body.


func _on_button_task_pressed() -> void:
	pass  # Replace with function body.


func _on_button_visitor_pressed() -> void:
	pass  # Replace with function body.


func _on_button_build_pressed() -> void:
	pass  # Replace with function body.


func _on_button_layout_pressed() -> void:
	pass  # Replace with function body.


func _on_button_lanscape_pressed() -> void:
	pass  # Replace with function body.


func _on_button_setting_pressed() -> void:
	pass  # Replace with function body.


func _on_left_button_expand_pressed() -> void:
	AudioManager.play_sound(ResPaths.AUDIO_RES.sfx.menu)
	_leftMenuExpanded = !_leftMenuExpanded
	var icon: AtlasTexture = left_button_expand.icon
	if _leftMenuExpanded:
		icon.region = Rect2(384.0, 0.0, 64.0, 64.0)
	else:
		icon.region = Rect2(320.0, 0.0, 64.0, 64.0)
	_left_box_expand(_leftMenuExpanded)


func _on_right_button_expand_pressed() -> void:
	AudioManager.play_sound(ResPaths.AUDIO_RES.sfx.menu)
	_rightMenuExpanded = !_rightMenuExpanded
	var icon: AtlasTexture = right_button_expand.icon
	if _rightMenuExpanded:
		icon.region = Rect2(192.0, 0.0, 64.0, 64.0)
	else:
		icon.region = Rect2(256.0, 0.0, 64.0, 64.0)
	_right_box_expand(_rightMenuExpanded)
	
	


#endregion

#region 私有方法


func _left_box_expand(expand: bool = true) -> void:
	var coords: Vector2 = Vector2.ZERO
	if !expand:
		coords = Vector2(0.0, 200 - info_box.find_child("InfoBG").size.y)
	if _isLeftTween:
		return
	_isLeftTween = await _tween_box_position(info_box, coords)


func _right_box_expand(expand: bool = true) -> void:
	var winSize = get_viewport_rect().size
	var coords: Vector2 = Vector2(winSize.x, 0.0)
	if !expand:
		coords = Vector2(winSize.x + backpack_box.find_child("BackpackBG").size.x + 12, 0.0)
	if _isRightTween:
		return
	_isRightTween = await _tween_box_position(backpack_box, coords)


func _tween_box_position(box: Control, coords: Vector2 = Vector2.ZERO, dt: float = 0.3) -> bool:
	var tween: Tween = create_tween()
	tween.set_parallel()
	tween.tween_property(box, "position", coords, dt)
	await tween.finished
	return false
#endregion
