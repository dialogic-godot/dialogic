shader_type canvas_item;

uniform sampler2D deformation_sampler : filter_linear, repeat_enable;
uniform float radius :hint_range(1.0, 200, 0.01)= 25;
uniform vec2 box_size = vec2(100, 100);
uniform float box_padding = 15;
uniform float wobble_amount : hint_range(0.0, 1.0, 0.01) = 0.2;
uniform float wobble_speed : hint_range(0.0, 10.0, 0.01) = 1;
uniform float wobble_detail : hint_range(0.01, 1, 0.01) = 0.5;

void fragment() {
	float adjusted_radius = min(min(radius, box_size.x/2.0), box_size.y/2.0);
	vec2 deformation_sample = texture(deformation_sampler, UV*wobble_detail+TIME*wobble_speed*0.05).xy*(vec2(box_padding)/box_size)*0.9;
	vec2 deformed_UV = UV+((deformation_sample)-vec2(0.5)*vec2(box_padding)/box_size)*wobble_amount;
	float rounded_box = length(max(abs(deformed_UV*(box_size+vec2(box_padding))-vec2(0.5)*(box_size+vec2(box_padding)))+adjusted_radius-vec2(0.5)*box_size,0))-adjusted_radius;
	COLOR.a = min(smoothstep(0.0, -1, rounded_box), COLOR.a);
}
