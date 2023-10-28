shader_type canvas_item;

// Indicates how far the transition is (0 start, 1 end).
uniform float progress : hint_range(0.0, 1.0);
// The previous background, transparent if there was none.
uniform sampler2D previousBackground : source_color, hint_default_transparent;
// The next background, transparent if there is none.
uniform sampler2D nextBackground : source_color, hint_default_transparent;

// The texture used to determine how far along the progress has to be for bending in the new background.
uniform sampler2D whipeTexture : source_color;
// The size of the trailing smear of the transition.
uniform float feather : hint_range(0.0, 1.0, 0.0001) = 0.1;
// Determines if the whipe texture should keep it's aspect ratio when scaled to the screen's size.
uniform bool keepAspectRatio = false;

void fragment() {
	vec2 fragCoord = UV;
	if(keepAspectRatio) {
    	vec2 ratio = (SCREEN_PIXEL_SIZE.x > SCREEN_PIXEL_SIZE.y)				// determine how to scale
			? vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1)				// fit to width
			: vec2(1, SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y);				// fit to height
    	fragCoord *= ratio;
	}
	
	// get the blend factor between the previous and next background.
	float alpha = (texture(whipeTexture, fragCoord).r) - progress;
	float blendFactor = 1. - smoothstep(0., feather, alpha + (feather * (1. -progress)));
	
	vec4 oldFrag = texture(previousBackground, UV);
	vec4 newFrag = texture(nextBackground, UV);
	
	COLOR = mix(oldFrag, newFrag, blendFactor);
}
