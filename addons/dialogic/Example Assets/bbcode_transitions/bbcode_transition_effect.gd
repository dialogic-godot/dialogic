@tool
class_name DialogicRichTextTransitionEffect
extends RichTextEffect

## A custom richt text effect class, that allows to easily animate letters when revealed.
## The DialogicNode_DialogText node correctly updates the [member visible_characters] and calls the [method reset] and [method skip].
## You can simply create a resource of this, edit it in the inspector and add it's path/uid to
## dialogics custom bbcode effects setting.

## Controlled by the DialogText node.
var visible_characters := -1

## The bbcode effect name.
@export var bbcode := "animate_in"
var _cache := []

## The length of the transition time.
@export_range(0.0, 5.0, 0.01) var time := 0.2
@export_group("Color", "color")
## A gradient modulating the color of text over the transition time.
## Use a transparent to white gradient to fade in the text.
@export var color_modulate: Gradient = null
## Allows to overwrite the color of the text, with transparency meaning no effect on the text color.
@export var color_replace: Gradient = null

@export_group("Scale", "scale")
## Enables the scale curve animation.
@export var scale_enabled := false
## A curve animating the scale of the character. Should end at 1.
@export var scale_curve := Curve.new()
## The pivot from which scaling is applied. Vector2(0,0) is a the bottom left of the character, Vector2(1, 1) at the top right.
@export var scale_pivot := Vector2()

@export_group("Position", "position")
## Enables the position curve animations.
@export var position_enabled := false
## A curve animating the x position of the character. Should end at 0.
@export var position_x_curve := Curve.new()
## A curve animating the y position of the character. Should end at 0.
@export var position_y_curve := Curve.new()

@export_group("Test", "test")
## Can be used to preview the animation on all the text at once. Is ignored when less then 0. 1 is the end of the animation independent of its length.
@export_range(-0.1, 1.0, 0.1) var test_value := -0.1

var _was_skipped := false
var _was_reset := false


## Called by the DialogText node when the text is cleared/changed.
func reset() -> void:
	_was_reset = true
	_was_skipped = false
	_cache.clear()


## Called by the DialogText node when the reveal was skipped, so it also skips the animation.
func skip() -> void:
	_was_skipped = true


## Actually process the animation of the characters.
func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var char_age :float = 0.0
	if test_value >= 0:
		char_age = remap(test_value, 0, 1, 0, time)

	else:
		if visible_characters == 0:
			_cache.clear()
			return false
		if _was_reset:
			if visible_characters != -1:
				_was_reset = false
			else:
				return false

		if len(_cache) < visible_characters or visible_characters == -1 or _was_skipped:
			if char_fx.range.x >= len(_cache):
				_cache.append(char_fx.elapsed_time)

		if _was_skipped:
			for i in range(len(_cache)):
				_cache[i] = char_fx.elapsed_time-time

		if len(_cache) > char_fx.range.x:
			char_age = char_fx.elapsed_time - _cache[char_fx.range.x]

	var text_server := TextServerManager.get_primary_interface()
	var trans: float = clamp(char_age, 0.0, time)/time

	if color_replace:
		var c := color_replace.sample(trans)
		c.a = 1
		char_fx.color = char_fx.color.lerp(c, color_replace.sample(trans).a)
	if color_modulate:
		char_fx.color *= color_modulate.sample(trans)
	if char_fx.font.is_valid():
		var glyph_size := text_server.font_get_glyph_size(char_fx.font, Vector2i(16,1), char_fx.glyph_index)
		if scale_enabled:
			char_fx.transform = char_fx.transform.translated_local(scale_pivot*glyph_size*Vector2(1, -1)*(1-scale_curve.sample(trans)))
			char_fx.transform = char_fx.transform.scaled_local(Vector2.ONE*scale_curve.sample(trans))

		if position_enabled:
			char_fx.transform = char_fx.transform.translated_local(Vector2(position_x_curve.sample(trans), position_y_curve.sample(trans))*glyph_size)

	return true
