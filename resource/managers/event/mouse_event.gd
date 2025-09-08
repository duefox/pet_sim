extends Node
## 全局记录鼠标相关信息

enum CONTROLS_TYPE { DEF, DRAG }  # 默认状态  # 拿起物品时的状态

var is_mouse_down: bool = false  # 记录鼠标是否按下
var mouse_position: Vector2  # 记录鼠标位置
var mouse_state: int = self.CONTROLS_TYPE.DEF  # 鼠标当前的操作状态
var mouse_cell_pos: Vector2  # 鼠标进入的格子坐标
var mouse_cell_matrix: MultiGridContainer  # 鼠标所在的多格子容器节点(引用)
var mouse_is_effective: bool  # 鼠标所点击的地方是不是无物品的


#获取鼠标是否在抓取状态
func is_mouse_drag() -> bool:
	if MouseEvent.mouse_state == MouseEvent.CONTROLS_TYPE.DRAG:
		return true
	else:
		return false
