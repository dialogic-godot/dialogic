shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

uniform float amplitude_x : hint_range(0.0, 1.0) = 0.0;
uniform float frequency_x = 0.0;
uniform float phase_x = 0.0;
uniform float time_x = 0.0;

uniform float amplitude_y : hint_range(0.0, 1.0) = 0.0;
uniform float frequency_y = 0.0;
uniform float phase_y = 0.0;
uniform float time_y = 0.0;

uniform vec3 clear_color : source_color = vec3(0.0, 0.0, 0.0);

void fragment() {
	vec2 uv = SCREEN_UV;

	float angular_frequency_x = 2.0 * PI * frequency_x;
	float displacement_x = amplitude_x * sin(angular_frequency_x * (time_x + phase_x));

	float angular_frequency_y = 2.0 * PI * frequency_y;
	float displacement_y = amplitude_y * sin(angular_frequency_y * (time_y + phase_y));

	uv.x += displacement_x / 1.0;
	uv.y += displacement_y / 1.0;

	if (uv.x > 1.0 || uv.y > 1.0 || uv.x < 0.0 || uv.y < 0.0) {
		COLOR.rgb = clear_color;
		COLOR.a = 1.0;
	} else {
		COLOR = texture(SCREEN_TEXTURE, uv);
	}
}
