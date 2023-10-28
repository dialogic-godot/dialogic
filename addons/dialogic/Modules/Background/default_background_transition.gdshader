shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0);
uniform sampler2D previousBackground : source_color, hint_default_transparent;
uniform sampler2D nextBackground : source_color, hint_default_transparent;

uniform sampler2D whipeTexture : source_color;
uniform float feather : hint_range(0.0, 1.0, 0.0001) = 0.1;

void fragment() {
	float alpha = (texture(whipeTexture, UV).r) - progress;
	
	float blendFactor = 1. - smoothstep(0., feather, alpha + (feather * (1. -progress)));
	
	vec4 oldFrag = texture(previousBackground, UV);
	vec4 newFrag = texture(nextBackground, UV);
	
	COLOR = mix(oldFrag, newFrag, blendFactor);
}
