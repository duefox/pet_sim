shader_type canvas_item;

//摇摆的速度
uniform float speed:hint_range(0.0, 5.0, 0.1) = 2.5;
//左右摇摆的范围
uniform float range:hint_range(0.0, 5.0, 0.1) = 2.5;
//垂直方向的开始距离
uniform float startY:hint_range(0.0, 1.0, 0.1) = 0.5;

void vertex() {
	if(UV.y < startY){
		VERTEX.x +=sin(TIME*speed)*range;
	}
}
