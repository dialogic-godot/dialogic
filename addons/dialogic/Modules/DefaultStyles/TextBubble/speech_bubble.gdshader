shader_type canvas_item;
uniform sampler2D deformation_sampler : filter_linear, repeat_enable;
uniform sampler2D spikes_sampler : filter_linear, repeat_enable;
uniform sampler2D curve_sampler;
uniform float radius :hint_range(0.1, 5, 0.01)= 0.25;
uniform vec2 ratio = vec2(1.0, 1.0);

uniform float crease : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float speed : hint_range(0.0, 10.0, 0.01) = 1;
uniform float texture_scale : hint_range(0.0, 0.5, 0.01) = 0.2;
uniform float texture_offset : hint_range(0.0, 300, 0.5) = 1;

void fragment() {
	vec2 ratio_uv = UV * ratio;
	float spikes = texture(spikes_sampler, ratio_uv * texture_scale + vec2(texture_offset)).x;
//
	float d = length(max(abs(ratio_uv - vec2(0.5) * ratio) + radius - vec2(0.5) * ratio,0.0)) - radius;
	d += (distance(vec2(0.5), UV) - 0.5) * radius;
	float curve = texture(curve_sampler, vec2(d + spikes, 0.0)).x;
	d += curve * crease;
	d += texture(deformation_sampler, ratio_uv * 0.05 + TIME * speed*0.01).x * 0.1;
	float mask = smoothstep(0.0, -0.005, d);
	COLOR.a = mask;
}
