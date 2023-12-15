shader_type canvas_item;

// Indicates how far the transition is (0 start, 1 end).
uniform float progress : hint_range(0.0, 1.0);
// The previous background, transparent if there was none.
uniform sampler2D previous_background : source_color, hint_default_transparent;
// The next background, transparent if there is none.
uniform sampler2D next_background : source_color, hint_default_transparent;

// The texture used to determine how far along the progress has to be for bending in the new background.
uniform sampler2D wipe_texture : source_color;
// The size of the trailing smear of the transition.
uniform float feather : hint_range(0.0, 1.0, 0.0001) = 0.1;
// Determines if the wipe texture should keep it's aspect ratio when scaled to the screen's size.
uniform bool keep_aspect_ratio = false;

void fragment() {
	vec2 frag_coord = UV;
	if(keep_aspect_ratio) {
		vec2 ratio = (SCREEN_PIXEL_SIZE.x > SCREEN_PIXEL_SIZE.y)				// determine how to scale
			? vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1)				// fit to width
			: vec2(1, SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y);				// fit to height

		frag_coord *= ratio;
		frag_coord += ((vec2(1,1) - ratio) / 2.0);
	}

	// get the blend factor between the previous and next background.
	float alpha = (texture(wipe_texture, frag_coord).r) - progress;
	float blend_factor = 1. - smoothstep(0., feather, alpha + (feather * (1. -progress)));

	vec4 old_frag = texture(previous_background, UV);
	vec4 new_frag = texture(next_background, UV);

	COLOR = mix(old_frag, new_frag, blend_factor);
}
