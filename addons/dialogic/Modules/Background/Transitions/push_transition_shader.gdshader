shader_type canvas_item;

uniform vec2 final_offset = vec2(0,-1);
uniform float progress: hint_range(0.0, 1.0);
uniform sampler2D previous_background: source_color, hint_default_transparent;
uniform sampler2D next_background: source_color, hint_default_transparent;


void fragment() {
	vec2 uv = UV + final_offset * progress*vec2(-1, -1);

	if (uv.x < 1.0 && uv.x > 0.0 && uv.y < 1.0 && uv.y > 0.0){
		COLOR = texture(previous_background, uv, 1);
	} else {
		COLOR = texture(next_background, uv-final_offset*vec2(-1,-1));
	}
}
