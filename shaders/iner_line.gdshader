shader_type canvas_item;
uniform float width:hint_range(0.0, 10.0)=1.0;
uniform vec4 outline_color:source_color=vec4(1.0,1.0,1.0,1.0);


void fragment() {
	vec4 text_color=texture(TEXTURE,UV);
	//float pos_x=width*1.0/float(textureSize(TEXTURE,0).x);
	//float pos_y=width*1.0/float(textureSize(TEXTURE,0).y);
	float pos_x=width*TEXTURE_PIXEL_SIZE.x;
	float pos_y=width*TEXTURE_PIXEL_SIZE.y;
	
	float alpha=8.0*text_color.a;
	alpha-=texture(TEXTURE,UV+vec2(pos_x,0)).a;
	alpha-=texture(TEXTURE,UV+vec2(-pos_x,0)).a;
	alpha-=texture(TEXTURE,UV+vec2(0,pos_y)).a;
	alpha-=texture(TEXTURE,UV+vec2(0,-pos_y)).a;
	alpha-=texture(TEXTURE,UV+vec2(-pos_x,-pos_y)).a;
	alpha-=texture(TEXTURE,UV+vec2(-pos_x,pos_y)).a;
	alpha-=texture(TEXTURE,UV+vec2(pos_x,-pos_y)).a;
	alpha-=texture(TEXTURE,UV+vec2(pos_x,pos_y)).a;
	
	vec4 final_color=mix(text_color,outline_color,clamp(alpha,0.0,1.0));
	COLOR=vec4(final_color.rgb,clamp(alpha+text_color.a,0.0,1.0));
	//COLOR=vec4(final_color.rgb,text_color.a);
	
}
